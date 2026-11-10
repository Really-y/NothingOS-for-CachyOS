pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root
    property bool dnd: false
    property int unread: 0
    property var times: ({})      // notification id -> arrival ms
    readonly property var list: server.trackedNotifications.values
    signal arrived(var notif)

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            root.times[n.id] = Date.now();
            root.unread++;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical) {
                root.arrived(n);
                if (!sound.running) sound.running = true;
            }
        }
    }

    Process {
        id: sound
        command: ["pw-play", Quickshell.env("HOME") + "/.local/share/sounds/nothing/stereo/message-new-instant.oga"]
    }

    function clearAll() {
        const all = server.trackedNotifications.values.slice();
        for (const n of all) n.dismiss();
        unread = 0;
    }
    function markRead() { unread = 0; }
}
