// render: rhi   (tools/render.sh uses the OpenGL RHI for this file so the ShaderEffect renders)
import QtQuick
import "../plasma/wallpapers/org.nothing.dots/contents/ui" as Dots

// org.nothing.dots at fixed times. Each frame is a full 1920x1080 screen scaled to 41 %.
Rectangle {
    color: "#000000"
    component Frame: Item {
        property alias time: f.time
        property alias field: f
        property string label
        width: 788; height: 443
        Item {
            width: 1920; height: 1080; scale: parent.width / 1920; transformOrigin: Item.TopLeft
            layer.enabled: true; layer.smooth: true; layer.mipmap: true
            Dots.GlyphField { id: f; anchors.fill: parent }
        }
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#2a2a2a"; border.width: 1 }
        Text {
            x: 14; y: 12; text: parent.label; color: "#8e8e8e"
            font.family: "Space Mono"; font.pixelSize: 11; font.letterSpacing: 1.2
        }
    }
    Grid {
        x: 8; y: 4; columns: 2; spacing: 8
        Frame { time: 0;    label: "T+0.0S  REST" }
        Frame { time: 2.6;  label: "T+2.6S  GLYPH SWEEP THROUGH HER" }
        Frame { time: 7.33; label: "T+7.3S  BLINK · HAIR SWAY" }
        Frame { time: 27.4; label: "T+27.4S  RIPPLE FROM THE HAIR CLIP" }
    }
}
