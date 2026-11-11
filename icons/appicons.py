"""Nothing app icons: one monochrome glyph on a #1a1a1a disc per installed app icon.

Glyph choice mirrors the drawer (plasma/plasmoids/org.nothing.drawer/contents/ui/iconmap.js —
keep RULES/OVERRIDES in sync): exact <icon>-symbolic → reverse-DNS tail → brand overrides →
category glyphs (from Name/GenericName/Categories/Keywords). Each installed app gets a glyph no
other app uses; when every fitting glyph is taken (or none fits) the app's own icon is turned
into a flat white silhouette instead.

Outputs into <theme>/scalable/apps/:
  <icon>.svg                      disc + glyph (what the dock, task switcher, menus show)
  nothing-app-<icon>-symbolic.svg glyph only, for the drawer (it draws its own disc)
and <theme>/glyphmap.json (icon → glyph source) for reference.

Everything is written for QtSvg: no nested <svg>, no CSS classes, plain fills.
"""
import base64
import configparser
import glob
import json
import os
import re
import subprocess
import tempfile

HOME = os.path.expanduser("~")
APP_DIRS = ["/usr/share/applications", f"{HOME}/.local/share/applications",
            "/var/lib/flatpak/exports/share/applications", f"{HOME}/.local/share/flatpak/exports/share/applications"]
# active theme chain under Nothing (Inherits=Papirus-Dark → breeze-dark → breeze → hicolor)
THEMES = ["/usr/share/icons/Papirus-Dark", "/usr/share/icons/Papirus", "/usr/share/icons/breeze-dark",
          "/usr/share/icons/breeze", "/usr/share/icons/hicolor",
          "/var/lib/flatpak/exports/share/icons/hicolor", f"{HOME}/.local/share/flatpak/exports/share/icons/hicolor",
          f"{HOME}/.local/share/icons/hicolor"]
PIXMAPS = ["/usr/share/pixmaps"]
NON_APP_CONTEXTS = {"actions", "status", "devices", "places", "mimetypes", "emblems", "categories",
                    "panel", "emotes", "animations", "preferences", "symbolic"}

OVERRIDES = {
    "kate": ["accessories-text-editor", "text-editor"],
    "org.kde.kate": ["accessories-text-editor", "text-editor"],
    "kwrite": ["text-editor", "document-edit"],
    "org.kde.kwrite": ["text-editor", "document-edit"],
    "com.google.chrome": ["google-chrome"], "google-chrome": ["google-chrome"],
    "vscodium": ["applications-development", "code-context"], "code": ["applications-development", "code-context"],
    "steam": ["input-gaming", "applications-games"],
}

# (regex, candidates) — first match = good fits, later matches = weaker guesses
RULES = [
    (r"screenshot|spectacle|screen capture|flameshot", ["accessories-screenshot", "camera-photo"]),
    (r"printer|cups|hplip|\bscan|\bhp\b", ["printer", "document-print"]),
    (r"torrent|download", ["edit-download", "download"]),
    (r"localsend|share|send", ["document-share"]),
    (r"steam_icon_|steam|lutris|heroic|proton|bottles|\bgames?\b|minecraft|tlauncher|days to die", ["applications-games", "input-gaming", "input-gamepad"]),
    (r"termin|konsole|alacritty|kitty|xterm|wezterm|\bfoot\b|tilix|console", ["utilities-terminal", "dialog-scripts", "system-run"]),
    (r"dolphin|nautilus|thunar|nemo|pcmanfm|file manager|filemanager", ["system-file-manager", "folder-open", "document-open-folder", "folder"]),
    (r"volman|removable|usb|ventoy|flash", ["media-flash", "drive-harddisk"]),
    (r"firefox|chrom|brave|vivaldi|opera|epiphany|librewolf|browser|\bweb\b|webbrowser", ["web-browser", "globe", "applications-internet"]),
    (r"spotify|music|elisa|rhythmbox|amarok|strawberry", ["audio-x-generic", "emblem-music", "audio-headphones"]),
    (r"pavucontrol|volume control|sound|mixer|audio", ["audio-headphones", "multimedia-player", "audio-x-generic"]),
    (r"vlc|mpv|haruna|celluloid|totem|freetube|youtube|media player|video player|player", ["video-x-generic", "media-playback-start", "emblem-videos", "multimedia-player"]),
    (r"kdenlive|\bobs\b|qvidcap|video", ["camera-video", "emblem-videos", "video-x-generic"]),
    (r"camera|webcam|qv4l2", ["camera-web", "camera-photo"]),
    (r"discord|vesktop|telegram|chat|signal|element|slack|zapzap|whatsapp|messenger|teams|irc|instantmessaging", ["im-user", "chat-message-new", "dialog-messages"]),
    (r"thunderbird|kmail|evolution|geary|\bmail\b|email", ["internet-mail", "mail-message", "mail-unread"]),
    (r"calc", ["accessories-calculator"]),
    (r"\bark\b|archiv|xarchiver|file-roller|peazip|compress", ["package-x-generic", "document-preview-archive"]),
    (r"codium|vscode|visual studio|\bzed\b|\bide\b|antigravity|jetbrains|code editor|\bcode\b", ["applications-development", "code-context", "code-block"]),
    (r"designer|linguist|cmake|qdbus|assistant|meld|develop|debug", ["code-class", "code-function", "dialog-xml-editor", "run-build", "code-block"]),
    (r"kate|kwrite|gedit|gvim|\bvim\b|micro|nano|notepad|text editor|texteditor|editor", ["accessories-text-editor", "text-editor", "document-edit", "draw-text"]),
    (r"discover|software|store|flatpak|octopi|pamac|package manager|packagemanager", ["system-software-install", "applications-all"]),
    (r"system monitor|monitor|htop|btop|resources|task manager|usage", ["utilities-system-monitor", "dialog-memory"]),
    (r"hwinfo|hwloc|hardware|cpu|topology", ["cpu", "computer", "dialog-memory"]),
    (r"gimp|krita|inkscape|paint|draw|mypaint|pinta|brush|vector", ["draw-brush", "applications-graphics", "draw-freehand", "draw-bezier-curves"]),
    (r"screenshot|spectacle|screen capture|flameshot", ["accessories-screenshot", "camera-photo"]),
    (r"anydesk|rustdesk|parsec|remote|vnc|desktop sharing|remoteaccess", ["user-desktop", "applications-network", "network-vpn"]),
    (r"gwenview|image|photo|viewer|picture|darktable|digikam|shotwell", ["image-x-generic", "emblem-photos", "color-management"]),
    (r"okular|pdf|evince|document|office|writer|reader", ["x-office-document", "document-preview", "applications-office"]),
    (r"virt|qemu|vmware|virtualbox|boxes|\bvm\b|emulator", ["virt-manager", "computer", "applications-system"]),
    (r"kdeconnect|connect|phone", ["kdeconnect", "smartphone", "phone"]),
    (r"network|wired|wi-?fi|connection", ["preferences-system-network", "network-wired", "applications-network"]),
    (r"help|bug|report|manual|welcome|hello", ["help-browser", "tools-report-bug", "dialog-question"]),
    (r"emoji|character", ["accessories-character-map", "preferences-other"]),
    (r"display|screen|monitor", ["video-display", "preferences-desktop-display"]),
    (r"kvantum|theme|style|appearance", ["color-management", "preferences-other"]),
    (r"kernel|scx|scheduler", ["cpu", "applications-system"]),
    (r"latte|dock|panel|plasma", ["plasma", "start-here"]),
    (r"menu edit|kmenuedit|menu", ["applications-all", "settings-configure"]),
    (r"setting|preference|configur|control|kcm|tweak", ["preferences-system", "settings-configure", "configure", "emblem-system", "dialog-object-properties"]),
    (r"game", ["applications-games"]),
    (r"graphics", ["applications-graphics"]),
    (r"audiovideo|multimedia", ["applications-multimedia"]),
    (r"network", ["applications-internet"]),
    (r"utility", ["applications-utilities"]),
    (r"system", ["applications-system"]),
]
RULES = [(re.compile(p), c) for p, c in RULES]


# ── icon lookup ─────────────────────────────────────────────────────────────
def index_icons():
    """name → {'symbolic': path, 'regular': [(size, path)], 'contexts': set}"""
    idx = {}
    for theme in THEMES:
        if not os.path.isdir(theme):
            continue
        for root, _dirs, files in os.walk(theme, followlinks=True):
            rel = os.path.relpath(root, theme).split(os.sep)
            ctx = {p for p in rel if p in NON_APP_CONTEXTS or p == "apps"}
            size = 0
            for p in rel:
                m = re.match(r"(\d+)x\d+", p) or re.match(r"^(\d+)$", p)
                if m:
                    size = int(m.group(1))
                if p == "scalable":
                    size = 512
            for f in files:
                if not f.endswith((".svg", ".png")):
                    continue
                name = f[:-4]
                e = idx.setdefault(name, {"symbolic": None, "regular": [], "contexts": set()})
                e["contexts"] |= ctx
                path = os.path.join(root, f)
                if name.endswith("-symbolic"):
                    if e["symbolic"] is None:
                        e["symbolic"] = path
                else:
                    e["regular"].append((size + (1 if f.endswith(".svg") else 0), path))
    for d in PIXMAPS:
        for path in glob.glob(os.path.join(d, "*")):
            name, ext = os.path.splitext(os.path.basename(path))
            if ext in (".svg", ".png", ".xpm"):
                idx.setdefault(name, {"symbolic": None, "regular": [], "contexts": set()})["regular"].append((1, path))
    return idx


def symbolic_names(idx):
    return {n[:-9] for n, e in idx.items() if n.endswith("-symbolic") and e["symbolic"]}


# ── desktop entries ─────────────────────────────────────────────────────────
def desktop_apps():
    apps = {}
    for d in APP_DIRS:
        for path in sorted(glob.glob(os.path.join(d, "**", "*.desktop"), recursive=True)):
            cp = configparser.RawConfigParser(strict=False, interpolation=None)
            try:
                cp.read(path, encoding="utf-8")
                e = cp["Desktop Entry"]
            except Exception:
                continue
            if e.get("Hidden", "false").lower() == "true" or e.get("Type", "Application") != "Application":
                continue
            # NoDisplay entries (KCM modules, helpers) never reach the dock/menus; leave their icons alone
            if e.get("NoDisplay", "false").lower() == "true":
                continue
            icon = e.get("Icon", "").strip()
            if not icon or "/" in icon:
                continue                      # absolute-path icons can't be themed by name
            hint = " ".join(e.get(k, "") for k in ("Name", "GenericName", "Categories", "Keywords"))
            a = apps.setdefault(icon, {"icon": icon, "hint": "", "names": []})
            a["hint"] += " " + hint.replace(";", " ")
            a["names"].append(e.get("Name", icon))
    return apps


# ── glyph choice (same as iconmap.js) ───────────────────────────────────────
def tiers(icon, hint, avail):
    good, weak = [], []

    def add(lst, n):
        if n in avail and n not in good and n not in weak:
            lst.append(n)
    s = icon.lower()
    for n in OVERRIDES.get(s, []):
        add(good, n)
    add(good, icon)
    add(good, s)
    last = s.split(".")[-1]
    if last != s:
        add(good, last)
    text = (s + " " + hint).lower()
    first = True
    for rx, names in RULES:
        if not rx.search(text):
            continue
        for n in names:
            add(good if first else weak, n)
        first = False
    return good, weak


def assign(apps, avail):
    used, out = set(), {}
    # apps whose own icon name hits a rule (steam, vscodium, …) choose before apps that only
    # match through their description; then fewer options first
    def named(a):
        if a["icon"].lower() in OVERRIDES:
            return -1                      # explicit brand choices win their glyph
        return 0 if any(rx.search(a["icon"].lower()) for rx, _ in RULES) else 1
    order = sorted(apps.values(), key=lambda a: (named(a), len(sum(tiers(a["icon"], a["hint"], avail), [])), a["icon"]))
    for a in order:
        good, weak = tiers(a["icon"], a["hint"], avail)
        g = next((n for n in good if n not in used), None) or next((n for n in weak if n not in used), None)
        if g:
            used.add(g)
        out[a["icon"]] = g            # None → silhouette of its own icon
    return out


# ── SVG building (QtSvg-safe) ───────────────────────────────────────────────
HEX = re.compile(r"#[0-9a-fA-F]{3,8}\b")
NAMED = re.compile(r"(fill|stroke|stop-color|color)(\s*[:=]\s*[\"']?)(black|white|gray|grey)\b")


def inline_symbolic(path, x, y, size):
    """Return a <g> with the symbolic SVG's content, recoloured white, fitted into a box."""
    src = open(path, encoding="utf-8", errors="replace").read()
    src = re.sub(r"<\?xml[^>]*\?>|<!DOCTYPE[^>]*>|<!--.*?-->", "", src, flags=re.S)
    m = re.search(r"<svg\b([^>]*)>(.*)</svg>", src, flags=re.S)
    attrs, body = m.group(1), m.group(2)
    vb = re.search(r'viewBox\s*=\s*"([^"]+)"', attrs)
    if vb:
        vx, vy, vw, vh = [float(v) for v in re.split(r"[ ,]+", vb.group(1).strip())]
    else:
        num = lambda k, d: float(re.sub(r"[^\d.]", "", (re.search(rf'\b{k}\s*=\s*"([^"]+)"', attrs) or [None, str(d)])[1]) or d)
        vx, vy, vw, vh = 0, 0, num("width", 16), num("height", 16)
    ns = " ".join(re.findall(r'xmlns:\w+="[^"]*"', attrs))
    body = re.sub(r"<style\b.*?</style>", "", body, flags=re.S)
    body = re.sub(r"<(sodipodi|inkscape):[^>]*/>", "", body)
    body = re.sub(r"<metadata\b.*?</metadata>", "", body, flags=re.S)
    body = re.sub(r"\sclass=\"[^\"]*\"", "", body)
    body = body.replace("currentColor", "#ffffff")
    body = HEX.sub("#ffffff", body)
    body = NAMED.sub(lambda mm: mm.group(1) + mm.group(2) + "#ffffff", body)
    s = size / max(vw, vh)
    ox = x + (size - vw * s) / 2 - vx * s
    oy = y + (size - vh * s) / 2 - vy * s
    return ns, f'<g fill="#ffffff" transform="translate({ox:.3f} {oy:.3f}) scale({s:.4f})">{body}</g>'


def silhouette_png(idx, icon):
    """Flat white silhouette (alpha of the app's own icon) as a base64 PNG, or None."""
    e = idx.get(icon)
    if not e or not e["regular"]:
        return None
    path = max(e["regular"])[1]
    with tempfile.TemporaryDirectory() as t:
        raw = os.path.join(t, "raw.png")
        out = os.path.join(t, "out.png")
        try:
            if path.endswith(".svg"):
                subprocess.run(["rsvg-convert", "-w", "128", "-h", "128", "-a", "-o", raw, path], check=True,
                               capture_output=True)
            else:
                subprocess.run(["magick", path, "-resize", "128x128", raw], check=True, capture_output=True)
            # white everywhere, keep the icon's alpha → flat silhouette
            subprocess.run(["magick", raw, "-alpha", "on", "-fill", "white", "-colorize", "100", "-trim",
                            "+repage", "-gravity", "center", "-background", "none", "-extent", "%[fx:max(w,h)]x%[fx:max(w,h)]",
                            out], check=True, capture_output=True)
        except Exception:
            return None
        return base64.b64encode(open(out, "rb").read()).decode()


def glyph_markup(idx, icon, glyph, x, y, size):
    if glyph:
        return inline_symbolic(idx[glyph + "-symbolic"]["symbolic"], x, y, size)
    png = silhouette_png(idx, icon)
    if not png:
        return None
    pad = size * 0.08
    return ('xmlns:xlink="http://www.w3.org/1999/xlink"',
            f'<image x="{x + pad:.2f}" y="{y + pad:.2f}" width="{size - 2 * pad:.2f}" height="{size - 2 * pad:.2f}" '
            f'xlink:href="data:image/png;base64,{png}"/>')


def svg(ns, inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" {ns} width="64" height="64" viewBox="0 0 64 64">'
            f'{inner}</svg>')


def build(theme_dir):
    idx = index_icons()
    avail = symbolic_names(idx)
    apps = desktop_apps()
    # never theme status/device/action/… names that some .desktop files borrow
    skip = {i for i in apps if idx.get(i) and idx[i]["contexts"] and "apps" not in idx[i]["contexts"]}
    skip |= {i for i in apps if i.endswith(("-symbolic", "-tray", "-panel", "-indicator", "-status"))}
    skip |= {i for i in apps if i.startswith(("preferences-", "applications-", "start-here"))}  # KCM/category/logo icons
    for i in skip:
        apps.pop(i, None)
    glyphs = assign(apps, avail)
    d = os.path.join(theme_dir, "scalable", "apps")
    os.makedirs(d, exist_ok=True)
    report = {"symbolic": [], "silhouette": [], "skipped": sorted(skip), "failed": []}
    gmap = {}
    for icon, g in sorted(glyphs.items()):
        disc = glyph_markup(idx, icon, g, 16, 16, 32)          # glyph ≈ 50% of the 60px disc
        if disc is None:
            report["failed"].append(icon)
            continue
        bare = glyph_markup(idx, icon, g, 2, 2, 60)
        ns, inner = disc
        with open(os.path.join(d, icon + ".svg"), "w") as f:
            f.write(svg(ns, f'<circle cx="32" cy="32" r="30" fill="#1a1a1a"/>{inner}'))
        with open(os.path.join(d, f"nothing-app-{icon}-symbolic.svg"), "w") as f:
            f.write(svg(bare[0], bare[1]))
        (report["symbolic"] if g else report["silhouette"]).append(icon)
        gmap[icon] = (g + "-symbolic") if g else "silhouette"
    with open(os.path.join(theme_dir, "glyphmap.json"), "w") as f:
        json.dump(gmap, f, indent=1, sort_keys=True)
    return report
