/*
    Nothing OS unlock prompt: status line (red dot), avatar + password pill,
    fingerprint/smartcard hints, extra content (media), action tiles.

    Keeps the API of Plasma's lockscreen MainBlock.qml so LockScreenUi.qml and
    org.kde.breeze.components' VirtualKeyboardLoader work unchanged:
      mainPasswordBox, showPassword, lockScreenUiVisible, visibleBoundary,
      userListModel, notificationMessage, actionItems, passwordResult(password),
      playHighlightAnimation().

    SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kscreenlocker as ScreenLocker

import "nothing"

FocusScope {
    id: block

    readonly property alias mainPasswordBox: passwordBox
    property bool lockScreenUiVisible: false
    property alias showPassword: passwordBox.showPassword

    property var userListModel
    property alias notificationMessage: status.message
    property alias actionItems: actionRow.children
    default property alias _children: extras.children

    // the y position that should be ensured visible when the on screen keyboard is visible
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + 8

    readonly property string userName: userListModel && userListModel.count > 0 ? userListModel.get(0).name : ""
    readonly property string userIcon: userListModel && userListModel.count > 0 ? userListModel.get(0).icon : ""

    // Where the prompt column starts (set by LockScreenUi so clock + prompt share one rhythm).
    property real promptTop: height / 2
    readonly property real contentHeight: column.implicitHeight

    signal passwordResult(string password)

    function playHighlightAnimation() {
        bounce.restart();
    }

    function startLogin() {
        const password = passwordBox.text
        // Looks nicer, and works round QTBUG-55460 (app closed with a TextField focused).
        loginButton.forceActiveFocus();
        passwordResult(password);
    }

    component FailableLabel : Label {
        id: _failableLabel
        required property int kind
        required property string label

        visible: authenticator.authenticatorTypes & kind
        text: label
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        Layout.fillWidth: true

        Connections {
            target: authenticator
            function onNoninteractiveError(kind, authenticator) {
                if (kind & _failableLabel.kind) {
                    _failableLabel.text = Qt.binding(() => authenticator.errorMessage)
                    _failableLabel.color = Theme.red
                    _timer.restart()
                }
            }
        }
        Timer {
            id: _timer
            interval: 5000
            onTriggered: {
                _failableLabel.text = Qt.binding(() => _failableLabel.label)
                _failableLabel.color = Theme.fg2
            }
        }
    }

    ColumnLayout {
        id: column
        // Rhythm: [media →24→] [status 16] →16→ pill 56 →(12→ hints)→24→ action tiles
        anchors.top: parent.top
        anchors.topMargin: block.promptTop
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(400, block.width - 48)
        spacing: 0

        // Extra content (media controls) supplied by LockScreenUi — above the status line.
        ColumnLayout {
            id: extras
            Layout.fillWidth: true
            Layout.bottomMargin: implicitHeight > 0 ? 24 : 0
            spacing: 0
        }

        // Status line: red dot + mono message (errors, caps lock, PAM prompts).
        Item {
            id: status
            property string message
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(16, statusText.implicitHeight)
            opacity: message ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: 10
                width: Math.min(implicitWidth, status.width)
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: Theme.red
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    id: statusText
                    text: status.message
                    color: Theme.fg
                    width: Math.min(implicitWidth, status.width - 18)
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            SequentialAnimation {
                id: bounce
                NumberAnimation { target: statusRow; property: "scale"; to: 1.08; duration: 120; easing.type: Easing.OutQuad }
                NumberAnimation { target: statusRow; property: "scale"; to: 1.0; duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
            }
        }

        // Avatar · password · submit — one pill.
        Rectangle {
            id: pill
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.preferredHeight: 56
            radius: height / 2
            color: "#1a1a1a"

            // Avatar (user picture, or the initial in dot-matrix type).
            Item {
                id: avatar
                width: 40; height: 40
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { anchors.fill: parent; radius: width / 2; color: "#2a2a2a" }
                Text {
                    anchors.centerIn: parent
                    visible: !face.ready
                    text: block.userName.charAt(0).toUpperCase()
                    color: Theme.fg
                    font.family: Theme.sans
                    font.pixelSize: 17
                    font.weight: Font.Medium
                }
                // User picture as a halftone dot dither on a black disc.
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: "#000000"
                    visible: face.ready
                }
                ArtCanvas {
                    id: face
                    anchors.fill: parent
                    visible: ready
                    source: block.userIcon
                    mode: "halftone"
                    radius: width / 2
                    pitch: 3
                    fadeTop: 0
                    fadeBottom: 0
                }
            }

            T.TextField {
                id: passwordBox
                property bool showPassword: false

                anchors.left: avatar.right; anchors.leftMargin: 14
                anchors.right: revealButton.visible ? revealButton.left : loginButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height

                text: PasswordSync.password
                echoMode: showPassword ? TextInput.Normal : TextInput.Password
                passwordCharacter: "●"
                passwordMaskDelay: 0
                inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                verticalAlignment: TextInput.AlignVCenter
                // Hidden: glyphs (and caret) are transparent; the 8 px dot row below is the visual.
                color: showPassword ? Theme.fg : "transparent"
                selectionColor: showPassword ? Theme.fg : "transparent"
                selectedTextColor: Theme.bg
                font.family: Theme.sans
                font.pixelSize: 17
                placeholderText: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:placeholder in text field", "Password")
                focus: true
                enabled: !authenticator.graceLocked

                // In Qt this is implicitly active based on focus rather than visibility;
                // here we use it to wake out of screensaver mode. Explicitly disable
                // cursor flashing when hidden to avoid unnecessary renders.
                cursorVisible: visible && activeFocus

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: !passwordBox.text && !passwordBox.preeditText
                    text: passwordBox.placeholderText
                    color: Theme.fg3
                    font.family: Theme.sans
                    font.pixelSize: 16
                    elide: Text.ElideRight
                }

                onAccepted: {
                    if (block.lockScreenUiVisible) {
                        block.startLogin();
                    }
                }

                Connections {
                    target: root
                    function onClearPassword() {
                        passwordBox.forceActiveFocus()
                        passwordBox.text = "";
                        passwordBox.text = Qt.binding(() => PasswordSync.password);
                    }
                    function onNotificationRepeated() {
                        block.playHighlightAnimation();
                    }
                }
            }
            // Password dots: 8 px, 8 px gaps, white; newest dots stay visible when long.
            Item {
                anchors.fill: passwordBox
                clip: true
                visible: !passwordBox.showPassword
                Row {
                    id: passwordDots
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.min(0, parent.width - width)
                    spacing: 8
                    Repeater {
                        model: passwordBox.text.length
                        Rectangle { width: 8; height: 8; radius: 4; color: Theme.fg }
                    }
                }
            }
            Binding {
                target: PasswordSync
                property: "password"
                value: passwordBox.text
            }

            Pressable {
                id: revealButton
                width: 36; height: 36
                anchors.right: loginButton.left; anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                visible: passwordBox.text.length > 0
                onClicked: { passwordBox.showPassword = !passwordBox.showPassword; passwordBox.forceActiveFocus() }
                Icon { anchors.centerIn: parent; name: passwordBox.showPassword ? "visibility_off" : "visibility"; size: 20; color: Theme.fg2 }
                Accessible.role: Accessible.Button
                Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button", "Show password")
            }

            Pressable {
                id: loginButton
                width: 40; height: 40
                anchors.right: parent.right; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                activeFocusOnTab: true
                onClicked: block.startLogin()
                Keys.onEnterPressed: block.startLogin()
                Keys.onReturnPressed: block.startLogin()
                Accessible.role: Accessible.Button
                Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button accessible only", "Unlock")

                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: passwordBox.text.length > 0 ? Theme.fg : "#2a2a2a"
                    Behavior on color { ColorAnimation { duration: Theme.normal } }
                }
                Icon {
                    anchors.centerIn: parent
                    name: LayoutMirroring.enabled ? "arrow_back" : "arrow_forward"
                    size: 22
                    weight: 400
                    color: passwordBox.text.length > 0 ? Theme.bg : Theme.fg
                }
            }
        }

        FailableLabel {
            Layout.topMargin: 12
            kind: ScreenLocker.Authenticator.Fingerprint
            label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your fingerprint on the reader)")
        }
        FailableLabel {
            Layout.topMargin: 12
            kind: ScreenLocker.Authenticator.Smartcard
            label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your smartcard)")
        }

        Row {
            id: actionRow
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            spacing: 28
        }
    }
}
