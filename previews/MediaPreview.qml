import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.media/contents/ui" as M

// Media card: playing with art, paused with long title / no art, idle.
Rectangle {
    color: Theme.bg
    Column {
        x: 24; y: 24; spacing: 16
        M.MediaFace { width: 360; height: 180; hasMedia: true; playing: true
            title: "Glass Phases"; artist: "Nothing Ensemble"; artUrl: Qt.resolvedUrl("mock-art.png") }
        M.MediaFace { width: 360; height: 180; hasMedia: true; playing: false; canPrevious: false
            title: "A Very Long Track Title That Keeps Going (Extended Mix)"; artist: "Somebody feat. Somebody Else & Friends" }
        M.MediaFace { width: 360; height: 180 }
    }
}
