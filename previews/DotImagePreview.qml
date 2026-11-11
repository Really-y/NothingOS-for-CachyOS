// render: rhi   (tools/render.sh uses the OpenGL RHI for this file so the ShaderEffect renders)
import QtQuick
import "../plasma/wallpapers/org.nothing.dotimage/contents/ui" as Dot

// org.nothing.dotimage, HALFTONE look, on a synthetic test card (previews/assets/dotimage-testcard.png,
// made by tools/dotimage_testcard.py). Each frame is a full 1920x1080 screen scaled down.
//   tools/render.sh previews/DotImagePreview.qml previews/dotimage-modes.png 1600 900
// Optional env-free variants: DotImageDetail.qml (1:1 crops, two pitches).
Rectangle {
    color: "#000000"
    component Frame: Item {
        id: fr
        property alias field: f
        property string label
        width: 788; height: 443
        Item {
            width: 1920; height: 1080; scale: parent.width / 1920; transformOrigin: Item.TopLeft
            layer.enabled: true; layer.smooth: true; layer.mipmap: true
            Dot.DotImageField {
                id: f; anchors.fill: parent
                source: Qt.resolvedUrl("assets/dotimage-testcard.png")
                transitionMs: 0; animated: false; look: 1   // halftone look
            }
        }
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#2a2a2a"; border.width: 1 }
        Text {
            x: 14; y: 12; text: fr.label; color: "#8e8e8e"
            font.family: "Space Mono"; font.pixelSize: 11; font.letterSpacing: 1.2
        }
    }
    Grid {
        x: 8; y: 4; columns: 2; spacing: 8
        Frame { label: "MONO · 5 PX · DEFAULTS"; field.pitch: 5 }
        Frame { label: "ORIGINAL COLOUR · 8 PX"; field.pitch: 8; field.colorMode: 1 }
        Frame { label: "MONO + RED ACCENT · 12 PX · GLYPH SWEEP"; field.pitch: 12; field.colorMode: 2; field.animated: true; field.time: 1.25 }
        Frame { label: "FIT · PORTRAIT · 6 PX · SMOOTH"; field.pitch: 6; field.fillMode: 1; field.levels: 0; field.source: Qt.resolvedUrl("assets/dotimage-portrait.png") }
    }
}
