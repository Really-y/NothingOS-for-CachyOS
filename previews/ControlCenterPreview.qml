import QtQuick
import QtQuick.Layouts
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.controlcenter/contents/ui"

// Control center mock: panel pills (closed / open / laptop) + two popup states.
Rectangle {
    color: "#060606"
    readonly property date fixed: new Date(2026, 10, 11, 12, 45)

    // fake 36px top panel
    Rectangle {
        width: parent.width; height: 36; color: Theme.bg
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#141414" }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 18
            StatusPill { height: 36; netIcon: "lan"; volIcon: "volume_up"; unread: true }
            StatusPill { height: 36; netIcon: "network_wifi_3_bar"; btOn: true; btConnected: true; volIcon: "volume_down"; hasBattery: true; batteryPercent: 64; dnd: true }
            StatusPill { height: 36; netIcon: "wifi"; volIcon: "volume_off"; hasBattery: true; batteryPercent: 12; open: true }
        }
    }

    Row {
        x: 24; y: 60; spacing: 28
        ControlPanel {
            width: 420; height: implicitHeight
            now: fixed
            wifiOn: true; netKind: "wifi"; netName: "Nothing HQ 5G"; netIcon: "wifi"
            btAvailable: true; btOn: true; btConnected: 2
            nightLight: true
            volume: 0.62; volIcon: "volume_up"
            micAvailable: true; micVolume: 0.35
            mediaActive: true; mediaPlaying: true
            mediaTitle: "Glyph Interface"; mediaArtist: "Teenage Engineering"; mediaApp: "Spotify"
        }
        ControlPanel {
            width: 420; height: implicitHeight
            now: fixed
            hasBattery: true; batteryPercent: 82; charging: true
            netKind: "ethernet"; netName: "Wired connection 1"
            btAvailable: false
            dnd: true
            volume: 0.3; muted: true; volIcon: "volume_off"
            powerOpen: true
        }
    }
}
