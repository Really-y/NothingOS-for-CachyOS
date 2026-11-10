pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared UI state: which panel is open and on which screen.
Singleton {
    id: root
    property var qsScreen: null        // quick settings open on this screen (null = closed)
    property var launcherScreen: null
    readonly property var primary: {
        const ss = Quickshell.screens;
        for (const s of ss) if (s.name === Theme.primaryScreen) return s;
        return ss.length ? ss[0] : null;
    }
    property var lastScreen: null
    function pick(s) { return s || lastScreen || primary; }
    property bool nightLight: false

    function toggleQs(screen) {
        launcherScreen = null;
        const s = pick(screen);
        qsScreen = (qsScreen === s) ? null : s;
        if (qsScreen) Notifs.markRead();
    }
    function toggleLauncher(screen) {
        qsScreen = null;
        launcherScreen = launcherScreen ? null : pick(screen);
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
