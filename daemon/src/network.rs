//! NetworkManager state via `nmcli -t`.

use serde_json::json;
use std::process::Stdio;
use std::time::Duration;
use tokio::process::Command;

/// Run a command with a timeout, returning stdout on success.
pub async fn run(cmd: &str, args: &[&str]) -> Option<String> {
    let fut = Command::new(cmd)
        .args(args)
        .env("LC_ALL", "C")
        .stdin(Stdio::null())
        .stderr(Stdio::piped())
        .kill_on_drop(true)
        .output();
    match tokio::time::timeout(Duration::from_secs(10), fut).await {
        Ok(Ok(out)) if out.status.success() => Some(String::from_utf8_lossy(&out.stdout).into_owned()),
        Ok(Ok(out)) => {
            eprintln!(
                "nothingd: `{cmd} {}` failed ({}): {}",
                args.join(" "),
                out.status,
                String::from_utf8_lossy(&out.stderr).trim()
            );
            None
        }
        Ok(Err(e)) => {
            eprintln!("nothingd: cannot run {cmd}: {e}");
            None
        }
        Err(_) => {
            eprintln!("nothingd: `{cmd} {}` timed out", args.join(" "));
            None
        }
    }
}

/// Split one `nmcli -t` line on unescaped ':' and unescape `\:` / `\\`.
fn split_terse(line: &str) -> Vec<String> {
    let mut fields = vec![String::new()];
    let mut chars = line.chars();
    while let Some(c) = chars.next() {
        match c {
            '\\' => {
                if let Some(n) = chars.next() {
                    fields.last_mut().unwrap().push(n);
                }
            }
            ':' => fields.push(String::new()),
            _ => fields.last_mut().unwrap().push(c),
        }
    }
    fields
}

pub async fn build_json() -> String {
    let wifi_enabled = run("nmcli", &["-t", "-f", "WIFI", "radio"])
        .await
        .map(|s| s.trim() == "enabled")
        .unwrap_or(false);

    let mut wifi_name: Option<String> = None;
    let mut eth_name: Option<String> = None;
    if let Some(out) = run("nmcli", &["-t", "-f", "TYPE,NAME", "connection", "show", "--active"]).await {
        for line in out.lines() {
            let f = split_terse(line);
            if f.len() < 2 {
                continue;
            }
            match f[0].as_str() {
                "802-11-wireless" | "wifi" if wifi_name.is_none() => wifi_name = Some(f[1].clone()),
                "802-3-ethernet" | "ethernet" if eth_name.is_none() => eth_name = Some(f[1].clone()),
                _ => {}
            }
        }
    }

    let (kind, name, signal) = if let Some(name) = wifi_name {
        let mut signal = 0i64;
        if let Some(out) =
            run("nmcli", &["-t", "-f", "ACTIVE,SIGNAL", "device", "wifi", "list", "--rescan", "no"]).await
        {
            for line in out.lines() {
                let f = split_terse(line);
                if f.len() >= 2 && f[0] == "yes" {
                    signal = f[1].trim().parse().unwrap_or(0);
                    break;
                }
            }
        }
        ("wifi", name, signal)
    } else if let Some(name) = eth_name {
        ("ethernet", name, 0)
    } else {
        ("none", String::new(), 0)
    };

    json!({ "wifiEnabled": wifi_enabled, "kind": kind, "name": name, "signal": signal }).to_string()
}

pub async fn set_wifi(on: bool) -> bool {
    run("nmcli", &["radio", "wifi", if on { "on" } else { "off" }]).await.is_some()
}
