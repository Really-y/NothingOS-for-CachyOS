import QtQuick
import QtQuick.Layouts
import "nothing"

// Nothing OS app drawer body. Pure view: it receives item models (roles
// `display`, `decoration`, `description`, `group`) and reports activations as
// (zone, row) so main.qml can call the Kicker model's trigger().
//
// Zones, in keyboard order: 0 = pinned (favourites), 1 = apps, 2 = other results.
Item {
    id: root

    property var pinnedModel: null
    property var appsModel: null
    property var resultsModel: null
    property int pinnedCount: 0
    property int appsCount: 0
    property int resultsCount: 0
    property int totalApps: 0          // shown next to the title
    property bool searching: query.length > 0
    property alias query: search.text
    property bool busy: false          // runner still querying

    property real pad: 24
    property real bleed: 0
    property real cardRadius: 32

    signal activate(int zone, int row)
    signal requestMenu(int zone, int row, Item item)
    signal close()

    // ── selection across zones ───────────────────────────────────────────
    property int zone: 0
    property int sel: 0
    property bool keyboardNav: false     // arrows/tab used since opening → show focus disc
    property string iconFallback: "grey" // non-symbolic icons: "grey" (desaturated) or "mask" (flat silhouette)
    property var symbolicNames: ({})     // set of "<icon>-symbolic" names available in the icon theme
    readonly property color widgetFill: "#1a1a1a"
    readonly property bool pinnedShown: !searching && pinnedCount > 0
    readonly property bool resultsShown: searching && resultsCount > 0
    readonly property int cols: Math.max(1, Math.floor((width - pad * 2) / 112))

    function zoneCount(z) { return z === 0 ? (pinnedShown ? pinnedCount : 0) : z === 1 ? appsCount : (resultsShown ? resultsCount : 0); }
    function firstZone() { for (let z = 0; z < 3; z++) if (zoneCount(z) > 0) return z; return 1; }
    function resetSelection() { zone = firstZone(); sel = 0; flick.contentY = 0; }
    function focusSearch() { search.forceActiveFocus(); }
    function clear() { search.text = ""; keyboardNav = false; resetSelection(); }
    function triggerCurrent() { if (zoneCount(zone) === 0) resetSelection(); if (zoneCount(zone) > 0) root.activate(zone, Math.min(sel, zoneCount(zone) - 1)); }

    function move(dx, dy) {
        if (!keyboardNav) { keyboardNav = true; if (zoneCount(zone) > 0) return; }
        if (zoneCount(zone) === 0) { resetSelection(); return; }
        const isGrid = zone !== 2;
        if (isGrid && dx !== 0) {
            const n = sel + dx;
            if (n >= 0 && n < zoneCount(zone)) sel = n;
            else if (n < 0) jumpZone(-1, true);
            else jumpZone(1, false);
        } else if (dy !== 0) {
            const step = isGrid ? cols : 1;
            const n = sel + dy * step;
            if (n >= 0 && n < zoneCount(zone)) sel = n;
            else if (isGrid && dy > 0 && Math.floor(sel / cols) < Math.floor((zoneCount(zone) - 1) / cols)) sel = zoneCount(zone) - 1;
            else jumpZone(dy, dy < 0);
        }
        ensureVisible();
    }
    function jumpZone(dir, toEnd) {
        for (let z = zone + dir; z >= 0 && z < 3; z += dir) {
            if (zoneCount(z) > 0) {
                const col = zone !== 2 ? sel % cols : 0;
                zone = z;
                if (toEnd) sel = z === 2 ? zoneCount(z) - 1 : Math.min(zoneCount(z) - 1, Math.floor((zoneCount(z) - 1) / cols) * cols + col);
                else sel = z === 2 ? 0 : Math.min(col, zoneCount(z) - 1);
                return;
            }
        }
    }
    function ensureVisible() {
        const it = zone === 0 ? pinnedGrid.itemAtIndex(sel) : zone === 1 ? appsGrid.itemAtIndex(sel) : resultsList.itemAtIndex(sel);
        if (!it) return;
        const p = it.mapToItem(content, 0, 0);
        if (p.y < flick.contentY) flick.contentY = Math.max(0, p.y - 8);
        else if (p.y + it.height > flick.contentY + flick.height) flick.contentY = Math.min(flick.contentHeight - flick.height, p.y + it.height - flick.height + 8);
    }
    onAppsCountChanged: { if (zone === 1 && sel >= appsCount) sel = Math.max(0, appsCount - 1); if (zoneCount(zone) === 0) resetSelection(); }
    onResultsCountChanged: if (zone === 2 && sel >= resultsCount) resetSelection()
    onQueryChanged: resetSelection()
    onPinnedShownChanged: resetSelection()
    onResultsShownChanged: if (zoneCount(zone) === 0) resetSelection()

    implicitWidth: 712
    implicitHeight: 620

    Rectangle {
        anchors.fill: parent
        anchors.margins: -root.bleed
        radius: root.cardRadius
        color: Theme.bg
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 16

        // ── title ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            DotString { text: root.searching ? "FIND" : "APPS"; size: 48 }
            Item { Layout.fillWidth: true }
            Rectangle {
                visible: root.busy
                width: 6; height: 6; radius: 3; color: Theme.fg2
                Layout.alignment: Qt.AlignVCenter
                SequentialAnimation on opacity { running: root.busy; loops: Animation.Infinite; NumberAnimation { to: 0.2; duration: 420 } NumberAnimation { to: 1; duration: 420 } }
            }
            SectionLabel {
                Layout.alignment: Qt.AlignVCenter
                text: root.searching ? (root.appsCount + root.resultsCount) + " found" : root.totalApps + " apps"
            }
        }

        // ── search pill ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: height / 2
            color: Theme.card2
            border.color: search.activeFocus ? Theme.fg3 : "transparent"; border.width: 1
            Behavior on border.color { ColorAnimation { duration: Theme.fast } }
            Icon { id: searchIcon; name: "search"; x: 18; anchors.verticalCenter: parent.verticalCenter; color: Theme.fg2 }
            TextInput {
                id: search
                anchors { left: searchIcon.right; leftMargin: 12; right: escHint.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                color: Theme.fg
                font.family: Theme.sans; font.pixelSize: 17; font.weight: Font.Normal
                selectionColor: Theme.fg; selectedTextColor: Theme.bg
                clip: true
                focus: true
                Keys.onEscapePressed: { if (text !== "") text = ""; else root.close(); }
                Keys.onReturnPressed: root.triggerCurrent()
                Keys.onEnterPressed: root.triggerCurrent()
                Keys.onDownPressed: root.move(0, 1)
                Keys.onUpPressed: root.move(0, -1)
                Keys.onTabPressed: root.move(1, 0)
                Keys.onBacktabPressed: root.move(-1, 0)
                Keys.onRightPressed: e => { if (cursorPosition === text.length) root.move(1, 0); else e.accepted = false; }
                Keys.onLeftPressed: e => { if (cursorPosition === 0) root.move(-1, 0); else e.accepted = false; }
                Keys.onMenuPressed: {
                    const it = root.zone === 0 ? pinnedGrid.itemAtIndex(root.sel) : root.zone === 1 ? appsGrid.itemAtIndex(root.sel) : resultsList.itemAtIndex(root.sel);
                    if (it) root.requestMenu(root.zone, root.sel, it);
                }
                Text {
                    visible: !search.text
                    text: "Search apps, files, settings"
                    color: Theme.fg3
                    font: search.font
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Label { id: escHint; text: "esc"; size: 10; color: Theme.fg3; anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter }
        }

        // ── scrolling content ────────────────────────────────────────────
        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: content.height
            boundsBehavior: Flickable.StopAtBounds
            Behavior on contentY { enabled: !flick.moving; NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

            Column {
                id: content
                width: flick.width
                spacing: 10

                SectionLabel { visible: root.pinnedShown; text: "Pinned"; leftPadding: 4 }
                AppGrid {
                    id: pinnedGrid
                    panel: root
                    width: content.width
                    visible: root.pinnedShown
                    zoneId: 0
                    model: root.pinnedShown ? root.pinnedModel : null
                    count: root.pinnedShown ? root.pinnedCount : 0
                }
                Item { visible: root.pinnedShown; width: 1; height: 0 }    // grid cells already leave ~24px of air: no divider
                SectionLabel { visible: root.pinnedShown || root.searching; text: root.searching ? "Apps" : "All apps"; leftPadding: 4 }

                AppGrid {
                    id: appsGrid
                    panel: root
                    width: content.width
                    zoneId: 1
                    model: root.appsModel
                    count: root.appsCount
                }
                Text {
                    visible: root.searching && root.appsCount === 0 && root.resultsCount === 0 && !root.busy
                    width: parent.width
                    topPadding: 40; bottomPadding: 40
                    horizontalAlignment: Text.AlignHCenter
                    text: "·  ·  ·   nothing found   ·  ·  ·"
                    color: Theme.fg3; font.family: Theme.mono; font.pixelSize: 12; font.weight: Font.Normal
                }

                SectionLabel { visible: root.resultsShown; text: "Files, settings & more"; leftPadding: 4; topPadding: 14 }
                ListView {
                    id: resultsList
                    visible: root.resultsShown
                    width: parent.width
                    height: contentHeight
                    interactive: false
                    spacing: 4
                    model: root.resultsShown ? root.resultsModel : null
                    delegate: Pressable {
                        id: row
                        required property int index
                        required property var model
                        readonly property bool selected: root.zone === 2 && root.sel === index && (root.keyboardNav || root.searching)
                        width: resultsList.width
                        height: 56
                        pressScale: 0.98
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) root.requestMenu(2, index, row);
                            else root.activate(2, index);
                        }
                        onEntered: { root.keyboardNav = false; root.zone = 2; root.sel = index; }
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: row.selected ? root.widgetFill : (row.containsMouse ? Theme.card : "transparent")
                        }
                        Rectangle {
                            id: rdisc
                            width: 40; height: 40; radius: 20
                            x: 8; anchors.verticalCenter: parent.verticalCenter
                            color: row.selected && root.keyboardNav ? Theme.fg : (row.selected ? Theme.card3 : root.widgetFill)
                            MonoIcon { anchors.centerIn: parent; size: 18; source: row.model.decoration; symbolicNames: root.symbolicNames; fallback: root.iconFallback; dark: row.selected && root.keyboardNav }
                        }
                        Column {
                            anchors.left: rdisc.right; anchors.leftMargin: 14
                            anchors.right: grp.left; anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                width: parent.width
                                text: row.model.display || ""
                                elide: Text.ElideRight
                                color: Theme.fg
                                font.family: Theme.sans; font.pixelSize: 14; font.weight: Font.Normal
                            }
                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: row.model.description || ""
                                elide: Text.ElideMiddle
                                color: Theme.fg2
                                font.family: Theme.mono; font.pixelSize: 10; font.weight: Font.Normal
                            }
                        }
                        SectionLabel {
                            id: grp
                            anchors.right: parent.right; anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.model.group || ""
                        }
                    }
                }
                Item { width: 1; height: 48 }   // room to scroll the last row out of the fade
            }
            Rectangle {
                // last 48px fade into the black card so rows never end in a hard cut
                parent: flick
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 48
                visible: flick.contentHeight > flick.height
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Theme.bg }
                }
            }
        }
    }

    component SectionLabel: Label {
        size: 11
        color: Theme.fg2
        font.letterSpacing: 1.8
        font.weight: Font.Normal
    }

    // ── app grid (pinned + all apps) ─────────────────────────────────────
    component AppGrid: GridView {
        id: grid
        property Item panel: null
        property int zoneId: 1
        property int count: 0
                height: Math.ceil(count / panel.cols) * cellHeight
        interactive: false
        cellWidth: Math.floor(width / panel.cols)
        cellHeight: 118
        delegate: Pressable {
            id: cell
            required property int index
            required property var model
            readonly property bool selected: panel.zone === grid.zoneId && panel.sel === index && (panel.keyboardNav || panel.searching)
            width: grid.cellWidth; height: grid.cellHeight
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) panel.requestMenu(grid.zoneId, index, cell);
                else panel.activate(grid.zoneId, index);
            }
            onEntered: { panel.keyboardNav = false; panel.zone = grid.zoneId; panel.sel = index; }
            Rectangle {
                id: disc
                width: 64; height: 64; radius: 32
                anchors.horizontalCenter: parent.horizontalCenter
                y: 8
                // white disc + black glyph only for keyboard focus; the Enter target while
                // typing gets a quiet ring instead
                readonly property bool focused: cell.selected && panel.keyboardNav
                color: focused ? Theme.fg : (cell.containsMouse ? Theme.card3 : panel.widgetFill)
                border.width: cell.selected && !focused && panel.searching ? 1 : 0
                border.color: Theme.fg3
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                MonoIcon { anchors.centerIn: parent; size: 26; source: cell.model.decoration; symbolicNames: panel.symbolicNames; fallback: panel.iconFallback; dark: disc.focused }
            }
            Text {
                anchors.top: disc.bottom; anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 12
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight          // last resort for very long names
                lineHeight: 0.95
                text: cell.model.display || ""
                color: disc.focused || cell.containsMouse ? Theme.fg : Theme.fg2
                font.family: Theme.sans; font.pixelSize: 12; font.weight: Font.Normal
            }
        }
    }
}
