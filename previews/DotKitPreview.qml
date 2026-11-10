import QtQuick
import "../plasma/plasmoids/shared"

// Dot kit: DotTime (inline / red colon / stacked), DotString, DotGlyph pictograms.
Rectangle {
    color: Theme.bg
    Column {
        x: 24; y: 24; spacing: 20
        Row {
            spacing: 32
            DotTime { hours: "21"; minutes: "47"; size: 80 }
            DotTime { hours: "09"; minutes: "05"; size: 50; stacked: true }
            DotString { text: "-3°"; size: 60 }
            DotString { text: "NO MEDIA"; size: 40 }
        }
        Row {
            spacing: 14
            Repeater {
                model: ["sun", "partly", "cloud", "fog", "rain", "snow", "storm", "cloudoff", "note", "vinyl"]
                Card {
                    width: 96; height: 112
                    DotGlyph { x: 10; y: 10; width: 76; height: 76; icon: modelData }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; y: 92; size: 9; text: modelData }
                }
            }
        }
        Row {
            spacing: 28
            Repeater {
                model: ["prev", "play", "pause", "next", "chevleft", "chevright"]
                DotGlyph { width: 30; height: 30; icon: modelData; dimColor: "transparent" }
            }
            DotTime { hours: "21"; minutes: "47"; size: 40; stacked: true }
            DotRing { width: 90; height: 90; value: 0.93 }
        }
    }
}
