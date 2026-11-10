//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io

// NothingOS shell for KDE Plasma: bar, quick settings, notifications,
// launcher, OSD and desktop widgets.
ShellRoot {
    Variants { model: Quickshell.screens; Bar {} }
    Variants { model: Quickshell.screens; QuickSettings {} }
    Variants { model: Quickshell.screens; Launcher {} }
    NotifPopups {}
    Osd {}
    DesktopWidgets {}

    // `qs -p <path> ipc call launcher toggle` etc.
    IpcHandler {
        target: "launcher"
        function toggle(): void { State.toggleLauncher(null); }
    }
    IpcHandler {
        target: "quicksettings"
        function toggle(): void { State.toggleQs(State.lastScreen); }
    }
    IpcHandler {
        target: "dnd"
        function toggle(): void { Notifs.dnd = !Notifs.dnd; }
    }
}
