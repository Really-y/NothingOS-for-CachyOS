import QtQuick
import QtQuick.Layouts

// Quick-settings tile. Active = white surface, black glyph (Nothing OS).
Pressable {
    id: root
    property string icon
    property string title
    property string subtitle: ""
    property bool active: false
    property bool round: false        // circular icon-only tile
    implicitHeight: round ? 64 : 76
    implicitWidth: round ? 64 : 180

    Rectangle {
        anchors.fill: parent
        radius: root.round ? width / 2 : Theme.r
        color: root.active ? Theme.fg : (root.containsMouse ? Theme.card3 : Theme.card2)
        Behavior on color { ColorAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
    }
    Icon {
        id: ic
        name: root.icon
        size: root.round ? 24 : 26
        fill: root.active ? 1 : 0
        color: root.active ? Theme.bg : Theme.fg
        anchors.verticalCenter: parent.verticalCenter
        x: root.round ? (parent.width - width) / 2 : 18
    }
    Column {
        visible: !root.round
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: ic.right; anchors.leftMargin: 12; anchors.right: parent.right; anchors.rightMargin: 14
        spacing: 2
        Text {
            text: root.title; width: parent.width; elide: Text.ElideRight
            color: root.active ? Theme.bg : Theme.fg
            font.family: Theme.sans; font.pixelSize: 15; font.weight: Font.Medium
            Behavior on color { ColorAnimation { duration: Theme.normal } }
        }
        Text {
            text: root.subtitle; visible: text !== ""; width: parent.width; elide: Text.ElideRight
            color: root.active ? "#555555" : Theme.fg2
            font.family: Theme.mono; font.pixelSize: 11
        }
    }
}
