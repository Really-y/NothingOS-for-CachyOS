import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "nothing"

// Now-playing mini card: monochrome art, title/artist, transport.
Rectangle {
    id: root
    property string title: ""
    property string artist: ""
    property string art: ""
    property string app: ""
    property bool playing: false
    property bool canPrev: true
    property bool canNext: true
    signal prev()
    signal playPause()
    signal next()

    implicitHeight: 92
    radius: 14
    color: "#1a1a1a"   // flat widget fill, no border (design review rule)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        Item {
            Layout.preferredWidth: 64; Layout.preferredHeight: 64
            Rectangle { id: artMask; anchors.fill: parent; radius: 4; color: "white"; visible: false; layer.enabled: true }
            Rectangle { anchors.fill: parent; radius: 4; color: Theme.card3 }
            Image {
                id: artImg
                anchors.fill: parent
                source: root.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
                sourceSize: Qt.size(128, 128)
            }
            MultiEffect {
                anchors.fill: parent
                source: artImg
                visible: artImg.status === Image.Ready
                saturation: -1
                contrast: 0.1
                maskEnabled: true
                maskSource: artMask
            }
            Icon { anchors.centerIn: parent; visible: artImg.status !== Image.Ready; name: "music_note"; color: Theme.fg2 }
            // live dot: the one red accent, only while playing
            Rectangle {
                visible: root.playing
                width: 8; height: 8; radius: 4
                color: Theme.red
                border.color: "#1a1a1a"; border.width: 2
                anchors.right: parent.right; anchors.top: parent.top
                anchors.rightMargin: -2; anchors.topMargin: -2
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Label { Layout.fillWidth: true; visible: root.app !== ""; text: root.app; size: 9; color: Theme.fg3; elide: Text.ElideRight }
            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: Theme.fg
                font.family: Theme.sans; font.pixelSize: 15; font.weight: Font.Medium
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.artist
                elide: Text.ElideRight
                color: Theme.fg2
                font.family: Theme.sans; font.pixelSize: 12; font.weight: Font.Normal
            }
        }

        Row {
            spacing: 2
            Pressable {
                width: 34; height: 44; enabled: root.canPrev; opacity: enabled ? 1 : 0.35
                onClicked: root.prev()
                Icon { anchors.centerIn: parent; name: "skip_previous"; fill: 1; size: 22 }
            }
            Pressable {
                width: 44; height: 44
                onClicked: root.playPause()
                Rectangle { anchors.fill: parent; radius: 22; color: Theme.fg }
                Icon { anchors.centerIn: parent; name: root.playing ? "pause" : "play_arrow"; fill: 1; color: Theme.bg; size: 24 }
            }
            Pressable {
                width: 34; height: 44; enabled: root.canNext; opacity: enabled ? 1 : 0.35
                onClicked: root.next()
                Icon { anchors.centerIn: parent; name: "skip_next"; fill: 1; size: 22 }
            }
        }
    }
}
