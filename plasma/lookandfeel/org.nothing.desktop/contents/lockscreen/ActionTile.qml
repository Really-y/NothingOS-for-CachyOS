/*
    Round icon tile with a mono caption underneath (sleep / hibernate / switch user).
    Replaces org.kde.breeze.components ActionButton.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import "nothing"

Item {
    id: tile
    property string text            // may contain a KDE "&" accelerator
    property string iconName
    signal clicked()

    readonly property string plainText: text.replace("&", "")
    implicitWidth: Math.max(64, caption.implicitWidth)
    implicitHeight: disc.height + 10 + caption.implicitHeight
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: plainText
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.onSpacePressed: clicked()

    Pressable {
        id: disc
        width: 56; height: 56
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: tile.clicked()
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: disc.containsMouse || tile.activeFocus ? Theme.card3 : Theme.card2
            border.width: tile.activeFocus ? 1 : 0
            border.color: Theme.fg2
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        Icon { anchors.centerIn: parent; name: tile.iconName; size: 24 }
    }
    Label {
        id: caption
        anchors.top: disc.bottom; anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        text: tile.plainText
        size: 10
    }
}
