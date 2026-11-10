import QtQuick
import Quickshell
import Quickshell.Wayland

// Volume OSD: vertical pill on the right edge, like Nothing OS.
PanelWindow {
    id: win
    screen: State.lastScreen
    anchors { right: true }
    margins { right: 18 }
    implicitWidth: 56; implicitHeight: 220
    color: "transparent"
    visible: shown || pill.opacity > 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nothing-osd"
    property bool shown: false
    property bool ready: false

    Connections {
        target: Audio.sink ? Audio.sink.audio : null
        function onVolumeChanged() { win.poke(); }
        function onMutedChanged() { win.poke(); }
    }
    function poke() { if (!ready || State.qsScreen) return; shown = true; hide.restart(); }
    Timer { id: hide; interval: 1400; onTriggered: win.shown = false }
    Timer { interval: 1500; running: true; onTriggered: win.ready = true }   // ignore startup values

    Rectangle {
        id: pill
        width: 52; height: 210; radius: 26
        anchors.verticalCenter: parent.verticalCenter
        x: win.shown ? 0 : 24
        opacity: win.shown ? 1 : 0
        color: Theme.card2
        border.color: Theme.line; border.width: 1
        clip: true
        Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: win.shown ? Theme.emphasized : Theme.accelerate } }
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        Rectangle {
            anchors.bottom: parent.bottom; width: parent.width
            height: Math.max(parent.width, parent.height * (Audio.muted ? 0 : Audio.volume))
            radius: 26; color: Theme.fg
            Behavior on height { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
        }
        Icon { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; name: Audio.icon; color: Theme.bg; size: 22 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 14
            text: Audio.muted ? "0" : Math.round(Audio.volume * 100)
            color: Audio.volume > 0.9 && !Audio.muted ? Theme.bg : Theme.fg
            font.family: Theme.dot; font.pixelSize: 18; font.variableAxes: ({ "ROND": 100, "wght": 800 })
        }
    }
}
