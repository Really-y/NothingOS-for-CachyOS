/*
    Shown when authentication succeeded without a password prompt
    (e.g. fingerprint, or no password required): a single white "Unlock" pill.

    SPDX-FileCopyrightText: 2022 David Edmundson <davidedmundson@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import "nothing"

FocusScope {
    id: screen
    focus: true
    property var userListModel

    Pressable {
        id: loginButton
        focus: true
        activeFocusOnTab: true
        width: Math.max(200, caption.implicitWidth + 64); height: 56
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: 48
        onClicked: Qt.quit()
        Keys.onEnterPressed: Qt.quit()
        Keys.onReturnPressed: Qt.quit()
        Keys.onSpacePressed: Qt.quit()
        Accessible.role: Accessible.Button
        Accessible.name: caption.text

        Rectangle { anchors.fill: parent; radius: height / 2; color: Theme.fg }
        Row {
            anchors.centerIn: parent
            spacing: 10
            Icon { name: "lock_open"; size: 22; color: Theme.bg; anchors.verticalCenter: parent.verticalCenter }
            Text {
                id: caption
                anchors.verticalCenter: parent.verticalCenter
                text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button no-password unlock", "Unlock")
                color: Theme.bg
                font.family: Theme.sans; font.pixelSize: 16; font.weight: Font.Medium
            }
        }
    }

    Component.onCompleted: {
        forceActiveFocus();
    }
}
