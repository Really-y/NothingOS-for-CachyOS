import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Full-screen transparent layer so a click outside closes the panel.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property bool open: Ui.qsScreen === modelData
    visible: open || panel.opacity > 0
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nothing-quicksettings"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    MouseArea { anchors.fill: parent; onClicked: Ui.closeAll() }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Rectangle {
        id: panel
        width: 420
        height: Math.min(content.implicitHeight + 40, win.height - 56)
        anchors.right: parent.right; anchors.rightMargin: 10
        y: 44 + (win.open ? 0 : -16)
        radius: 30
        color: Theme.bg
        border.color: Theme.line; border.width: 1
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.97
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: win.open ? Theme.normal : Theme.fast } }
        Behavior on y { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: win.open ? Theme.emphasized : Theme.accelerate } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        MouseArea { anchors.fill: parent }   // swallow clicks
        Keys.onEscapePressed: Ui.closeAll()
        focus: win.open

        Flickable {
            anchors.fill: parent; anchors.margins: 20
            contentHeight: content.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: content
                width: parent.width
                spacing: 12

                // header: date as dot-matrix
                RowLayout {
                    Layout.bottomMargin: 6
                    ColumnLayout {
                        spacing: 0
                        DotText { text: Qt.formatTime(clock.date, "HH:mm"); size: 52; weight: 800 }
                        Label { text: Qt.formatDate(clock.date, "dddd, d MMMM") }
                    }
                    Item { Layout.fillWidth: true }
                    Tile {
                        round: true; icon: "power_settings_new"; implicitWidth: 44; implicitHeight: 44
                        onClicked: powerMenu.visible = !powerMenu.visible
                    }
                }

                // power menu
                RowLayout {
                    id: powerMenu
                    visible: false
                    spacing: 8
                    Repeater {
                        model: [
                            { i: "lock", t: "Lock", c: ["loginctl", "lock-session"] },
                            { i: "logout", t: "Log out", c: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "logout"] },
                            { i: "restart_alt", t: "Restart", c: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "logoutAndReboot"] },
                            { i: "power_settings_new", t: "Off", c: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "logoutAndShutdown"] }
                        ]
                        Tile {
                            required property var modelData
                            Layout.fillWidth: true; implicitHeight: 56
                            icon: modelData.i; title: modelData.t
                            onClicked: { Ui.closeAll(); Ui.run(modelData.c); }
                        }
                    }
                }

                GridLayout {
                    columns: 2; columnSpacing: 10; rowSpacing: 10
                    Layout.fillWidth: true
                    Tile {
                        Layout.fillWidth: true
                        icon: Net.icon; active: Net.wifiOn || Net.kind === "ethernet"
                        title: Net.kind === "ethernet" ? "Ethernet" : "Internet"
                        subtitle: Net.name || (Net.wifiOn ? "Not connected" : "Off")
                        onClicked: if (Net.kind !== "ethernet") Net.toggleWifi()
                        onPressAndHold: { Ui.closeAll(); Ui.run(["systemsettings", "kcm_networkmanagement"]); }
                    }
                    Tile {
                        Layout.fillWidth: true
                        icon: Net.btConnected > 0 ? "bluetooth_connected" : "bluetooth"; active: Net.btOn
                        title: "Bluetooth"
                        subtitle: !Net.bt ? "Unavailable" : Net.btOn ? (Net.btConnected > 0 ? Net.btConnected + " connected" : "On") : "Off"
                        onClicked: Net.toggleBt()
                        onPressAndHold: { Ui.closeAll(); Ui.run(["systemsettings", "kcm_bluetooth"]); }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Tile { round: true; icon: "do_not_disturb_on"; active: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd }
                    Item { Layout.fillWidth: true }
                    Tile { round: true; icon: "nightlight"; active: Ui.nightLight; onClicked: Ui.toggleNightLight() }
                    Item { Layout.fillWidth: true }
                    Tile { round: true; icon: "screenshot_region"; onClicked: { Ui.closeAll(); Ui.run(["sh", "-c", "sleep 0.3; spectacle -r"]); } }
                    Item { Layout.fillWidth: true }
                    Tile { round: true; icon: "settings"; onClicked: { Ui.closeAll(); Ui.run(["systemsettings"]); } }
                    Item { Layout.fillWidth: true }
                    Tile { round: true; icon: "grid_view"; onClicked: Ui.toggleLauncher(win.screen) }
                }

                NSlider {
                    Layout.fillWidth: true
                    value: Audio.muted ? 0 : Audio.volume
                    icon: Audio.icon
                    onMoved: v => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
                }

                // media
                Rectangle {
                    visible: Media.active
                    Layout.fillWidth: true
                    implicitHeight: 92
                    radius: Theme.r; color: Theme.card
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14
                        spacing: 14
                        ClippingRectangle {
                            Layout.preferredWidth: 64; Layout.preferredHeight: 64; radius: 14
                            color: Theme.card3
                            Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                            Icon { anchors.centerIn: parent; visible: Media.art === ""; name: "music_note"; color: Theme.fg2 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text { Layout.fillWidth: true; text: Media.title; elide: Text.ElideRight; color: Theme.fg; font.family: Theme.sans; font.pixelSize: 15; font.weight: Font.Medium }
                            Label { Layout.fillWidth: true; text: Media.artist; elide: Text.ElideRight }
                        }
                        Row {
                            spacing: 4
                            Pressable { width: 32; height: 32; onClicked: Media.player.previous(); Icon { anchors.centerIn: parent; name: "skip_previous"; fill: 1 } }
                            Pressable {
                                width: 44; height: 44
                                onClicked: Media.player.togglePlaying()
                                Rectangle { anchors.fill: parent; radius: 22; color: Theme.fg }
                                Icon { anchors.centerIn: parent; name: Media.playing ? "pause" : "play_arrow"; fill: 1; color: Theme.bg; size: 24 }
                            }
                            Pressable { width: 32; height: 32; onClicked: Media.player.next(); Icon { anchors.centerIn: parent; name: "skip_next"; fill: 1 } }
                        }
                    }
                }

                // notifications
                RowLayout {
                    Layout.topMargin: 8
                    Label { text: "Notifications"; Layout.fillWidth: true }
                    Label {
                        visible: Notifs.list.length > 0
                        text: "Clear all"; color: cm.containsMouse ? Theme.red : Theme.fg2
                        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                    }
                }
                Text {
                    visible: Notifs.list.length === 0
                    Layout.fillWidth: true; Layout.topMargin: 10; Layout.bottomMargin: 10
                    horizontalAlignment: Text.AlignHCenter
                    text: "· · ·  nothing here  · · ·"
                    color: Theme.fg3; font.family: Theme.mono; font.pixelSize: 12
                }
                Repeater {
                    model: Notifs.list.slice().reverse()
                    NotifCard {
                        required property var modelData
                        notif: modelData
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
