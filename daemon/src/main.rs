//! nothingd — session DBus daemon for the NothingOS Plasma theme.
//!
//! Service `org.nothing.Daemon`, object `/org/nothing/Daemon`, interface `org.nothing.Daemon1`.
//! Data methods return JSON strings; `Changed(s topic)` is emitted for "stats", "weather", "network".

mod config;
mod network;
mod stats;
mod weather;

use std::process::Stdio;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::Command;
use tokio::sync::Notify;
use zbus::object_server::SignalEmitter;
use zbus::{connection, interface, Connection};

const BUS_NAME: &str = "org.nothing.Daemon";
const OBJ_PATH: &str = "/org/nothing/Daemon";

const STATS_INTERVAL: Duration = Duration::from_secs(2);
const WEATHER_INTERVAL: Duration = Duration::from_secs(15 * 60);
const WEATHER_RETRY: Duration = Duration::from_secs(2 * 60);
const NETWORK_POLL: Duration = Duration::from_secs(30);

struct Shared {
    stats: Mutex<String>,
    weather: Mutex<String>,
    network: Mutex<String>,
    net_refresh: Notify,
}

fn get(m: &Mutex<String>) -> String {
    m.lock().map(|s| s.clone()).unwrap_or_else(|e| e.into_inner().clone())
}

/// Store a value; returns true if it changed.
fn set(m: &Mutex<String>, v: String) -> bool {
    let mut g = m.lock().unwrap_or_else(|e| e.into_inner());
    if *g == v {
        false
    } else {
        *g = v;
        true
    }
}

struct Daemon {
    shared: Arc<Shared>,
}

#[interface(name = "org.nothing.Daemon1")]
impl Daemon {
    /// `{"cpu","mem","memUsedGb","memTotalGb","tempC","uptimeS"}`
    async fn stats(&self) -> String {
        get(&self.shared.stats)
    }

    /// `{"ok","temp","hi","lo","code","icon","desc","city","updated"}`
    async fn weather(&self) -> String {
        get(&self.shared.weather)
    }

    /// `{"wifiEnabled","kind","name","signal"}`
    async fn network(&self) -> String {
        get(&self.shared.network)
    }

    async fn set_wifi(&self, on: bool) -> bool {
        let ok = network::set_wifi(on).await;
        eprintln!("nothingd: SetWifi({on}) -> {ok}");
        self.shared.net_refresh.notify_one();
        ok
    }

    async fn play_sound(&self, event: String) {
        play_sound(&event);
    }

    #[zbus(signal)]
    async fn changed(emitter: &SignalEmitter<'_>, topic: &str) -> zbus::Result<()>;
}

fn sanitize_event(event: &str) -> String {
    event
        .to_ascii_lowercase()
        .chars()
        .filter(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || *c == '-')
        .take(64)
        .collect()
}

fn play_sound(event: &str) {
    let ev = sanitize_event(event);
    if ev.is_empty() {
        eprintln!("nothingd: PlaySound: empty/invalid event {event:?}");
        return;
    }
    let path = config::home_dir().join(format!(".local/share/sounds/nothing/stereo/{ev}.oga"));
    if !path.is_file() {
        eprintln!("nothingd: PlaySound: missing {}", path.display());
        return;
    }
    match Command::new("pw-play")
        .arg(&path)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
    {
        Ok(mut child) => {
            // Reap the child so it never becomes a zombie.
            tokio::spawn(async move {
                let _ = child.wait().await;
            });
        }
        Err(e) => eprintln!("nothingd: PlaySound: cannot run pw-play: {e}"),
    }
}

async fn emit(conn: &Connection, topic: &str) {
    match SignalEmitter::new(conn, OBJ_PATH) {
        Ok(em) => {
            if let Err(e) = Daemon::changed(&em, topic).await {
                eprintln!("nothingd: emit Changed({topic}) failed: {e}");
            }
        }
        Err(e) => eprintln!("nothingd: signal emitter error: {e}"),
    }
}

async fn stats_task(
    conn: Connection,
    shared: Arc<Shared>,
    sensor: Option<std::path::PathBuf>,
    mut prev: Option<stats::CpuSample>,
) {
    let mut tick = tokio::time::interval(STATS_INTERVAL);
    tick.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);
    tick.tick().await; // first tick is immediate
    loop {
        tick.tick().await;
        let cur = stats::read_cpu();
        let cpu = match (prev, cur) {
            (Some(p), Some(c)) => stats::cpu_usage(p, c),
            _ => 0.0,
        };
        prev = cur;
        set(&shared.stats, stats::build_json(cpu, sensor.as_deref()));
        emit(&conn, "stats").await;
    }
}

async fn weather_task(conn: Connection, shared: Arc<Shared>) {
    loop {
        let cfg = config::load_weather();
        let res = tokio::task::spawn_blocking(move || weather::fetch(&cfg))
            .await
            .unwrap_or_else(|e| Err(format!("task failed: {e}")));
        let wait = match res {
            Ok(json) => {
                set(&shared.weather, json);
                emit(&conn, "weather").await;
                WEATHER_INTERVAL
            }
            Err(e) => {
                eprintln!("nothingd: weather: {e}");
                WEATHER_RETRY
            }
        };
        tokio::time::sleep(wait).await;
    }
}

/// Refreshes network state whenever notified (debounced) or every NETWORK_POLL.
async fn network_task(conn: Connection, shared: Arc<Shared>) {
    loop {
        let json = network::build_json().await;
        if set(&shared.network, json) {
            emit(&conn, "network").await;
        }
        let _ = tokio::time::timeout(NETWORK_POLL, shared.net_refresh.notified()).await;
        // Debounce bursts of nmcli monitor events.
        tokio::time::sleep(Duration::from_millis(400)).await;
    }
}

/// Follows `nmcli monitor` and pokes the network task on every event line.
async fn nm_monitor_task(shared: Arc<Shared>) {
    loop {
        match Command::new("nmcli")
            .arg("monitor")
            .env("LC_ALL", "C")
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .kill_on_drop(true)
            .spawn()
        {
            Ok(mut child) => {
                if let Some(out) = child.stdout.take() {
                    let mut lines = BufReader::new(out).lines();
                    while let Ok(Some(_)) = lines.next_line().await {
                        shared.net_refresh.notify_one();
                    }
                }
                let _ = child.wait().await;
                eprintln!("nothingd: nmcli monitor exited; restarting in 10 s");
            }
            Err(e) => eprintln!("nothingd: cannot run nmcli monitor: {e}; retrying in 10 s"),
        }
        tokio::time::sleep(Duration::from_secs(10)).await;
    }
}

#[tokio::main(flavor = "multi_thread", worker_threads = 2)]
async fn main() {
    let city = config::load_weather().city;

    // Prime Stats() so the very first call (e.g. right after DBus activation) has real data.
    let sensor = stats::find_temp_sensor();
    match &sensor {
        Some(p) => eprintln!("nothingd: temperature sensor {}", p.display()),
        None => eprintln!("nothingd: no temperature sensor found"),
    }
    let first = stats::read_cpu();
    tokio::time::sleep(Duration::from_millis(250)).await;
    let second = stats::read_cpu();
    let cpu0 = match (first, second) {
        (Some(a), Some(b)) => stats::cpu_usage(a, b),
        _ => 0.0,
    };

    let shared = Arc::new(Shared {
        stats: Mutex::new(stats::build_json(cpu0, sensor.as_deref())),
        weather: Mutex::new(weather::unavailable_json(&city)),
        network: Mutex::new(
            r#"{"wifiEnabled":false,"kind":"none","name":"","signal":0}"#.to_string(),
        ),
        net_refresh: Notify::new(),
    });

    let daemon = Daemon { shared: shared.clone() };
    let conn = match connection::Builder::session()
        .and_then(|b| b.name(BUS_NAME))
        .and_then(|b| b.serve_at(OBJ_PATH, daemon))
    {
        Ok(b) => match b.build().await {
            Ok(c) => c,
            Err(e) => {
                eprintln!("nothingd: cannot connect/own {BUS_NAME}: {e}");
                std::process::exit(1);
            }
        },
        Err(e) => {
            eprintln!("nothingd: dbus setup failed: {e}");
            std::process::exit(1);
        }
    };
    eprintln!("nothingd: serving {BUS_NAME} at {OBJ_PATH}");

    tokio::spawn(stats_task(conn.clone(), shared.clone(), sensor, second));
    tokio::spawn(weather_task(conn.clone(), shared.clone()));
    tokio::spawn(network_task(conn.clone(), shared.clone()));
    tokio::spawn(nm_monitor_task(shared.clone()));

    // Run until SIGTERM/SIGINT; zbus handles requests on its own executor tasks.
    use tokio::signal::unix::{signal, SignalKind};
    match signal(SignalKind::terminate()) {
        Ok(mut term) => {
            tokio::select! {
                _ = term.recv() => {}
                _ = tokio::signal::ctrl_c() => {}
            }
        }
        Err(_) => {
            let _ = tokio::signal::ctrl_c().await;
        }
    }
    eprintln!("nothingd: exiting");
}
