import QtQuick
import "../plasma/plasmoids/shared"

// Nothing app icons (icons/Nothing/scalable/apps) rendered through QtSvg, like KDE does:
// a dock strip at 48px, the same icons small (22px, menus/task switcher) and the
// dot-letter fallbacks.
Rectangle {
    color: "#0b0b0b"
    readonly property string dir: Qt.resolvedUrl("../icons/Nothing/scalable/apps/")
    readonly property string dir22: Qt.resolvedUrl("../icons/Nothing/22/apps/")
    property real zoom: 1
    readonly property var dock: ["firefox", "com.google.Chrome", "com.brave.Browser", "discord", "org.telegram.desktop",
        "com.rtosta.zapzap", "steam", "vscodium", "mpv", "org.qbittorrent.qBittorrent", "org.wireshark.Wireshark",
        "com.anydesk.Anydesk", "com.rustdesk.RustDesk", "org.kde.dolphin", "org.gnome.Nautilus", "utilities-terminal",
        "Alacritty", "spectacle", "freetube", "plasmadiscover", "xarchiver", "kdeconnect", "virt-manager", "localsend"]
    readonly property var generic: ["filelight", "preferences-security-firewall", "internet-web-browser", "kfind",
        "preferences-desktop-font", "krunner", "preferences-web-browser-shortcuts", "preferences-desktop-display",
        "preferences-desktop-sound", "preferences-desktop-keyboard", "preferences-desktop-mouse",
        "preferences-desktop-notification", "preferences-system-bluetooth", "preferences-desktop-wallpaper",
        "preferences-desktop-color", "preferences-system-power-management", "preferences-desktop-user",
        "preferences-desktop-locale", "applications-graphics", "accessories-calculator"]
    readonly property var fallback: ["../../../../previews/assets/dotletter-L", "../../../../previews/assets/dotletter-S", "../../../../previews/assets/dotletter-R"]

    Column {
        x: 24; y: 24; spacing: 22
        Label { text: "Dock · 48px — brand marks + Material outline (wght 600, optical sizing)" }
        Rectangle {
            width: dockRow.width + 24; height: 64; radius: 32; color: "#000000"
            Row {
                id: dockRow
                anchors.centerIn: parent; spacing: 8
                Repeater {
                    model: dock
                    Image { required property string modelData; width: 48; height: 48; sourceSize: Qt.size(96, 96); source: dir + modelData + ".svg" }
                }
            }
        }
        Label { text: "Menus · 22px set (wght 600, 700 for thin symbols, opsz 20)" + (zoom > 1 ? " ×" + zoom : "") }
        Row {
            spacing: 14
            Repeater {
                model: dock
                Image { required property string modelData; width: 22 * zoom; height: 22 * zoom; smooth: false; sourceSize: Qt.size(22, 22); source: dir22 + modelData + ".svg" }
            }
        }
        Label { text: "KRunner / System Settings modules / categories · 48px + 22px" }
        Row {
            spacing: 8
            Repeater {
                model: generic
                Image { required property string modelData; width: 48; height: 48; sourceSize: Qt.size(48, 48); source: dir + modelData + ".svg" }
            }
        }
        Row {
            spacing: 14
            Repeater {
                model: generic
                Image { required property string modelData; width: 22; height: 22; sourceSize: Qt.size(22, 22); source: dir22 + modelData + ".svg" }
            }
        }
        Label { text: "Fallback · 48px dots (2px on 3px pitch) / 22px pixel letter" }
        Row {
            spacing: 8
            Repeater {
                model: fallback.concat(fallback)
                Image { required property string modelData; required property int index; readonly property int px: index < 3 ? 48 : 22
                        width: px * (index < 3 ? 1 : zoom); height: width; smooth: false; anchors.verticalCenter: parent.verticalCenter
                        sourceSize: index < 3 ? Qt.size(48, 48) : Qt.size(22, 22)
                        source: dir + (index < 3 ? modelData : modelData.replace("dotletter-", "dotletter-small-")) + ".svg" }
            }
        }
    }
}
