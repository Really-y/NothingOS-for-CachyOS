pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared UI state: which panel is open and on which screen.
Singleton {
    id: root
    property var qsScreen: null        // quick settings open on this screen (null = closed)
    property var launcherScreen: null
    property var lastScreen: Quickshell.screens[0]
    property bool nightLight: false

    function toggleQs(screen) {
        launcherScreen = null;
        qsScreen = (qsScreen === screen) ? null : screen;
        if (qsScreen) Notifs.markRead();
    }
    function toggleLauncher(screen) {
        qsScreen = null;
        const s = screen || lastScreen;
        launcherScreen = launcherScreen ? null : s;
    }
    function closeAll() { qsScreen = null; launcherScreen = null; }

    function run(cmd) { runner.command = cmd; runner.running = true; }
    Process { id: runner }

    function toggleNightLight() {
        nightLight = !nightLight;
        run(["sh", "-c", "kwriteconfig6 --file kwinrc --group NightColor --key Active " + nightLight
             + " && qdbus6 org.kde.KWin /KWin reconfigure"]);
    }
    Process {
        running: true
        command: ["kreadconfig6", "--file", "kwinrc", "--group", "NightColor", "--key", "Active"]
        stdout: StdioCollector { onStreamFinished: root.nightLight = text.trim() === "true" }
    }
}
