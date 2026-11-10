import QtQuick
import "nothing"

// Panel status pill: monochrome glyphs on a #111 capsule. Pure view — all
// state comes in through properties so it renders offscreen.
Item {
    id: root

    property string netIcon: "wifi"
    property bool netOff: false
    property bool btOn: false
    property bool btConnected: false
    property string volIcon: "volume_up"
    property bool hasBattery: false
    property int batteryPercent: 100
    property bool charging: false
    property bool dnd: false
    property bool unread: false
    property bool open: false
    property bool hovered: false

    readonly property int glyph: 16

    implicitHeight: 26
    implicitWidth: row.implicitWidth + 24

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: root.implicitWidth
        height: Math.min(root.height, 26)
        radius: height / 2
        color: root.open ? Theme.fg : (root.hovered ? Theme.card2 : Theme.card)
        border.width: root.open ? 0 : 1
        border.color: Theme.line
        Behavior on color { ColorAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
    }

    Row {
        id: row
        anchors.centerIn: pill
        spacing: 9
        readonly property color ink: root.open ? Theme.bg : Theme.fg

        Rectangle {
            visible: root.unread
            width: 6; height: 6; radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.red
        }
        Icon {
            visible: root.dnd
            name: "do_not_disturb_on"; size: root.glyph; color: row.ink
            anchors.verticalCenter: parent.verticalCenter
        }
        Icon {
            name: root.netIcon; size: root.glyph
            color: root.netOff ? (root.open ? "#666666" : Theme.fg3) : row.ink
            anchors.verticalCenter: parent.verticalCenter
        }
        Icon {
            visible: root.btOn
            name: root.btConnected ? "bluetooth_connected" : "bluetooth"; size: root.glyph; color: row.ink
            anchors.verticalCenter: parent.verticalCenter
        }
        Icon {
            name: root.volIcon; size: root.glyph; color: row.ink
            anchors.verticalCenter: parent.verticalCenter
        }
        Row {
            visible: root.hasBattery
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter
            // horizontal battery: Nothing-style outline cell with a solid level bar
            Item {
                width: 20; height: 10
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 18; height: 10; radius: 3
                    color: "transparent"; border.width: 1; border.color: row.ink
                    Rectangle {
                        x: 2; y: 2; height: 6; radius: 1
                        width: Math.max(1, 14 * Math.max(0, Math.min(100, root.batteryPercent)) / 100)
                        color: root.batteryPercent <= 15 && !root.charging ? Theme.red : row.ink
                    }
                }
                Rectangle { x: 18; y: 3; width: 2; height: 4; radius: 1; color: row.ink }
            }
            Text {
                text: (root.charging ? "+" : "") + root.batteryPercent
                color: row.ink
                font.family: Theme.mono; font.pixelSize: 11; font.weight: Font.Normal
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
