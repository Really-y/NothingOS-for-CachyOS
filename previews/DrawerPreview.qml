import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.drawer/contents/ui"

// App drawer mock: panel glyph (closed/open), idle drawer, searching drawer.
Rectangle {
    color: "#060606"
    // mock of the theme scan in main.qml (names that really ship as -symbolic here)
    readonly property var sym: ({ "firefox-symbolic": true, "system-file-manager-symbolic": true, "utilities-terminal-symbolic": true,
        "accessories-calculator-symbolic": true, "kate-symbolic": true, "utilities-system-monitor-symbolic": true, "vlc-symbolic": true })
    ListModel {
        id: pinned
        ListElement { display: "Firefox"; decoration: "firefox" }
        ListElement { display: "Dolphin"; decoration: "system-file-manager" }
        ListElement { display: "Konsole"; decoration: "utilities-terminal" }
        ListElement { display: "Spotify"; decoration: "spotify-client" }
        ListElement { display: "Settings"; decoration: "systemsettings" }
    }
    ListModel {
        id: apps
        ListElement { display: "Alacritty"; decoration: "Alacritty" }
        ListElement { display: "Ark"; decoration: "ark" }
        ListElement { display: "Calculator"; decoration: "accessories-calculator" }
        ListElement { display: "Discover"; decoration: "plasmadiscover" }
        ListElement { display: "Dolphin"; decoration: "system-file-manager" }
        ListElement { display: "Firefox"; decoration: "firefox" }
        ListElement { display: "GIMP"; decoration: "gimp" }
        ListElement { display: "Gwenview"; decoration: "gwenview" }
        ListElement { display: "Kate"; decoration: "kate" }
        ListElement { display: "Konsole"; decoration: "utilities-terminal" }
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
        ListElement { display: "Files"; decoration: "system-file-manager" }
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
        }
        DrawerPanel {
            width: 600; height: 560
            query: "fi"
            appsModel: found; appsCount: found.count
            resultsModel: other; resultsCount: other.count
            totalApps: 88
            busy: true
            symbolicNames: sym
        }
    }
}
