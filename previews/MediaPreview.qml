import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.media/contents/ui" as M

// Media: square (playing halftone art, paused long title, idle) and wide
// (playing mono art, paused no art + disabled prev, idle).
Rectangle {
    color: Theme.bg
    Column {
        x: 24; y: 24; spacing: 16
        Row {
            spacing: 16
            M.MediaFace { width: 180; height: 180; hasMedia: true; playing: true
                title: "Glass Phases"; artist: "Nothing Ensemble"; artUrl: Qt.resolvedUrl("mock-art.png") }
            M.MediaFace { width: 180; height: 180; hasMedia: true; playing: false
                title: "A Very Long Track Title That Keeps Going"; artist: "Somebody feat. Somebody Else" }
            M.MediaFace { width: 180; height: 180 }
        }
        Row {
            spacing: 16
            M.MediaFace { width: 360; height: 180; hasMedia: true; playing: true
                title: "Glass Phases"; artist: "Nothing Ensemble"; artUrl: Qt.resolvedUrl("mock-art.png") }
            M.MediaFace { width: 360; height: 180; hasMedia: true; playing: false; canPrevious: false
                title: "A Very Long Track Title That Keeps Going (Extended Mix)"; artist: "Somebody feat. Somebody Else & Friends" }
        }
        Row {
            spacing: 16
            M.MediaFace { width: 360; height: 180 }
            M.MediaFace { width: 220; height: 220; hasMedia: true; playing: true
                title: "Portrait"; artist: "Dot Matrix"; artUrl: Qt.resolvedUrl("mock-art.png") }
        }
    }
}
