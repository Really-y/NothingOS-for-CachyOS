// render: rhi   (tools/render.sh uses the OpenGL RHI for this file so the ShaderEffect renders)
import QtQuick
import "../plasma/wallpapers/org.nothing.dotimage/contents/ui" as Dot

// org.nothing.dotimage at 1:1 (no scaling): 1920x1080 screens, cropped. Top row: the
// synthetic test card's face at two pitches. Bottom row: a KDE-shipped photo wallpaper
// (Coast, CC-BY-SA-4.0, read from /usr/share/wallpapers, not copied into the repo).
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
        Text {
            x: 14; y: 12; text: cr.label; color: "#8e8e8e"
            font.family: "Space Mono"; font.pixelSize: 11; font.letterSpacing: 1.2
        }
    }
    readonly property url photo: "file:///usr/share/wallpapers/Coast/contents/images/5120x2880.png"
    Grid {
        x: 8; y: 4; columns: 2; spacing: 8
        Crop { label: "1:1 · MONO · 6 PX"; at: Qt.point(1272, 560); field.pitch: 6 }
        Crop { label: "1:1 · MONO + RED · 10 PX"; at: Qt.point(1272, 520); field.pitch: 10; field.colorMode: 2 }
        Crop { label: "1:1 · PHOTO · MONO · 8 PX"; at: Qt.point(960, 540); field.pitch: 8; field.source: parent.parent.photo }
        Crop { label: "1:1 · PHOTO · COLOUR · 8 PX"; at: Qt.point(960, 540); field.pitch: 8; field.colorMode: 1; field.source: parent.parent.photo }
    }
}
