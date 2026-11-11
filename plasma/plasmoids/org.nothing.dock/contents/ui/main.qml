import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.taskmanager as TaskManager
import "nothing"

// Nothing OS dock: a task manager on the native TasksModel (pinned launchers + running
// windows, grouped by app). The look lives in DockBar.qml; this file wires it to Plasma.
PlasmoidItem {
    id: root

    readonly property var atm: TaskManager.AbstractTasksModel
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.constraintHints: Plasmoid.CanFillArea        // panel gives us its full thickness, no margins
    preferredRepresentation: fullRepresentation
    toolTipMainText: ""
    toolTipSubText: ""

    Layout.fillWidth: false
    Layout.fillHeight: !vertical
    Layout.minimumWidth: bar.implicitWidth
    Layout.preferredWidth: bar.implicitWidth
    Layout.maximumWidth: bar.implicitWidth
    Layout.minimumHeight: vertical ? bar.implicitHeight : 0
    Layout.preferredHeight: bar.implicitHeight

    Binding {
        target: Plasmoid
        property: "status"
        value: tasksModel.anyTaskDemandsAttention ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.PassiveStatus
        restoreMode: Binding.RestoreBinding
    }

    // ── model ──────────────────────────────────────────────────────────
    TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }

    TaskManager.TasksModel {
        id: tasksModel
        screenGeometry: Plasmoid.containment.screenGeometry
        activity: activityInfo.currentActivity
        virtualDesktop: virtualDesktopInfo.currentDesktop
        filterByCurrentVirtualDesktop: Plasmoid.configuration.showOnlyCurrentDesktop
        filterByActivity: Plasmoid.configuration.showOnlyCurrentActivity
        filterByScreen: Plasmoid.configuration.showOnlyCurrentScreen
        // icon-only task manager semantics (like org.kde.plasma.icontasks):
        // a pinned app turns into its running task in place
        sortMode: TaskManager.TasksModel.SortManual
        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        separateLaunchers: true
        hideActivatedLaunchers: true
        launchInPlace: true

        onLauncherListChanged: Plasmoid.configuration.launchers = launcherList
        Component.onCompleted: {
            launcherList = Plasmoid.configuration.launchers;
            bar.model = tasksModel;      // hook the view up only after the launcher churn
        }
    }
    Connections {
        target: Plasmoid.configuration
        function onLaunchersChanged() {
            if (String(tasksModel.launcherList) !== String(Plasmoid.configuration.launchers))
                tasksModel.launcherList = Plasmoid.configuration.launchers;
        }
    }

    function idx(row, child) { return child === undefined ? tasksModel.makeModelIndex(row) : tasksModel.makeModelIndex(row, child); }
    function get(row, role) { return tasksModel.data(idx(row), role); }

    // ── .desktop lookups: Nothing icon available? which actions? ─────────
    // Icons: the Nothing theme ships a disc icon per app (named after the .desktop Icon=).
    // Anything without one gets a drawn disc with its nothing-glyph-<id> or a dot letter.
    property var themeIcons: ({})
    property bool themeLoaded: false
    property var apps: ({})            // desktop key -> { icon, actions:[{name, exec, icon}] }
    property var pending: ({})
    readonly property string themeDir: "$HOME/.local/share/icons/Nothing/scalable/apps"

    P5Support.DataSource {
        id: sh
        engine: "executable"
        property var handlers: ({})
        onNewData: (source, data) => {
            const cb = handlers[source];
            delete handlers[source];
            disconnectSource(source);
            if (cb) cb(String(data.stdout || ""));
        }
        function run(cmd, cb) { handlers[cmd] = cb; connectSource(cmd); }
    }
    Component.onCompleted: sh.run("ls \"" + themeDir + "\" 2>/dev/null", out => {
        const set = {};
        for (const f of out.split("\n")) if (f.endsWith(".svg")) set[f.slice(0, -4)] = true;
        themeIcons = set;
        themeLoaded = true;
    })

    function shQuote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'"; }

    // "applications:org.kde.dolphin.desktop" / "file:///…/x.desktop" (falls back to AppId)
    function desktopKey(m) {
        let u = String(m.LauncherUrlWithoutIcon || "");
        if (!u && m.AppId) u = "applications:" + String(m.AppId).replace(/\.desktop$/, "") + ".desktop";
        return u;
    }
    function lookup(key) {
        if (!key || apps[key] !== undefined || pending[key]) return;
        let cmd = "";
        if (key.startsWith("applications:")) {
            const id = key.slice(13);
            if (!/^[A-Za-z0-9._+-]+\.desktop$/.test(id)) return;
            cmd = "for d in \"${XDG_DATA_HOME:-$HOME/.local/share}\" $(echo \"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}\" | tr : ' '); do "
                + "[ -f \"$d/applications/" + id + "\" ] && exec cat \"$d/applications/" + id + "\"; done";
        } else if (key.startsWith("file://") && key.endsWith(".desktop")) {
            cmd = "cat " + shQuote(decodeURIComponent(key.slice(7)));
        } else return;
        pending[key] = true;
        sh.run(cmd, out => {
            delete pending[key];
            const a = Object.assign({}, apps);
            a[key] = parseDesktop(out);
            apps = a;
        });
    }
    function parseDesktop(text) {
        const loc = Qt.locale().name, lang = loc.split("_")[0];
        const res = { icon: "", actions: [] }, acts = {};
        let order = [], section = "";
        for (let line of text.split("\n")) {
            line = line.trim();
            if (!line || line[0] === "#") continue;
            const s = line.match(/^\[(.+)\]$/);
            if (s) { section = s[1]; continue; }
            const eq = line.indexOf("=");
            if (eq < 0) continue;
            const k = line.slice(0, eq).trim(), v = line.slice(eq + 1).trim();
            if (section === "Desktop Entry") {
                if (k === "Icon") res.icon = v;
                else if (k === "Actions") order = v.split(";").filter(x => x);
            } else if (section.startsWith("Desktop Action ")) {
                const id = section.slice(15);
                const a = acts[id] || (acts[id] = { name: "", lname: "", exec: "", icon: "" });
                if (k === "Name") a.name = v;
                else if (k === "Name[" + loc + "]" || (k === "Name[" + lang + "]" && !a.lname)) a.lname = v;
                else if (k === "Exec") a.exec = v;
                else if (k === "Icon") a.icon = v;
            }
        }
        res.actions = order.map(id => acts[id]).filter(a => a && a.name && a.exec)
                           .map(a => ({ name: a.lname || a.name, exec: a.exec, icon: a.icon }));
        return res;
    }
    function iconInfo(m) {
        const key = desktopKey(m);
        lookup(key);
        const app = apps[key];
        const icon = app ? app.icon : "";
        if (icon && !icon.startsWith("/") && themeIcons[icon]) return { themed: true, icon: icon };
        const id = key.replace(/^applications:/, "").replace(/^.*\//, "").replace(/\.desktop$/, "");
        if (id && themeIcons["nothing-glyph-" + id]) return { themed: false, glyph: "nothing-glyph-" + id };
        return { themed: false, glyph: "", loading: !themeLoaded || !!(key && !app && pending[key]) };
    }
    function runAction(a) {
        const exec = a.exec.replace(/@@[a-z]?/g, "").replace(/%[fFuUdDnNvmik]/g, "").replace(/%c/g, a.name).replace(/%%/g, "%").trim();
        if (exec) sh.run("setsid -f " + exec + " >/dev/null 2>&1 # " + Date.now(), () => {});
    }

    // ── actions ───────────────────────────────────────────────────────
    function children(row) {
        const list = [], n = tasksModel.rowCount(idx(row));
        for (let i = 0; i < n; i++) list.push(idx(row, i));
        return list;
    }
    function topChild(list) {
        let best, bestVal = -1;
        for (const c of list) {
            const v = tasksModel.data(c, atm.LastActivated) || tasksModel.data(c, atm.StackingOrder) || 0;
            const t = (v instanceof Date) ? v.getTime() : Number(v);
            if (t > bestVal) { bestVal = t; best = c; }
        }
        return best || list[0];
    }
    function activate(row, mods) {
        const i = idx(row);
        if (mods & Qt.ShiftModifier) { tasksModel.requestNewInstance(i); return; }
        if (get(row, atm.IsGroupParent)) {
            const list = children(row);
            const cur = list.findIndex(c => tasksModel.data(c, atm.IsActive));
            tasksModel.requestActivate(cur >= 0 ? list[(cur + 1) % list.length] : topChild(list));
        } else if (get(row, atm.IsWindow) && get(row, atm.IsActive) && !get(row, atm.IsMinimized)) {
            tasksModel.requestToggleMinimized(i);
        } else {
            tasksModel.requestActivate(i);       // launchers start the app
        }
    }
    property real wheelAcc: 0
    function cycle(row, delta) {
        wheelAcc += delta;
        if (Math.abs(wheelAcc) < 120) return;
        const step = wheelAcc > 0 ? -1 : 1;
        wheelAcc = 0;
        if (get(row, atm.IsGroupParent)) {
            const list = children(row);
            const cur = list.findIndex(c => tasksModel.data(c, atm.IsActive));
            const next = cur < 0 ? topChild(list) : list[((cur + step) % list.length + list.length) % list.length];
            tasksModel.requestActivate(next);
        } else if (get(row, atm.IsWindow) && !get(row, atm.IsActive)) {
            tasksModel.requestActivate(idx(row));
        }
    }
    function publishGeometries() {
        for (let r = 0; r < bar.count; r++) {
            const it = bar.itemAt(r);
            if (!it || get(r, atm.IsLauncher) || get(r, atm.IsStartup)) continue;
            const p = it.mapToGlobal(0, 0);
            tasksModel.requestPublishDelegateGeometry(idx(r), Qt.rect(p.x, p.y, it.width, it.height), it);
        }
    }
    Timer { id: geometryTimer; interval: 400; onTriggered: root.publishGeometries() }

    // ── context menu ─────────────────────────────────────────────────
    Component {
        id: menuComponent
        PlasmaExtras.Menu {
            id: menu
            placement: Plasmoid.location === PlasmaCore.Types.TopEdge ? PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
                     : Plasmoid.location === PlasmaCore.Types.LeftEdge ? PlasmaExtras.Menu.RightPosedTopAlignedPopup
                     : Plasmoid.location === PlasmaCore.Types.RightEdge ? PlasmaExtras.Menu.LeftPosedTopAlignedPopup
                     : PlasmaExtras.Menu.TopPosedLeftAlignedPopup
            onStatusChanged: if (status === PlasmaExtras.Menu.Closed) { root.menuOpen = false; destroy(); }
        }
    }
    property bool menuOpen: false
    function addItem(menu, props, onClicked) {
        const it = Qt.createQmlObject("import org.kde.plasma.extras as PlasmaExtras; PlasmaExtras.MenuItem {}", menu);
        for (const k in props) it[k] = props[k];
        if (onClicked) it.clicked.connect(onClicked);
        menu.addMenuItem(it);
        return it;
    }
    function showMenu(row, item) {
        const i = idx(row);
        const m = { LauncherUrlWithoutIcon: get(row, atm.LauncherUrlWithoutIcon), AppId: get(row, atm.AppId) };
        const app = apps[desktopKey(m)];
        const name = get(row, atm.AppName) || get(row, Qt.DisplayRole) || "";
        const launcherUrl = get(row, atm.LauncherUrlWithoutIcon);
        const isWindow = !!get(row, atm.IsWindow);
        const group = !!get(row, atm.IsGroupParent);
        const windows = group ? tasksModel.rowCount(i) : (isWindow ? 1 : 0);
        const pinned = launcherUrl && String(launcherUrl) !== "" && tasksModel.launcherPosition(launcherUrl) >= 0;

        const menu = menuComponent.createObject(root, { visualParent: item });
        if (name) addItem(menu, { text: name, section: true });
        if (app) for (const a of app.actions)
            addItem(menu, { text: a.name, icon: a.icon || "" }, () => root.runAction(a));
        if (app && app.actions.length) addItem(menu, { separator: true });

        if (windows > 0 && get(row, atm.CanLaunchNewInstance))
            addItem(menu, { text: i18n("New Window"), icon: "window-new" }, () => tasksModel.requestNewInstance(i));
        else if (windows === 0)
            addItem(menu, { text: i18n("Open"), icon: "media-playback-start" }, () => tasksModel.requestActivate(i));

        if (launcherUrl && String(launcherUrl) !== "") {
            if (pinned) addItem(menu, { text: i18n("Unpin from Dock"), icon: "window-unpin" },
                                () => tasksModel.requestRemoveLauncher(launcherUrl));
            else addItem(menu, { text: i18n("Pin to Dock"), icon: "window-pin" },
                         () => tasksModel.requestAddLauncher(get(row, atm.LauncherUrl)));
        }
        if (windows === 1 && isWindow && !group && get(row, atm.IsMinimizable))
            addItem(menu, { text: get(row, atm.IsMinimized) ? i18n("Restore") : i18n("Minimize"), icon: "window-minimize" },
                    () => tasksModel.requestToggleMinimized(i));
        if (windows > 0) {
            addItem(menu, { separator: true });
            addItem(menu, { text: windows > 1 ? i18n("Close All %1 Windows", windows) : i18n("Close"), icon: "window-close" },
                    () => tasksModel.requestClose(i));
        }
        menuOpen = true;
        menu.openRelative();
    }

    // ── view ─────────────────────────────────────────────────────────
    DockBar {
        id: bar
        anchors.centerIn: parent
        width: implicitWidth
        height: root.vertical ? implicitHeight : root.height
        pillHeight: Math.max(40, Math.min(root.vertical ? 64 : root.height, 64))
        iconInfo: m => root.iconInfo(m)

        onActivated: (index, mods) => root.activate(index, mods)
        onMiddleClicked: index => tasksModel.requestNewInstance(root.idx(index))
        onContextMenuRequested: (index, item) => root.showMenu(index, item)
        onWheeled: (index, delta) => root.cycle(index, delta)
        onMoveRequested: (from, to) => tasksModel.move(from, to)
        onDragFinished: { tasksModel.syncLaunchers(); geometryTimer.restart(); }
        onCountChanged: geometryTimer.restart()
        onWidthChanged: geometryTimer.restart()
    }

    // Hover label: leaves the panel, so it lives in its own background-less tooltip window.
    property string tipText: ""
    Timer { id: tipDelay; interval: 120; onTriggered: tip.visible = root.wantTip }
    readonly property bool wantTip: bar.hoveredItem !== null && !bar.dragging && !menuOpen
    onWantTipChanged: {
        if (wantTip) { tipText = bar.hoveredLabel; if (!tip.visible) tipDelay.restart(); }
        else { tipDelay.stop(); tip.visible = false; }
    }
    Connections {
        target: bar
        function onHoveredLabelChanged() { if (bar.hoveredLabel) root.tipText = bar.hoveredLabel; }
    }
    PlasmaCore.Dialog {
        id: tip
        type: PlasmaCore.Dialog.Tooltip
        flags: Qt.WindowDoesNotAcceptFocus | Qt.WindowStaysOnTopHint
        location: Plasmoid.location
        backgroundHints: PlasmaCore.Dialog.NoBackground
        outputOnly: true
        hideOnWindowDeactivate: false
        visualParent: bar.hoveredItem
        visible: false
        mainItem: Item {
            width: label.width
            height: label.height + 8          // gap between pill and label
            DockTooltip { id: label; text: root.tipText }
        }
    }
}
