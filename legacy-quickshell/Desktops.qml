pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// KWin virtual desktops over DBus.
Singleton {
    id: root
    property int count: 1
    property int current: 1

    function go(n) { sw.command = ["qdbus6", "org.kde.KWin", "/KWin", "org.kde.KWin.setCurrentDesktop", String(n)]; sw.running = true; }
    function refresh() { q.running = true; }

    Process {
        id: q
        command: ["sh", "-c", "qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.count; qdbus6 org.kde.KWin /KWin org.kde.KWin.currentDesktop"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.count = parseInt(l[0]) || 1;
                root.current = parseInt(l[1]) || 1;
            }
        }
    }
    Process { id: sw; onExited: root.refresh() }
    Process {
        running: true
        command: ["dbus-monitor", "--session", "type='signal',interface='org.kde.KWin.VirtualDesktopManager'"]
        stdout: SplitParser { onRead: _ => deb.restart() }
    }
    Timer { id: deb; interval: 120; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
