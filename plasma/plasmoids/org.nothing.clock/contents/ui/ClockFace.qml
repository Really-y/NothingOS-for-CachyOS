import QtQuick
import "nothing"

// Nothing clock card. Pure view: feed it `now`.
//  wide   (≈2:1): date caption + HH:mm in dots with a red two-dot colon
//  square (≈1:1): hours stacked over minutes, date column on the right
// `variant: "auto"` picks from the aspect ratio.
Card {
    id: root
    property var now: new Date()
    property bool use24h: true
    property bool showSeconds: false
    property string variant: "auto"          // "auto" | "wide" | "square"

    readonly property bool square: variant === "square" || (variant === "auto" && width / Math.max(1, height) < 1.5)
    readonly property real u: square ? Math.min(width, height) / 180 : Math.min(width / 360, height / 180)
    // Labels stay English: Nothing's mono captions are part of the look.
    readonly property var en: Qt.locale("en_US")
    readonly property int h24: now.getHours()
    readonly property int h12: (h24 + 11) % 12 + 1
    readonly property string mm: String(now.getMinutes()).padStart(2, "0")
    readonly property string day: en.dayName(now.getDay(), Locale.ShortFormat)
    readonly property string mon: en.monthName(now.getMonth(), Locale.ShortFormat)

    padding: Math.round(22 * u)
    implicitWidth: 360
    implicitHeight: 180

    // ── Wide ───────────────────────────────────────────────────────────────
    Item {
        id: wide
        visible: !root.square
        anchors.fill: parent
        anchors.margins: root.padding

        Label {
            id: dateLabel
            size: Math.max(10, Math.round(11 * root.u))
            text: root.day + " " + root.now.getDate() + " " + root.mon
        }
        Label {
            anchors.right: parent.right
            anchors.verticalCenter: dateLabel.verticalCenter
            visible: !root.use24h
            size: dateLabel.size
            color: Theme.fg3
            text: root.h24 < 12 ? "AM" : "PM"
        }

        Item {
            id: timeArea
            anchors.top: dateLabel.bottom
            anchors.bottom: secs.visible ? secs.top : parent.bottom
            anchors.bottomMargin: secs.visible ? Math.round(10 * root.u) : 0
            width: parent.width

            DotTime {
                id: wt
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Math.round(4 * root.u)
                hours: root.use24h ? String(root.h24).padStart(2, "0") : String(root.h12)
                minutes: root.mm
                colonColor: Theme.red
                // fill the width of a 24h "HH:mm" (25 dot columns), capped by height
                size: Math.min(wide.width * 10 / (25 - 1 + dotRatio), timeArea.height * 10 / (6 + dotRatio) * 0.92)
                width: implicitWidth; height: implicitHeight
            }
        }

        // Optional seconds strip: 60 tiny dots, the current one red.
        Canvas {
            id: secs
            visible: root.showSeconds
            anchors.bottom: parent.bottom
            width: parent.width
            height: Math.max(3, Math.round(width / 60 * 0.55))
            property int s: root.now.getSeconds()
            onSChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset();
                const p = (width - height) / 59, r = height / 2;
                for (let i = 0; i < 60; i++) {
                    c.beginPath(); c.arc(r + i * p, r, r, 0, Math.PI * 2);
                    c.fillStyle = i === s ? Theme.red : i < s ? Theme.fg : Theme.dotDim;
                    c.fill();
                }
            }
        }
    }

    // ── Square ─────────────────────────────────────────────────────────────
    Item {
        id: sq
        visible: root.square
        anchors.fill: parent
        anchors.margins: root.padding

        DotTime {
            id: st
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            stacked: true
            hours: String(root.use24h ? root.h24 : root.h12).padStart(2, "0")
            minutes: root.mm
            // 11 columns wide, 16 rows tall; leave room for the date column
            size: Math.min(sq.height * 10 / (15 + dotRatio), (sq.width - dateCol.width - 8 * root.u) * 10 / (10 + dotRatio))
            width: implicitWidth; height: implicitHeight
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: st.top
            width: Math.round(7 * root.u); height: width; radius: width / 2
            color: Theme.red
        }

        Column {
            id: dateCol
            anchors.right: parent.right
            anchors.bottom: st.bottom
            spacing: Math.round(3 * root.u)
            Repeater {
                model: [root.day, String(root.now.getDate()), root.mon].concat(root.use24h ? [] : [root.h24 < 12 ? "AM" : "PM"])
                Label {
                    anchors.right: parent.right
                    size: Math.max(10, Math.round(11 * root.u))
                    color: index === 1 ? Theme.fg : Theme.fg2
                    text: modelData
                }
            }
        }
    }
}
