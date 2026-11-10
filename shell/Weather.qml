pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Open-Meteo (no API key). Sends only the configured coordinates.
Singleton {
    id: root
    property bool ok: false
    property int temp: 0
    property int hi: 0
    property int lo: 0
    property int code: 0
    readonly property string icon: iconFor(code)
    readonly property string desc: descFor(code)

    function iconFor(c) {
        if (c === 0) return "clear_day";
        if (c <= 2) return "partly_cloudy_day";
        if (c === 3) return "cloud";
        if (c <= 48) return "foggy";
        if (c <= 67 || (c >= 80 && c <= 82)) return "rainy";
        if (c <= 77 || c === 85 || c === 86) return "weather_snowy";
        return "thunderstorm";
    }
    function descFor(c) {
        if (c === 0) return "Clear";
        if (c <= 2) return "Partly cloudy";
        if (c === 3) return "Cloudy";
        if (c <= 48) return "Fog";
        if (c <= 57) return "Drizzle";
        if (c <= 67) return "Rain";
        if (c <= 77) return "Snow";
        if (c <= 82) return "Showers";
        if (c <= 86) return "Snow showers";
        return "Storm";
    }

    Process {
        id: fetch
        command: ["curl", "-fsS", "--max-time", "15",
            "https://api.open-meteo.com/v1/forecast?latitude=" + Theme.lat + "&longitude=" + Theme.lon
            + "&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min&forecast_days=1&timezone=auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    root.temp = Math.round(j.current.temperature_2m);
                    root.code = j.current.weather_code;
                    root.hi = Math.round(j.daily.temperature_2m_max[0]);
                    root.lo = Math.round(j.daily.temperature_2m_min[0]);
                    root.ok = true;
                } catch (e) { root.ok = false; }
            }
        }
    }
    Timer { interval: 15 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetch.running = true }
}
