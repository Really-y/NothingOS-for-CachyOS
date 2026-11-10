import QtQuick
import Quickshell
import Quickshell.Wayland

// Toasts in the top-right of the primary screen.
PanelWindow {
    id: win
    screen: Ui.primary
    anchors { top: true; right: true }
    margins { top: 44; right: 10 }
    implicitWidth: 380
    implicitHeight: Math.max(1, stack.implicitHeight)
    visible: items.length > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nothing-notifications"

    property var items: []

    Connections {
        target: Notifs
        function onArrived(n) {
            if (Ui.qsScreen) return;            // panel already shows them
            win.items = [n].concat(win.items).slice(0, 4);
        }
    }
    function drop(n) { items = items.filter(x => x !== n); }

    Column {
        id: stack
        width: parent.width
        spacing: 8
        move: Transition { NumberAnimation { properties: "y"; duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Repeater {
            model: win.items
            NotifCard {
                id: c
                required property var modelData
                notif: modelData
                popup: true
                width: stack.width
                onDismissed: win.drop(modelData)
                // slide in from the right
                x: 40; opacity: 0
                Component.onCompleted: enter.start()
                ParallelAnimation {
                    id: enter
                    NumberAnimation { target: c; property: "x"; to: 0; duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
                    NumberAnimation { target: c; property: "opacity"; to: 1; duration: Theme.normal }
                }
                Timer {
                    interval: c.notif.urgency === 2 ? 15000 : 5500
                    running: !hover.hovered; onTriggered: win.drop(c.modelData)
                }
                HoverHandler { id: hover }
                Connections { target: c.notif; function onClosed() { win.drop(c.modelData); } }
            }
        }
    }
}
