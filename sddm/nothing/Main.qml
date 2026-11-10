/*
    "nothing" — SDDM 0.21 (Qt 6) login theme in the Nothing OS style.

    Pure black, huge Doto dot-matrix clock, round user avatars, password pill,
    session picker, round power tiles, one red dot for errors / caps lock.
    Self-contained: fonts are bundled in fonts/ and loaded with FontLoader
    (the greeter runs as the sddm user and cannot see per-user fonts).

    SDDM context objects used: sddm, userModel, sessionModel, keyboard, config.

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import "components"

Rectangle {
    id: root

    // ── design tokens ───────────────────────────────────────────────────────
    readonly property color bg: "#000000"
    readonly property color card: "#111111"
    readonly property color card2: "#1c1c1c"
    readonly property color card3: "#262626"
    readonly property color line: "#2a2a2a"
    readonly property color fg: "#ffffff"
    readonly property color fg2: "#8e8e8e"
    readonly property color fg3: "#5e5e5e"
    readonly property color red: "#d71921"
    readonly property var emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var accelerate: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property string fDot: dotoFont.status === FontLoader.Ready ? dotoFont.font.family : "Doto"
    readonly property string fSans: sansFont.status === FontLoader.Ready ? sansFont.font.family : "Space Grotesk"
    readonly property string fMono: monoFont.status === FontLoader.Ready ? monoFont.font.family : "Space Mono"
    readonly property string fIcon: iconFont.status === FontLoader.Ready ? iconFont.font.family : "Material Symbols Rounded"
    readonly property bool showClock: cfg("showClock", "true") !== "false"
    readonly property bool showHostName: cfg("showHostName", "true") !== "false"
    readonly property bool use24h: cfg("clockFormat", "auto") === "24" ? true : cfg("clockFormat", "auto") === "12" ? false : !/[aA]/.test(Qt.locale().timeFormat(Locale.ShortFormat))
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string message: ""
    property bool busy: false
    property date now: new Date()
    readonly property bool manualUser: userModel.count === 0
    readonly property string userName: manualUser ? userField.text : (userList.currentItem ? userList.currentItem.userName : "")
    readonly property bool needsPassword: manualUser || !userList.currentItem || userList.currentItem.needsPassword

    // ── state ───────────────────────────────────────────────────────────────
    function cfg(key, fallback) {
        const v = config[key];
        return v === undefined || v === null || v === "" ? fallback : String(v);
    }

    function doLogin() {
        if (busy || userName === "")
            return ;

        busy = true;
        message = "";
        sddm.login(userName, passwordField.text, sessionIndex);
    }

    width: 1280
    height: 720
    color: bg
    Keys.onEscapePressed: sessionMenu.open = false

    FontLoader {
        id: dotoFont

        source: "fonts/Doto.ttf"
    }

    FontLoader {
        id: sansFont

        source: "fonts/SpaceGrotesk.ttf"
    }

    FontLoader {
        id: monoFont

        source: "fonts/SpaceMono-Regular.ttf"
    }

    FontLoader {
        id: iconFont

        source: "fonts/MaterialSymbolsRounded.ttf"
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Connections {
        function onLoginFailed() {
            root.busy = false;
            root.message = "Login failed";
            passwordField.text = "";
            passwordField.forceActiveFocus();
            shake.restart();
        }

        function onLoginSucceeded() {
            fadeOut.start();
        }

        function onInformationMessage(message) {
            root.message = message;
        }

        target: sddm
    }

    // ── content ─────────────────────────────────────────────────────────────
    Item {
        id: content

        anchors.fill: parent
        opacity: 0
        Component.onCompleted: fadeIn.start()

        NumberAnimation {
            id: fadeIn

            target: content
            property: "opacity"
            to: 1
            duration: 420
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.emphasized
        }

        NumberAnimation {
            id: fadeOut

            target: content
            property: "opacity"
            to: 0
            duration: 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.accelerate
        }

        // Host name, top-left.
        Row {
            visible: root.showHostName && sddm.hostName !== ""
            x: 28
            y: 26
            spacing: 10

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: root.fg
                anchors.verticalCenter: parent.verticalCenter
            }

            Mono {
                text: sddm.hostName
                color: root.fg2
            }

        }

        // Clock + prompt, centred together.
        Column {
            id: centre

            // Fixed top, same formula as the lock screen's activeTop. The user row is left out
            // on purpose so the clock never moves with the number of users.
            readonly property real fixedPart: (clock.visible ? clock.height + 48 : 0) + 16 + 16 + 56 + 24 + powerRow.height
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(24, Math.round((root.height - fixedPart) / 2))
            spacing: 48

            // Clock + date.
            Column {
                id: clock

                visible: root.showClock
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 32

                // Same dot renderer as the desktop/lock screen clocks (real two-dot colon).
                DotTime {
                    id: clockText

                    readonly property int h: root.now.getHours()

                    anchors.horizontalCenter: parent.horizontalCenter
                    hours: root.use24h ? (h < 10 ? "0" : "") + h : String((h + 11) % 12 + 1)
                    minutes: Qt.formatTime(root.now, "mm")
                    // multiple of 10 → integer dot pitch, so the canvas never clips the last row
                    size: Math.max(60, Math.floor(Math.min(root.height * 0.19, root.width * 0.15, 230) / 10) * 10)
                    color: root.fg
                    width: implicitWidth
                    height: implicitHeight
                }

                Row {
                    readonly property int sz: 13

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Mono {
                        text: Qt.formatDate(root.now, "dddd")
                        color: root.fg
                        size: parent.sz
                        font.letterSpacing: 2.4
                    }

                    Mono {
                        text: Qt.formatDate(root.now, "d MMMM")
                        size: parent.sz
                        font.letterSpacing: 2.4
                    }

                    Mono {
                        visible: !root.use24h
                        text: Qt.formatTime(root.now, "AP")
                        size: parent.sz
                        font.letterSpacing: 2.4
                    }

                }

            }

            // Prompt: users, status, password pill.
            Column {
                id: prompt

                width: Math.min(400, root.width - 48)
                anchors.horizontalCenter: parent.horizontalCenter
                // users →8→ status 16 →8→ pill (32 between name labels and pill)
                spacing: userList.visible ? 8 : 16

                ListView {
                    id: userList

                    visible: userModel.count > 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(contentWidth, root.width - 48)
                    height: 56 + 10 + 16
                    orientation: ListView.Horizontal
                    spacing: 18
                    interactive: contentWidth > width
                    model: userModel
                    currentIndex: root.userIndex
                    onCurrentIndexChanged: root.userIndex = currentIndex
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: false

                    delegate: Item {
                        id: userDelegate

                        required property int index
                        required property string name
                        required property string realName
                        required property string icon
                        required property bool needsPassword
                        readonly property string userName: name
                        readonly property bool isCurrent: ListView.isCurrentItem

                        width: 72
                        height: userList.height

                        Avatar {
                            id: face

                            // 56 px for everyone; selected = white disk + black initial
                            width: 56
                            height: 56
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            source: userDelegate.icon
                            initial: (userDelegate.realName || userDelegate.name).charAt(0).toUpperCase()
                            fillColor: userDelegate.isCurrent ? root.fg : "#1a1a1a"
                            letterColor: userDelegate.isCurrent ? root.bg : root.fg2
                            Behavior on fillColor { ColorAnimation { duration: 260 } }

                        }
                        Mono {
                            anchors.top: parent.top
                            anchors.topMargin: 66
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width + 16
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: userDelegate.realName || userDelegate.name
                            size: 11
                            font.letterSpacing: 1.5
                            color: userDelegate.isCurrent ? root.fg : root.fg2
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                userList.currentIndex = userDelegate.index;
                                passwordField.forceActiveFocus();
                            }
                        }

                    }

                }

                // Username pill — only when SDDM lists no users (hidden users / large directories).
                Rectangle {
                    visible: root.manualUser
                    width: parent.width
                    height: 56
                    radius: height / 2
                    color: "#1a1a1a"

                    Icon {
                        id: personIcon

                        x: 22
                        anchors.verticalCenter: parent.verticalCenter
                        name: "person"
                        color: root.fg2
                    }

                    TextInput {
                        id: userField

                        anchors.left: personIcon.right
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.fg
                        font.family: root.fSans
                        font.pixelSize: 17
                        selectionColor: root.fg
                        selectedTextColor: root.bg
                        clip: true
                        focus: root.manualUser
                        KeyNavigation.tab: passwordField
                        onAccepted: passwordField.forceActiveFocus()

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !parent.text && !parent.preeditText
                            text: "Username"
                            color: root.fg3
                            font.family: root.fSans
                            font.pixelSize: 16
                        }

                    }

                }

                // Status line: one red dot + mono message.
                Item {
                    readonly property string text: {
                        const parts = [];
                        if (keyboard.capsLock)
                            parts.push("Caps Lock is on");

                        if (root.message)
                            parts.push(root.message);

                        return parts.join("  ·  ");
                    }

                    width: parent.width
                    height: 16
                    opacity: text ? 1 : 0

                    Row {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: root.red
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Mono {
                            text: parent.parent.text
                            color: root.fg
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 260
                        }

                    }

                }

                // Avatar · password · go.
                Rectangle {
                    id: pill

                    width: parent.width
                    height: 56
                    radius: height / 2
                    color: "#1a1a1a"

                    Avatar {
                        id: pillAvatar

                        visible: !userList.visible && !root.manualUser
                        width: 40
                        height: 40
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        ringColor: pill.color
                        fillColor: "#2a2a2a"
                        source: userList.currentItem ? userList.currentItem.icon : ""
                        initial: root.userName.charAt(0).toUpperCase()
                    }

                    Icon {
                        id: lockIcon

                        visible: !pillAvatar.visible
                        x: 22
                        anchors.verticalCenter: parent.verticalCenter
                        name: "lock"
                        color: root.fg2
                    }

                    TextInput {
                        id: passwordField

                        anchors.left: pillAvatar.visible ? pillAvatar.right : lockIcon.right
                        anchors.leftMargin: 14
                        anchors.right: goButton.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: root.needsPassword && !root.busy
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        passwordMaskDelay: 0
                        // glyphs + caret transparent; the 8 px dot row below is the visual
                        color: "transparent"
                        selectionColor: "transparent"
                        selectedTextColor: root.bg
                        font.family: root.fSans
                        font.pixelSize: 17
                        clip: true
                        focus: !root.manualUser
                        onAccepted: root.doLogin()
                        Keys.onEscapePressed: {
                            text = "";
                            root.message = "";
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !parent.text && !parent.preeditText
                            elide: Text.ElideRight
                            text: !root.needsPassword ? "No password needed" : "Enter password"
                            color: root.fg3
                            font.family: root.fSans
                            font.pixelSize: 16
                            font.letterSpacing: 0
                        }

                    }

                    // Password dots: 8 px, 8 px gaps, white; newest stay visible when long.
                    Item {
                        anchors.fill: passwordField
                        clip: true

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.min(0, parent.width - width)
                            spacing: 8

                            Repeater {
                                model: passwordField.text.length

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: root.fg
                                }
                            }
                        }
                    }

                    Press {
                        id: goButton

                        readonly property bool ready: passwordField.text.length > 0 || !root.needsPassword

                        width: 40
                        height: 40
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: root.doLogin()
                        Accessible.role: Accessible.Button
                        Accessible.name: "Log in"

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: goButton.ready ? root.fg : "#2a2a2a"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 260
                                }

                            }

                        }

                        Icon {
                            anchors.centerIn: parent
                            name: root.busy ? "more_horiz" : "arrow_forward"
                            color: goButton.ready ? root.bg : root.fg
                        }

                    }

                }

                transform: Translate {
                    id: shakeX
                }

            }

        }

        // Power tiles: 24 px under the password pill, like the lock screen's action row.
        Row {
            id: powerRow

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: centre.bottom
            anchors.topMargin: 24
            spacing: 28

            PowerTile {
                visible: sddm.canSuspend
                iconName: "bedtime"
                label: "Sleep"
                onClicked: sddm.suspend()
            }

            PowerTile {
                visible: sddm.canReboot
                iconName: "restart_alt"
                label: "Restart"
                onClicked: sddm.reboot()
            }

            PowerTile {
                visible: sddm.canPowerOff
                iconName: "power_settings_new"
                label: "Shut down"
                onClicked: sddm.powerOff()
            }

        }

        // Keyboard layout, bottom-left.
        Press {
            id: layoutButton

            visible: keyboard.layouts && keyboard.layouts.length > 1
            x: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            width: layoutRow.implicitWidth + 28
            height: 40
            onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#1a1a1a"
            }

            Row {
                id: layoutRow

                anchors.centerIn: parent
                spacing: 8

                Icon {
                    name: "language"
                    size: 18
                    anchors.verticalCenter: parent.verticalCenter
                }

                Mono {
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.fg
                    text: layoutButton.visible && keyboard.layouts[keyboard.currentLayout] ? keyboard.layouts[keyboard.currentLayout].shortName : ""
                }

            }

        }

        // Session picker, bottom-right.
        Press {
            id: sessionButton

            visible: sessionModel.count > 0
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            width: sessionRow.implicitWidth + 32
            height: 40
            onClicked: sessionMenu.open = !sessionMenu.open
            Accessible.role: Accessible.ComboBox
            Accessible.name: "Session: " + sessionName.text

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: sessionMenu.open ? root.fg : "#1a1a1a"
            }

            Row {
                id: sessionRow

                anchors.centerIn: parent
                spacing: 8

                Icon {
                    name: "desktop_windows"
                    size: 18
                    color: sessionMenu.open ? root.bg : root.fg
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: sessionName

                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.fSans
                    font.pixelSize: 14
                    color: sessionMenu.open ? root.bg : root.fg
                    text: sessionRepeater.count > root.sessionIndex && sessionRepeater.itemAt(root.sessionIndex) ? sessionRepeater.itemAt(root.sessionIndex).sessionName : ""
                }

                Icon {
                    name: sessionMenu.open ? "expand_more" : "expand_less"
                    size: 18
                    color: sessionMenu.open ? root.bg : root.fg2
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

        }

        Rectangle {
            id: sessionMenu

            property bool open: false

            anchors.right: sessionButton.right
            anchors.bottom: sessionButton.top
            anchors.bottomMargin: 10
            width: Math.max(240, sessionColumn.implicitWidth + 16)
            height: sessionColumn.implicitHeight + 16
            radius: 24
            color: "#1a1a1a"
            visible: opacity > 0
            opacity: open ? 1 : 0

            Column {
                id: sessionColumn

                anchors.centerIn: parent
                width: parent.width - 16

                Repeater {
                    id: sessionRepeater

                    model: sessionModel

                    delegate: Press {
                        id: sessionItem

                        required property int index
                        required property string name
                        readonly property string sessionName: name
                        readonly property bool current: index === root.sessionIndex

                        width: sessionColumn.width
                        height: 44
                        scale: 1
                        onClicked: {
                            root.sessionIndex = index;
                            sessionMenu.open = false;
                            passwordField.forceActiveFocus();
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            // hover only; the selected session is marked by the white dot alone
                            color: sessionItem.containsMouse ? "#2a2a2a" : "transparent"
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.right: dotMark.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: sessionItem.name
                            elide: Text.ElideRight
                            color: root.fg
                            font.family: root.fSans
                            font.pixelSize: 14
                        }

                        Rectangle {
                            id: dotMark

                            visible: sessionItem.current
                            width: 6
                            height: 6
                            radius: 3
                            color: root.fg
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                }

            }

            transform: Translate {
                y: sessionMenu.open ? 0 : 8

                Behavior on y {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.emphasized
                    }

                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: sessionMenu.open ? 260 : 140
                }

            }

        }

    }

    SequentialAnimation {
        id: shake

        NumberAnimation {
            target: shakeX
            property: "x"
            to: -14
            duration: 50
        }

        NumberAnimation {
            target: shakeX
            property: "x"
            to: 12
            duration: 70
        }

        NumberAnimation {
            target: shakeX
            property: "x"
            to: -7
            duration: 60
        }

        NumberAnimation {
            target: shakeX
            property: "x"
            to: 0
            duration: 140
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.emphasized
        }

    }

    // Clicking empty space closes the session menu.
    TapHandler {
        enabled: sessionMenu.open
        onTapped: sessionMenu.open = false
    }

    // ── reusable bits ───────────────────────────────────────────────────────
    component Icon: Text {
        property string name
        property int size: 22
        property real fill: 0

        text: name
        color: root.fg
        font.family: root.fIcon
        font.pixelSize: size
        font.variableAxes: ({
            "FILL": fill,
            "wght": 300,
            "opsz": Math.max(20, Math.min(48, size)),
            "GRAD": 0
        })
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    component Mono: Text {
        property int size: 11

        color: root.fg2
        font.family: root.fMono
        font.pixelSize: size
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.6
    }

    component Press: MouseArea {
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        scale: pressed ? 0.94 : 1

        Behavior on scale {
            SpringAnimation {
                spring: 6
                damping: 0.42
                epsilon: 0.002
            }

        }

    }
    // Round power tile with a mono caption.

    component PowerTile: Item {
        id: tile

        property string iconName
        property string label

        signal clicked()

        width: 72
        height: 56 + 10 + 14
        activeFocusOnTab: true
        Keys.onReturnPressed: clicked()
        Keys.onEnterPressed: clicked()
        Keys.onSpacePressed: clicked()
        Accessible.role: Accessible.Button
        Accessible.name: label

        Press {
            id: disc

            width: 56
            height: 56
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: tile.clicked()

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: disc.containsMouse || tile.activeFocus ? "#2a2a2a" : "#1a1a1a"
            }

            Icon {
                anchors.centerIn: parent
                name: tile.iconName
                size: 24
            }

        }

        Mono {
            anchors.top: disc.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.label
            size: 11
            color: root.fg2
            font.letterSpacing: 1.5
        }

    }
    // Avatar: picture, or the user's initial; circular crop without layer effects.

    component Avatar: Item {
        id: av

        property string source
        property string initial
        property color ringColor: root.bg
        property color fillColor: "#1a1a1a"
        property color letterColor: root.fg

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: av.fillColor
        }

        Text {
            anchors.centerIn: parent
            visible: img.status !== Image.Ready
            text: av.initial
            color: av.letterColor
            font.family: root.fSans
            font.pixelSize: Math.round(av.height * 0.42)
            font.weight: Font.Medium
        }

        Image {
            id: img

            anchors.fill: parent
            source: av.source
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: av.width * 2
            sourceSize.height: av.height * 2
            asynchronous: true
            visible: status === Image.Ready
        }

        Rectangle {
            visible: img.visible
            anchors.fill: parent
            anchors.margins: -10
            radius: width / 2
            color: "transparent"
            border.width: 10
            border.color: av.ringColor
        }

    }

}
