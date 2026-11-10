import QtQuick
import QtQuick.Layouts
import "../plasma/plasmoids/shared"

// Kitchen sink of the shared Nothing components.
Rectangle {
    color: Theme.bg
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 24; spacing: 14
        DotTime { hours: "12"; minutes: "45"; size: 72; colonColor: Theme.red }
        Label { text: "Tuesday, 11 November" }
        RowLayout {
            spacing: 10
            Tile { icon: "wifi"; title: "Internet"; subtitle: "Home 5G"; active: true }
            Tile { icon: "bluetooth"; title: "Bluetooth"; subtitle: "Off" }
            Tile { round: true; icon: "do_not_disturb_on" }
            Tile { round: true; icon: "nightlight"; active: true }
        }
        NSlider { Layout.preferredWidth: 420; value: 0.62; icon: "volume_up" }
        RowLayout {
            spacing: 10
            Card { width: 168; height: 168; DotRing { anchors.centerIn: parent; width: 90; height: 90; value: 0.42; dots: 20 } }
            Card { width: 168; height: 168; DotRing { anchors.centerIn: parent; width: 90; height: 90; value: 0.91; dots: 20 } }
        }
    }
}
