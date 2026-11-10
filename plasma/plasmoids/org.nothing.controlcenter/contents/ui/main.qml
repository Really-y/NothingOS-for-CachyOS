import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.bluezqt as BluezQt
import org.kde.plasma.private.volume
import org.kde.plasma.private.battery
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.private.sessions as Sessions
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.workspace.dbus as DBus
import org.kde.kcmutils as KCMUtils
import org.kde.ksvg as KSvg
import "nothing"

// Nothing OS control center. All data comes from native KDE QML APIs:
// plasma-nm, BluezQt, plasma-pa, batterycontrol, MPRIS, notificationmanager,
// SessionManagement, KWin NightLight (DBus). Views live in StatusPill/ControlPanel.
PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    preferredRepresentation: compactRepresentation
    // never inline the full representation, always a popup
    switchWidth: 10000
    switchHeight: 10000
    toolTipMainText: i18n("Control Center")
    toolTipSubText: [netName, volumePercent + "%", hasBattery ? batteryPercent + "% battery" : ""].filter(s => s).join("  ·  ")

    // ── clock ────────────────────────────────────────────────────────────
    property date now: new Date()
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: root.expanded
        onTriggered: root.now = new Date()
    }

    // ── network (plasma-nm) ──────────────────────────────────────────────
    PlasmaNM.NetworkStatus { id: networkStatus }
    PlasmaNM.ConnectionIcon { id: connectionIcon; connectivity: networkStatus.connectivity }
    PlasmaNM.EnabledConnections { id: enabledConnections }
    PlasmaNM.WirelessStatus { id: wirelessStatus }
    PlasmaNM.Handler { id: nmHandler }

    readonly property string nmIcon: connectionIcon.connectionIcon
    readonly property string netKind: nmIcon.indexOf("wired") >= 0 ? "ethernet"
                                    : (nmIcon.indexOf("wireless") >= 0 && wirelessStatus.wifiSSID !== "") ? "wifi" : "none"
    readonly property bool wifiOn: enabledConnections.wirelessEnabled
    readonly property bool wifiAvailable: enabledConnections.wirelessHwEnabled && !PlasmaNM.Configuration.airplaneModeEnabled
    readonly property string netName: {
        if (netKind === "wifi") return wirelessStatus.wifiSSID;
        if (netKind === "ethernet") {
            // "Wired Ethernet: Connected to <name>" (first line) → "<name>"
            const first = (networkStatus.activeConnections || "").split("\n")[0];
            const afterColon = first.indexOf(": ") >= 0 ? first.slice(first.indexOf(": ") + 2) : first;
            const m = afterColon.match(/^\S+\s+\S+\s+(.+)$/);   // drop the localized "Connected to"
            return m ? m[1] : afterColon;
        }
        return "";
    }
    readonly property string netGlyph: {
        const i = nmIcon;
        if (i.indexOf("wired") >= 0) return "lan";
        if (i.indexOf("airplane") >= 0 || i.indexOf("flightmode") >= 0) return "airplanemode_active";
        if (i.indexOf("wireless") >= 0) {
            if (i.indexOf("disconnected") >= 0 || i.indexOf("offline") >= 0) return "wifi_off";
            if (/(100|80|excellent|good)/.test(i)) return "wifi";
            if (/(60|ok)/.test(i)) return "network_wifi_3_bar";
            if (/(40|weak)/.test(i)) return "network_wifi_2_bar";
            return "network_wifi_1_bar";
        }
        if (i.indexOf("mobile") >= 0) return "signal_cellular_alt";
        return wifiOn ? "wifi_find" : "wifi_off";
    }
    readonly property bool netOff: netKind === "none"

    // ── bluetooth (BluezQt) ──────────────────────────────────────────────
    readonly property bool btAvailable: BluezQt.Manager.adapters.length > 0 || BluezQt.Manager.bluetoothBlocked
    readonly property bool btOn: BluezQt.Manager.bluetoothOperational
    readonly property int btConnected: BluezQt.Manager.connectedDevices.length
    function setBluetooth(enable) {
        BluezQt.Manager.bluetoothBlocked = !enable;
        BluezQt.Manager.adapters.forEach(adapter => { adapter.powered = enable; });
    }

    // ── audio (plasma-pa) ────────────────────────────────────────────────
    readonly property var sink: PreferredDevice.sink
    readonly property var source: PreferredDevice.source
    readonly property real volume: sink ? Math.min(1, sink.volume / PulseAudio.NormalVolume) : 0
    readonly property bool muted: sink ? sink.muted : true
    readonly property int volumePercent: Math.round(volume * 100)
    readonly property string volGlyph: (!sink || muted || volume <= 0) ? "volume_off"
                                     : volume < 0.34 ? "volume_mute" : volume < 0.67 ? "volume_down" : "volume_up"
    function setSinkVolume(v) {
        if (!sink) return;
        sink.volume = Math.round(Math.max(0, Math.min(1, v)) * PulseAudio.NormalVolume);
        if (sink.muted && v > 0) sink.muted = false;
    }
    function setSourceVolume(v) {
        if (!source) return;
        source.volume = Math.round(Math.max(0, Math.min(1, v)) * PulseAudio.NormalVolume);
        if (source.muted && v > 0) source.muted = false;
    }

    // ── battery (powerdevil via batterycontrol) ──────────────────────────
    BatteryControlModel { id: battery }
    readonly property bool hasBattery: battery.hasInternalBatteries
    readonly property int batteryPercent: battery.percent
    readonly property bool charging: battery.state === BatteryControlModel.Charging

    // ── media (MPRIS) ────────────────────────────────────────────────────
    Mpris.Mpris2Model { id: mpris }
    readonly property var player: mpris.currentPlayer
    readonly property int playback: player ? player.playbackStatus : 0
    readonly property bool mediaActive: !!player && player.track !== ""
                                        && (playback === Mpris.PlaybackStatus.Playing || playback === Mpris.PlaybackStatus.Paused)

    // ── do not disturb (notificationmanager) ─────────────────────────────
    NotificationManager.Settings { id: notificationSettings; live: true }
    property bool dnd: false
    function updateDnd() {
        const until = notificationSettings.notificationsInhibitedUntil;
        const t = until ? until.getTime() : NaN;
        dnd = (!isNaN(t) && Date.now() < t) || notificationSettings.notificationsInhibitedByApplication;
    }
    Connections {
        target: notificationSettings
        function onNotificationsInhibitedUntilChanged() { root.updateDnd(); }
        function onNotificationsInhibitedByApplicationChanged() { root.updateDnd(); }
    }
    function toggleDnd() {
        // Same logic as the native notifications applet (Globals.toggleDoNotDisturbMode)
        if (dnd) {
            notificationSettings.notificationsInhibitedUntil = undefined;
            notificationSettings.revokeApplicationInhibitions();
        } else {
            const d = new Date();
            d.setFullYear(d.getFullYear() + 1);   // "until turned off"
            notificationSettings.notificationsInhibitedUntil = d;
        }
        notificationSettings.save();
        updateDnd();
    }

    // unread notifications → red dot (relative to when this popup was last opened)
    NotificationManager.Notifications {
        id: history
        showExpired: true
        showDismissed: true
        showJobs: false
        showNotifications: true
        urgencies: NotificationManager.Notifications.CriticalUrgency | NotificationManager.Notifications.NormalUrgency
        blacklistedDesktopEntries: notificationSettings.historyBlacklistedApplications
        blacklistedNotifyRcNames: notificationSettings.historyBlacklistedServices
    }
    readonly property bool unread: history.unreadNotificationsCount > 0

    // ── night light (KWin DBus) ──────────────────────────────────────────
    property bool nightAvailable: false
    property bool nightEnabled: false
    property bool nightInhibited: false
    readonly property bool nightLight: nightEnabled && !nightInhibited
    function refreshNightLight() {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin", path: "/org/kde/KWin/NightLight",
            iface: "org.freedesktop.DBus.Properties", member: "GetAll",
            arguments: [new DBus.string("org.kde.KWin.NightLight")]
        }, reply => {
            const p = reply.value || {};
            root.nightAvailable = !!p.available;
            root.nightEnabled = !!p.enabled;
            root.nightInhibited = !!p.inhibited;
        }, error => { root.nightAvailable = false; });
    }
    function toggleNightLight() {
        if (!nightEnabled) {
            // Night Light is switched off in settings: turn it on persistently.
            run("kwriteconfig6 --file kwinrc --group NightColor --key Active true && qdbus6 org.kde.KWin /KWin reconfigure");
        } else {
            // Same as the native shortcut / brightness applet: temporary inhibit toggle inside KWin.
            DBus.SessionBus.asyncCall({
                service: "org.kde.kglobalaccel", path: "/component/kwin",
                iface: "org.kde.kglobalaccel.Component", member: "invokeShortcut",
                arguments: [new DBus.string("Toggle Night Color")]
            }, () => {}, () => {});
        }
        nightRefresh.restart();
    }
    Timer { id: nightRefresh; interval: 400; onTriggered: root.refreshNightLight() }
    Timer { interval: 30000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.refreshNightLight() }

    // ── sessions / commands ──────────────────────────────────────────────
    Sessions.SessionManagement { id: session }
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }
    function run(cmd) { executable.connectSource(cmd); }

    function powerAction(a) {
        root.expanded = false;
        switch (a) {
        case "lock": session.lock(); break;
        case "logout": session.requestLogout(); break;
        case "reboot": session.requestReboot(); break;
        case "shutdown": session.requestShutdown(); break;
        }
    }

    onExpandedChanged: {
        if (root.expanded) {
            now = new Date();
            refreshNightLight();
            updateDnd();
            history.lastRead = undefined;   // opening the control center marks everything as seen
        } else if (fullRepresentationItem) {
            fullRepresentationItem.panel.powerOpen = false;
        }
    }
    Component.onCompleted: updateDnd()

    // ── compact: status pill ─────────────────────────────────────────────
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        Layout.minimumWidth: pill.implicitWidth + 6
        Layout.preferredWidth: pill.implicitWidth + 6
        Layout.maximumWidth: pill.implicitWidth + 6
        Layout.fillHeight: true
        property bool wasExpanded: false
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded
        onWheel: wheel => root.setSinkVolume(root.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))

        StatusPill {
            id: pill
            anchors.centerIn: parent
            height: parent.height
            netIcon: root.netGlyph
            netOff: root.netOff
            btOn: root.btOn
            btConnected: root.btConnected > 0
            volIcon: root.volGlyph
            hasBattery: root.hasBattery
            batteryPercent: root.batteryPercent
            charging: root.charging
            dnd: root.dnd
            unread: root.unread && !root.expanded
            open: root.expanded
            hovered: compact.containsMouse
        }
    }

    // ── full: quick settings popup ───────────────────────────────────────
    fullRepresentation: Item {
        id: full
        readonly property alias panel: panel
        readonly property real frameMargin: Math.max(0, frameMetrics.margins.top)
        Layout.preferredWidth: 420 - frameMargin * 2   // whole card incl. frame = 420px
        Layout.minimumWidth: Layout.preferredWidth
        Layout.maximumWidth: Layout.preferredWidth
        Layout.preferredHeight: panel.implicitHeight
        Layout.minimumHeight: panel.implicitHeight
        Layout.maximumHeight: panel.implicitHeight

        // Plasma dialog frame metrics: the black card bleeds over the themed frame
        KSvg.FrameSvgItem {
            id: frameMetrics
            imagePath: "dialogs/background"
            visible: false
        }

        ControlPanel {
            id: panel
            anchors.fill: parent
            bleed: full.frameMargin
            pad: Math.max(4, 20 - full.frameMargin)
            cardRadius: Math.max(8, full.frameMargin)
            now: root.now

            hasBattery: root.hasBattery
            batteryPercent: root.batteryPercent
            charging: root.charging

            wifiAvailable: root.wifiAvailable
            wifiOn: root.wifiOn
            netKind: root.netKind
            netName: root.netName
            netIcon: root.netKind === "wifi" ? root.netGlyph : (root.wifiOn ? "wifi" : "wifi_off")

            btAvailable: root.btAvailable
            btOn: root.btOn
            btConnected: root.btConnected

            dnd: root.dnd
            dndAvailable: true
            nightLight: root.nightLight
            nightLightAvailable: root.nightAvailable

            volAvailable: !!root.sink
            volume: root.volume
            muted: root.muted
            volIcon: root.volGlyph
            micAvailable: !!root.source
            micVolume: root.source ? Math.min(1, root.source.volume / PulseAudio.NormalVolume) : 0
            micMuted: root.source ? root.source.muted : true

            mediaActive: root.mediaActive
            mediaPlaying: root.playback === Mpris.PlaybackStatus.Playing
            mediaTitle: root.player ? root.player.track : ""
            mediaArtist: root.player ? root.player.artist : ""
            mediaArt: root.player ? root.player.artUrl : ""
            mediaApp: root.player ? root.player.identity : ""
            mediaCanPrev: root.player ? root.player.canGoPrevious : false
            mediaCanNext: root.player ? root.player.canGoNext : false

            onToggleWifi: nmHandler.enableWireless(!root.wifiOn)
            onToggleBluetooth: root.setBluetooth(!root.btOn)
            onOpenNetworkSettings: { root.expanded = false; KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement"); }
            onOpenBluetoothSettings: { root.expanded = false; KCMUtils.KCMLauncher.openSystemSettings("kcm_bluetooth"); }
            onToggleDnd: root.toggleDnd()
            onToggleNightLight: root.toggleNightLight()
            onScreenshot: { root.expanded = false; root.run("sh -c 'sleep 0.4; spectacle -r'"); }
            onOpenSettings: { root.expanded = false; root.run("systemsettings"); }
            onSetVolume: v => root.setSinkVolume(v)
            onToggleMute: if (root.sink) root.sink.muted = !root.sink.muted
            onSetMic: v => root.setSourceVolume(v)
            onToggleMicMute: if (root.source) root.source.muted = !root.source.muted
            onMediaPrev: if (root.player) root.player.Previous()
            onMediaPlayPause: if (root.player) root.player.PlayPause()
            onMediaNext: if (root.player) root.player.Next()
            onPower: a => root.powerAction(a)
        }

        Keys.onEscapePressed: root.expanded = false
        focus: true
    }
}
