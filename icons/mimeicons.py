"""Nothing mimetype, device and small place icons (same Material glyph rules as appicons.py).

  scalable/mimetypes  ≥25px  #1a1a1a rounded page (no border) + white glyph, wght 600
  22/mimetypes        19–24  same page, glyph wght 600/700, pixel-snapped
  16/mimetypes        ≤18    same page, glyph wght 600/700, pixel-snapped
  scalable/devices    ≥25px  #1a1a1a disc + white glyph (drives, removable media)
  22|16/devices              bare white glyph
  22|16/places               bare white glyph (no folder body: readable in Dolphin's Places)

Every mimetype icon name the parent themes ship (Papirus/Breeze) is covered, so KDE never falls
through to a colourful parent icon for a specific type (image-png, application-pdf, …).
"""
import os
import re

import appicons

PARENT_MIME_DIRS = ["/usr/share/icons/Papirus/64x64/mimetypes", "/usr/share/icons/breeze/mimetypes/32",
                    "/usr/share/icons/breeze-dark/mimetypes/32", "/usr/share/icons/hicolor/scalable/mimetypes"]

# name regex → Material symbol; first match wins
MIME_RULES = [(re.compile(p), s) for p, s in [
    (r"^inode-", None),                                           # folders stay the Nothing folder
    (r"pdf", "picture_as_pdf"),
    (r"x-iso9660|cd-image|disk-image|x-raw-disk|x-apple-diskimage", "album"),
    (r"\b(x-)?(deb|rpm|flatpak|snap|appimage|apk|x-arch|x-alpm|pkg)|package", "package_2"),
    (r"zip|tar|archive|compress|7z|rar|gzip|bzip|-xz|zstd|lzma|lz4|lzip|cpio|arj|lha|lzh|cab|ace|x-ar$|stuffit", "folder_zip"),
    (r"spreadsheet|excel|ms-works|\bcsv|text-csv|x-gnumeric|sheet|calc", "table_chart"),
    (r"presentation|powerpoint|impress|slide|keynote", "slideshow"),
    (r"epub|x-fictionbook|mobipocket|ebook|comicbook|x-cb", "menu_book"),
    (r"font", "font_download"),
    (r"-rom$|-rom\b|x-mame|x-nes|x-snes|x-gba|x-n64|x-genesis|x-sega|x-psx|x-nintendo", "sports_esports"),
    (r"vhd|vdi|vmdk|vmware|virtualbox|ovf|qcow|x-hda", "hard_drive"),
    (r"x509|cert|pgp|gpg|pkcs|keepass|keyring|password|encrypted|x-java-keystore|spkac", "key"),
    (r"openvpn|wireguard|vpn", "vpn_key"),
    (r"playlist|mpegurl|x-cue|scpls|xspf", "queue_music"),
    (r"application-ogg|realmedia|mplayer|media-audio|x-content-audio", "music_note"),
    (r"x-content-video|x-content-", "album"),
    (r"drawing|draw|dxf|dwg|afdesigner|x-krita|kicad|x-step|cad|x-xcf|inkscape|sketch|figma", "design_services"),
    (r"formula|math|wolfram|x-kig|mathematica|x-maple", "functions"),
    (r"database|ms-access|kexi|x-sqlite|sql", "database"),
    (r"calendar|icalendar|ics|todo|vcalendar|x-vnd\.akonadi\.calendar", "calendar_month"),
    (r"message|rmail|tnef|vcard|contact|mbox|x-mimearchive|eml", "mail"),
    (r"gpx|kml|kmz|marble|oziexplorer|igc|qgis|shp|geojson|osm", "map"),
    (r"mswinurl|x-url|webloc|internet-shortcut|-link$", "link"),
    (r"addon|extension|plugin|x-kns|x-xpinstall|crx", "extension"),
    (r"xl[st]x?$|\.xls|ods|numbers", "table_chart"),
    (r"postscript|dvi|troff|x-man|texinfo", "article"),
    (r"\.docx?$|\.dot$|-dot$|oasis-text|text-template|libreoffice-text|openoffice4-text|wps-office\.(doc|wps)", "article"),
    (r"\.pptx?$|\.potx?$|visio|mxfile|publisher|scribus", "slideshow"),
    (r"application-java|dart|coffeescript|x-asp|wasm|relaxng|x-ocaml|x-haskell|x-erlang", "code"),
    (r"bitwig|ardour|audacity|lmms|x-reaper|x-flp|shorten", "music_note"),
    (r"squashfs|efi\.(img|iso)|x-adf|amiga-disk", "album"),
    (r"jar$|x-jar|x-wine|cpl$|x-ms-shortcut|x-msdownload", "deployed_code"),
    (r"^image-", "image"),
    (r"^video-|x-matroska|x-flv|mp4|webm|quicktime|x-ms-asf|x-mpegurl", "movie"),
    (r"^audio-|x-ogg|x-flac|x-wav|mpegurl|x-mpeg|vorbis", "music_note"),
    (r"x-desktop", "apps"),
    (r"shellscript|x-sh$|bash|zsh|fish|csh|x-perl|x-ruby|x-script|x-tcl|x-awk|powershell|bat$|x-ms-dos", "terminal"),
    (r"executable|sharedlib|x-object|x-elf|x-core|x-dosexec|ms-dos-executable|x-msi|x-java-archive|x-pie", "deployed_code"),
    (r"json|yaml|toml|x-ini|x-config|text-x-csv", "data_object"),
    (r"html|xhtml", "html"),
    (r"css|scss|sass|less", "css"),
    (r"markdown|text-x-rst|asciidoc", "markdown"),
    (r"javascript|typescript|ecmascript", "javascript"),
    (r"text-x-|source|x-python|x-java|x-rust|x-go|x-php|x-csrc|x-chdr|xml|x-qml|x-makefile|x-cmake|x-patch|x-diff|sql|x-lua|x-kotlin|x-swift|x-dart", "code"),
    (r"document|word|writer|opendocument\.text|rtf|x-tex|abiword|kword|pages|msword", "article"),
    (r"x-office|^text-|plain", "description"),
    (r".", "draft"),                                              # octet-stream, unknown, everything else
]]

DEVICES = {
    "drive-harddisk": "hard_drive", "drive-harddisk-root": "hard_drive", "drive-harddisk-system": "hard_drive",
    "drive-harddisk-ieee1394": "hard_drive", "drive-harddisk-solidstate": "hard_drive_2", "drive-multidisk": "storage",
    "drive-virtual": "hard_drive_2", "drive-removable-media": "usb", "drive-removable-media-usb": "usb",
    "drive-removable-media-usb-pendrive": "usb", "media-removable": "eject", "drive-optical": "album",
    "media-optical": "album", "media-optical-audio": "album", "media-optical-blu-ray": "album",
    "media-optical-data": "album", "media-optical-dvd": "album", "media-optical-dvd-video": "album",
    "media-optical-mixed-cd": "album", "media-optical-recordable": "album", "media-optical-video": "album",
    "media-cdrom": "album", "media-flash": "sd_card", "media-flash-memory-stick": "sd_card",
    "media-flash-sd-mmc": "sd_card", "media-flash-smart-media": "sd_card", "media-memory": "sd_card",
    "media-memory-sd": "sd_card", "media-floppy": "save", "media-floppy-3_5": "save", "media-tape": "storage",
}


# wide lettering glyphs turn into a smudge at ≤22px: use the plain family glyph there
SMALL_SWAP = {"html": "code", "markdown": "description", "css": "code", "javascript": "code",
              "picture_as_pdf": "contract"}          # the "PDF" lettering is a smudge at 16–22px; still white, never red


def mime_names():
    names = set()
    for d in PARENT_MIME_DIRS:
        if os.path.isdir(d):
            names |= {f[:-4] for f in os.listdir(d) if f.endswith((".svg", ".png")) and not f.endswith("-symbolic.svg")}
    names |= {"application-octet-stream", "unknown", "text-plain", "text-x-generic", "image-x-generic",
              "video-x-generic", "audio-x-generic", "package-x-generic", "application-x-executable",
              "application-x-shellscript", "x-office-document", "x-office-spreadsheet", "x-office-presentation"}
    return sorted(names)


def mime_symbol(name):
    for rx, sym in MIME_RULES:
        if rx.search(name):
            return sym
    return "draft"


def page(c):
    """#1a1a1a rounded page, no border; proportions shared by all sizes."""
    if c == 64:
        return '<rect x="12" y="5" width="40" height="54" rx="7" fill="#1a1a1a"/>'
    if c == 22:
        return '<rect x="4" y="1" width="14" height="20" rx="3" fill="#1a1a1a"/>'
    return '<rect x="2.5" y="0.5" width="11" height="15" rx="2.5" fill="#1a1a1a"/>'


def build(theme_dir, places):
    big = appicons.load_font(600, 24)
    small = appicons.load_font(600, 20)
    bold = appicons.load_font(700, 20)
    cache = {}

    def glyph(sym, c, box, snap):
        f = big if c == 64 else (bold if sym in appicons.SMALL_BOLD or c == 16 else small)
        k = (sym, c, box)
        if k not in cache:
            cache[k] = appicons.glyph_markup(f, sym, c=c, disc_d=box, snap=snap)
        return cache[k]

    def write(sub, name, inner, c):
        d = os.path.join(theme_dir, sub)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, name + ".svg"), "w") as fh:
            fh.write(appicons.svg(inner, c))

    report = {"mimetypes": 0, "devices": 0, "places_small": 0, "by_symbol": {}}
    # mimetypes: page + glyph (glyph box = page width-ish so 48–58% of it is the ink)
    for n in mime_names():
        sym = mime_symbol(n)
        if not sym:
            continue
        sym_s = SMALL_SWAP.get(sym, sym)
        write("scalable/mimetypes", n, page(64) + glyph(sym, 64, 48, False), 64)
        write("22/mimetypes", n, page(22) + glyph(sym_s, 22, 21, True), 22)
        write("16/mimetypes", n, page(16) + glyph(sym_s, 16, 16, True), 16)
        report["mimetypes"] += 1
        report["by_symbol"][sym] = report["by_symbol"].get(sym, 0) + 1
    # devices: disc + glyph large, bare glyph small
    for n, sym in DEVICES.items():
        write("scalable/devices", n, f'<circle cx="32" cy="32" r="30" fill="{appicons.DISC}"/>' + glyph(sym, 64, 60, False), 64)
        write("22/devices", n, glyph(sym, 22, 30, True), 22)
        write("16/devices", n, glyph(sym, 16, 24, True), 16)
        report["devices"] += 1
    # places: bare glyph at 16/22 (the folder body + tiny glyph is unreadable there)
    for names, sym in places.items():
        sym = "folder" if sym is None else ("folder_open" if sym == "__open__" else sym)
        for n in names:
            write("22/places", n, glyph(sym, 22, 30, True), 22)
            write("16/places", n, glyph(sym, 16, 24, True), 16)
            report["places_small"] += 1
    return report


INDEX_DIRS = """
[16/places]
Size=16
MinSize=8
MaxSize=18
Type=Scalable
Context=Places

[22/places]
Size=22
MinSize=19
MaxSize=24
Type=Scalable
Context=Places

[scalable/devices]
Size=64
MinSize=25
MaxSize=512
Type=Scalable
Context=Devices

[22/devices]
Size=22
MinSize=19
MaxSize=24
Type=Scalable
Context=Devices

[16/devices]
Size=16
MinSize=8
MaxSize=18
Type=Scalable
Context=Devices

[scalable/mimetypes]
Size=64
MinSize=25
MaxSize=512
Type=Scalable
Context=MimeTypes

[22/mimetypes]
Size=22
MinSize=19
MaxSize=24
Type=Scalable
Context=MimeTypes

[16/mimetypes]
Size=16
MinSize=8
MaxSize=18
Type=Scalable
Context=MimeTypes
"""
DIRS = "16/places,22/places,scalable/devices,22/devices,16/devices,scalable/mimetypes,22/mimetypes,16/mimetypes"
