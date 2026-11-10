import QtQuick

// Mock SDDM greeter environment (sddm, userModel, sessionModel, keyboard, config)
// for offscreen previews of sddm/nothing/Main.qml. No real users or sessions are read.
Rectangle {
    id: mock
    color: "black"
    property int users: 3
    property string message: ""
    property bool capsLock: false
    property bool menuOpen: false
    property string typed: ""

    QtObject {
        id: sddm
        signal loginFailed()
        signal loginSucceeded()
        signal informationMessage(string message)
        property string hostName: "nothing-pc"
        property bool canPowerOff: true
        property bool canReboot: true
        property bool canSuspend: true
        property bool canHibernate: false
        function login(u, p, s) {}
        function powerOff() {}
        function reboot() {}
        function suspend() {}
    }
    ListModel {
        id: userModel
        property int lastIndex: 0
        property string lastUser: "alex"
        property bool containsAllUsers: true
        Component.onCompleted: {
            const all = [
                { name: "alex", realName: "Alex", icon: "", needsPassword: true },
                { name: "sam", realName: "Sam", icon: "", needsPassword: true },
                { name: "guest", realName: "Guest", icon: "", needsPassword: false },
            ];
            for (let i = 0; i < mock.users; ++i) append(all[i]);
        }
    }
    ListModel {
        id: sessionModel
        property int lastIndex: 0
        ListElement { name: "Plasma (Wayland)"; file: "plasma.desktop" }
        ListElement { name: "Plasma (X11)"; file: "plasmax11.desktop" }
        ListElement { name: "Hyprland"; file: "hyprland.desktop" }
    }
    QtObject {
        id: keyboard
        property bool capsLock: mock.capsLock
        property bool numLock: false
        property var layouts: [{ shortName: "us", longName: "English (US)" }, { shortName: "az", longName: "Azerbaijani" }]
        property int currentLayout: 0
    }
    QtObject {
        id: config
        property string showClock: "true"
        property string clockFormat: "24"
        property string showHostName: "true"
    }

    Loader {
        id: loader
        anchors.fill: parent
        source: "../sddm/nothing/Main.qml"
    }
    Timer {
        interval: 500; running: true
        onTriggered: {
            if (mock.message) sddm.informationMessage(mock.message);
            const q = [loader.item];
            while (q.length) {
                const it = q.shift();
                if (!it) continue;
                if (mock.menuOpen && it.open !== undefined && it.radius === 24) it.open = true;
                if (mock.typed && it.echoMode === TextInput.Password) it.text = mock.typed;
                if (it.children) for (let i = 0; i < it.children.length; ++i) q.push(it.children[i]);
            }
        }
    }
}
