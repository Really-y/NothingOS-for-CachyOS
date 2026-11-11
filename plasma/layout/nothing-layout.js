// Nothing layout, applied through plasmashell's own scripting API so every
// piece is a real Plasma panel/widget (editable, Meta+D aware, persistent).
// Idempotent: removes earlier Nothing top panels before re-creating them.

const TOP_ID = "nothingTopPanel";

// 1. bottom dock: every bottom panel holds only org.nothing.dock. The pinned apps of a stock
//    task manager that was there are copied over first (same `launchers` key and format).
//    The theme's "south" panel frame is invisible, so only the dock's own pill shows.
const DOCK = "org.nothing.dock";
const TASKMANAGERS = ["org.kde.plasma.icontasks", "org.kde.plasma.taskmanager"];
const asList = v => Array.isArray(v) ? v.map(String) : String(v || "").split(",").filter(x => x);
let haveBottom = false;
for (const p of panels()) {
    if (p.readConfig(TOP_ID, false)) { p.remove(); continue; }
    if (p.location !== "bottom") continue;
    haveBottom = true;
    let launchers = [], dock = null;
    for (const w of p.widgets()) {
        if (w.type === DOCK && !dock) { dock = w; continue; }
        if (TASKMANAGERS.indexOf(w.type) >= 0 && !launchers.length) {
            w.currentConfigGroup = ["General"];
            launchers = asList(w.readConfig("launchers", []));
        }
        w.remove();
    }
    if (!dock) dock = p.addWidget(DOCK);
    dock.currentConfigGroup = ["General"];
    if (launchers.length && !asList(dock.readConfig("launchers", [])).length) {
        dock.writeConfig("launchers", launchers);
        dock.reloadConfig();
    }
    p.height = 64; p.floating = true; p.lengthMode = "fit"; p.alignment = "center"; p.hiding = "none";
}
if (!haveBottom) {
    const p = new Panel("org.kde.panel");
    p.screen = 0;
    p.location = "bottom";
    p.addWidget(DOCK);
    p.height = 64; p.floating = true; p.lengthMode = "fit"; p.alignment = "center"; p.hiding = "none";
}

// 2. top bar on every screen (system tray only on the primary one)
for (let s = 0; s < screenCount; s++) {
    const p = new Panel("org.kde.panel");
    p.screen = s;
    p.location = "top";
    p.height = 36;
    p.floating = false;
    p.hiding = "none";
    p.lengthMode = "fill";
    p.writeConfig(TOP_ID, true);
    p.addWidget("org.nothing.drawer");
    p.addWidget("org.kde.plasma.panelspacer");
    p.addWidget("org.nothing.clock");
    p.addWidget("org.kde.plasma.panelspacer");
    if (s === 0) p.addWidget("org.kde.plasma.systemtray");
    p.addWidget("org.nothing.controlcenter");
}

// 3. desktop widgets on the primary screen (only once)
for (const d of desktops()) {
    if (d.screen !== 0) continue;
    const have = d.widgets().map(w => w.type);
    const add = (id, x, y, w, h) => { if (have.indexOf(id) < 0) d.addWidget(id, x, y, w, h); };
    add("org.nothing.clock", 40, 40, 352, 168);
    add("org.nothing.weather", 40, 218, 168, 168);
    add("org.nothing.system", 224, 218, 168, 168);
    add("org.nothing.media", 40, 396, 352, 168);
}
