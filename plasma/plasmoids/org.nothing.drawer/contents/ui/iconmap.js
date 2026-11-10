.pragma library

// Picks a monochrome "-symbolic" glyph for every app so the drawer renders all apps
// as flat white line glyphs, and (via assign()) gives installed apps DISTINCT glyphs
// where the theme has alternatives. `available` is the set of "<name>-symbolic"
// names shipped by the active icon themes (scanned once in main.qml).
// No glyph → "" → MonoIcon masks the normal icon into a flat silhouette.

// Brand glyphs that read badly at 24px: use the category glyph instead.
const overrides = {
    "kate": ["accessories-text-editor", "text-editor"],
    "org.kde.kate": ["accessories-text-editor", "text-editor"],
    "kwrite": ["text-editor", "document-edit"],
    "org.kde.kwrite": ["text-editor", "document-edit"],
};

// keyword (matched against icon name + app name + generic name) → glyph candidates,
// most fitting first. All matching rules contribute, in this order.
const rules = [
    [/steam_icon_|steam|lutris|heroic|proton|bottles|\bgames?\b|minecraft|tlauncher|days to die/, ["applications-games", "input-gaming", "input-gamepad"]],
    [/print|scan|cups|hplip|\bhp\b/, ["printer", "document-print"]],
    [/torrent|download/, ["edit-download", "download"]],
    [/localsend|share|send/, ["document-share"]],
    [/termin|konsole|alacritty|kitty|xterm|wezterm|\bfoot\b|tilix|console/, ["utilities-terminal", "dialog-scripts", "system-run"]],
    [/dolphin|nautilus|thunar|nemo|pcmanfm|file manager|^files$/, ["system-file-manager", "folder-open", "document-open-folder", "folder"]],
    [/volman|removable|usb|ventoy|flash/, ["media-flash", "drive-harddisk"]],
    [/firefox|chrom|brave|vivaldi|opera|epiphany|librewolf|browser|\bweb\b/, ["web-browser", "internet-web-browser", "globe"]],
    [/spotify|music|elisa|rhythmbox|amarok|strawberry/, ["audio-x-generic", "emblem-music", "audio-headphones"]],
    [/pavucontrol|volume control|sound|mixer|audio/, ["audio-headphones", "multimedia-player", "audio-x-generic"]],
    [/vlc|mpv|haruna|celluloid|totem|freetube|youtube|media player|video player/, ["video-x-generic", "media-playback-start", "emblem-videos", "multimedia-player"]],
    [/kdenlive|\bobs\b|qvidcap|video/, ["camera-video", "emblem-videos", "video-x-generic"]],
    [/camera|webcam|qv4l2/, ["camera-web", "camera-photo"]],
    [/discord|telegram|chat|signal|element|slack|zapzap|whatsapp|messenger|teams|irc/, ["im-user", "chat-message-new", "dialog-messages"]],
    [/thunderbird|kmail|evolution|geary|\bmail\b/, ["internet-mail", "mail-message", "mail-unread"]],
    [/calc/, ["accessories-calculator"]],
    [/\bark\b|archiv|xarchiver|file-roller|peazip|compress/, ["package-x-generic", "document-preview-archive"]],
    [/codium|vscode|visual studio|\bzed\b|\bide\b|antigravity|jetbrains|code editor|\bcode\b/, ["applications-development", "code-context", "code-block"]],
    [/designer|linguist|cmake|qdbus|assistant|meld|develop|debug/, ["code-class", "code-function", "dialog-xml-editor", "run-build", "code-block"]],
    [/kate|kwrite|gedit|gvim|\bvim\b|micro|nano|notepad|text editor|editor/, ["accessories-text-editor", "text-editor", "document-edit", "draw-text"]],
    [/discover|software|store|flatpak|octopi|pamac|package manager/, ["system-software-install", "applications-all"]],
    [/system monitor|monitor|htop|btop|resources|task manager|usage/, ["utilities-system-monitor", "dialog-memory"]],
    [/hwinfo|hwloc|hardware|cpu|topology/, ["cpu", "computer", "dialog-memory"]],
    [/gimp|krita|inkscape|paint|draw|mypaint|pinta|brush|vector/, ["draw-brush", "applications-graphics", "draw-freehand", "draw-bezier-curves"]],
    [/screenshot|spectacle|screen capture|flameshot/, ["accessories-screenshot", "camera-photo"]],
    [/anydesk|rustdesk|parsec|remote|vnc|desktop sharing/, ["user-desktop", "applications-network", "network-vpn"]],
    [/gwenview|image|photo|viewer|picture|darktable|digikam|shotwell/, ["image-x-generic", "emblem-photos", "color-management"]],
    [/okular|pdf|evince|document|office|writer|reader/, ["x-office-document", "document-preview", "applications-office"]],
    [/virt|qemu|vmware|virtualbox|boxes|\bvm\b|viewer/, ["virt-manager", "computer", "applications-system"]],
    [/kdeconnect|connect|phone/, ["kdeconnect", "smartphone", "phone"]],
    [/network|wired|wi-?fi|connection/, ["preferences-system-network", "network-wired", "applications-network"]],
    [/help|bug|report|manual|welcome|hello/, ["help-browser", "tools-report-bug", "dialog-question"]],
    [/emoji|character/, ["accessories-character-map", "preferences-other"]],
    [/display|screen|monitor/, ["video-display", "preferences-desktop-display"]],
    [/kvantum|theme|style|appearance/, ["color-management", "preferences-other"]],
    [/kernel|scx|scheduler/, ["cpu", "applications-system"]],
    [/latte|dock|panel|plasma/, ["plasma", "start-here"]],
    [/menu edit|kmenuedit|menu/, ["applications-all", "settings-configure"]],
    [/setting|preference|configur|control|kcm|tweak/, ["preferences-system", "settings-configure", "configure", "emblem-system", "dialog-object-properties"]],
];

function has(available, name) {
    return !!available && available[name + "-symbolic"] === true;
}

// Fitting glyph names (without "-symbolic"), best first, unique. Only the app's own
// glyph(s) and its FIRST matching category count as good fits; later matches are
// weaker guesses and only used when nothing better exists.
function tiers(source, hint, available) {
    const good = [], weak = [];
    const add = (list, n) => { if (has(available, n) && good.indexOf(n) < 0 && weak.indexOf(n) < 0) list.push(n); };
    if (typeof source !== "string" || source === "" || !available) return { good: good, weak: weak };
    const s = source.toLowerCase();
    if (overrides[s]) overrides[s].forEach(n => add(good, n));
    if (s.indexOf("/") < 0) {
        add(good, source); add(good, s);
        const last = s.split(".").pop();                 // org.kde.konsole → konsole
        if (last !== s) add(good, last);
    }
    const text = (s + " " + String(hint || "")).toLowerCase();
    let first = true;
    for (const [re, names] of rules) {
        if (!re.test(text)) continue;
        names.forEach(n => add(first ? good : weak, n));
        first = false;
    }
    return { good: good, weak: weak };
}
function candidates(source, hint, available) {
    const t = tiers(source, hint, available);
    return t.good.length ? t.good : t.weak;
}

// Greedy distinct assignment over the installed apps: each app takes its best glyph
// that no earlier app took; apps whose candidates are all taken share their best one.
// apps: [{ key, source, hint }] → { key: "<glyph>-symbolic" }
function assign(apps, available) {
    const used = {}, map = {}, seen = {};
    apps = apps.filter(a => { if (seen[a.key]) return false; seen[a.key] = true; return true; });
    // apps with fewer options pick first so they don't lose their only glyph
    const list = apps.map(a => { const t = tiers(a.source, a.hint, available);
                                 return { a: a, t: t, c: t.good.length ? t.good : t.weak }; })
                     .filter(x => x.c.length > 0)
                     .sort((x, y) => x.c.length - y.c.length);
    for (const x of list) {
        // best unused good fit → unused weaker guess → share the best good fit
        let g = x.t.good.find(n => !used[n]) || x.t.weak.find(n => !used[n]) || x.c[0];
        used[g] = true;
        map[x.a.key] = g + "-symbolic";
    }
    return map;
}

function resolve(source, hint, available, assigned, key) {
    if (assigned && key && assigned[key]) return assigned[key];
    const c = candidates(source, hint, available);
    return c.length ? c[0] + "-symbolic" : "";
}
