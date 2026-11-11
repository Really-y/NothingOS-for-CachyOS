import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.drawer/contents/ui"
import "../plasma/plasmoids/org.nothing.drawer/contents/ui/iconmap.js" as IconMap

// App drawer mock: panel glyph (closed/open), idle drawer, searching drawer.
Rectangle {
    color: "#060606"
    // mock of the theme scan in main.qml (names that really ship as -symbolic here)
    readonly property var sym: {
        // mock of main.qml's theme scan: glyph names that ship in Papirus/Breeze here
        const n = ["firefox", "system-file-manager", "utilities-terminal", "accessories-calculator", "kate", "utilities-system-monitor",
                   "vlc", "audio-x-generic", "video-x-generic", "web-browser", "preferences-system", "image-x-generic",
                   "package-x-generic", "applications-games", "applications-development", "system-software-install",
                   "im-user", "x-office-document", "applications-internet", "help-browser", "draw-brush", "applications-graphics",
                   "accessories-text-editor", "text-editor", "dialog-scripts", "system-run", "emblem-photos", "folder-open",
                   "emblem-music", "media-playback-start", "code-context", "applications-all", "accessories-screenshot",
                   "settings-configure", "input-gaming", "preferences-system-network"];
        const o = {}; for (const k of n) o[k + "-symbolic"] = true; return o;
    }
    // same distinct assignment main.qml does over the installed apps
    readonly property var glyphs: {
        const a = [];
        for (const m of [pinned, apps, found]) for (let i = 0; i < m.count; i++) {
            const e = m.get(i); a.push({ key: e.decoration + "|" + e.display, name: e.display, source: e.decoration, hint: e.display });
        }
        return IconMap.assign(a, sym);
    }
    ListModel {
        id: pinned
        ListElement { display: "Firefox"; decoration: "firefox" }
        ListElement { display: "Dolphin"; decoration: "org.kde.dolphin" }
        ListElement { display: "Konsole"; decoration: "org.kde.konsole" }
        ListElement { display: "Spotify"; decoration: "spotify-client" }
        ListElement { display: "Settings"; decoration: "systemsettings" }
    }
    ListModel {
        id: apps
        ListElement { display: "Alacritty"; decoration: "Alacritty" }
        ListElement { display: "Ark"; decoration: "ark" }
        ListElement { display: "Calculator"; decoration: "accessories-calculator" }
        ListElement { display: "Discover"; decoration: "plasmadiscover" }
        ListElement { display: "Dolphin"; decoration: "org.kde.dolphin" }
        ListElement { display: "Firefox"; decoration: "firefox" }
        ListElement { display: "GIMP"; decoration: "gimp" }
        ListElement { display: "Gwenview"; decoration: "gwenview" }
        ListElement { display: "Kate"; decoration: "kate" }
        ListElement { display: "Konsole"; decoration: "org.kde.konsole" }
        ListElement { display: "Krita"; decoration: "krita" }
        ListElement { display: "Okular"; decoration: "okular" }
        ListElement { display: "Spectacle"; decoration: "spectacle" }
        ListElement { display: "Steam"; decoration: "steam" }
        ListElement { display: "System Monitor"; decoration: "utilities-system-monitor" }
        ListElement { display: "VLC"; decoration: "vlc" }
        ListElement { display: "Wireshark"; decoration: "wireshark" }
        ListElement { display: "Zed"; decoration: "zed" }
    }
    ListModel {
        id: found
        ListElement { display: "Firefox"; decoration: "firefox" }
        ListElement { display: "FreeTube"; decoration: "freetube" }
        ListElement { display: "Files"; decoration: "org.kde.dolphin" }
    }
    ListModel {
        id: other
        ListElement { display: "Firewall"; description: "Control your network rules"; group: "System Settings"; decoration: "preferences-security-firewall" }
        ListElement { display: "firefox-notes.md"; description: "~/Documents/notes/firefox-notes.md"; group: "Files"; decoration: "text-markdown" }
        ListElement { display: "Claude Code — Mozilla Firefox"; description: "Activate running window"; group: "Windows"; decoration: "firefox" }
    }

    Rectangle {
        width: parent.width; height: 36; color: Theme.bg
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#141414" }
        Row {
            x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 20
            DotGrid {}
            DotGrid { open: true }
        }
    }
    Row {
        x: 16; y: 52; spacing: 20
        DrawerPanel {
            width: 712; height: 560
            pinnedModel: pinned; pinnedCount: pinned.count
            appsModel: apps; appsCount: apps.count; totalApps: 88
            symbolicNames: sym
            glyphMap: glyphs
        }
        DrawerPanel {
            width: 600; height: 560
            query: "fi"
            appsModel: found; appsCount: found.count
            resultsModel: other; resultsCount: other.count
            totalApps: 88
            busy: true
            symbolicNames: sym
            glyphMap: glyphs
        }
    }
}
