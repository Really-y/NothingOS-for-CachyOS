import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.dock/contents/ui"

// Nothing dock (org.nothing.dock) with mock tasks: idle, and the same dock hovered.
// Slots: pinned only · active · 3 windows · minimized · attention · 2 windows · launching · no theme icon
Rectangle {
    color: "#000000"
    readonly property string dir: Qt.resolvedUrl("../icons/Nothing/scalable/apps/")

    component Tasks: ListModel {
        ListElement { AppName: "Files";    decoration: "org.kde.dolphin";      IsWindow: false; IsGroupParent: false; ChildCount: 0; IsActive: false; IsMinimized: false; IsDemandingAttention: false; IsStartup: false; IsLauncher: true }
        ListElement { AppName: "Chrome";   decoration: "com.google.Chrome";    IsWindow: true;  IsGroupParent: false; ChildCount: 0; IsActive: true;  IsMinimized: false; IsDemandingAttention: false; IsStartup: false; IsLauncher: false }
        ListElement { AppName: "Alacritty"; decoration: "Alacritty";           IsWindow: true;  IsGroupParent: true;  ChildCount: 3; IsActive: false; IsMinimized: false; IsDemandingAttention: false; IsStartup: false; IsLauncher: false }
        ListElement { AppName: "Vesktop";  decoration: "discord";              IsWindow: true;  IsGroupParent: false; ChildCount: 0; IsActive: false; IsMinimized: true;  IsDemandingAttention: false; IsStartup: false; IsLauncher: false }
        ListElement { AppName: "Telegram"; decoration: "org.telegram.desktop"; IsWindow: true;  IsGroupParent: false; ChildCount: 0; IsActive: false; IsMinimized: false; IsDemandingAttention: true;  IsStartup: false; IsLauncher: false }
        ListElement { AppName: "Firefox";  decoration: "firefox";              IsWindow: true;  IsGroupParent: true;  ChildCount: 2; IsActive: false; IsMinimized: false; IsDemandingAttention: false; IsStartup: false; IsLauncher: false }
        ListElement { AppName: "Steam";    decoration: "steam";                IsWindow: false; IsGroupParent: false; ChildCount: 0; IsActive: false; IsMinimized: false; IsDemandingAttention: false; IsStartup: true;  IsLauncher: false }
        ListElement { AppName: "Wine App"; decoration: "";                     IsWindow: true;  IsGroupParent: false; ChildCount: 0; IsActive: false; IsMinimized: false; IsDemandingAttention: false; IsStartup: false; IsLauncher: false }
    }
    readonly property var info: function (m) {
        return m.decoration ? { themed: true, icon: dir + m.decoration + ".svg" } : { themed: false };
    }

    Column {
        anchors.centerIn: parent
        spacing: 18
        Row {
            spacing: 40
            Column {
                spacing: 50
                Label { text: "Idle" }
                DockBar { model: Tasks {} iconInfo: info }
            }
            Column {
                spacing: 50
                Label { text: "Hover · Firefox" }
                DockBar { model: Tasks {} iconInfo: info; forcedHover: 5; inlineTooltip: true }
            }
        }
        Label {
            text: "Files pinned · Chrome active · Alacritty 3 windows · Vesktop minimized · Telegram attention · Firefox 2 · Steam launching · dot-letter fallback"
            size: 10
            color: Theme.fg3
        }
    }
}
