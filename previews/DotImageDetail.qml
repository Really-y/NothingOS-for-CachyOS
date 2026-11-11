// render: rhi   (tools/render.sh uses the OpenGL RHI for this file so the ShaderEffect renders)
import QtQuick
import "../plasma/wallpapers/org.nothing.dotimage/contents/ui" as Dot

// org.nothing.dotimage at 1:1 (no scaling): 1920x1080 screens, cropped, default settings
// unless labelled. Synthetic cards only (tools/dotimage_testcard.py --all).
//   tools/render.sh previews/DotImageDetail.qml previews/dotimage-detail.png 1600 900
Rectangle {
    color: "#000000"
    component Crop: Item {
        id: cr
        property alias field: f
        property string label
        property point at                 // screen point shown at the crop's centre
        width: 788; height: 443; clip: true
        Dot.DotImageField {
            id: f; width: 1920; height: 1080
            x: -cr.at.x + cr.width / 2; y: -cr.at.y + cr.height / 2
            source: Qt.resolvedUrl("assets/dotimage-testcard.png")
            transitionMs: 0; animated: false
        }
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#2a2a2a"; border.width: 1 }
        Rectangle { x: 8; y: 8; width: lbl.width + 12; height: lbl.height + 6; color: "#000000" }
        Text {
            id: lbl; x: 14; y: 11; text: cr.label; color: "#8e8e8e"
            font.family: "Space Mono"; font.pixelSize: 11; font.letterSpacing: 1.2
        }
    }
    readonly property url square: Qt.resolvedUrl("assets/dotimage-square.png")
    readonly property url lineart: Qt.resolvedUrl("assets/dotimage-lineart.png")
    Grid {
        x: 8; y: 4; columns: 2; spacing: 8
        Crop { label: "SQUARE · FILL · 5 PX (DEFAULT)"; at: Qt.point(960, 300); field.source: parent.parent.square }
        Crop { label: "SQUARE · MONO + RED · 3 PX"; at: Qt.point(1010, 230); field.source: parent.parent.square; field.pitch: 3; field.colorMode: 2 }
        Crop { label: "LINE ART · 5 PX · DETAIL ON (DEFAULT)"; at: Qt.point(1340, 560); field.source: parent.parent.lineart }
        Crop { label: "LINE ART · 5 PX · DETAIL OFF"; at: Qt.point(1340, 560); field.source: parent.parent.lineart; field.edges: false }
    }
}
