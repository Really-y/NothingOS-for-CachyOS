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
        const o = {}; for (const k of n) o[k + "-symbolic"] = true;
        // theme glyph files written by icons/appicons.py (installed in ~/.local/share/icons/Nothing)
        o["nothing-glyph-icon-firefox"] = true;
        for (const id of ["Alacritty", "FreeTube", "alacritty-terminal", "com.anydesk.Anydesk", "com.brave.Browser", "com.google.Chrome", "discord", "firefox", "localsend", "mpv", "org.gnome.Meld", "org.gnome.Nautilus", "org.kde.discover", "org.kde.dolphin", "org.kde.spectacle", "org.qbittorrent.qBittorrent", "org.telegram.desktop", "steam", "systemsettings", "vscodium"]) o["nothing-glyph-" + id] = true;
        return o;
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
        ListElement { display: "Firefox"; decoration: "firefox"; favoriteId: "applications:firefox.desktop" }
        ListElement { display: "Dolphin"; decoration: "org.kde.dolphin"; favoriteId: "applications:org.kde.dolphin.desktop" }
        ListElement { display: "Terminal"; decoration: "utilities-terminal"; favoriteId: "applications:alacritty-terminal.desktop" }
        ListElement { display: "Telegram"; decoration: "org.telegram.desktop"; favoriteId: "applications:org.telegram.desktop.desktop" }
        ListElement { display: "System Settings"; decoration: "preferences-system"; favoriteId: "applications:systemsettings.desktop" }
    }
    ListModel {
        id: apps
        ListElement { display: "Alacritty"; decoration: "utilities-terminal"; favoriteId: "applications:Alacritty.desktop" }
        ListElement { display: "AnyDesk"; decoration: "com.anydesk.Anydesk"; favoriteId: "applications:com.anydesk.Anydesk.desktop" }
        ListElement { display: "Brave"; decoration: "com.brave.Browser"; favoriteId: "applications:com.brave.Browser.desktop" }
        ListElement { display: "Discord"; decoration: "discord"; favoriteId: "applications:discord.desktop" }
        ListElement { display: "Discover"; decoration: "plasmadiscover"; favoriteId: "applications:org.kde.discover.desktop" }
        ListElement { display: "Files"; decoration: "org.gnome.Nautilus"; favoriteId: "applications:org.gnome.Nautilus.desktop" }
        ListElement { display: "FreeTube"; decoration: "freetube"; favoriteId: "applications:FreeTube.desktop" }
        ListElement { display: "Google Chrome"; decoration: "com.google.Chrome"; favoriteId: "applications:com.google.Chrome.desktop" }
        ListElement { display: "LocalSend"; decoration: "localsend"; favoriteId: "applications:localsend.desktop" }
        ListElement { display: "Meld"; decoration: "org.gnome.Meld"; favoriteId: "applications:org.gnome.Meld.desktop" }
        ListElement { display: "mpv Media Player"; decoration: "mpv"; favoriteId: "applications:mpv.desktop" }
        ListElement { display: "qBittorrent"; decoration: "org.qbittorrent.qBittorrent"; favoriteId: "applications:org.qbittorrent.qBittorrent.desktop" }
        ListElement { display: "Spectacle"; decoration: "spectacle"; favoriteId: "applications:org.kde.spectacle.desktop" }
        ListElement { display: "Steam"; decoration: "steam"; favoriteId: "applications:steam.desktop" }
        ListElement { display: "VSCodium"; decoration: "vscodium"; favoriteId: "applications:vscodium.desktop" }
    }
    ListModel {
        id: found
        ListElement { display: "Firefox"; decoration: "firefox"; favoriteId: "applications:firefox.desktop" }
        ListElement { display: "FreeTube"; decoration: "freetube"; favoriteId: "applications:FreeTube.desktop" }
        ListElement { display: "Files"; decoration: "org.gnome.Nautilus"; favoriteId: "applications:org.gnome.Nautilus.desktop" }
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
            appsModel: apps; appsCount: apps.count; totalApps: 93
            symbolicNames: sym
            glyphMap: glyphs
        }
        DrawerPanel {
            width: 600; height: 560
            query: "fi"
            appsModel: found; appsCount: found.count
            resultsModel: other; resultsCount: other.count
            totalApps: 93
            busy: true
            symbolicNames: sym
            glyphMap: glyphs
        }
    }
}
