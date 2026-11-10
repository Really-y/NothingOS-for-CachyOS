import QtQuick
import org.kde.plasma.workspace.dbus as DBus

// Client for the nothingd session service. Calls `member` (returns a JSON
// string), polls every `interval`, re-polls on Changed(topic), and while the
// daemon is absent retries every `retryInterval` with `result` = null.
Item {
    id: root
    property string member: ""
    property int interval: 2000
    property int retryInterval: 5000
    property string topic: ""
    property var result: null
    readonly property bool available: result !== null
    property bool _busy: false

    readonly property var _msg: ({
        service: "org.nothing.Daemon", path: "/org/nothing/Daemon",
        iface: "org.nothing.Daemon1", member: root.member, arguments: []
    })

    function refresh() {
        if (_busy || member === "") return;
        _busy = true;
        DBus.SessionBus.asyncCall(_msg, reply => {
            _busy = false;
            try {
                // reply.value is a DBus STRING wrapper: {value: "<json>"}
                const v = reply.value;
                const s = (v !== null && typeof v === "object" && v.value !== undefined) ? v.value : String(v);
                const d = JSON.parse(s);
                root.result = (d && d.ok === false) ? null : d;
            } catch (e) {
                root.result = null;
            }
        }, err => {
            _busy = false;
            root.result = null;
        });
    }

    Timer {
        interval: root.available ? root.interval : root.retryInterval
        running: root.member !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    DBus.SignalWatcher {
        enabled: root.topic !== ""
        busType: DBus.BusType.Session
        service: "org.nothing.Daemon"
        path: "/org/nothing/Daemon"
        iface: "org.nothing.Daemon1"
        // SignalWatcher dispatches signal `X(args)` to a function named `dbusX`.
        function dbusChanged(topic) { if (topic === root.topic) root.refresh(); }
    }
}
