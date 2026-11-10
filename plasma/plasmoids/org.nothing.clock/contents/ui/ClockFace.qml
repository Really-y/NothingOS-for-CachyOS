import QtQuick
import "nothing"

// Big dot-matrix clock card (≈2:1). Pure view: feed it `now`.
Card {
    id: root
    property var now: new Date()
    property bool use24h: true
    property bool showCard: true
    // Labels stay English: Nothing's mono captions are part of the look.
    readonly property var en: Qt.locale("en_US")

    // Everything scales from the 360×180 reference design.
    readonly property real u: Math.max(0.5, Math.min(width / 360, height / 180))
    readonly property int pad: Math.round(24 * u)
    readonly property int sec: now.getSeconds()
    readonly property int hours: use24h ? now.getHours() : ((now.getHours() + 11) % 12 + 1)
    readonly property string timeText: (use24h ? String(hours).padStart(2, "0") : String(hours))
                                       + ":" + String(now.getMinutes()).padStart(2, "0")

    implicitWidth: 360
    implicitHeight: 180
    color: showCard ? Theme.card : "transparent"
    border.width: showCard ? 1 : 0

    // Top row: weekday/date on the left, period (12h) or seconds on the right.
    Label {
        id: dateLabel
        x: root.pad; y: root.pad - Math.round(2 * root.u)
        size: Math.round(11 * root.u)
        text: root.en.dayName(root.now.getDay(), Locale.ShortFormat) + ", " + root.now.getDate() + " " + root.en.monthName(root.now.getMonth(), Locale.ShortFormat)
    }
    Label {
        anchors.right: parent.right; anchors.rightMargin: root.pad
        anchors.verticalCenter: dateLabel.verticalCenter
        size: Math.round(11 * root.u)
        color: Theme.fg3
        text: root.use24h ? String(root.sec).padStart(2, "0") : (root.now.getHours() < 12 ? "AM" : "PM")
    }

    DotText {
        id: time
        x: root.pad - Math.round(4 * root.u)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Math.round(1 * root.u)
        size: Math.round(94 * root.u)
        weight: 800
        text: root.timeText
    }

    // Seconds as 12 dots: each dot = 5 s, the current one glows red.
    Row {
        id: dots
        readonly property real dot: Math.round(7 * root.u)
        x: root.pad
        anchors.bottom: parent.bottom; anchors.bottomMargin: root.pad
        width: parent.width - 2 * root.pad
        spacing: (width - 12 * dot) / 11
        Repeater {
            model: 12
            Rectangle {
                readonly property int cur: Math.floor(root.sec / 5)
                width: dots.dot; height: dots.dot; radius: dots.dot / 2
                color: index === cur ? Theme.red : index < cur ? Theme.fg : Theme.card3
                Behavior on color { ColorAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
            }
        }
    }
}
