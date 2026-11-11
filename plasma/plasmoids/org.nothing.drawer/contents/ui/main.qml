import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.kicker as Kicker
import org.kde.kitemmodels as KItemModels
import org.kde.ksvg as KSvg
import "nothing"
import "iconmap.js" as IconMap

// Nothing OS app drawer. Lists/launches apps through the Kicker models (same as
// Kickoff), so launches feed KActivities recents, favourites stay in sync and
// .desktop actions show in the context menu. Search = KRunner (RunnerModel).
// Provides org.kde.plasma.launchermenu so the bare Meta key opens it.
PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "start-here-kde-symbolic"
    preferredRepresentation: compactRepresentation
    switchWidth: 10000
    switchHeight: 10000
    toolTipMainText: i18n("Apps")
    toolTipSubText: i18n("Meta to open · type to search")

    // ── models ───────────────────────────────────────────────────────────
    readonly property Kicker.RootModel rootModel: Kicker.RootModel {
        autoPopulate: false
        appletInterface: root
        appNameFormat: 0              // name only
        flat: true
        sorted: true
        showSeparators: false
        showTopLevelItems: false
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        Component.onCompleted: favoritesModel.initForClient("org.nothing.drawer.favorites.instance-" + Plasmoid.id)
        onRefreshed: root.allApps = modelForRow(0)
    }
    // row 0 = "All Applications" (flat, alphabetical AppsModel)
    property var allApps: null
    readonly property var favorites: rootModel.favoritesModel

    readonly property Kicker.RunnerModel runnerModel: Kicker.RunnerModel {
        appletInterface: root
        mergeResults: true
        favoritesModel: root.favorites
        query: root.fullRepresentationItem ? root.fullRepresentationItem.panel.query : ""
    }
    // re-evaluated whenever count changes (same trick Kickoff uses)
    readonly property var runnerMatches: runnerModel.count ? runnerModel.modelForRow(0) : null

    function isAppMatch(model, row, parent) {
        const role = model.KItemModels.KRoleNames.role("favoriteId");
        const id = model.data(model.index(row, 0, parent), role);
        return typeof id === "string" && id.indexOf("applications:") === 0;
    }
    KItemModels.KSortFilterProxyModel {
        id: runnerApps
        sourceModel: root.runnerMatches
        filterRowCallback: (row, parent) => root.isAppMatch(sourceModel, row, parent)
    }
    KItemModels.KSortFilterProxyModel {
        id: runnerOther
        sourceModel: root.runnerMatches
        filterRowCallback: (row, parent) => !root.isAppMatch(sourceModel, row, parent)
    }

    // zone/row → (model, sourceRow)
    function resolve(zone, row) {
        const searching = fullRepresentationItem && fullRepresentationItem.panel.searching;
        if (zone === 0) return { model: favorites, row: row };
        if (zone === 1 && !searching) return { model: allApps, row: row };
        const proxy = zone === 1 ? runnerApps : runnerOther;
        const src = proxy.mapToSource(proxy.index(row, 0));
        return { model: runnerMatches, row: src.row };
    }
    function activate(zone, row) {
        const t = resolve(zone, row);
        if (!t.model || t.row < 0) return;
        t.model.trigger(t.row, "", null);
        root.expanded = false;
    }

    // ── which "<icon>-symbolic" glyphs the icon themes ship (scanned once) ──
    property var symbolicNames: ({})
    P5Support.DataSource {
        id: iconScan
        engine: "executable"
        // only the active theme chain (Nothing → Papirus-Dark → breeze-dark → breeze → hicolor) + flatpak exports
        readonly property string cmd: "find -L \"$HOME/.local/share/icons\" /usr/share/icons/Papirus-Dark /usr/share/icons/Papirus /usr/share/icons/breeze-dark /usr/share/icons/breeze /usr/share/icons/hicolor /var/lib/flatpak/exports/share/icons \"$HOME/.local/share/flatpak/exports/share/icons\" -name '*-symbolic.svg' -printf '%f\\n' 2>/dev/null | sort -u"
        connectedSources: [cmd]
        onNewData: (source, data) => {
            const set = {};
            for (const f of String(data.stdout || "").split("\n"))
                if (f) set[f.replace(/\.svg$/, "")] = true;
            root.symbolicNames = set;
            disconnectSource(source);
        }
    }

    // distinct glyph per installed app (recomputed when apps or the icon scan change)
    property var glyphMap: ({})
    function updateGlyphs() {
        if (!allApps || Object.keys(symbolicNames).length === 0) return;
        const R = allApps.KItemModels.KRoleNames;
        const dec = R.role("decoration"), disp = R.role("display"), desc = R.role("description");
        const apps = [];
        for (let i = 0; i < allApps.count; i++) {
            const ix = allApps.index(i, 0);
            const d = allApps.data(ix, dec), n = allApps.data(ix, disp);
            apps.push({ key: d + "|" + n, name: n, source: d, hint: n + " " + (allApps.data(ix, desc) || "") });
        }
        glyphMap = IconMap.assign(apps, symbolicNames);
    }
    onAllAppsChanged: updateGlyphs()
    onSymbolicNamesChanged: updateGlyphs()
    Connections {
        target: root.allApps
        ignoreUnknownSignals: true
        function onCountChanged() { root.updateGlyphs(); }
    }

    // ── context menu: .desktop actions + favourites (like Kickoff's ActionMenu) ──
    property var menuTarget: null
    property var menuActions: []
    function favoriteActions(favoriteId) {
        if (!favorites || !favoriteId || !favorites.enabled) return [];
        if (favorites.isFavorite(favoriteId))
            return [{ text: i18n("Unpin from drawer"), icon: "window-unpin", actionId: "_kicker_favorite_remove", actionArgument: { favoriteId: favoriteId } }];
        return [{ text: i18n("Pin to drawer"), icon: "window-pin", actionId: "_kicker_favorite_add", actionArgument: { favoriteId: favoriteId } }];
    }
    function openMenu(zone, row, item) {
        const list = item.model.actionList ? Array.from(item.model.actionList) : [];
        const fav = favoriteActions(item.model.favoriteId);
        if (fav.length) {
            if (list.length) list.push({ type: "separator" });
            list.push(...fav);
        }
        if (!list.length) return;
        menuTarget = resolve(zone, row);
        menuActions = list;
        actionMenu.visualParent = item;
        actionMenu.openRelative();
    }
    function runMenuAction(a) {
        if (a.actionId === "_kicker_favorite_add") { favorites.addFavorite(a.actionArgument.favoriteId); return; }
        if (a.actionId === "_kicker_favorite_remove") { favorites.removeFavorite(a.actionArgument.favoriteId); return; }
        if (menuTarget && menuTarget.model && menuTarget.model.trigger(menuTarget.row, a.actionId, a.actionArgument))
            root.expanded = false;
    }
    PlasmaExtras.Menu {
        id: actionMenu
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
    }
    Instantiator {
        model: root.menuActions
        delegate: PlasmaExtras.MenuItem {
            required property var modelData
            text: modelData.text ?? ""
            icon: modelData.icon ?? null
            separator: modelData.type === "separator"
            section: modelData.type === "title"
            enabled: modelData.type !== "title" && (modelData.enabled ?? true)
            onClicked: root.runMenuAction(modelData)
        }
        onObjectAdded: (index, object) => actionMenu.addMenuItem(object)
        onObjectRemoved: (index, object) => actionMenu.removeMenuItem(object)
    }

    onExpandedChanged: {
        if (root.expanded && fullRepresentationItem) {
            fullRepresentationItem.panel.clear();
            fullRepresentationItem.panel.focusSearch();
        }
    }
    Component.onCompleted: {
        Plasmoid.activationTogglesExpanded = true;   // Meta / global shortcut toggles the popup
        rootModel.refresh();
    }

    // ── compact: 3x3 dot grid ────────────────────────────────────────────
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        readonly property real side: Math.min(width, height)
        Layout.minimumWidth: dots.implicitWidth + 8
        Layout.preferredWidth: dots.implicitWidth + 8
        Layout.fillHeight: true
        property bool wasExpanded: false
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded
        DotGrid {
            id: dots
            anchors.centerIn: parent
            open: root.expanded
            hovered: compact.containsMouse
        }
    }

    // ── full: drawer popup ───────────────────────────────────────────────
    fullRepresentation: Item {
        id: full
        readonly property alias panel: panel
        readonly property real frameMargin: Math.max(0, frameMetrics.margins.top)
        Layout.preferredWidth: 712 - frameMargin * 2
        Layout.preferredHeight: 620 - frameMargin * 2
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight

        KSvg.FrameSvgItem { id: frameMetrics; imagePath: "dialogs/background"; visible: false }

        DrawerPanel {
            id: panel
            anchors.fill: parent
            bleed: full.frameMargin
            pad: 24 - full.frameMargin      // may be negative: visible inset stays 24px
            cardRadius: Math.max(8, full.frameMargin)

            pinnedModel: root.favorites
            pinnedCount: root.favorites ? root.favorites.count : 0
            appsModel: searching ? runnerApps : root.allApps
            appsCount: searching ? runnerApps.count : (root.allApps ? root.allApps.count : 0)
            resultsModel: runnerOther
            resultsCount: runnerOther.count
            totalApps: root.allApps ? root.allApps.count : 0
            busy: root.runnerModel.querying
            symbolicNames: root.symbolicNames
            glyphMap: root.glyphMap

            onActivate: (zone, row) => root.activate(zone, row)
            onRequestMenu: (zone, row, item) => root.openMenu(zone, row, item)
            onClose: root.expanded = false
        }
        Component.onCompleted: panel.focusSearch()
    }
}
