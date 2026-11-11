"""Nothing app icons: one Material Symbols glyph language for every app.

Every app glyph comes from Material Symbols Rounded instanced at FILL 0, wght 400, opsz 24,
GRAD 0 — one outline weight, one solid white path per glyph. Each app gets a DISTINCT symbol
(curated map + generic rules); entries of the same app may share. Apps without a fitting
symbol get the first letter of their name in the house 5×7 dot-matrix (round white dots),
ported from plasma/plasmoids/shared/dotfont.js. No silhouettes, no borrowed theme art.

Output into <theme>/scalable/apps/:
  <icon>.svg                       64×64: #1a1a1a disc (r 30) + glyph — dock, task switcher, menus
  nothing-glyph-<desktop-id>.svg   64×64: the same glyph at the same spot, no disc — the drawer
                                   draws its own disc and overlays this, so both are identical
  nothing-glyph-icon-<icon>.svg    the same, keyed by icon name (for items without a desktop id)
and <theme>/glyphmap.json (desktop id → symbol or "dot:<letter>").

Glyphs are optically sized from their real bounding box (round ≈26/60 of the disc,
square ≈24/60, wide ≈30/60) and centred on the bbox, not the em box.
"""
import configparser
import glob
import json
import os
import re
import subprocess
import tempfile

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, "..", "fonts", "MaterialSymbolsRounded.ttf")
DOTFONT = os.path.join(HERE, "..", "plasma", "plasmoids", "shared", "dotfont.js")
HOME = os.path.expanduser("~")
APP_DIRS = ["/usr/share/applications", f"{HOME}/.local/share/applications",
            "/var/lib/flatpak/exports/share/applications", f"{HOME}/.local/share/flatpak/exports/share/applications"]
THEMES = ["/usr/share/icons/Papirus-Dark", "/usr/share/icons/Papirus", "/usr/share/icons/breeze-dark",
          "/usr/share/icons/breeze", "/usr/share/icons/hicolor"]
NON_APP_CONTEXTS = {"actions", "status", "devices", "places", "mimetypes", "emblems", "categories",
                    "panel", "emotes", "animations", "preferences"}
DISC = "#1a1a1a"

# desktop id or icon name (lower case) → Material Symbols, best first
CURATED = {
    # browsers
    "firefox": ["brand:firefoxbrowser"], "com.google.chrome": ["brand:googlechrome"], "com.brave.browser": ["brand:brave"],
    "chromium": ["travel_explore"], "org.kde.falkon": ["explore"],
    # files
    "org.kde.dolphin": ["folder_open"], "thunar": ["folder_special"], "org.gnome.nautilus": ["folder_copy"],
    "thunar-bulk-rename": ["drive_file_rename_outline"], "thunar-settings": ["tune"],
    "thunar-volman-settings": ["usb"], "xarchiver": ["folder_zip"], "org.kde.ark": ["inventory_2"],
    # terminals
    "alacritty-terminal": ["terminal"], "org.kde.konsole": ["terminal"], "alacritty": ["chevron_right"],
    "xterm": ["keyboard"], "kitty": ["chevron_right", "code_blocks"],
    # chat
    "discord": ["brand:discord"], "vesktop": ["brand:vencord"], "com.rtosta.zapzap": ["brand:whatsapp"],
    "com.rtosta.zapzap.nogpu": ["brand:whatsapp"], "org.telegram.desktop": ["brand:telegram"],
    # games
    "steam": ["brand:steam"], "ru.linux_gaming.portproton": ["rocket_launch"],
    "tlauncher": ["toys"],
    # code / text
    "vscodium": ["brand:vscodium"], "vscodium-wayland": ["brand:vscodium"], "code": ["code"], "antigravity-ide": ["deployed_code"],
    "micro": ["edit_note"], "vim": ["edit"], "org.kde.kate": ["edit_note"], "org.kde.kwrite": ["description"],
    "org.gnome.meld": ["compare_arrows", "difference"], "designer": ["design_services"], "linguist": ["translate"],
    "assistant": ["menu_book"], "cmake-gui": ["build"], "qdbusviewer": ["hub"], "org.kde.iconexplorer": ["interests"],
    # media
    "org.kde.spectacle": ["screenshot_region"], "mpv": ["brand:custom/mpv"], "freetube": ["smart_display"],
    "org.pulseaudio.pavucontrol": ["volume_up"], "qv4l2": ["videocam"], "qvidcap": ["video_camera_front"],
    "org.kde.plasma.bigscreen.uvcviewer": ["photo_camera"], "plasma-bigscreen-swap-session": ["tv"],
    "spotify": ["brand:spotify"], "com.spotify.client": ["brand:spotify"], "obs": ["brand:obsstudio"], "com.obsproject.studio": ["brand:obsstudio"], "vlc": ["brand:vlcmediaplayer"], "org.videolan.vlc": ["brand:vlcmediaplayer"], "thunderbird": ["brand:thunderbird"], "org.mozilla.thunderbird": ["brand:thunderbird"], "libreoffice-startcenter": ["brand:libreoffice"], "org.kde.elisa": ["headphones"], "org.kde.gwenview": ["image"],
    "gimp": ["brand:gimp"], "org.gimp.gimp": ["brand:gimp"], "org.kde.krita": ["palette"],
    # software
    "org.kde.discover": ["storefront"], "cachyos-pi": ["install_desktop"], "com.shellyorg.shelly": ["package_2"],
    # network / remote
    "org.qbittorrent.qbittorrent": ["brand:custom/qbittorrent"], "localsend": ["share"],
    "org.kde.kdeconnect.app": ["smartphone"], "org.kde.kdeconnect.nonplasma": ["smartphone"],
    "org.kde.kdeconnect.sms": ["smartphone"], "com.anydesk.anydesk": ["brand:anydesk"], "com.rustdesk.rustdesk": ["brand:rustdesk"],
    "com.parsecgaming.parsec": ["cast_connected"], "remote-viewer": ["connected_tv", "cast"],
    "virt-manager": ["computer"], "qemu": ["dns"], "org.wireshark.wireshark": ["brand:custom/wireshark"],
    "avahi-discover": ["travel_explore"], "bssh": ["vpn_key"], "bvnc": ["screen_share"],
    "nm-connection-editor": ["settings_ethernet"],
    # system
    "org.kde.plasma-systemmonitor": ["monitoring"], "focuslock-extra": [], "org.gnome.systemmonitor": ["speed"],
    "gnome-system-monitor-kde": ["equalizer"], "org.kde.kinfocenter": ["info"], "lstopo": ["developer_board"],
    "org.cachyos.kernelmanager": ["memory"], "org.cachyos.scx-manager": ["schedule"],
    "cachyos-hello": ["waving_hand"], "org.kde.plasma-welcome": ["celebration"], "xfce4-about": ["help"],
    "org.kde.drkonqi.coredump.gui": ["bug_report"], "org.kde.kmenuedit": ["menu_open"],
    "org.kde.latte-dock": ["dock"], "kvantummanager": ["style"],
    "org.kde.plasma.lookandfeelexplorer": ["format_paint"], "org.kde.plasma.themeexplorer": ["texture"],
    "org.kde.plasmaengineexplorer": ["widgets"], "org.kde.plasma.emojier": ["emoji_emotions"],
    "kde_wacom_tabletfinder": ["stylus"], "systemsettings": ["settings"], "kdesystemsettings": ["settings"],
    "focuslock": ["timer"], "cups": ["print"], "hp-uiscan": ["scanner"], "hplip": ["print_connect"],
    "ventoy": ["hard_drive", "usb"], "io.github.sigmasd.stimulator": ["coffee"],
    "org.kde.kcalc": ["calculate"], "org.gnome.calculator": ["calculate"],
}

# generic rules for apps not in CURATED (matched on id + icon + Name/GenericName/Categories/Keywords)
RULES = [(re.compile(p), c) for p, c in [
    (r"steam_icon_|\bgames?\b|lutris|heroic|bottles|minecraft", ["stadia_controller", "joystick", "videogame_asset", "casino", "sports_score", "toys"]),
    (r"browser|webbrowser", ["explore", "travel_explore", "captive_portal"]),
    (r"termin|console", ["terminal", "chevron_right", "code_blocks"]),
    (r"file ?manager|files", ["folder", "folder_open", "folder_copy"]),
    (r"chat|messag|instantmessaging|irc", ["chat", "forum", "chat_bubble"]),
    (r"\bmail\b|email", ["mail"]),
    (r"music|audio player|player.*audio", ["music_note", "headphones"]),
    (r"video|player|\btv\b", ["movie", "play_circle", "smart_display"]),
    (r"camera|webcam", ["photo_camera", "videocam"]),
    (r"paint|draw|graphics", ["brush", "palette"]),
    (r"image|photo|viewer", ["image"]),
    (r"calc", ["calculate"]),
    (r"archiv|compress", ["inventory_2", "folder_zip"]),
    (r"text editor|editor|texteditor", ["edit_note", "description", "edit"]),
    (r"\bcode\b|\bide\b|develop|debug", ["code", "deployed_code", "build"]),
    (r"office|document|pdf|writer|reader", ["article", "description"]),
    (r"store|software|package", ["storefront", "package_2"]),
    (r"download|torrent", ["download", "cloud_download"]),
    (r"remote|vnc|rdp", ["screen_share", "cast"]),
    (r"virt|emulator", ["computer", "dns"]),
    (r"network|wi-?fi", ["lan", "router", "wifi"]),
    (r"monitor|usage", ["monitoring", "speed"]),
    (r"print|scan", ["print", "scanner"]),
    (r"help|manual|welcome", ["help", "info"]),
    (r"setting|preference|configur|control", ["settings", "tune", "settings_applications"]),
    (r"utility", ["widgets", "apps"]),
]]


# ── Material Symbols ────────────────────────────────────────────────────────
def load_font(wght=400, opsz=24):
    f = TTFont(FONT)
    return instancer.instantiateVariableFont(f, {"wght": wght, "FILL": 0, "GRAD": 0, "opsz": opsz})


def ligature_glyph(font, name):
    cmap = font.getBestCmap()
    seq = [cmap[ord(c)] for c in name]
    for lookup in font["GSUB"].table.LookupList.Lookup:
        for st in lookup.SubTable:
            if lookup.LookupType == 7:
                st = st.ExtSubTable
            for lig in (getattr(st, "ligatures", None) or {}).get(seq[0], []):
                if lig.Component == seq[1:]:
                    return lig.LigGlyph
    raise KeyError(name)


# symbols with large solid areas at FILL 0 (measured: survive a 4px erosion at 128px);
# they read heavier than the outline set, so they are never picked
HEAVY = {"public", "compare", "radio_button_checked", "language", "circle"}


BRANDS = os.path.join(HERE, "brands")


def brand_path(slug):
    """(d, fill-rule) of the single <path> of a Simple Icons mark or one of our filled variants in
    brands/custom/ (24×24 viewBox) — treated as data."""
    if not re.fullmatch(r"(custom/)?[a-z0-9]+", slug):
        raise ValueError(f"bad brand slug {slug}")
    src = open(os.path.join(BRANDS, slug + ".svg"), encoding="utf-8").read()
    paths = re.findall(r'<path[^>]*\sd="([^"]+)"', src)
    if len(paths) != 1 or re.search(r"<(script|image|use|foreignObject|style)\b", src):
        raise ValueError(f"unexpected brand svg {slug}")
    if not re.fullmatch(r"[MmLlHhVvCcSsQqTtAaZz0-9.,\s+eE-]+", paths[0]):
        raise ValueError(f"unexpected path data in {slug}")
    rule = "evenodd" if 'fill-rule="evenodd"' in src else "nonzero"
    return paths[0], rule


def has_symbol(font, name):
    if name.startswith("brand:"):
        return os.path.exists(os.path.join(BRANDS, name[6:] + ".svg"))
    if name in HEAVY:
        return False
    try:
        ligature_glyph(font, name)
        return True
    except Exception:
        return False


def _shape(font, gname, bounds):
    """'round' | 'square' from how empty the bbox corners are (rasterised with rsvg)."""
    xmin, ymin, xmax, ymax = bounds
    w, h = xmax - xmin, ymax - ymin
    s = 96 / max(w, h)
    pen = SVGPathPen(font.getGlyphSet())
    font.getGlyphSet()[gname].draw(TransformPen(pen, (s, 0, 0, -s, -xmin * s + (96 - w * s) / 2, ymax * s + (96 - h * s) / 2)))
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96"><path d="{pen.getCommands()}" '
           f'fill="#fff"/></svg>')
    with tempfile.TemporaryDirectory() as t:
        p, o = os.path.join(t, "g.svg"), os.path.join(t, "g.txt")
        open(p, "w").write(svg)
        out = subprocess.run(["magick", "svg:" + p, "-alpha", "extract", "-resize", "12x12!", "txt:-"],
                             capture_output=True, text=True).stdout
    px = {}
    for line in out.splitlines()[1:]:
        m = re.match(r"(\d+),(\d+):.*?gray\((\d+)", line) or re.match(r"(\d+),(\d+):\s*\((\d+)", line)
        if m:
            px[(int(m.group(1)), int(m.group(2)))] = int(m.group(3))
    corners = [px.get((x, y), 0) for x in (0, 1, 10, 11) for y in (0, 1, 10, 11)]
    return "round" if sum(corners) / max(1, len(corners)) < 60 else "square"


def _ink_bbox(d, rule="nonzero", view=24.0):
    """Ink bbox of a path in its own units (rasterised: Simple Icons paths use arcs)."""
    k = 40
    svgsrc = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{view * k:.0f}" height="{view * k:.0f}" '
              f'viewBox="0 0 {view} {view}"><path d="{d}" fill="#fff" fill-rule="{rule}"/></svg>')
    with tempfile.TemporaryDirectory() as t:
        p, q = os.path.join(t, "b.svg"), os.path.join(t, "b.png")
        open(p, "w").write(svgsrc)
        subprocess.run(["rsvg-convert", "-o", q, p], check=True)
        g = subprocess.run(["magick", q, "-trim", "-format", "%@", "info:"], capture_output=True, text=True).stdout
    w, h, x, y = map(int, re.match(r"(\d+)x(\d+)\+(\d+)\+(\d+)", g).groups())
    return x / k, y / k, (x + w) / k, (y + h) / k


def glyph_source(font, val):
    """(path d in y-down units, (xmin, ymin, xmax, ymax)) for 'brand:<slug>' or a Material symbol."""
    if val.startswith("brand:"):
        d, rule = brand_path(val[6:])
        return d, _ink_bbox(d, rule), rule
    gname = ligature_glyph(font, val)
    gs = font.getGlyphSet()
    bp = BoundsPen(gs)
    gs[gname].draw(bp)
    x0, y0, x1, y1 = bp.bounds
    pen = SVGPathPen(gs)
    gs[gname].draw(TransformPen(pen, (1, 0, 0, -1, 0, 0)))      # flip to y-down
    return pen.getCommands(), (x0, -y1, x1, -y0), "nonzero"


# 22px set: symbols whose strokes render under 1.5px get a sturdier stand-in / weight
SMALL_SWAP = {"folder_zip": "inventory_2", "brand:googlechrome": "brand:custom/chrome22"}
SMALL_BOLD = {"smartphone", "computer", "phone_iphone", "desktop_windows", "connected_tv", "developer_board",
              "account_tree", "vpn_key", "keyboard", "interests", "hub", "translate"}

def _ink_stats(d, bbox, rule):
    """(fill ratio, corner fill) of the glyph inside its own ink bbox, rasterised at 48px."""
    x0, y0, x1, y1 = bbox
    w, h = x1 - x0, y1 - y0
    W, H = (48, max(4, round(48 * h / w))) if w >= h else (max(4, round(48 * w / h)), 48)
    svgsrc = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="{x0} {y0} {w} {h}" '
              f'preserveAspectRatio="none"><path d="{d}" fill="#fff" fill-rule="{rule}"/></svg>')
    with tempfile.TemporaryDirectory() as t:
        p, q = os.path.join(t, "s.svg"), os.path.join(t, "s.png")
        open(p, "w").write(svgsrc)
        subprocess.run(["rsvg-convert", "-o", q, p], check=True)
        fill = float(subprocess.run(["magick", q, "-alpha", "extract", "-format", "%[fx:mean]", "info:"],
                                    capture_output=True, text=True).stdout or 0)
        cw, ch = max(2, W // 6), max(2, H // 6)
        corners = []
        for gx, gy in ((0, 0), (W - cw, 0), (0, H - ch), (W - cw, H - ch)):
            v = subprocess.run(["magick", q, "-alpha", "extract", "-crop", f"{cw}x{ch}+{gx}+{gy}", "+repage",
                                "-format", "%[fx:mean]", "info:"], capture_output=True, text=True).stdout
            corners.append(float(v or 0))
    return fill, sum(corners) / 4


def optical_fraction(d, bbox, rule):
    """Longest ink side : disc diameter, by shape class (ink-bbox aspect + fill):
    tall narrow (phone) 0.58, round / narrow 0.54, squares and wide rectangles 0.48."""
    x0, y0, x1, y1 = bbox
    aspect = (x1 - x0) / (y1 - y0)
    if aspect < 0.72:
        return 0.58
    _fill, corner = _ink_stats(d, bbox, rule)
    if corner < 0.12 or aspect < 0.85:
        return 0.54
    return 0.48


def glyph_markup(font, val, c=64, disc_d=60, snap=False):
    d, (x0, y0, x1, y1), rule = glyph_source(font, val)
    w, h = x1 - x0, y1 - y0
    s = optical_fraction(d, (x0, y0, x1, y1), rule) * disc_d / max(w, h)
    tx = c / 2 - (x0 + w / 2) * s
    ty = c / 2 - (y0 + h / 2) * s
    if snap:                                         # bbox on whole pixels
        tx += round(x0 * s + tx) - (x0 * s + tx)
        ty += round(y0 * s + ty) - (y0 * s + ty)
    return (f'<path transform="translate({tx:.3f} {ty:.3f}) scale({s:.5f})" d="{d}" '
            f'fill="#ffffff" fill-rule="{rule}"/>')


# ── dot-matrix letter fallback (shared/dotfont.js) ──────────────────────────
def load_dotfont():
    src = open(DOTFONT, encoding="utf-8").read()
    return {m.group(1): json.loads(m.group(2))
            for m in re.finditer(r'"(.)"\s*:\s*(\[[^\]]*\])', src)}


def dot_letter_markup(dots, ch):
    """5×7 letter for the scalable set: round dots on an integer 4-unit pitch at integer centres."""
    rows = dots.get(ch.upper()) or dots.get("?")
    pitch, r = 4, 1.5
    x0 = 32 - (len(rows[0]) - 1) * pitch // 2
    y0 = 32 - (len(rows) - 1) * pitch // 2
    return "".join(f'<circle cx="{x0 + c * pitch}" cy="{y0 + y * pitch}" r="{r}" fill="#ffffff"/>'
                   for y, row in enumerate(rows) for c, v in enumerate(row) if v == "#")


def dot_letter_48(dots, ch):
    """5×7 letter for the 48px set: 2×2px dots on a 3px pitch at integer offsets — crisp, no AA smears."""
    rows = dots.get(ch.upper()) or dots.get("?")
    x0 = 24 - (len(rows[0]) * 3 - 1) // 2
    y0 = 24 - (len(rows) * 3 - 1) // 2
    return "".join(f'<rect x="{x0 + c * 3}" y="{y0 + y * 3}" width="2" height="2" fill="#ffffff"/>'
                   for y, row in enumerate(rows) for c, v in enumerate(row) if v == "#")


DOT3X5 = os.path.join(HERE, "..", "plasma", "plasmoids", "org.nothing.drawer", "contents", "ui", "dot3x5.js")


def load_dot3x5():
    src = open(DOT3X5, encoding="utf-8").read()
    return {m.group(1): json.loads(m.group(2)) for m in re.finditer(r'"(.)"\s*:\s*(\[[^\]]*\])', src)}


def dot_letter_small(dots, ch, c=22):
    """≤24px fallback: solid 3×5 pixel letter on whole-pixel 2px cells, no gaps (6×10 px)."""
    rows = dots.get(ch.upper()) or dots.get("?")
    cell = 2
    x0 = round(c / 2 - len(rows[0]) * cell / 2)
    y0 = round(c / 2 - len(rows) * cell / 2)
    return "".join(f'<rect x="{x0 + i * cell}" y="{y0 + y * cell}" width="{cell}" height="{cell}" fill="#ffffff"/>'
                   for y, row in enumerate(rows) for i, v in enumerate(row) if v == "#")


# ── desktop entries ─────────────────────────────────────────────────────────
def desktop_entries():
    out = []
    seen = set()
    for d in APP_DIRS:
        for path in sorted(glob.glob(os.path.join(d, "*.desktop"))):
            did = os.path.basename(path)[:-8]
            if did in seen:
                continue
            cp = configparser.RawConfigParser(strict=False, interpolation=None)
            try:
                cp.read(path, encoding="utf-8")
                e = cp["Desktop Entry"]
            except Exception:
                continue
            if (e.get("Hidden", "false").lower() == "true" or e.get("NoDisplay", "false").lower() == "true"
                    or e.get("Type", "Application") != "Application"):
                continue
            seen.add(did)
            name = e.get("Name", did)
            hint = " ".join(e.get(k, "") for k in ("GenericName", "Categories", "Keywords")).replace(";", " ")
            out.append({"id": did, "icon": e.get("Icon", "").strip(), "name": name, "hint": hint})
    return out


def non_app_icon_names():
    """Icon names the theme chain ships only outside the apps context (status, devices, …)."""
    ctx = {}
    for theme in THEMES:
        for root, _d, files in os.walk(theme, followlinks=True):
            parts = set(os.path.relpath(root, theme).split(os.sep))
            c = "apps" if "apps" in parts else ("other" if parts & NON_APP_CONTEXTS else None)
            if not c:
                continue
            for f in files:
                if f.endswith((".svg", ".png")):
                    ctx.setdefault(f[:-4], set()).add(c)
    return {n for n, c in ctx.items() if "apps" not in c}


# ── generic coverage: KCMs, NoDisplay entries, KRunner runners, category names ─────────────
RUNNER_ICONS = ["internet-web-browser", "system-search", "plasma-search", "krunner", "applications-internet",
                "preferences-desktop-font", "kfind", "filelight", "preferences-web-browser-shortcuts",
                "accessories-dictionary", "accessories-calculator", "utilities-terminal", "system-run",
                "preferences-system-windows", "preferences-desktop-locale", "kdeconnect", "org.kde.kfind",
                "org.kde.filelight", "help-browser", "system-file-manager", "preferences-kde-plasma",
                "accessories-character-map", "applications-all", "utilities-system-monitor"]
GENERIC_PREFIXES = ("applications-", "accessories-", "utilities-", "system-", "preferences-")
GENERIC_OK_CONTEXTS = {"apps", "categories", "preferences"}

# name/hint regex → Material symbol (generic names may share)
GENERIC = [(re.compile(p), g) for p, g in [
    (r"font", "text_fields"), (r"firewall|security|privacy|kwallet|password|encrypt", "shield"),
    (r"web-?browser|internet|webshortcut|web-shortcut|browser", "travel_explore"),
    (r"search|krunner|kfind|find|baloo", "search"), (r"filelight|disk-?usage|pie", "pie_chart"),
    (r"bluetooth", "bluetooth"), (r"network|wifi|wireless|proxy|connection|vpn", "lan"),
    (r"display|monitor|screen|randr|kscreen|kwin-?scale|night", "monitor"),
    (r"sound|audio|speaker|pulseaudio|volume|phonon|multimedia", "volume_up"),
    (r"keyboard|shortcut|keys|input-method", "keyboard"), (r"mouse|cursor|pointer", "mouse"),
    (r"touchpad|touchscreen|touch", "touch_app"), (r"tablet|stylus|wacom|pen", "stylus"),
    (r"color|colour|palette", "palette"), (r"theme|style|look|decoration|plasma-theme|icons|splash|effects", "style"),
    (r"wallpaper|background", "wallpaper"), (r"notification|bell", "notifications"),
    (r"power|energy|battery|session|shutdown|logout", "power_settings_new"),
    (r"user|account|people|password", "person"), (r"locale|language|region|translate|spell", "translate"),
    (r"clock|date|time", "schedule"), (r"print", "print"), (r"virtual|desktops|pager|activities", "view_quilt"),
    (r"window|task-?switch|tabbox|kwin", "web_asset"), (r"accessib", "accessibility"),
    (r"gaming|game|joystick|controller", "sports_esports"), (r"thunderbolt|usb|device", "bolt"),
    (r"online-accounts|cloud", "cloud"), (r"login|sddm|startup|autostart|boot", "login"),
    (r"backup|sync", "backup"), (r"calendar|kontact|pim", "calendar_month"), (r"mail", "mail"),
    (r"dictionary|book|help|documentation|manual", "menu_book"), (r"calculat", "calculate"),
    (r"character|emoji|emoticon", "emoji_emotions"), (r"terminal|konsole|run|command", "terminal"),
    (r"file-?manager|files|folder", "folder"), (r"monitor|system-monitor|ksysguard", "monitoring"),
    (r"graphics|image|photo|camera", "image"), (r"development|code|ide|debug", "code"),
    (r"office|document|text", "article"), (r"education|science|math", "school"),
    (r"games", "sports_esports"), (r"utilities|accessories|tools", "build"),
    (r"software|package|install|update|discover", "storefront"), (r"plasma|desktop|kde", "widgets"),
    (r"system|preferences|settings|configure|kcm", "settings"), (r"applications|apps", "apps"),
]]


def icon_contexts():
    ctx = {}
    for theme in THEMES:
        for root, _d, files in os.walk(theme, followlinks=True):
            parts = set(os.path.relpath(root, theme).split(os.sep))
            c = parts & (NON_APP_CONTEXTS | {"apps"})
            if not c:
                continue
            for f in files:
                if f.endswith((".svg", ".png")):
                    ctx.setdefault(f[:-4], set()).update(c)
    return ctx


def generic_icon_names():
    """{icon: hint} for KCM / NoDisplay / runner / category icon names (never status/action/places)."""
    names = {}
    for d in APP_DIRS:
        for path in glob.glob(os.path.join(d, "*.desktop")):
            cp = configparser.RawConfigParser(strict=False, interpolation=None)
            try:
                cp.read(path, encoding="utf-8")
                e = cp["Desktop Entry"]
            except Exception:
                continue
            icon = e.get("Icon", "").strip()
            if icon and "/" not in icon:
                hint = " ".join(e.get(k, "") for k in ("Name", "GenericName", "Comment", "Categories", "Keywords"))
                names[icon] = names.get(icon, "") + " " + os.path.basename(path) + " " + hint.replace(";", " ")
    for n in RUNNER_ICONS:
        names.setdefault(n, "")
    ctx = icon_contexts()
    for n, c in ctx.items():
        if n.startswith(GENERIC_PREFIXES) and c & GENERIC_OK_CONTEXTS and not n.endswith("-symbolic"):
            names.setdefault(n, "")
    out = {}
    for n, hint in names.items():
        c = ctx.get(n, set())
        if c - GENERIC_OK_CONTEXTS and "apps" not in c:
            continue                       # a status/action/device/place/mimetype name: leave it alone
        if n.endswith(("-symbolic", "-tray", "-panel", "-indicator", "-status")) or n.startswith(("start-here", "folder", "user-")):
            continue
        out[n] = hint
    return out


def generic_symbol(font, name, hint):
    text = f"{name} {hint}".lower()
    for rx, g in GENERIC:
        if rx.search(name.lower()) and has_symbol(font, g):
            return g
    for rx, g in GENERIC:
        if rx.search(text) and has_symbol(font, g):
            return g
    return "apps"


def same_family(a, b):
    a, b = a.lower(), b.lower()
    return a in b or b in a or a.split()[0] == b.split()[0]


def assign(font, entries):
    """desktop id → ('sym', name) | ('dot', letter); distinct across apps, shared within a family."""
    used, out, by_icon = {}, {}, {}          # used: glyph → name of the app that owns it

    def candidates(e):
        c = list(CURATED.get(e["id"].lower(), [])) + list(CURATED.get(e["icon"].lower(), []))
        text = f'{e["id"]} {e["icon"]} {e["name"]} {e["hint"]}'.lower()
        for rx, names in RULES:
            if rx.search(text):
                c += names
        return [n for i, n in enumerate(c) if n not in c[:i] and has_symbol(font, n)]

    # curated first, then the rest; inside each, entries whose id names their icon first
    order = sorted(entries, key=lambda e: (e["id"].lower() not in CURATED, e["icon"].lower() not in e["id"].lower(), e["id"]))
    for e in order:
        fam = next((o for o in by_icon.get(e["icon"], []) if same_family(o["name"], e["name"])), None)
        if fam and e["icon"] and e["id"].lower() not in CURATED:
            out[e["id"]] = out[fam["id"]]
        else:
            # a glyph already taken may be reused only by the same app (VSCodium / VSCodium - Wayland)
            g = next((n for n in candidates(e) if n not in used or same_family(used[n], e["name"])), None)
            if g:
                used.setdefault(g, e["name"])
                out[e["id"]] = ("sym", g)
            else:
                letter = next((ch for ch in e["name"] if ch.isalnum()), "?")
                out[e["id"]] = ("dot", letter.upper())
        by_icon.setdefault(e["icon"], []).append(e)
    return out


def svg(inner, c=64):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{c}" height="{c}" viewBox="0 0 {c} {c}">{inner}</svg>'


def build(theme_dir):
    font = load_font(600, 24)          # ≥25px: weight 600 so outlines match the filled brand marks
    font_s = load_font(600, 20)        # small sizes: heavier, low optical size
    font_b = load_font(700, 20)        # thin-stroked symbols that would drop under 1.5px at 22px
    dots = load_dotfont()
    dots_s = load_dot3x5()
    entries = desktop_entries()
    glyphs = assign(font, entries)
    skip_names = non_app_icon_names()
    d = os.path.join(theme_dir, "scalable", "apps")
    d22 = os.path.join(theme_dir, "22", "apps")       # ≤24px: menus, tray-size lists, task switcher rows
    d48 = os.path.join(theme_dir, "48", "apps")       # dot-letter fallbacks only: pixel-exact at 48px
    os.makedirs(d48, exist_ok=True)
    os.makedirs(d, exist_ok=True)
    os.makedirs(d22, exist_ok=True)
    markup_cache, gmap = {}, {}
    report = {"symbol": [], "dot": [], "dock_icons": 0, "dock_skipped": set()}
    dock = {}                                   # icon name → glyph of its first (primary) entry
    order = sorted(entries, key=lambda e: (e["icon"].lower() not in e["id"].lower(), e["id"]))
    for e in order:
        kind, val = glyphs[e["id"]]
        key = (kind, val)
        if key not in markup_cache:
            markup_cache[key] = glyph_markup(font, val) if kind == "sym" else dot_letter_markup(dots, val)
        inner = markup_cache[key]
        with open(os.path.join(d, f'nothing-glyph-{e["id"]}.svg'), "w") as f:
            f.write(svg(inner))
        gmap[e["id"]] = val if kind == "sym" else "dot:" + val
        report["symbol" if kind == "sym" else "dot"].append(f'{e["name"]} → {gmap[e["id"]]}')
        icon = e["icon"]
        themable = (icon and "/" not in icon and icon not in skip_names
                    and not icon.startswith(("preferences-", "applications-", "start-here"))
                    and not icon.endswith(("-symbolic", "-tray", "-panel", "-indicator", "-status")))
        if not themable:
            report["dock_skipped"].add(icon)
            continue
        if icon not in dock:
            dock[icon] = inner
            with open(os.path.join(d, icon + ".svg"), "w") as f:
                f.write(svg(f'<circle cx="32" cy="32" r="30" fill="{DISC}"/>{inner}'))
            if kind == "sym":
                v22 = SMALL_SWAP.get(val, val)
                small = glyph_markup(font_b if v22 in SMALL_BOLD else font_s, v22, c=22, disc_d=21, snap=True)
            else:
                small = dot_letter_small(dots_s, val)
                with open(os.path.join(d48, icon + ".svg"), "w") as f:
                    f.write(svg(f'<circle cx="24" cy="24" r="22.5" fill="{DISC}"/>{dot_letter_48(dots, val)}', 48))
            with open(os.path.join(d22, icon + ".svg"), "w") as f:
                f.write(svg(f'<circle cx="11" cy="11" r="10.5" fill="{DISC}"/>{small}', 22))
            # glyph-only twin by icon name, for drawer items that only know the icon (window/runner results)
            with open(os.path.join(d, f"nothing-glyph-icon-{icon}.svg"), "w") as f:
                f.write(svg(inner))
    # generic coverage (KCMs, NoDisplay entries, runners, categories): may share glyphs
    report["generic"] = []
    for icon, hint in sorted(generic_icon_names().items()):
        if icon in dock:
            continue
        g = generic_symbol(font, icon, hint)
        key = ("sym", g)
        if key not in markup_cache:
            markup_cache[key] = glyph_markup(font, g)
        inner = markup_cache[key]
        with open(os.path.join(d, icon + ".svg"), "w") as f:
            f.write(svg(f'<circle cx="32" cy="32" r="30" fill="{DISC}"/>{inner}'))
        v22 = SMALL_SWAP.get(g, g)
        k22 = ("s22", v22)
        if k22 not in markup_cache:
            markup_cache[k22] = glyph_markup(font_b if v22 in SMALL_BOLD else font_s, v22, c=22, disc_d=21, snap=True)
        with open(os.path.join(d22, icon + ".svg"), "w") as f:
            f.write(svg(f'<circle cx="11" cy="11" r="10.5" fill="{DISC}"/>{markup_cache[k22]}', 22))
        with open(os.path.join(d, f"nothing-glyph-icon-{icon}.svg"), "w") as f:
            f.write(svg(inner))
        report["generic"].append(f"{icon}→{g}")
        dock[icon] = inner
    report["dock_icons"] = len(dock)
    report["dock_skipped"] = sorted(report["dock_skipped"])
    with open(os.path.join(theme_dir, "glyphmap.json"), "w") as f:
        json.dump(gmap, f, indent=1, sort_keys=True)
    return report
