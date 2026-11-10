import QtQuick
import QtQuick.Layouts
import "nothing"

// Nothing OS quick settings body. Pure view: no Plasma imports, all state in
// properties, all actions out through signals (wired up in main.qml).
Item {
    id: root

    // ── state ────────────────────────────────────────────────────────────
    property date now: new Date()
    property bool hasBattery: false
    property int batteryPercent: 100
    property bool charging: false

    property bool wifiAvailable: true
    property bool wifiOn: false
    property string netKind: "none"          // wifi | ethernet | none
    property string netName: ""
    property string netIcon: "wifi"

    property bool btAvailable: false
    property bool btOn: false
    property int btConnected: 0

    property bool dnd: false
    property bool dndAvailable: true
    property bool nightLight: false
    property bool nightLightAvailable: true

    property bool volAvailable: true
    property real volume: 0
    property bool muted: false
    property string volIcon: "volume_up"
    property bool micAvailable: false
    property real micVolume: 0
    property bool micMuted: false

    property bool mediaActive: false
    property bool mediaPlaying: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaArt: ""
    property string mediaApp: ""
    property bool mediaCanPrev: true
    property bool mediaCanNext: true

    property bool powerOpen: false

    // geometry: `pad` = inner padding, `bleed` = how far the black card extends
    // beyond this item (to cover the Plasma dialog frame in the real popup)
    property real pad: 20
    property real bleed: 0
    property real cardRadius: 30

    // ── actions ──────────────────────────────────────────────────────────
    signal toggleWifi()
    signal toggleBluetooth()
    signal openNetworkSettings()
    signal openBluetoothSettings()
    signal toggleDnd()
    signal toggleNightLight()
    signal screenshot()
    signal openSettings()
    signal setVolume(real v)
    signal toggleMute()
    signal setMic(real v)
    signal toggleMicMute()
    signal mediaPrev()
    signal mediaPlayPause()
    signal mediaNext()
    signal power(string action)   // lock | logout | reboot | shutdown

    implicitWidth: 420

    // Explicit height: ColumnLayout's implicitHeight goes stale while the popup is hidden
    // (no polish), which would size the Plasma dialog wrongly.
    readonly property real headerHeight: Math.max(6 + clock.implicitHeight + 12 + dateRow.implicitHeight, 6 + 48)
    readonly property real contentHeight: headerHeight + header.Layout.bottomMargin
        + col.spacing + powerBox.Layout.preferredHeight
        + col.spacing + bigRow.implicitHeight
        + col.spacing + roundRow.Layout.topMargin + roundRow.implicitHeight
        + (volAvailable ? col.spacing + volBox.Layout.topMargin + volBox.implicitHeight : 0)
        + (micAvailable ? col.spacing + micBox.implicitHeight : 0)
        + (mediaActive ? col.spacing + mediaBox.Layout.topMargin + mediaBox.implicitHeight : 0)
    implicitHeight: Math.ceil(contentHeight + pad * 2)

    Rectangle {
        anchors.fill: parent
        anchors.margins: -root.bleed
        radius: root.cardRadius
        color: Theme.bg
    }

    ColumnLayout {
        id: col
        x: root.pad; y: root.pad
        width: root.width - root.pad * 2
        height: root.contentHeight
        spacing: 12

        // ── header: dot-matrix time, mono date, battery, power ───────────
        RowLayout {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            Layout.bottomMargin: 4
            spacing: 10
            ColumnLayout {
                spacing: 12
                Layout.topMargin: 6
                DotTime { id: clock; hours: Qt.formatTime(root.now, "HH"); minutes: Qt.formatTime(root.now, "mm"); size: 80; dotRatio: 0.65 }   // pitch 8px, white colon
                RowLayout {
                    id: dateRow
                    spacing: 10
                    Label { text: Qt.formatDate(root.now, "ddd, d MMM") }
                    Rectangle { visible: root.hasBattery; width: 3; height: 3; radius: 1.5; color: Theme.fg3 }
                    Label {
                        visible: root.hasBattery
                        text: root.batteryPercent + "%"
                        color: root.batteryPercent <= 15 && !root.charging ? Theme.red : Theme.fg2
                    }
                    Icon { visible: root.hasBattery && root.charging; name: "bolt"; size: 13; color: Theme.fg2; Layout.leftMargin: -8 }
                }
            }
            Item { Layout.fillWidth: true }
            Tile {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 6
                round: true; icon: root.powerOpen ? "close" : "power_settings_new"
                implicitWidth: 48; implicitHeight: 48
                active: root.powerOpen
                onClicked: root.powerOpen = !root.powerOpen
            }
        }

        // ── power actions (revealed by the power button) ─────────────────
        Item {
            id: powerBox
            Layout.fillWidth: true
            Layout.preferredHeight: root.powerOpen ? powerRow.implicitHeight : 0
            clip: true
            opacity: root.powerOpen ? 1 : 0
            Behavior on Layout.preferredHeight { NumberAnimation { duration: root.powerOpen ? Theme.normal : Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: root.powerOpen ? Theme.emphasized : Theme.accelerate } }
            Behavior on opacity { NumberAnimation { duration: root.powerOpen ? Theme.normal : Theme.fast } }

            RowLayout {
                id: powerRow
                width: parent.width
                spacing: 8
                Repeater {
                    model: [
                        { i: "lock", t: "Lock", a: "lock" },
                        { i: "logout", t: "Log out", a: "logout" },
                        { i: "restart_alt", t: "Restart", a: "reboot" },
                        { i: "power_settings_new", t: "Shut down", a: "shutdown" }
                    ]
                    Pressable {
                        id: pw
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 78
                        onClicked: root.power(modelData.a)
                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: pw.containsMouse ? Theme.card3 : Theme.card2
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                        }
                        Icon {
                            id: pwIcon
                            name: pw.modelData.i; size: 24
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 15
                            color: pw.modelData.a === "shutdown" && pw.containsMouse ? Theme.red : Theme.fg
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: pwIcon.bottom; anchors.topMargin: 8
                            text: pw.modelData.t      // uppercase mono, like the toggle captions
                            size: 11
                            color: Theme.fg2
                        }
                    }
                }
            }
        }

        // ── big tiles ────────────────────────────────────────────────────
        RowLayout {
            id: bigRow
            Layout.fillWidth: true
            spacing: 10
            WideTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: root.netKind === "ethernet" ? "lan" : root.netIcon
                active: root.netKind === "ethernet" || root.wifiOn
                title: root.netKind === "ethernet" ? "Ethernet" : "Internet"
                subtitle: root.netName !== "" ? root.netName
                        : !root.wifiAvailable ? "Unavailable"
                        : root.wifiOn ? "Not connected" : "Off"
                onClicked: root.wifiAvailable ? root.toggleWifi() : root.openNetworkSettings()
                onPressAndHold: root.openNetworkSettings()
            }
            WideTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: !root.btAvailable ? "bluetooth_disabled" : root.btConnected > 0 ? "bluetooth_connected" : "bluetooth"
                active: root.btOn
                opacity: root.btAvailable ? 1 : 0.55
                title: "Bluetooth"
                subtitle: !root.btAvailable ? "Unavailable"
                        : !root.btOn ? "Off"
                        : root.btConnected > 0 ? root.btConnected + " connected" : "On"
                onClicked: root.btAvailable ? root.toggleBluetooth() : root.openBluetoothSettings()
                onPressAndHold: root.openBluetoothSettings()
            }
        }

        // ── round tiles ──────────────────────────────────────────────────
        RowLayout {
            id: roundRow
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 0
            Repeater {
                model: [
                    { k: "dnd", i: "do_not_disturb_on", t: "Focus" },
                    { k: "night", i: "nightlight", t: "Night" },
                    { k: "shot", i: "screenshot_region", t: "Capture" },
                    { k: "settings", i: "settings", t: "Settings" }
                ]
                Item {
                    id: rt
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: rtTile.implicitHeight + 24
                    readonly property bool on: modelData.k === "dnd" ? root.dnd
                                             : modelData.k === "night" ? root.nightLight : false
                    readonly property bool avail: modelData.k === "dnd" ? root.dndAvailable
                                                : modelData.k === "night" ? root.nightLightAvailable : true
                    Tile {
                        id: rtTile
                        round: true
                        implicitWidth: 64; implicitHeight: 64
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: rt.modelData.i
                        active: rt.on
                        opacity: rt.avail ? 1 : 0.4
                        enabled: rt.avail
                        onClicked: {
                            switch (rt.modelData.k) {
                            case "dnd": root.toggleDnd(); break;
                            case "night": root.toggleNightLight(); break;
                            case "shot": root.screenshot(); break;
                            case "settings": root.openSettings(); break;
                            }
                        }
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        text: rt.modelData.t
                        size: 11
                        color: rt.on ? Theme.fg : (rt.avail ? Theme.fg2 : Theme.fg3)   // off ≠ unavailable
                    }
                }
            }
        }

        // ── sliders ──────────────────────────────────────────────────────
        NSlider {
            id: volBox
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root.volAvailable
            value: root.muted ? 0 : root.volume
            icon: root.volIcon
            onMoved: v => root.setVolume(v)
            onIconClicked: root.toggleMute()
        }
        NSlider {
            id: micBox
            Layout.fillWidth: true
            visible: root.micAvailable
            value: root.micMuted ? 0 : root.micVolume
            icon: root.micMuted ? "mic_off" : "mic"
            onMoved: v => root.setMic(v)
            onIconClicked: root.toggleMicMute()
        }

        // ── media ────────────────────────────────────────────────────────
        MediaCard {
            id: mediaBox
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root.mediaActive
            title: root.mediaTitle
            artist: root.mediaArtist
            art: root.mediaArt
            app: root.mediaApp
            playing: root.mediaPlaying
            accent: !(root.hasBattery && root.batteryPercent <= 15 && !root.charging)   // one red per surface
            canPrev: root.mediaCanPrev
            canNext: root.mediaCanNext
            onPrev: root.mediaPrev()
            onPlayPause: root.mediaPlayPause()
            onNext: root.mediaNext()
        }
    }
}
