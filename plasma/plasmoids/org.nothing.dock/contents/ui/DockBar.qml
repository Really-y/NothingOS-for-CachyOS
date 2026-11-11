import QtQuick
import "nothing"

// The dock body: one flat pill (no border, radius = height / 2) holding app discs.
// Pure view — no Plasma imports — so previews render it offscreen with mock data.
// The plasmoid wires the signals to the TasksModel.
FocusScope {
    id: dockBar
    property var model                      // TasksModel, or a ListModel with the same role names
    property int pillHeight: 68
    property int iconSize: pillHeight - 22                  // 46 at 68: theme disc ≈ 43px
    property int spacing: 10
    property int padding: Math.round((pillHeight - iconSize) / 2)   // concentric end caps
    property color fill: Theme.card
    // 68px pill: disc box 8–54, dots 58–62
    readonly property int iconY: pillHeight - iconSize - 14
    readonly property int dotY: iconY + iconSize + 4

    // (model) -> { themed: bool, icon: name/url, glyph: name/url } — how to draw the disc
    property var iconInfo: function (m) { return { themed: true, icon: m.decoration }; }
    property int forcedHover: -1            // previews: pretend this slot is hovered
    property bool inlineTooltip: false      // previews: draw the label inside this item
    property bool dragging: false
    property alias row: row
    readonly property int count: rep.count

    // hovered slot (for the tooltip window)
    property Item hoveredItem: null
    readonly property string hoveredLabel: hoveredItem ? hoveredItem.label : ""

    signal activated(int index, int modifiers)
    signal middleClicked(int index)
    signal contextMenuRequested(int index, Item item)
    signal wheeled(int index, int delta)
    signal moveRequested(int from, int to)
    signal dragFinished()

    implicitWidth: rep.count > 0 ? row.implicitWidth + 2 * padding : pillHeight
    implicitHeight: pillHeight

    function itemAt(i) { return rep.itemAt(i); }
    function hoverChanged(item, on) {
        if (on) hoveredItem = item;
        else if (hoveredItem === item) hoveredItem = null;
    }
    function focusNeighbour(i, step) {
        const n = rep.count;
        if (n === 0) return;
        const it = rep.itemAt(((i + step) % n + n) % n);
        if (it) it.forceActiveFocus(Qt.TabFocusReason);
    }
    // live reorder while dragging: move the dragged slot to whichever slot is under the cursor
    function dragOver(slot, x) {
        for (let i = 0; i < rep.count; i++) {
            const it = rep.itemAt(i);
            if (!it || it === slot) continue;
            if (x >= it.x && x < it.x + it.width) { moveRequested(slot.index, i); return; }
        }
    }

    Rectangle {
        id: pill
        width: dockBar.implicitWidth
        height: dockBar.pillHeight
        anchors.centerIn: parent
        radius: height / 2
        color: dockBar.fill
        Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

        Row {
            id: row
            x: dockBar.padding
            spacing: dockBar.spacing
            Repeater {
                id: rep
                model: dockBar.model
                delegate: DockItem { bar: dockBar }
            }
        }
    }

    // previews only: the real dock shows this in a popup window above the panel
    DockTooltip {
        visible: dockBar.inlineTooltip && dockBar.hoveredLabel !== ""
        text: dockBar.hoveredLabel
        readonly property Item target: dockBar.hoveredItem
        x: target ? pill.x + row.x + target.x + target.width / 2 - width / 2 : 0
        y: pill.y - height - 10
    }
    // previews: forcedHover drives hoveredItem
    onForcedHoverChanged: syncForced()
    onCountChanged: syncForced()
    function syncForced() { if (forcedHover >= 0) hoveredItem = rep.itemAt(forcedHover); }
}
