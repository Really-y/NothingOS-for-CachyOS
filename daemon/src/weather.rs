//! Open-Meteo current weather (only the configured coordinates are sent).

use crate::config::WeatherConfig;
use serde::Deserialize;
use serde_json::json;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

#[derive(Deserialize)]
struct Resp {
    current: Current,
    daily: Daily,
}

#[derive(Deserialize)]
struct Current {
    temperature_2m: f64,
    weather_code: i64,
}

#[derive(Deserialize)]
struct Daily {
    temperature_2m_max: Vec<Option<f64>>,
    temperature_2m_min: Vec<Option<f64>>,
}

/// WMO weather interpretation code -> (Material Symbols icon, short description).
pub fn wmo(code: i64) -> (&'static str, &'static str) {
    match code {
        0 => ("clear_day", "Clear"),
        1 => ("clear_day", "Mostly clear"),
        2 => ("partly_cloudy_day", "Partly cloudy"),
        3 => ("cloud", "Cloudy"),
        45 | 48 => ("foggy", "Fog"),
        51 | 53 | 55 => ("rainy", "Drizzle"),
        56 | 57 => ("rainy", "Freezing drizzle"),
        61 | 63 => ("rainy", "Rain"),
        65 => ("rainy", "Heavy rain"),
        66 | 67 => ("rainy", "Freezing rain"),
        71 | 73 | 75 | 77 => ("weather_snowy", "Snow"),
        80 | 81 | 82 => ("rainy", "Showers"),
        85 | 86 => ("weather_snowy", "Snow showers"),
        95 => ("thunderstorm", "Thunderstorm"),
        96 | 99 => ("thunderstorm", "Thunderstorm, hail"),
        _ => ("cloud", "Unknown"),
    }
}

fn now_unix() -> u64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0)
}

/// JSON used before the first successful fetch / when no data is available.
pub fn unavailable_json(city: &str) -> String {
    json!({
        "ok": false, "temp": null, "hi": null, "lo": null, "code": null,
        "icon": "cloud", "desc": "Unavailable", "city": city, "updated": 0,
    })
    .to_string()
}

/// Blocking fetch; call from `spawn_blocking`. Returns the Weather() JSON on success.
pub fn fetch(cfg: &WeatherConfig) -> Result<String, String> {
    let url = format!(
        "https://api.open-meteo.com/v1/forecast?latitude={:.4}&longitude={:.4}\
         &current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min\
         &forecast_days=1&timezone=auto",
        cfg.lat, cfg.lon
    );
    let agent: ureq::Agent = ureq::Agent::config_builder()
        .timeout_global(Some(Duration::from_secs(20)))
        .user_agent("nothingd/0.1")
        .build()
        .into();
    let mut resp = agent.get(&url).call().map_err(|e| format!("request failed: {e}"))?;
    let body = resp.body_mut().read_to_string().map_err(|e| format!("read failed: {e}"))?;
    let r: Resp = serde_json::from_str(&body).map_err(|e| format!("bad response: {e}"))?;

    let temp = r.current.temperature_2m.round() as i64;
    let hi = r.daily.temperature_2m_max.first().copied().flatten().map(|v| v.round() as i64).unwrap_or(temp);
    let lo = r.daily.temperature_2m_min.first().copied().flatten().map(|v| v.round() as i64).unwrap_or(temp);
    let code = r.current.weather_code;
    let (icon, desc) = wmo(code);
    Ok(json!({
        "ok": true, "temp": temp, "hi": hi, "lo": lo, "code": code,
        "icon": icon, "desc": desc, "city": cfg.city, "updated": now_unix(),
    })
    .to_string())
}
