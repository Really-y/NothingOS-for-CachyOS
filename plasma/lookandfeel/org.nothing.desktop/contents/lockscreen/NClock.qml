/*
    Huge dot-matrix clock + mono date (Nothing OS lock screen / AOD style).
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import "nothing"

Column {
    id: clock
    property int size: 160
    property date now: new Date()
    // 24h unless the locale's short time format uses AM/PM.
    readonly property bool use24h: !/[aA]/.test(Qt.locale().timeFormat(Locale.ShortFormat))

    spacing: Math.round(size * 0.12)

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: clock.now = new Date()
    }

    DotText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(clock.now, clock.use24h ? "HH:mm" : "h:mm")
        size: clock.size
        weight: 800
        Accessible.name: Qt.formatTime(clock.now, Qt.locale().timeFormat(Locale.ShortFormat))
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12
        Label {
            text: Qt.formatDate(clock.now, "dddd")
            size: Math.max(12, Math.round(clock.size * 0.1))
            color: Theme.fg
            font.letterSpacing: 2.4
        }
        Label {
            text: Qt.formatDate(clock.now, "d MMMM")
            size: Math.max(12, Math.round(clock.size * 0.1))
            font.letterSpacing: 2.4
        }
        Label {
            visible: !clock.use24h
            text: Qt.formatTime(clock.now, "AP")
            size: Math.max(12, Math.round(clock.size * 0.1))
            font.letterSpacing: 2.4
        }
    }
}
