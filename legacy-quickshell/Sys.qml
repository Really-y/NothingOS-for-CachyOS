pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root
    property real cpu: 0
    property real mem: 0
    property real memUsedGb: 0
    property var _prev: null

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isLaptopBattery
    readonly property real batteryLevel: hasBattery ? battery.percentage : 0
    readonly property bool charging: hasBattery && battery.state === UPowerDeviceState.Charging

    FileView { id: stat; path: "/proc/stat" }
    FileView { id: meminfo; path: "/proc/meminfo" }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { stat.reload(); meminfo.reload(); root.parse(); }
    }
    function parse() {
        const s = stat.text();
        if (s) {
            const f = s.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
            if (_prev) {
                const dt = total - _prev.total, di = idle - _prev.idle;
                cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
            }
            _prev = { total: total, idle: idle };
        }
        const m = meminfo.text();
        if (m) {
            const get = k => { const r = new RegExp("^" + k + ":\\s+(\\d+)", "m").exec(m); return r ? Number(r[1]) : 0; };
            const tot = get("MemTotal"), av = get("MemAvailable");
            mem = tot ? 1 - av / tot : 0;
            memUsedGb = (tot - av) / 1048576;
        }
    }
}
