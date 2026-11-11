import QtQuick
import "../plasma/plasmoids/shared"

// Nothing app icons (icons/Nothing/scalable/apps) rendered through QtSvg, like KDE does:
// a dock strip at 48px, the same icons small (22px, menus/task switcher) and the
// dot-letter fallbacks.
Rectangle {
    color: "#0b0b0b"
    readonly property string dir: Qt.resolvedUrl("../icons/Nothing/scalable/apps/")
    readonly property var dock: ["firefox", "org.kde.dolphin", "utilities-terminal", "Alacritty", "discord",
        "org.telegram.desktop", "vscodium", "steam", "com.google.Chrome", "com.brave.Browser", "spectacle",
        "mpv", "freetube", "plasmadiscover", "org.qbittorrent.qBittorrent", "xarchiver", "kdeconnect",
        "virt-manager", "org.wireshark.Wireshark", "com.anydesk.Anydesk", "org.gnome.Nautilus", "localsend"]
    readonly property var fallback: ["../../../../previews/assets/dotletter-L", "../../../../previews/assets/dotletter-S", "../../../../previews/assets/dotletter-R"]

    Column {
        x: 24; y: 24; spacing: 22
        Label { text: "Dock · 48px" }
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
        Label { text: "Menus / task switcher · 22px" }
        Row {
            spacing: 14
            Repeater {
                model: dock
                Image { required property string modelData; width: 22; height: 22; sourceSize: Qt.size(22, 22); source: dir + modelData + ".svg" }
            }
        }
        Label { text: "Dot-letter fallback · 48px / 22px" }
        Row {
            spacing: 8
            Repeater {
                model: fallback.concat(fallback)
                Image { required property string modelData; required property int index; readonly property int px: index < 3 ? 48 : 22
                        width: px; height: px; anchors.verticalCenter: parent.verticalCenter; sourceSize: Qt.size(px * 2, px * 2); source: dir + modelData + ".svg" }
            }
        }
    }
}
