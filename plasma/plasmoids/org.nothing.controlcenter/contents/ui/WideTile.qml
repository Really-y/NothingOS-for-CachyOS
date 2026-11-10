import QtQuick
import "nothing"

// Big quick-settings tile (Internet / Bluetooth). Local variant of the kit's Tile:
// radius concentric with the 30px popup, and text shrinks to fit instead of eliding.
Pressable {
    id: root
    property string icon
    property string title
    property string subtitle: ""
    property bool active: false
    property real radius: 16
    implicitHeight: 76
    implicitWidth: 180

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.active ? Theme.fg : (root.containsMouse ? Theme.card3 : Theme.card2)
        Behavior on color { ColorAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
    }
    Icon {
        id: ic
        name: root.icon
        size: 24
        fill: root.active ? 1 : 0
        color: root.active ? Theme.bg : Theme.fg
        anchors.verticalCenter: parent.verticalCenter
        x: 18
    }
    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: ic.right; anchors.leftMargin: 12
        anchors.right: parent.right; anchors.rightMargin: 14
        spacing: 2
        Text {
            width: parent.width
            text: root.title
            color: root.active ? Theme.bg : Theme.fg
            font.family: Theme.sans; font.pixelSize: 15; font.weight: Font.Medium
            fontSizeMode: Text.HorizontalFit; minimumPixelSize: 10
            Behavior on color { ColorAnimation { duration: Theme.normal } }
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: root.subtitle
            color: root.active ? "#555555" : Theme.fg2
            font.family: Theme.mono; font.pixelSize: 11; font.weight: Font.Normal
            fontSizeMode: Text.HorizontalFit; minimumPixelSize: 8
        }
    }
}
