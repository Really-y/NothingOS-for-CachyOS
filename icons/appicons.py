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
    "firefox": ["public"], "com.google.chrome": ["language"], "com.brave.browser": ["shield"],
    "chromium": ["travel_explore"], "org.kde.falkon": ["explore"],
    # files
    "org.kde.dolphin": ["folder_open"], "thunar": ["folder"], "org.gnome.nautilus": ["folder_copy"],
    "thunar-bulk-rename": ["drive_file_rename_outline"], "thunar-settings": ["folder_special"],
    "thunar-volman-settings": ["usb"], "xarchiver": ["inventory_2"], "org.kde.ark": ["inventory_2"],
    # terminals
    "alacritty": ["terminal"], "alacritty-terminal": ["terminal"], "org.kde.konsole": ["terminal"],
    "xterm": ["code_blocks"], "uxterm": ["code_blocks"], "kitty": ["keyboard_command_key"],
    # chat
    "discord": ["forum"], "vesktop": ["chat"], "com.rtosta.zapzap": ["chat_bubble"],
    "com.rtosta.zapzap.nogpu": ["chat_bubble"], "org.telegram.desktop": ["send"],
    # games
    "steam": ["sports_esports"], "ru.linux_gaming.portproton": ["rocket_launch"],
    "tlauncher": ["toys"],
    # code / text
    "vscodium": ["code"], "vscodium-wayland": ["code"], "code": ["code"], "antigravity-ide": ["deployed_code"],
    "micro": ["edit_note"], "vim": ["edit"], "org.kde.kate": ["edit_note"], "org.kde.kwrite": ["description"],
    "org.gnome.meld": ["compare"], "designer": ["design_services"], "linguist": ["translate"],
    "assistant": ["menu_book"], "cmake-gui": ["build"], "qdbusviewer": ["hub"], "org.kde.iconexplorer": ["interests"],
    # media
    "org.kde.spectacle": ["screenshot_region"], "mpv": ["play_circle"], "freetube": ["smart_display"],
    "org.pulseaudio.pavucontrol": ["volume_up"], "qv4l2": ["videocam"], "qvidcap": ["video_camera_front"],
    "org.kde.plasma.bigscreen.uvcviewer": ["photo_camera"], "plasma-bigscreen-swap-session": ["tv"],
    "spotify": ["music_note"], "org.kde.elisa": ["headphones"], "org.kde.gwenview": ["image"],
    "gimp": ["brush"], "org.kde.krita": ["palette"],
    # software
    "org.kde.discover": ["storefront"], "cachyos-pi": ["install_desktop"], "com.shellyorg.shelly": ["package_2"],
    # network / remote
    "org.qbittorrent.qbittorrent": ["download"], "localsend": ["share"],
    "org.kde.kdeconnect.app": ["smartphone"], "org.kde.kdeconnect.nonplasma": ["smartphone"],
    "org.kde.kdeconnect.sms": ["smartphone"], "com.anydesk.anydesk": ["cast"], "com.rustdesk.rustdesk": ["screen_share"],
    "com.parsecgaming.parsec": ["cast_connected"], "remote-viewer": ["desktop_windows"],
    "virt-manager": ["computer"], "qemu": ["dns"], "org.wireshark.wireshark": ["lan"],
    "avahi-discover": ["router"], "bssh": ["network_check"], "bvnc": ["devices"],
    "nm-connection-editor": ["settings_ethernet"],
    # system
    "org.kde.plasma-systemmonitor": ["monitoring"], "org.gnome.systemmonitor": ["speed"],
    "gnome-system-monitor-kde": ["equalizer"], "org.kde.kinfocenter": ["info"], "lstopo": ["account_tree"],
    "org.cachyos.kernelmanager": ["memory"], "org.cachyos.scx-manager": ["tune"],
    "cachyos-hello": ["waving_hand"], "org.kde.plasma-welcome": ["celebration"], "xfce4-about": ["help"],
    "org.kde.drkonqi.coredump.gui": ["bug_report"], "org.kde.kmenuedit": ["menu_open"],
    "org.kde.latte-dock": ["dock"], "kvantummanager": ["style"],
    "org.kde.plasma.lookandfeelexplorer": ["palette"], "org.kde.plasma.themeexplorer": ["texture"],
    "org.kde.plasmaengineexplorer": ["widgets"], "org.kde.plasma.emojier": ["emoji_emotions"],
    "kde_wacom_tabletfinder": ["stylus"], "systemsettings": ["settings"], "kdesystemsettings": ["settings"],
    "focuslock": ["timer"], "cups": ["print"], "hp-uiscan": ["scanner"], "hplip": ["print_connect"],
    "ventoy": ["usb", "hard_drive"], "io.github.sigmasd.stimulator": ["coffee"],
    "org.kde.kcalc": ["calculate"], "org.gnome.calculator": ["calculate"],
}

# generic rules for apps not in CURATED (matched on id + icon + Name/GenericName/Categories/Keywords)
RULES = [(re.compile(p), c) for p, c in [
    (r"steam_icon_|\bgames?\b|lutris|heroic|bottles|minecraft", ["stadia_controller", "joystick", "videogame_asset", "casino", "sports_score", "toys"]),
    (r"browser|webbrowser", ["travel_explore", "explore", "public", "language"]),
    (r"termin|console", ["terminal", "code_blocks", "keyboard_command_key"]),
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
def load_font():
    f = TTFont(FONT)
    return instancer.instantiateVariableFont(f, {"wght": 400, "FILL": 0, "GRAD": 0, "opsz": 24})


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


def has_symbol(font, name):
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


def symbol_markup(font, name):
    """Solid white path of a symbol, optically sized and centred on its bbox in a 64 canvas."""
    gname = ligature_glyph(font, name)
    gs = font.getGlyphSet()
    bp = BoundsPen(gs)
    gs[gname].draw(bp)
    xmin, ymin, xmax, ymax = bp.bounds
    w, h = xmax - xmin, ymax - ymin
    aspect = w / h
    if aspect > 1.25:
        s = 30 / w                                   # wide
    elif aspect < 0.8:
        s = 26 / h                                   # tall
    else:
        s = (26 if _shape(font, gname, bp.bounds) == "round" else 24) / max(w, h)
    tx = 32 - (xmin + w / 2) * s
    ty = 32 + (ymin + h / 2) * s
    pen = SVGPathPen(gs)
    gs[gname].draw(TransformPen(pen, (s, 0, 0, -s, tx, ty)))
    return f'<path d="{pen.getCommands()}" fill="#ffffff"/>'


# ── dot-matrix letter fallback (shared/dotfont.js) ──────────────────────────
def load_dotfont():
    src = open(DOTFONT, encoding="utf-8").read()
    return {m.group(1): json.loads(m.group(2))
            for m in re.finditer(r'"(.)"\s*:\s*(\[[^\]]*\])', src)}


def dot_letter_markup(dots, ch):
    rows = dots.get(ch.upper()) or dots.get("?")
    pitch = 34 / 7                                     # 7 rows ≈ a tall glyph; dots stay legible at 22px
    r = pitch * 0.75 / 2                               # fuller dots than UI text so the letter survives 22px
    cols = len(rows[0])
    x0 = 32 - (cols - 1) * pitch / 2
    y0 = 32 - (len(rows) - 1) * pitch / 2
    return "".join(f'<circle cx="{x0 + c * pitch:.2f}" cy="{y0 + y * pitch:.2f}" r="{r:.2f}" fill="#ffffff"/>'
                   for y, row in enumerate(rows) for c, v in enumerate(row) if v == "#")


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


def same_family(a, b):
    a, b = a.lower(), b.lower()
    return a in b or b in a or a.split()[0] == b.split()[0]


def assign(font, entries):
    """desktop id → ('sym', name) | ('dot', letter); distinct across apps, shared within a family."""
    used, out, by_icon = set(), {}, {}

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
        if fam and e["icon"]:
            out[e["id"]] = out[fam["id"]]
        else:
            g = next((n for n in candidates(e) if n not in used), None)
            if g:
                used.add(g)
                out[e["id"]] = ("sym", g)
            else:
                letter = next((ch for ch in e["name"] if ch.isalnum()), "?")
                out[e["id"]] = ("dot", letter.upper())
        by_icon.setdefault(e["icon"], []).append(e)
    return out


def svg(inner):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">{inner}</svg>'


def build(theme_dir):
    font = load_font()
    dots = load_dotfont()
    entries = desktop_entries()
    glyphs = assign(font, entries)
    skip_names = non_app_icon_names()
    d = os.path.join(theme_dir, "scalable", "apps")
    os.makedirs(d, exist_ok=True)
    markup_cache, gmap = {}, {}
    report = {"symbol": [], "dot": [], "dock_icons": 0, "dock_skipped": set()}
    dock = {}                                   # icon name → glyph of its first (primary) entry
    order = sorted(entries, key=lambda e: (e["icon"].lower() not in e["id"].lower(), e["id"]))
    for e in order:
        kind, val = glyphs[e["id"]]
        key = (kind, val)
        if key not in markup_cache:
            markup_cache[key] = symbol_markup(font, val) if kind == "sym" else dot_letter_markup(dots, val)
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
            # glyph-only twin by icon name, for drawer items that only know the icon (window/runner results)
            with open(os.path.join(d, f"nothing-glyph-icon-{icon}.svg"), "w") as f:
                f.write(svg(inner))
    report["dock_icons"] = len(dock)
    report["dock_skipped"] = sorted(report["dock_skipped"])
    with open(os.path.join(theme_dir, "glyphmap.json"), "w") as f:
        json.dump(gmap, f, indent=1, sort_keys=True)
    return report
