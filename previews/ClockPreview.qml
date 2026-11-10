import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.clock/contents/ui" as Clock

// Nothing clock: desktop card (24h + 12h), panel compact, popup calendar.
Rectangle {
    color: Theme.bg
    readonly property var mock: new Date(2026, 10, 11, 21, 47, 38)
    Column {
        x: 24; y: 24; spacing: 16
        Clock.ClockFace { width: 360; height: 180; now: mock }
        Clock.ClockFace { width: 300; height: 150; now: mock; use24h: false }
        // compact representation inside a 36px panel
        Rectangle {
            width: 360; height: 36; color: "#000000"; border.color: Theme.line
            DotText { anchors.centerIn: parent; text: "21:47"; size: 26; weight: 900 }
        }
    }
    Clock.DotCalendar { x: 408; y: 24; width: 360; today: mock }
}
