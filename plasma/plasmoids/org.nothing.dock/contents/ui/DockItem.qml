import QtQuick
import org.kde.kirigami as Kirigami
import "nothing"

// One app slot: monochrome disc + dot indicators underneath.
// Reads TasksModel role names (IsActive, IsMinimized, ...) from `model`, so the
// previews can feed a plain ListModel with the same roles.
FocusScope {
    id: slot
    required property int index
    required property var model
    property Item bar                       // owning DockBar

    readonly property int windows: model.IsGroupParent ? (model.ChildCount || 0) : (model.IsWindow ? 1 : 0)
    readonly property bool running: windows > 0
    readonly property bool active: running && !!model.IsActive
    readonly property bool minimized: running && !!model.IsMinimized && !active
    readonly property bool attention: !!model.IsDemandingAttention
    readonly property bool startup: !!model.IsStartup
    readonly property string label: String(model.AppName || model.display || "")
    readonly property var info: bar ? bar.iconInfo(model) : ({})
    readonly property bool hovered: (bar && bar.forcedHover === index) || mouse.containsMouse
    readonly property bool lifted: (hovered || activeFocus) && !mouse.pressed && !(bar && bar.dragging)

    width: bar.iconSize
    height: bar.pillHeight

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.description: running ? (windows > 1 ? windows + " windows" : (active ? "active" : (minimized ? "minimized" : "running")))
                                    : "pinned"
    Accessible.onPressAction: bar.activated(index, 0)

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            bar.activated(index, event.modifiers); event.accepted = true;
        } else if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && event.modifiers & Qt.ShiftModifier)) {
            bar.contextMenuRequested(index, slot); event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            bar.focusNeighbour(index, event.key === Qt.Key_Left ? -1 : 1); event.accepted = true;
        }
    }

    // ── disc ───────────────────────────────────────────────────────────
    Item {
        id: lift
        width: bar.iconSize; height: bar.iconSize
        y: bar.iconY - (slot.lifted ? 2 : 0)
        Behavior on y { SpringAnimation { spring: 5; damping: 0.32; epsilon: 0.05 } }
        scale: mouse.pressed ? 0.94 : 1
        Behavior on scale { SpringAnimation { spring: 6; damping: 0.42; epsilon: 0.002 } }

        // Disc for anything the Nothing theme has no disc icon for (glyph or dot letter on top).
        // Theme icons are drawn r=30 on a 64 canvas: match that so every disc is the same size.
        Rectangle {
            visible: !slot.info.themed
            anchors.centerIn: parent
            width: parent.width * 60 / 64; height: width; radius: width / 2
            color: Theme.widget
        }
        Kirigami.Icon {
            id: icon
            anchors.fill: parent
            visible: source !== "" && source !== undefined
            source: slot.info.themed ? slot.info.icon : (slot.info.glyph || "")
            roundToIconSize: false
            animated: false
        }
        DotString {
            visible: !slot.info.themed && !slot.info.glyph && !slot.info.loading
            anchors.centerIn: parent
            text: (slot.label.match(/[A-Za-z0-9]/) || ["?"])[0].toUpperCase()
            pitch: Math.round(bar.iconSize / 11.5)   // 4px at 46: 5×7 letter fits inside the 43px disc
            dotRatio: 0.7
            color: Theme.fg
        }
        // keyboard focus: thin white ring just outside the disc
        Rectangle {
            visible: slot.activeFocus && !mouse.containsMouse
            anchors.centerIn: parent
            width: parent.width * 60 / 64 + 6; height: width; radius: width / 2
            color: "transparent"
            border.color: Theme.fg; border.width: 1.5
        }
    }

    // ── indicators: dots under the disc ───────────────────────────────
    // running = white dot per window (max 3) · active = first dot stretches to a pill
    // minimized = grey #5e5e5e dots (one per window, max 3) · attention = one red dot (the only red)
    // launching = three 3px dots lighting up in sequence (#8e8e8e), one always lit
    readonly property bool launching: startup && !running && !attention
    property int launchStep: 0
    Timer {
        running: slot.launching
        interval: 160; repeat: true
        onTriggered: slot.launchStep = (slot.launchStep + 1) % 3
    }
    Row {
        id: dots
        visible: !slot.launching
        anchors.horizontalCenter: parent.horizontalCenter
        y: bar.dotY
        spacing: 3
        readonly property int count: slot.attention ? 1 : (slot.running ? Math.min(slot.windows, 3) : 0)
        Repeater {
            model: dots.count
            Rectangle {
                required property int index
                height: 4
                width: index === 0 && slot.active && !slot.attention ? 12 : 4
                radius: 2
                color: slot.attention ? Theme.red : slot.minimized ? Theme.fg3 : Theme.fg
                Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }
        }
    }
    Row {
        visible: slot.launching
        anchors.horizontalCenter: parent.horizontalCenter
        y: bar.dotY + 0.5
        spacing: 3
        Repeater {
            model: 3
            Rectangle {
                required property int index
                width: 3; height: 3; radius: 1.5
                color: index === slot.launchStep ? Theme.fg2 : Theme.dotDim
            }
        }
    }

    // ── input ─────────────────────────────────────────────────────────
    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.leftMargin: -bar.spacing / 2; anchors.rightMargin: -bar.spacing / 2   // no dead gaps
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        property real pressX: 0
        property bool dragged: false

        onPressed: mouse => { pressX = mouse.x; dragged = false; }
        onPositionChanged: mouse => {
            if (!pressed || !(pressedButtons & Qt.LeftButton)) return;
            if (!dragged && Math.abs(mouse.x - pressX) > 8) { dragged = true; bar.dragging = true; }
            if (dragged) bar.dragOver(slot, mapToItem(bar.row, mouse.x, mouse.y).x);
        }
        onReleased: mouse => {
            if (dragged) { dragged = false; bar.dragging = false; bar.dragFinished(); }
        }
        onCanceled: { if (dragged) { dragged = false; bar.dragging = false; bar.dragFinished(); } }
        onClicked: mouse => {
            if (dragged) return;
            if (mouse.button === Qt.LeftButton) bar.activated(slot.index, mouse.modifiers);
            else if (mouse.button === Qt.MiddleButton) bar.middleClicked(slot.index);
            else if (mouse.button === Qt.RightButton) bar.contextMenuRequested(slot.index, slot);
        }
        onWheel: wheel => { bar.wheeled(slot.index, wheel.angleDelta.y || wheel.angleDelta.x); }
        onContainsMouseChanged: bar.hoverChanged(slot, containsMouse)
    }
}
