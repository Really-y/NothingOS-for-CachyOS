import QtQuick
import "nothing"

// 3x3 dot launcher glyph; the centre dot turns red while the drawer is open.
Item {
    id: root
    property bool open: false
    property bool hovered: false
    property real dot: 4
    property real gap: 4
    implicitWidth: dot * 3 + gap * 2 + 16
    implicitHeight: implicitWidth

    Rectangle {
        anchors.centerIn: parent
        width: root.implicitWidth; height: width; radius: width / 2
        color: root.hovered || root.open ? Theme.card2 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
    Grid {
        anchors.centerIn: parent
        columns: 3; spacing: root.gap
        Repeater {
            model: 9
            Rectangle {
                required property int index
                width: root.dot; height: root.dot; radius: root.dot / 2
                color: index === 4 && root.open ? Theme.red : Theme.fg
                scale: index === 4 && root.open ? 1.35 : 1
                Behavior on color { ColorAnimation { duration: Theme.normal } }
                Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            }
        }
    }
}
