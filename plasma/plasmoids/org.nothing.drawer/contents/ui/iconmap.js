.pragma library

// Picks a monochrome "-symbolic" glyph for an app icon so the drawer renders every
// app as a flat white line glyph. `available` is the set of symbolic icon names the
// active icon themes ship (scanned once in main.qml). Returns "" when nothing fits,
// in which case MonoIcon masks the normal icon into a flat silhouette.

// keyword (matched against icon name + app name + generic name) → glyph candidates.
// Order matters: earlier rules win.
const rules = [
    [/steam_icon_|steam|lutris|heroic|proton|bottles|game|minecraft|tlauncher/, ["applications-games", "input-gaming"]],
    [/termin|konsole|alacritty|kitty|xterm|wezterm|foot|tilix|console/, ["utilities-terminal"]],
    [/dolphin|nautilus|thunar|nemo|pcmanfm|file manager|^files|\bfiles\b|volman/, ["system-file-manager", "folder"]],
    [/firefox|chrom|brave|vivaldi|opera|epiphany|librewolf|browser|\bweb\b/, ["web-browser", "internet-web-browser"]],
    [/spotify|music|audio|elisa|rhythmbox|amarok|strawberry|pavucontrol|sound|volume/, ["audio-x-generic", "multimedia-player"]],
    [/vlc|mpv|video|haruna|celluloid|totem|freetube|kdenlive|\bobs\b|youtube|player|qvidcap/, ["video-x-generic", "applications-multimedia"]],
    [/discord|telegram|chat|signal|element|slack|zapzap|whatsapp|messenger|teams|irc/, ["im-user"]],
    [/thunderbird|kmail|evolution|geary|\bmail\b/, ["internet-mail", "mail-message"]],
    [/calc/, ["accessories-calculator"]],
    [/\bark\b|archiv|xarchiver|file-roller|peazip|compress/, ["package-x-generic"]],
    [/code|codium|vscode|\bzed\b|\bide\b|antigravity|designer|linguist|cmake|jetbrains|meld|qdbus|assistant|develop/, ["applications-development", "code-context"]],
    [/kate|kwrite|gedit|gvim|\bvim\b|micro|nano|notepad|text editor|editor/, ["accessories-text-editor", "text-editor"]],
    [/discover|software|store|flatpak|octopi|pamac|package/, ["system-software-install"]],
    [/monitor|htop|btop|hwinfo|hwloc|resources|task manager|usage/, ["utilities-system-monitor"]],
    [/gwenview|image|photo|gimp|krita|inkscape|darktable|paint|draw|graphic|screenshot|spectacle|colou?r/, ["image-x-generic", "applications-graphics"]],
    [/okular|pdf|evince|document|office|writer|reader/, ["x-office-document"]],
    [/print|cups|hplip|\bhp\b/, ["printer"]],
    [/camera|webcam|qv4l2/, ["camera-photo"]],
    [/virt|qemu|vmware|virtualbox|boxes|\bvm\b/, ["virt-manager", "applications-system"]],
    [/network|wired|wi-?fi|anydesk|rustdesk|parsec|remote|vnc|kdeconnect|localsend|torrent|download|ventoy/, ["applications-internet", "network-wired"]],
    [/help|bug|report|manual|welcome|hello/, ["help-browser"]],
    [/setting|preference|configur|control|kcm|tweak|kvantum|theme|kernel|scx|menu edit|kmenuedit|latte|plasma/, ["preferences-system", "emblem-system"]],
    [/emoji|character/, ["preferences-other"]],
    [/display|monitor|screen/, ["video-display"]],
];

function has(available, name) {
    return !!available && available[name + "-symbolic"] === true;
}

function resolve(source, hint, available) {
    if (typeof source !== "string" || source === "" || !available) return "";
    const s = source.toLowerCase();
    if (s.indexOf("/") < 0) {
        if (has(available, source)) return source + "-symbolic";
        if (has(available, s)) return s + "-symbolic";
        // reverse-DNS ids: org.kde.konsole → konsole, com.google.Chrome → chrome
        const last = s.split(".").pop();
        if (last !== s && has(available, last)) return last + "-symbolic";
    }
    const text = (s + " " + String(hint || "")).toLowerCase();
    for (const [re, names] of rules) {
        if (!re.test(text)) continue;
        for (const n of names) if (has(available, n)) return n + "-symbolic";
    }
    return "";
}
