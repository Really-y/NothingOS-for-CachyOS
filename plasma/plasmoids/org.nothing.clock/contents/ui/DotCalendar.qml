import QtQuick
import "nothing"

// Month grid in Nothing style: mono numerals, today = white disc with black
// numeral, days outside the month collapse to dim dots.
Card {
    id: root
    property var today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()          // 0..11
    property int firstDayOfWeek: Qt.locale().firstDayOfWeek % 7   // 0 = Sunday
    readonly property int pad: 22
    readonly property var en: Qt.locale("en_US")
    readonly property real cell: Math.floor((width - 2 * pad) / 7)

    implicitWidth: 360
    implicitHeight: 320

    function shift(d) {
        let m = month + d, y = year;
        if (m < 0) { m = 11; y--; } else if (m > 11) { m = 0; y++; }
        month = m; year = y;
    }
    function reset() { year = today.getFullYear(); month = today.getMonth(); }

    // Header: MONTH in dot type · year mono caption · dot chevrons
    Item {
        id: header
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad; height: monthDots.height
        DotString {
            id: monthDots
            // pitch 5; long month names fall back to the 3-letter form
            readonly property string longName: root.en.standaloneMonthName(root.month, Locale.LongFormat).toUpperCase()
            pitch: 5
            text: longName.length * 6 - 1 <= Math.floor((header.width - 110) / 5) ? longName : longName.slice(0, 3)
            width: implicitWidth; height: implicitHeight
        }
        Label {
            anchors.left: monthDots.right; anchors.leftMargin: 10
            anchors.bottom: monthDots.bottom; anchors.bottomMargin: -2
            size: 11; color: Theme.fg2
            text: root.year
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: -8
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: [{ i: "chevleft", d: -1 }, { i: "chevright", d: 1 }]
                Pressable {
                    width: 30; height: 30
                    onClicked: root.shift(modelData.d)
                    DotGlyph {
                        anchors.centerIn: parent
                        width: 9; height: 15
                        icon: modelData.i
                        dimColor: "transparent"
                        dotRatio: 0.8
                        litColor: parent.containsMouse ? Theme.fg : Theme.fg2
                    }
                }
            }
        }
    }

    Grid {
        id: grid
        x: root.pad + ((parent.width - 2 * root.pad) - 7 * root.cell) / 2
        anchors.top: header.bottom; anchors.topMargin: 12
        columns: 7

        // Weekday initials
        Repeater {
            model: 7
            Item {
                width: root.cell; height: 24
                Label {
                    anchors.centerIn: parent
                    size: 11
                    color: Theme.fg2
                    text: root.en.dayName((root.firstDayOfWeek + index) % 7, Locale.ShortFormat).charAt(0)
                }
            }
        }

        // 6 weeks of days
        Repeater {
            model: 42
            Item {
                readonly property var first: new Date(root.year, root.month, 1)
                readonly property int lead: (first.getDay() - root.firstDayOfWeek + 7) % 7
                readonly property var date: new Date(root.year, root.month, 1 + index - lead)
                readonly property bool inMonth: date.getMonth() === root.month
                readonly property bool isToday: date.toDateString() === root.today.toDateString()
                readonly property bool weekend: date.getDay() === 0 || date.getDay() === 6
                width: root.cell; height: Math.min(root.cell, 35)

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 6; height: width; radius: width / 2
                    color: Theme.fg
                    visible: parent.isToday
                }
                Text {
                    anchors.centerIn: parent
                    visible: parent.inMonth
                    text: parent.date.getDate()
                    color: parent.isToday ? Theme.bg : (parent.weekend ? Theme.fg2 : Theme.fg)
                    font.family: Theme.mono
                    font.pixelSize: 13
                    font.bold: parent.isToday
                }
                Rectangle {
                    anchors.centerIn: parent
                    visible: !parent.inMonth
                    width: 4; height: 4; radius: 2
                    color: Theme.dotDim
                }
            }
        }
    }
}
