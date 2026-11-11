// render: rhi   (tools/render.sh uses the OpenGL RHI for this file so the ShaderEffect renders)
import QtQuick
import "../plasma/wallpapers/org.nothing.dotimage/contents/ui" as Dot

// org.nothing.dotimage framing (halftone look) on synthetic cards (tools/dotimage_testcard.py --all): each
// frame is a full 1920x1080 screen scaled down. White border = picture edge, bars = TOP / BOTTOM.
//   tools/render.sh previews/DotImageFraming.qml previews/dotimage-framing.png 1600 690
Rectangle {
    color: "#000000"
    component Frame: Item {
        id: fr
        property alias field: f
        property string label
        width: 524; height: 295
        Item {
            width: 1920; height: 1080; scale: parent.width / 1920; transformOrigin: Item.TopLeft
            layer.enabled: true; layer.smooth: true; layer.mipmap: true
            Dot.DotImageField { id: f; anchors.fill: parent; transitionMs: 0; animated: false; pitch: 6; look: 1 }
        }
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#2a2a2a"; border.width: 1 }
        Rectangle { x: 8; y: 8; width: lbl.width + 12; height: lbl.height + 6; color: "#000000" }
        Text {
            id: lbl; x: 14; y: 11; text: fr.label; color: "#8e8e8e"
            font.family: "Space Mono"; font.pixelSize: 11; font.letterSpacing: 1.2
        }
    }
    Grid {
        x: 8; y: 8; columns: 3; spacing: 8
        Frame { label: "SQUARE · FILL · FOCUS 0.3 (DEFAULT)"; field.source: Qt.resolvedUrl("assets/dotimage-square.png") }
        Frame { label: "SQUARE · FILL · CENTRE (OLD BEHAVIOUR)"; field.source: Qt.resolvedUrl("assets/dotimage-square.png"); field.focusY: 0.5 }
        Frame { label: "SQUARE · FIT"; field.source: Qt.resolvedUrl("assets/dotimage-square.png"); field.fillMode: 1 }
        Frame { label: "PORTRAIT 2:3 · FILL · FOCUS 0.3"; field.source: Qt.resolvedUrl("assets/dotimage-portrait.png") }
        Frame { label: "PORTRAIT 2:3 · FIT"; field.source: Qt.resolvedUrl("assets/dotimage-portrait.png"); field.fillMode: 1 }
        Frame { label: "ULTRA-WIDE 21:9 · FILL"; field.source: Qt.resolvedUrl("assets/dotimage-ultrawide.png") }
    }
}
