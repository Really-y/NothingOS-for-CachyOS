import QtQuick
import "nothing"

// Single line of text that scrolls back and forth when it does not fit —
// never an ellipsis.
Item {
    id: root
    property alias text: label.text
    property alias color: label.color
    property alias font: label.font
    property color fadeColor: Theme.widget   // background the edges fade into
    property int fade: 22
    readonly property bool overflow: label.implicitWidth > width + 1
    implicitHeight: label.implicitHeight
    clip: true

    Text {
        id: label
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        onTextChanged: { anim.restart(); }
    }
    // Soft edges so a mid-scroll cut is never hard.
    Rectangle {
        anchors.left: parent.left
        width: root.fade; height: parent.height
        visible: label.x < -0.5
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.fadeColor }
            GradientStop { position: 1; color: Qt.rgba(root.fadeColor.r, root.fadeColor.g, root.fadeColor.b, 0) }
        }
    }
    Rectangle {
        anchors.right: parent.right
        width: root.fade; height: parent.height
        visible: label.x + label.implicitWidth > root.width + 0.5
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(root.fadeColor.r, root.fadeColor.g, root.fadeColor.b, 0) }
            GradientStop { position: 1; color: root.fadeColor }
        }
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
