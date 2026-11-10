/*
    Nothing OS lock screen UI.

    A copy of Plasma's org.kde.plasma.desktop lockscreen/LockScreenUi.qml with the
    authentication flow left intact (authenticator connections, grace lock,
    PasswordSync, StackView + NoPasswordUnlock, virtual keyboard, keyboard
    layout switcher, OSD). Only the visuals changed:
      - pure black instead of the blurred wallpaper (no WallpaperFader / shadows)
      - huge Doto clock that rises when the prompt appears (AOD-like when idle)
      - Nothing-style prompt (MainBlock.qml), round action tiles, mono footer

    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.workspace.components as PW
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.kirigami as Kirigami

import org.kde.plasma.private.sessions
import org.kde.breeze.components

import "nothing"

Item {
    id: lockScreenUi

    function handleMessage(msg) {
        if (!root.notification) {
            root.notification += msg;
        } else if (root.notification.includes(msg)) {
            root.notificationRepeated();
        } else {
            root.notification += "\n" + msg
        }
    }

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind != 0) { // if this is coming from the noninteractive authenticators
                return;
            }
            const msg = i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Unlocking failed");
            lockScreenUi.handleMessage(msg);
            graceLockTimer.restart();
            notificationRemoveTimer.restart();
            rejectPasswordAnimation.start();
        }

        function onSucceeded() {
            if (authenticator.hadPrompt) {
                Qt.quit();
            } else {
                mainStack.replace(null, Qt.resolvedUrl("NoPasswordUnlock.qml"),
                    {
                        userListModel: users
                    },
                    StackView.Immediate,
                );
                mainStack.forceActiveFocus();
            }
        }

        function onInfoMessageChanged() {
            lockScreenUi.handleMessage(authenticator.infoMessage);
        }

        function onErrorMessageChanged() {
            lockScreenUi.handleMessage(authenticator.errorMessage);
        }

        function onPromptChanged(msg) {
            lockScreenUi.handleMessage(authenticator.prompt);
        }
        function onPromptForSecretChanged(msg) {
            mainBlock.showPassword = false;
            mainBlock.mainPasswordBox.forceActiveFocus();
        }
    }

    SessionManagement {
        id: sessionManagement
    }

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    Connections {
        target: sessionManagement
        function onAboutToSuspend() {
            root.clearPassword();
        }
    }

    RejectPasswordAnimation {
        id: rejectPasswordAnimation
        target: mainBlock
    }

    // Pure black, always (OLED-friendly, like Nothing's always-on display).
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    MouseArea {
        id: lockScreenRoot

        property bool uiVisible: false
        property bool seenPositionChange: false
        property bool blockUI: containsMouse && (mainStack.depth > 1 || mainBlock.mainPasswordBox.text.length > 0 || inputPanel.keyboardActive)

        x: parent.x
        y: parent.y
        width: parent.width
        height: parent.height
        hoverEnabled: true
        cursorShape: uiVisible ? Qt.ArrowCursor : Qt.BlankCursor
        drag.filterChildren: true
        onPressed: uiVisible = true;
        onPositionChanged: {
            uiVisible = seenPositionChange;
            seenPositionChange = true;
        }
        onUiVisibleChanged: {
            if (uiVisible) {
                Window.window.requestActivate();
            }

            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
            authenticator.startAuthenticating();
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }
        onExited: {
            uiVisible = false;
        }
        Keys.onEscapePressed: {
            // If the escape key is pressed, kscreenlocker will turn off the screen.
            // We do not want to show the password prompt in this case.
            if (uiVisible) {
                uiVisible = false;
                if (inputPanel.keyboardActive) {
                    inputPanel.showHide();
                }
                root.clearPassword();
            }
        }
        Keys.onPressed: event => {
            uiVisible = true;
            event.accepted = false;
        }
        Timer {
            id: fadeoutTimer
            interval: 10000
            onTriggered: {
                if (!lockScreenRoot.blockUI) {
                    mainBlock.mainPasswordBox.showPassword = false;
                    lockScreenRoot.uiVisible = false;
                }
            }
        }
        Timer {
            id: notificationRemoveTimer
            interval: 3000
            onTriggered: root.notification = ""
        }
        Timer {
            id: graceLockTimer
            interval: 3000
            onTriggered: {
                root.clearPassword();
                authenticator.startAuthenticating();
            }
        }

        PropertyAnimation {
            id: launchAnimation
            target: lockScreenRoot
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.slow
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasized
        }

        Component.onCompleted: {
            launchAnimation.start();
            if (root.previewMode) {
                uiVisible = true;
            }
        }

        // One vertical rhythm for clock + prompt: clock →48→ prompt, block centred.
        readonly property real clockBlock: clock.visible ? clock.height + 48 : 0
        readonly property real activeTop: Math.max(24, Math.round((height - clockBlock - mainBlock.contentHeight) / 2))

        // Clock: AOD-style (dimmed, ~40 px above centre) when idle, rises above the prompt when it appears.
        NClock {
            id: clock
            visible: config.alwaysShowClock
            idle: !lockScreenRoot.uiVisible
            // multiple of 10 → integer dot pitch, so the canvas never clips the last row
            size: Math.max(60, Math.floor(Math.min(lockScreenRoot.height * 0.21, lockScreenRoot.width * 0.15, 230) / 10) * 10)
            anchors.horizontalCenter: parent.horizontalCenter
            y: lockScreenRoot.uiVisible
                ? lockScreenRoot.activeTop
                : Math.round((lockScreenRoot.height - height) / 2 - 40)
            opacity: lockScreenRoot.uiVisible || !config.hideClockWhenIdle ? 1 : 0
            Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        }

        ListModel {
            id: users

            Component.onCompleted: {
                users.append({
                    name: kscreenlocker_userName,
                    realName: kscreenlocker_userName,
                    icon: kscreenlocker_userImage !== ""
                          ? "file://" + kscreenlocker_userImage.split("/").map(encodeURIComponent).join("/")
                          : "",
                })
            }
        }

        StackView {
            id: mainStack
            anchors {
                left: parent.left
                right: parent.right
            }
            height: lockScreenRoot.height + Kirigami.Units.gridUnit * 3
            focus: true //StackView is an implicit focus scope, so we need to give this focus so the item inside will have it

            // this isn't implicit, otherwise items still get processed for the scenegraph
            visible: opacity > 0
            opacity: lockScreenRoot.uiVisible ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: lockScreenRoot.uiVisible ? Theme.slow : Theme.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: lockScreenRoot.uiVisible ? Theme.emphasized : Theme.accelerate
                }
            }

            initialItem: MainBlock {
                id: mainBlock
                lockScreenUiVisible: lockScreenRoot.uiVisible
                promptTop: lockScreenRoot.activeTop + lockScreenRoot.clockBlock

                enabled: !graceLockTimer.running

                StackView.onStatusChanged: {
                    // prepare for presenting again to the user
                    if (StackView.status === StackView.Activating) {
                        mainPasswordBox.clear();
                        mainPasswordBox.focus = true;
                        root.notification = "";
                    }
                }
                userListModel: users

                notificationMessage: {
                    const parts = [];
                    if (capsLockState.locked) {
                        parts.push(i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Caps Lock is on"));
                    }
                    if (root.notification) {
                        parts.push(root.notification);
                    }
                    return parts.join("  ·  ");
                }

                onPasswordResult: password => {
                    authenticator.respond(password)
                }

                actionItems: [
                    ActionTile {
                        text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button", "Slee&p")
                        iconName: "bedtime"
                        onClicked: sessionManagement.suspend()
                        visible: sessionManagement.canSuspend
                    },
                    ActionTile {
                        text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button", "&Hibernate")
                        iconName: "ac_unit"
                        onClicked: sessionManagement.hibernate()
                        visible: sessionManagement.canHibernate
                    },
                    ActionTile {
                        text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button", "Switch &User")
                        iconName: "switch_account"
                        onClicked: {
                            sessionManagement.switchUser();
                        }
                        visible: sessionManagement.canSwitchUser
                    }
                ]

                Loader {
                    Layout.fillWidth: true
                    visible: item !== null && item.hasMedia === true
                    Layout.preferredHeight: visible ? item.implicitHeight : 0
                    active: config.showMediaControls
                    sourceComponent: root.mockMedia ? mockMediaComponent : mediaComponent
                }
            }
        }

        Component {
            id: mediaComponent
            MediaControls {
                onInteracted: fadeoutTimer.running = false
            }
        }
        Component {
            id: mockMediaComponent
            MediaCard {
                track: root.mockMedia.track
                artist: root.mockMedia.artist
                playing: root.mockMedia.playing
            }
        }

        VirtualKeyboardLoader {
            id: inputPanel

            z: 1

            screenRoot: lockScreenRoot
            mainStack: mainStack
            mainBlock: mainBlock
            passwordField: mainBlock.mainPasswordBox
        }

        Loader {
            z: 2
            active: root.viewVisible
            source: "LockOsd.qml"
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Kirigami.Units.gridUnit
            }
        }

        // Footer: virtual keyboard + keyboard layout on the left, battery on the right.
        RowLayout {
            id: footer
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 10
            opacity: lockScreenRoot.uiVisible ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.normal } }

            Pressable {
                id: virtualKeyboardButton
                implicitWidth: 40; implicitHeight: 40
                activeFocusOnTab: true
                visible: inputPanel.status === Loader.Ready
                onClicked: {
                    // Otherwise the password field loses focus and virtual keyboard
                    // keystrokes get eaten
                    mainBlock.mainPasswordBox.forceActiveFocus();
                    inputPanel.showHide()
                }
                Accessible.role: Accessible.Button
                Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "Button to show/hide virtual keyboard", "Virtual Keyboard")
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: inputPanel.keyboardActive ? Theme.fg : Theme.card2
                }
                Icon {
                    anchors.centerIn: parent; size: 20
                    name: "keyboard"
                    color: inputPanel.keyboardActive ? Theme.bg : Theme.fg
                }
            }

            Pressable {
                id: keyboardButton
                implicitWidth: layoutRow.implicitWidth + 28; implicitHeight: 40
                activeFocusOnTab: true
                visible: keyboardLayoutSwitcher.hasMultipleKeyboardLayouts
                onClicked: keyboardLayoutSwitcher.keyboardLayout.switchToNextLayout()
                Accessible.role: Accessible.Button
                Accessible.description: i18ndc("plasma_shell_org.kde.plasma.desktop", "Button to change keyboard layout", "Switch layout")
                Accessible.name: keyboardLayoutSwitcher.layoutNames.longName

                PW.KeyboardLayoutSwitcher {
                    id: keyboardLayoutSwitcher
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                }

                Rectangle { anchors.fill: parent; radius: height / 2; color: Theme.card2 }
                Row {
                    id: layoutRow
                    anchors.centerIn: parent
                    spacing: 8
                    Icon { name: "language"; size: 18; anchors.verticalCenter: parent.verticalCenter }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: keyboardLayoutSwitcher.layoutNames.shortName || keyboardLayoutSwitcher.layoutNames.longName
                        color: Theme.fg
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Loader {
                source: "BatteryIndicator.qml"
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
