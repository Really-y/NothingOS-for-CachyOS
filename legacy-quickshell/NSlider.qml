import QtQuick

// Thick pill slider: white fill grows from the left, glyph rides inside.
Item {
    id: root
    property real value: 0          // 0..1
    property string icon: ""
    signal moved(real v)
    signal iconClicked()
    implicitHeight: 52

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.card2
        clip: true
        Rectangle {
            id: fillRect
            height: parent.height
            width: Math.max(parent.height, parent.width * root.value)
            radius: height / 2
            color: Theme.fg
            Behavior on width { enabled: !ma.pressed; NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        }
    }
    Icon {
        name: root.icon; size: 22
        color: Theme.bg
        anchors.verticalCenter: parent.verticalCenter
        x: (root.height - width) / 2
        MouseArea { anchors.fill: parent; anchors.margins: -10; z: 2; cursorShape: Qt.PointingHandCursor; onClicked: root.iconClicked() }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right; anchors.rightMargin: 18
        text: Math.round(root.value * 100)
        color: root.value > 0.88 ? Theme.bg : Theme.fg2
        font.family: Theme.mono; font.pixelSize: 12
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.leftMargin: root.height
        cursorShape: Qt.PointingHandCursor
        function set(x) { root.moved(Math.max(0, Math.min(1, (x + root.height) / root.width))); }
        onPressed: e => set(e.x)
        onPositionChanged: e => { if (pressed) set(e.x); }
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
