// render: rhi
import QtQuick
import "../plasma/wallpapers/org.nothing.dots/contents/ui" as Dots

// 1:1 pixel crop of a 1920x1080 screen around the character (right half), eyes open / closed.
Rectangle {
    id: r
    color: "#000000"
    property real t: 0
    Row {
        spacing: 0
        Repeater {
            model: [ { t: 1.0, label: "T+1.0S" }, { t: 7.32, label: "T+7.3S  BLINK" } ]
            Item {
                width: 800; height: 900; clip: true
                Dots.GlyphField { x: -1040; y: 0; width: 1920; height: 1080; time: modelData.t }
                Text { x: 14; y: 12; text: modelData.label; color: "#8e8e8e"; font.family: "Space Mono"; font.pixelSize: 11; font.letterSpacing: 1.2 }
            }
        }
    }
}
