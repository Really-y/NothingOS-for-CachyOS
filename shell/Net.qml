pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// NetworkManager via nmcli (robust, no extra deps) + Quickshell Bluetooth.
Singleton {
    id: root
    property bool wifiOn: false
    property string kind: "none"          // wifi | ethernet | none
    property string name: ""
    property int signal: 0
    readonly property string icon: kind === "ethernet" ? "lan"
                                  : kind === "wifi" ? (signal > 66 ? "wifi" : signal > 33 ? "wifi_2_bar" : "wifi_1_bar")
                                  : wifiOn ? "wifi_find" : "wifi_off"

    readonly property var bt: Bluetooth.defaultAdapter
    readonly property bool btOn: !!(bt && bt.enabled)
    readonly property int btConnected: {
        if (!bt) return 0;
        let c = 0;
        for (const d of bt.devices.values) if (d.connected) c++;
        return c;
    }

    function refresh() { status.running = true; }
    function toggleWifi() { cmd.command = ["nmcli", "radio", "wifi", wifiOn ? "off" : "on"]; cmd.running = true; wifiOn = !wifiOn; }
    function toggleBt() { if (bt) bt.enabled = !bt.enabled; }

    Process {
        id: status
        command: ["sh", "-c", "nmcli -t -f WIFI g; nmcli -t -f TYPE,STATE,CONNECTION d; nmcli -t -f ACTIVE,SIGNAL d wifi 2>/dev/null | grep '^yes' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.wifiOn = lines[0] === "enabled";
                let k = "none", n = "", s = 0;
                for (const l of lines.slice(1)) {
                    const p = l.split(":");
                    if (p[0] === "yes") { s = parseInt(p[1]) || 0; continue; }
                    if (p[1] === "connected" && k === "none" && (p[0] === "ethernet" || p[0] === "wifi")) { k = p[0]; n = p.slice(2).join(":"); }
                }
                root.kind = k; root.name = n; root.signal = s;
            }
        }
    }
    Process { id: cmd; onExited: root.refresh() }
    // react to NetworkManager events instead of polling hard
    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: _ => debounce.restart() }
    }
    Timer { id: debounce; interval: 400; onTriggered: root.refresh() }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
