//! `~/.config/nothingos/config.toml` loading (created with defaults if missing).

use serde::Deserialize;
use std::path::PathBuf;

pub const DEFAULT_LAT: f64 = 40.4093;
pub const DEFAULT_LON: f64 = 49.8671;
pub const DEFAULT_CITY: &str = "BAKU";

const DEFAULT_FILE: &str = r#"# NothingOS configuration (read by nothingd)

[weather]
# Only these coordinates are sent to api.open-meteo.com.
lat = 40.4093
lon = 49.8671
city = "BAKU"
"#;

#[derive(Debug, Clone)]
pub struct WeatherConfig {
    pub lat: f64,
    pub lon: f64,
    pub city: String,
}

impl Default for WeatherConfig {
    fn default() -> Self {
        Self { lat: DEFAULT_LAT, lon: DEFAULT_LON, city: DEFAULT_CITY.to_string() }
    }
}

#[derive(Deserialize, Default)]
struct RawConfig {
    weather: Option<RawWeather>,
}

#[derive(Deserialize, Default)]
struct RawWeather {
    lat: Option<f64>,
    lon: Option<f64>,
    city: Option<String>,
}

pub fn home_dir() -> PathBuf {
    std::env::var_os("HOME").map(PathBuf::from).unwrap_or_else(|| PathBuf::from("/tmp"))
}

pub fn config_path() -> PathBuf {
    let base = std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .filter(|p| p.is_absolute())
        .unwrap_or_else(|| home_dir().join(".config"));
    base.join("nothingos").join("config.toml")
}

/// Load the weather section. Never fails: falls back to defaults and logs.
pub fn load_weather() -> WeatherConfig {
    let path = config_path();
    if !path.exists() {
        if let Some(dir) = path.parent() {
            if let Err(e) = std::fs::create_dir_all(dir) {
                eprintln!("nothingd: cannot create {}: {e}", dir.display());
            }
        }
        match std::fs::write(&path, DEFAULT_FILE) {
            Ok(()) => eprintln!("nothingd: wrote default config {}", path.display()),
            Err(e) => eprintln!("nothingd: cannot write {}: {e}", path.display()),
        }
        return WeatherConfig::default();
    }
    let text = match std::fs::read_to_string(&path) {
        Ok(t) => t,
        Err(e) => {
            eprintln!("nothingd: cannot read {}: {e}", path.display());
            return WeatherConfig::default();
        }
    };
    let raw: RawConfig = match toml::from_str(&text) {
        Ok(r) => r,
        Err(e) => {
            eprintln!("nothingd: invalid {}: {e}", path.display());
            return WeatherConfig::default();
        }
    };
    let w = raw.weather.unwrap_or_default();
    let d = WeatherConfig::default();
    let valid_lat = w.lat.filter(|v| v.is_finite() && (-90.0..=90.0).contains(v));
    let valid_lon = w.lon.filter(|v| v.is_finite() && (-180.0..=180.0).contains(v));
    WeatherConfig {
        lat: valid_lat.unwrap_or(d.lat),
        lon: valid_lon.unwrap_or(d.lon),
        city: w.city.filter(|c| !c.trim().is_empty()).unwrap_or(d.city),
    }
}
