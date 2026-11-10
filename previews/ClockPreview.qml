import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.clock/contents/ui" as Clock

// Nothing clock: wide 24h, wide 12h with seconds strip, square (stacked),
// small square, panel compact (unboxed), popup calendar.
Rectangle {
    color: Theme.bg
    readonly property var mock: new Date(2026, 10, 11, 21, 47, 38)
    readonly property var morning: new Date(2026, 10, 11, 9, 5, 12)
    Column {
        x: 24; y: 24; spacing: 16
        Clock.ClockFace { width: 360; height: 180; now: mock }
        Clock.ClockFace { width: 360; height: 180; now: morning; use24h: false; showSeconds: true }
        Row {
            spacing: 16
            Clock.ClockFace { width: 180; height: 180; now: mock }
            Clock.ClockFace { width: 164; height: 164; now: morning; use24h: false }
        }
        // compact representation on a 36px black panel
        Rectangle {
            width: 360; height: 36; color: "#000000"
            Text { anchors.centerIn: parent; text: "21:47"; color: Theme.fg; font.family: Theme.mono; font.bold: true; font.pixelSize: 15; font.letterSpacing: 0.5 }
        }
    }
    Clock.DotCalendar { x: 408; y: 24; width: 360; height: 320; today: mock }
}
