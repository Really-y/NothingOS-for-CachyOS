import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: 36
    color: Theme.bg
    WlrLayershell.namespace: "nothing-bar"
    WlrLayershell.layer: WlrLayer.Top

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ---------------------------------------------------------------- left
    RowLayout {
        anchors.left: parent.left; anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        // 3x3 dot grid: app drawer
        Pressable {
            Layout.preferredWidth: 22; Layout.preferredHeight: 22
            onClicked: { Ui.lastScreen = bar.screen; Ui.toggleLauncher(bar.screen); }
            Grid {
                anchors.centerIn: parent; columns: 3; spacing: 3
                Repeater {
                    model: 9
                    Rectangle {
                        required property int index
                        width: 4; height: 4; radius: 2
                        color: index === 4 && Ui.launcherScreen === bar.screen ? Theme.red : (parent.parent.containsMouse ? Theme.fg : Theme.fg2)
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }
                }
            }
        }

        // virtual desktops as dots (only if more than one)
        Row {
            visible: Desktops.count > 1
            spacing: 6
            Repeater {
                model: Desktops.count
                Rectangle {
                    required property int index
                    readonly property bool cur: index + 1 === Desktops.current
                    width: cur ? 18 : 6; height: 6; radius: 3
                    color: cur ? Theme.fg : Theme.fg3
                    Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                    MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: Desktops.go(index + 1) }
                }
            }
        }

        // now playing
        Row {
            visible: Media.active
            spacing: 8
            Rectangle {
                width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter
                color: Media.playing ? Theme.red : Theme.fg3
                SequentialAnimation on opacity {
                    running: Media.playing; loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                }
            }
            Text {
                text: Media.title + (Media.artist ? "  ·  " + Media.artist : "")
                width: Math.min(implicitWidth, 320); elide: Text.ElideRight
                color: Theme.fg2; font.family: Theme.mono; font.pixelSize: 11
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (Media.player) Media.player.togglePlaying() }
            }
        }
    }

    // ---------------------------------------------------------------- centre
    DotText {
        anchors.centerIn: parent
        text: Qt.formatTime(clock.date, "HH:mm")
        size: 20; weight: 800
    }

    // ---------------------------------------------------------------- right
    RowLayout {
        anchors.right: parent.right; anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: SystemTray.items
            Pressable {
                id: trayBtn
                required property var modelData
                Layout.preferredWidth: 24; Layout.preferredHeight: 24
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: e => {
                    if (e.button === Qt.LeftButton && !modelData.onlyMenu) modelData.activate();
                    else if (e.button === Qt.MiddleButton) modelData.secondaryActivate();
                    else if (modelData.hasMenu) {
                        const p = trayBtn.mapToItem(null, 0, trayBtn.height + 6);
                        modelData.display(bar, p.x, p.y);
                    }
                }
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 16
                    source: trayBtn.modelData.icon
                    layer.enabled: true
                    layer.effect: MultiEffect { saturation: -1; brightness: trayBtn.containsMouse ? 0.25 : 0 }
                }
            }
        }

        Item { Layout.preferredWidth: 4 }

        // status pill → quick settings
        Pressable {
            id: pill
            pressScale: 0.96
            Layout.preferredHeight: 26
            Layout.preferredWidth: statusRow.implicitWidth + 22
            onClicked: { Ui.lastScreen = bar.screen; Ui.toggleQs(bar.screen); }
            Rectangle {
                anchors.fill: parent; radius: height / 2
                color: Ui.qsScreen === bar.screen ? Theme.fg : (pill.containsMouse ? Theme.card2 : Theme.card)
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }
            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: 8
                readonly property color c: Ui.qsScreen === bar.screen ? Theme.bg : Theme.fg
                Icon { name: Net.icon; size: 16; color: statusRow.c }
                Icon { visible: Net.btOn; name: Net.btConnected > 0 ? "bluetooth_connected" : "bluetooth"; size: 16; color: statusRow.c }
                Icon { name: Audio.icon; size: 16; color: statusRow.c }
                Icon { visible: Sys.hasBattery; name: Sys.charging ? "battery_charging_full" : "battery_full"; size: 16; color: statusRow.c }
                Icon { visible: Notifs.dnd; name: "do_not_disturb_on"; size: 16; color: statusRow.c }
                Rectangle {
                    visible: Notifs.unread > 0
                    width: 6; height: 6; radius: 3; color: Theme.red
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
