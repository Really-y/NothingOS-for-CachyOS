import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Nothing-style widgets pinned under windows on the primary screen.
PanelWindow {
    id: win
    screen: Quickshell.screens[0]
    anchors { top: true; left: true }
    margins { top: 64; left: 40 }
    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "nothing-widgets"

    SystemClock { id: clock; precision: SystemClock.Seconds }

    GridLayout {
        id: grid
        columns: 2; rowSpacing: Theme.gap; columnSpacing: Theme.gap

        // ---- big dot-matrix clock (wide)
        Card {
            span: 2; Layout.columnSpan: 2
            DotText {
                id: big
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: 14
                text: Qt.formatTime(clock.date, "HH:mm")
                size: 98; weight: 800
            }
            RowLayout {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 22 }
                Label { text: Qt.formatDate(clock.date, "ddd d MMM"); color: Theme.fg }
                Item { Layout.fillWidth: true }
                // seconds as a running dot bar
                Row {
                    spacing: 3
                    Repeater {
                        model: 12
                        Rectangle {
                            required property int index
                            width: 4; height: 4; radius: 2
                            color: index <= Math.floor(clock.date.getSeconds() / 5) ? (index === Math.floor(clock.date.getSeconds() / 5) ? Theme.red : Theme.fg) : Theme.card3
                        }
                    }
                }
            }
        }

        // ---- weather
        Card {
            Icon { x: 20; y: 18; name: Weather.icon; size: 30; color: Theme.fg }
            Label { anchors.right: parent.right; anchors.rightMargin: 20; y: 24; text: Theme.city }
            DotText {
                x: 18; anchors.bottom: wdesc.top; anchors.bottomMargin: -2
                text: Weather.ok ? Weather.temp + "°" : "--"
                size: 56; weight: 800
            }
            Label {
                id: wdesc
                x: 20; anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                text: Weather.ok ? Weather.hi + "° / " + Weather.lo + "°  " + Weather.desc : "offline"
                width: parent.width - 40; elide: Text.ElideRight
            }
        }

        // ---- system: CPU + RAM as dot rings
        Card {
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -8
                spacing: 6
                Repeater {
                    model: [{ v: Sys.cpu, l: "CPU" }, { v: Sys.mem, l: "RAM" }]
                    Item {
                        required property var modelData
                        width: 72; height: 72
                        DotRing { anchors.fill: parent; value: parent.modelData.v; dots: 20; dotSize: 4.5 }
                        Text {
                            anchors.centerIn: parent
                            text: Math.round(parent.modelData.v * 100)
                            color: Theme.fg; font.family: Theme.dot; font.pixelSize: 22
                            font.variableAxes: ({ "ROND": 100, "wght": 800 })
                        }
                    }
                }
            }
            Row {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 46
                Label { text: "cpu" }
                Label { text: "ram" }
            }
        }

        // ---- media (wide, only while something plays)
        Card {
            span: 2; Layout.columnSpan: 2
            visible: Media.active
            RowLayout {
                anchors.fill: parent; anchors.margins: 18
                spacing: 16
                ClippingRectangle {
                    Layout.preferredWidth: 130; Layout.preferredHeight: 130; radius: 20
                    color: Theme.card3
                    Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                    Icon { anchors.centerIn: parent; visible: Media.art === ""; name: "album"; size: 48; color: Theme.fg3 }
                }
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    spacing: 4
                    Label { text: Media.playing ? "now playing" : "paused"; color: Media.playing ? Theme.red : Theme.fg2 }
                    Text { Layout.fillWidth: true; text: Media.title; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap; color: Theme.fg; font.family: Theme.sans; font.pixelSize: 17; font.weight: Font.Medium }
                    Text { Layout.fillWidth: true; text: Media.artist; elide: Text.ElideRight; color: Theme.fg2; font.family: Theme.sans; font.pixelSize: 13 }
                    Item { Layout.fillHeight: true }
                    Row {
                        spacing: 10
                        Pressable { width: 36; height: 36; onClicked: Media.player.previous(); Icon { anchors.centerIn: parent; name: "skip_previous"; fill: 1 } }
                        Pressable {
                            width: 36; height: 36; onClicked: Media.player.togglePlaying()
                            Rectangle { anchors.fill: parent; radius: 18; color: Theme.fg }
                            Icon { anchors.centerIn: parent; name: Media.playing ? "pause" : "play_arrow"; fill: 1; color: Theme.bg }
                        }
                        Pressable { width: 36; height: 36; onClicked: Media.player.next(); Icon { anchors.centerIn: parent; name: "skip_next"; fill: 1 } }
                    }
                }
            }
        }
    }
}
