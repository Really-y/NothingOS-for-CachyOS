import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.media/contents/ui" as M

// Media: small 2×2 (playing / paused no-art / idle), wide (playing /
// paused with no previous track / idle), and the small card at panel scale.
Rectangle {
    color: Theme.bg
    Column {
        x: 24; y: 20; spacing: 10
        Label { text: "2×2 · playing   ·   paused, no art   ·   idle" }
        Row {
            spacing: 16
            M.MediaFace { width: 180; height: 180; hasMedia: true; playing: true
                title: "Glass Phases"; artist: "Nothing Ensemble"; artUrl: Qt.resolvedUrl("mock-art.png") }
            M.MediaFace { width: 180; height: 180; hasMedia: true; playing: false
                title: "A Very Long Track Title That Keeps Going"; artist: "Somebody feat. Somebody Else" }
            M.MediaFace { width: 180; height: 180 }
        }
        Item { width: 1; height: 6 }
        Label { text: "4×2 · playing   ·   paused · no previous track" }
        Row {
            spacing: 16
            M.MediaFace { width: 360; height: 180; hasMedia: true; playing: true
                title: "Glass Phases"; artist: "Nothing Ensemble"; artUrl: Qt.resolvedUrl("mock-art.png") }
            M.MediaFace { width: 360; height: 180; hasMedia: true; playing: false; canPrevious: false
                title: "A Very Long Track Title That Keeps Going (Extended Mix)"; artist: "Somebody feat. Somebody Else & Friends" }
        }
        Item { width: 1; height: 6 }
        Row {
            spacing: 16
            Column {
                spacing: 10
                Label { text: "4×2 · idle" }
                M.MediaFace { width: 360; height: 180 }
            }
            Column {
                spacing: 10
                Label { text: "2×2 · panel scale 1.22×" }
                M.MediaFace { width: 220; height: 220; hasMedia: true; playing: true
                    title: "Portrait"; artist: "Dot Matrix"; artUrl: Qt.resolvedUrl("mock-art.png") }
            }
        }
    }
}
