// render: rhi   (tools/render.sh uses the OpenGL RHI for this file so the ShaderEffect renders)
import QtQuick
import "../plasma/wallpapers/org.nothing.dotimage/contents/ui" as Dot

// org.nothing.dotimage, GLYPH FIELD look (default), on synthetic cards
// (tools/dotimage_testcard.py --all). Top: full 1920x1080 screens scaled down — rest, and
// the ripple out of the red ribbon (mono + red). Bottom: 1:1 crops at 4 px and 6 px.
//   tools/render.sh previews/DotImageGlyph.qml previews/dotimage-glyph.png 1600 900
Rectangle {
    id: root
    color: "#000000"
    readonly property url card: Qt.resolvedUrl("assets/dotimage-testcard.png")
    readonly property url square: Qt.resolvedUrl("assets/dotimage-square.png")
    component Label: Item {
        property string text
        Rectangle { x: 8; y: 8; width: t.width + 12; height: t.height + 6; color: "#000000" }
        Text { id: t; x: 14; y: 11; text: parent.text; color: "#8e8e8e"; font.family: "Space Mono"; font.pixelSize: 11; font.letterSpacing: 1.2 }
    }
    component Frame: Item {
        id: fr
        property alias field: f
        property string label
        width: 788; height: 443
        Item {
            width: 1920; height: 1080; scale: parent.width / 1920; transformOrigin: Item.TopLeft
            layer.enabled: true; layer.smooth: true; layer.mipmap: true
            Dot.DotImageField { id: f; anchors.fill: parent; transitionMs: 0; twinkle: false; time: 6 }
        }
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#2a2a2a"; border.width: 1 }
        Label { text: fr.label }
    }
    component Crop: Item {
        id: cr
        property alias field: f
        property string label
        property point at
        width: 788; height: 443; clip: true
        Dot.DotImageField {
            id: f; width: 1920; height: 1080; transitionMs: 0; animated: false
            x: -cr.at.x + cr.width / 2; y: -cr.at.y + cr.height / 2
        }
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#2a2a2a"; border.width: 1 }
        Label { text: cr.label }
    }
    Grid {
        x: 8; y: 4; columns: 2; spacing: 8
        Frame { label: "GLYPH FIELD · MONO · AUTO 4 PX"; field.source: root.card }
        Frame { label: "GLYPH FIELD · MONO + RED · RIPPLE"; field.source: root.card; field.colorMode: 2; field.time: 20.4 }
        Crop { label: "1:1 · GLYPH · 4 PX"; at: Qt.point(1272, 560); field.source: root.card; field.colorMode: 2 }
        Crop { label: "1:1 · GLYPH · SQUARE · 6 PX"; at: Qt.point(960, 330); field.source: root.square; field.finePitch: 6; field.colorMode: 2 }
    }
}
