import QtQuick
import QtQuick.Layouts
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
    property bool accent: true          // false when another red (critical battery) owns the surface
    signal prev()
    signal playPause()
    signal next()

    implicitHeight: 92
    radius: 16
    color: "#1a1a1a"   // flat widget fill, no border (design review rule)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        Item {
            Layout.preferredWidth: 64; Layout.preferredHeight: 64
            // cover art as a halftone dot portrait on a black tile (shared kit, same as the media widget)
            Rectangle { anchors.fill: parent; radius: 4; color: Theme.bg }
            ArtCanvas {
                id: art
                anchors.fill: parent
                visible: root.art !== ""
                source: root.art
                mode: "halftone"
                radius: 4
                preset: "small"             // shared small-tile recipe (media 2×2, lockscreen)
                fadeTop: 0
                fadeBottom: 0
                matte: "#1a1a1a"
            }
            // no cover art: dot note pictogram on black
            DotGlyph {
                anchors.centerIn: parent
                visible: !art.ready
                // 7×7 note at a whole 5px pitch, 3px+ dots on pixel centres
                width: 35; height: 35
                icon: "note_s"
                snap: true
                dimColor: "transparent"
                litColor: Theme.fg2
                halfColor: Theme.fg2
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            // "● SPOTIFY": the live dot (the one red accent, only while playing) before the source
            Row {
                Layout.fillWidth: true
                visible: root.app !== ""
                spacing: 6
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: 6; radius: 3
                    color: root.playing ? (root.accent ? Theme.red : Theme.fg) : Theme.fg3
                }
                Label { text: root.app; size: 11; color: Theme.fg2; elide: Text.ElideRight }
            }
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
            component Transport: Pressable {
                id: t
                property string glyph
                property bool can: true
                width: 34; height: 44
                enabled: can
                DotGlyph {
                    anchors.centerIn: parent
                    width: 16; height: 16
                    icon: t.glyph
                    dimColor: "transparent"
                    dotRatio: 0.9
                    litColor: t.can ? Theme.fg : "#4a4a4a"
                    opacity: t.can && !t.containsMouse ? 0.9 : 1
                }
            }
            Transport { glyph: "prev"; can: root.canPrev; onClicked: root.prev() }
            Pressable {
                width: 44; height: 44
                onClicked: root.playPause()
                Rectangle { anchors.fill: parent; radius: 22; color: Theme.fg }
                DotGlyph {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: root.playing ? 0 : 1
                    width: 16; height: 16
                    icon: root.playing ? "pause" : "play"
                    dimColor: "transparent"
                    litColor: Theme.bg
                    dotRatio: 0.9
                }
            }
            Transport { glyph: "next"; can: root.canNext; onClicked: root.next() }
        }
    }
}
