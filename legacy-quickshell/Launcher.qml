import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// App drawer: search pill + monochrome icon grid. Type to filter, Enter to launch.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property bool open: Ui.launcherScreen === modelData
    visible: open || sheet.opacity > 0
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nothing-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open) { search.text = ""; grid.currentIndex = 0; search.forceActiveFocus(); }

    readonly property var apps: {
        const q = search.text.trim().toLowerCase();
        const all = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        const scored = [];
        for (const a of all) {
            const n = (a.name || "").toLowerCase();
            let s = -1;
            if (!q) s = 0;
            else if (n.startsWith(q)) s = 3;
            else if (n.includes(q)) s = 2;
            else if ((a.genericName || "").toLowerCase().includes(q) || (a.keywords || []).join(" ").toLowerCase().includes(q)) s = 1;
            if (s >= 0) scored.push({ a: a, s: s, n: n });
        }
        scored.sort((x, y) => y.s - x.s || x.n.localeCompare(y.n));
        return scored.map(x => x.a);
    }
    function launch(a) { if (!a) return; a.execute(); Ui.closeAll(); }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: win.open ? 0.72 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        MouseArea { anchors.fill: parent; onClicked: Ui.closeAll() }
    }

    Rectangle {
        id: sheet
        width: Math.min(860, win.width - 80)
        height: Math.min(620, win.height - 120)
        anchors.horizontalCenter: parent.horizontalCenter
        y: (win.height - height) / 2 + (win.open ? 0 : 28)
        radius: 32; color: Theme.bg
        border.color: Theme.line; border.width: 1
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: win.open ? Theme.normal : Theme.fast } }
        Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: win.open ? Theme.emphasized : Theme.accelerate } }
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 24
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                DotText { text: "APPS"; size: 34; weight: 800 }
                Item { Layout.fillWidth: true }
                Label { text: win.apps.length + " found" }
            }

            // search pill
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 52; radius: 26
                color: Theme.card2
                border.color: search.activeFocus ? Theme.fg3 : "transparent"; border.width: 1
                Icon { id: si; name: "search"; x: 18; anchors.verticalCenter: parent.verticalCenter; color: Theme.fg2 }
                TextInput {
                    id: search
                    anchors { left: si.right; leftMargin: 12; right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                    color: Theme.fg; font.family: Theme.sans; font.pixelSize: 17
                    selectionColor: Theme.fg; selectedTextColor: Theme.bg
                    onTextChanged: grid.currentIndex = 0
                    Keys.onEscapePressed: Ui.closeAll()
                    Keys.onReturnPressed: win.launch(win.apps[grid.currentIndex])
                    Keys.onDownPressed: grid.moveCurrentIndexDown()
                    Keys.onUpPressed: grid.moveCurrentIndexUp()
                    Keys.onRightPressed: e => { if (cursorPosition === text.length) grid.moveCurrentIndexRight(); else e.accepted = false; }
                    Keys.onLeftPressed: e => { if (cursorPosition === 0) grid.moveCurrentIndexLeft(); else e.accepted = false; }
                    Keys.onTabPressed: grid.moveCurrentIndexRight()
                    Text { visible: !search.text; text: "Search"; color: Theme.fg3; font: search.font }
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                cellWidth: width / Math.max(1, Math.floor(width / 120))
                cellHeight: 118
                model: win.apps
                highlightFollowsCurrentItem: false
                boundsBehavior: Flickable.StopAtBounds
                delegate: Pressable {
                    id: cell
                    required property var modelData
                    required property int index
                    width: grid.cellWidth; height: grid.cellHeight
                    readonly property bool sel: GridView.isCurrentItem
                    onClicked: win.launch(modelData)
                    onEntered: grid.currentIndex = index
                    Rectangle {
                        id: disc
                        width: 64; height: 64; radius: 32
                        anchors.horizontalCenter: parent.horizontalCenter; y: 10
                        color: cell.sel ? Theme.fg : Theme.card2
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 34
                            source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                            layer.enabled: true
                            layer.effect: MultiEffect { saturation: -1; contrast: 0.15; brightness: cell.sel ? -0.15 : 0.05 }
                        }
                    }
                    Text {
                        anchors.top: disc.bottom; anchors.topMargin: 8
                        width: parent.width - 12; anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                        text: cell.modelData.name
                        color: cell.sel ? Theme.fg : Theme.fg2
                        font.family: Theme.sans; font.pixelSize: 12
                    }
                }
            }
        }
    }
}
