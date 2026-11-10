//! CPU / memory / temperature / uptime from procfs and sysfs.

use serde_json::json;
use std::fs;
use std::path::{Path, PathBuf};

/// Aggregate CPU counters from the first line of /proc/stat.
#[derive(Clone, Copy, Debug)]
pub struct CpuSample {
    idle: u64,
    total: u64,
}

pub fn read_cpu() -> Option<CpuSample> {
    let text = fs::read_to_string("/proc/stat").ok()?;
    let line = text.lines().find(|l| l.starts_with("cpu "))?;
    let vals: Vec<u64> = line.split_whitespace().skip(1).filter_map(|v| v.parse().ok()).collect();
    if vals.len() < 4 {
        return None;
    }
    // user nice system idle iowait irq softirq steal [guest guest_nice]
    // guest/guest_nice are already included in user/nice, so only sum the first 8.
    let total: u64 = vals.iter().take(8).sum();
    let idle = vals[3] + vals.get(4).copied().unwrap_or(0);
    Some(CpuSample { idle, total })
}

pub fn cpu_usage(prev: CpuSample, cur: CpuSample) -> f64 {
    let dt = cur.total.saturating_sub(prev.total);
    let di = cur.idle.saturating_sub(prev.idle);
    if dt == 0 {
        return 0.0;
    }
    (1.0 - di as f64 / dt as f64).clamp(0.0, 1.0)
}

/// (total_kib, available_kib)
fn read_meminfo() -> Option<(u64, u64)> {
    let text = fs::read_to_string("/proc/meminfo").ok()?;
    let mut total = None;
    let mut avail = None;
    for line in text.lines() {
        let mut it = line.split_whitespace();
        match (it.next(), it.next().and_then(|v| v.parse::<u64>().ok())) {
            (Some("MemTotal:"), Some(v)) => total = Some(v),
            (Some("MemAvailable:"), Some(v)) => avail = Some(v),
            _ => {}
        }
    }
    Some((total?, avail?))
}

fn read_uptime() -> Option<u64> {
    let text = fs::read_to_string("/proc/uptime").ok()?;
    let secs: f64 = text.split_whitespace().next()?.parse().ok()?;
    Some(secs as u64)
}

fn read_trim(p: &Path) -> Option<String> {
    fs::read_to_string(p).ok().map(|s| s.trim().to_string())
}

fn read_milli_c(p: &Path) -> Option<f64> {
    let v: f64 = read_trim(p)?.parse().ok()?;
    let c = v / 1000.0;
    // Discard obviously bogus readings.
    (c > -50.0 && c < 150.0).then_some(c)
}

/// Locate the best CPU temperature sensor input file once.
/// Preference: k10temp Tctl -> coretemp "Package id" -> zenpower Tdie -> first temp1_input.
pub fn find_temp_sensor() -> Option<PathBuf> {
    let mut dirs: Vec<PathBuf> = fs::read_dir("/sys/class/hwmon")
        .ok()?
        .filter_map(|e| e.ok().map(|e| e.path()))
        .collect();
    dirs.sort();

    let labeled = |dir: &Path, want: &dyn Fn(&str) -> bool| -> Option<PathBuf> {
        let mut entries: Vec<PathBuf> = fs::read_dir(dir).ok()?.filter_map(|e| e.ok().map(|e| e.path())).collect();
        entries.sort();
        for p in entries {
            let name = p.file_name()?.to_str()?.to_string();
            if name.starts_with("temp") && name.ends_with("_label") {
                if let Some(label) = read_trim(&p) {
                    if want(&label) {
                        let input = dir.join(name.replace("_label", "_input"));
                        if read_milli_c(&input).is_some() {
                            return Some(input);
                        }
                    }
                }
            }
        }
        None
    };

    let named: Vec<(String, PathBuf)> =
        dirs.iter().filter_map(|d| Some((read_trim(&d.join("name"))?, d.clone()))).collect();

    let prefs: [(&str, &dyn Fn(&str) -> bool); 3] = [
        ("k10temp", &|l: &str| l == "Tctl"),
        ("coretemp", &|l: &str| l.starts_with("Package")),
        ("zenpower", &|l: &str| l == "Tdie" || l == "Tctl"),
    ];
    for (chip, want) in prefs {
        for (n, d) in &named {
            if n == chip {
                if let Some(p) = labeled(d, want) {
                    return Some(p);
                }
                let t1 = d.join("temp1_input");
                if read_milli_c(&t1).is_some() {
                    return Some(t1);
                }
            }
        }
    }
    dirs.iter().map(|d| d.join("temp1_input")).find(|p| read_milli_c(p).is_some())
}

fn round(v: f64, places: i32) -> f64 {
    let m = 10f64.powi(places);
    (v * m).round() / m
}

/// Build the Stats() JSON string.
pub fn build_json(cpu: f64, temp_path: Option<&Path>) -> String {
    const KIB_PER_GIB: f64 = 1024.0 * 1024.0;
    let (mem, used_gb, total_gb) = match read_meminfo() {
        Some((total, avail)) if total > 0 => {
            let used = total.saturating_sub(avail);
            (used as f64 / total as f64, used as f64 / KIB_PER_GIB, total as f64 / KIB_PER_GIB)
        }
        _ => (0.0, 0.0, 0.0),
    };
    let temp = temp_path.and_then(read_milli_c).map(|c| round(c, 1));
    json!({
        "cpu": round(cpu, 3),
        "mem": round(mem, 3),
        "memUsedGb": round(used_gb, 1),
        "memTotalGb": round(total_gb, 1),
        "tempC": temp,
        "uptimeS": read_uptime().unwrap_or(0),
    })
    .to_string()
}
