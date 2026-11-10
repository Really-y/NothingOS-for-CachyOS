/*
    Huge dot-matrix clock + mono date (Nothing OS lock screen / AOD style).
    Uses the shared kit's DotTime (same dot renderer as the control center, with a
    real two-dot colon). When `idle`, the clock dims and a quiet status row
    (battery, on laptops) appears under the date.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import "nothing"

Column {
    id: clock

    property int size: 150
    property bool idle: false
    property date now: new Date()
    // 24h unless the locale's short time format uses AM/PM.
    readonly property bool use24h: !/[aA]/.test(Qt.locale().timeFormat(Locale.ShortFormat))

    spacing: 32

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clock.now = new Date()
    }

    DotTime {
        readonly property int h: clock.now.getHours()

        anchors.horizontalCenter: parent.horizontalCenter
        hours: clock.use24h ? (h < 10 ? "0" : "") + h : String((h + 11) % 12 + 1)
        minutes: Qt.formatTime(clock.now, "mm")
        size: clock.size
        // AOD: ~60% grey, thinner dots
        color: clock.idle ? "#9a9a9a" : Theme.fg
        dotRatio: 0.65   // one dot renderer system-wide: dot:pitch ≈ 0.65
        width: implicitWidth
        height: implicitHeight
        Accessible.role: Accessible.StaticText
        Accessible.name: Qt.formatTime(clock.now, Qt.locale().timeFormat(Locale.ShortFormat))
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Label {
                text: Qt.formatDate(clock.now, "dddd")
                size: 13
                color: clock.idle ? Theme.fg3 : Theme.fg
                font.letterSpacing: 2.4
            }

            Label {
                text: Qt.formatDate(clock.now, "d MMMM")
                size: 13
                color: clock.idle ? Theme.fg3 : Theme.fg2
                font.letterSpacing: 2.4
            }

            Label {
                visible: !clock.use24h
                text: Qt.formatTime(clock.now, "AP")
                size: 13
                color: clock.idle ? Theme.fg3 : Theme.fg2
                font.letterSpacing: 2.4
            }

        }

        // Quiet AOD status row: battery % (laptops only). Collapses when empty.
        Loader {
            anchors.horizontalCenter: parent.horizontalCenter
            active: clock.idle
            visible: active && item && item.visible
            height: visible ? implicitHeight : 0
            source: "BatteryIndicator.qml"
            onLoaded: item.quiet = true
        }

    }

}
