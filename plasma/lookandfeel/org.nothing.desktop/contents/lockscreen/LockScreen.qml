/*
    Nothing OS lock screen — entry point loaded by kscreenlocker_greet.
    Based on Plasma's org.kde.plasma.desktop LockScreen.qml (structure unchanged).

    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Item {
    id: root
    property bool debug: false
    property string notification
    signal clearPassword()
    signal notificationRepeated()

    // These are magical properties that kscreenlocker looks for
    property bool viewVisible: false

    // Offscreen preview hooks only (previews/LockscreenPreview.qml). The greeter
    // never sets these, so they have no effect on the real lock screen.
    property bool previewMode: false
    property var mockMedia: null

    LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitWidth: 800
    implicitHeight: 600

    LockScreenUi {
        anchors.fill: parent
    }
}
