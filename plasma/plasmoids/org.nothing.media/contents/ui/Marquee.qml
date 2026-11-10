import QtQuick

// Single line of text that scrolls back and forth when it does not fit —
// never an ellipsis.
Item {
    id: root
    property alias text: label.text
    property alias color: label.color
    property alias font: label.font
    readonly property bool overflow: label.implicitWidth > width + 1
    implicitHeight: label.implicitHeight
    clip: true

    Text {
        id: label
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        onTextChanged: { anim.restart(); }
    }
    SequentialAnimation {
        id: anim
        running: root.overflow && root.visible
        loops: Animation.Infinite
        onStopped: label.x = 0
        PauseAnimation { duration: 2200 }
        NumberAnimation {
            target: label; property: "x"; to: -(label.implicitWidth - root.width)
            duration: Math.max(1200, (label.implicitWidth - root.width) * 28)
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: 1600 }
        NumberAnimation {
            target: label; property: "x"; to: 0
            duration: Math.max(800, (label.implicitWidth - root.width) * 14)
            easing.type: Easing.InOutSine
        }
    }
}
