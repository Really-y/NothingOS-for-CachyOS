#!/usr/bin/env python3
"""Nothing icon theme: monochrome folders/places + app icons (appicons.py), inherits Papirus-Dark.

Folder glyphs are real vector paths pulled out of Material Symbols Rounded
(instanced at a thin weight) so they match the rest of the UI.
"""
import os
import shutil

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, "..", "fonts", "MaterialSymbolsRounded.ttf")
OUT = os.path.join(HERE, "Nothing")

# icon name(s) -> material symbol (None = plain folder)
PLACES = {
    ("folder", "inode-directory", "folder-blue", "folder-grey", "folder-black"): None,
    ("folder-open", "folder-drag-accept"): "__open__",
    ("folder-documents", "folder-documents-open"): "description",
    ("folder-download", "folder-downloads", "folder-download-open"): "download",
    ("folder-music", "folder-music-open", "folder-sound"): "music_note",
    ("folder-pictures", "folder-pictures-open", "folder-image", "folder-photo"): "image",
    ("folder-videos", "folder-video", "folder-videos-open"): "movie",
    ("folder-desktop", "user-desktop"): "desktop_windows",
    ("folder-templates", "folder-templates-open"): "content_copy",
    ("folder-publicshare", "folder-public", "folder-publicshare-open"): "share",
    ("folder-development", "folder-code", "folder-projects", "folder-script"): "code",
    ("folder-git", "folder-github", "folder-gitlab"): "commit",
    ("folder-cloud", "folder-nextcloud", "folder-dropbox", "folder-google-drive", "folder-onedrive"): "cloud",
    ("folder-games",): "sports_esports",
    ("folder-recent", "document-open-recent"): "schedule",
    ("folder-favorites", "folder-important"): "favorite",
    ("folder-network", "folder-remote", "network-workgroup"): "lan",
    ("folder-locked", "folder-private", "folder-encrypted"): "lock",
    ("folder-backup",): "history",
    ("folder-books", "folder-notes"): "menu_book",
    ("folder-mail",): "mail",
    ("folder-print",): "print",
    ("user-home", "folder-home"): "home",
    ("user-trash",): "delete",
    ("user-trash-full",): "delete_forever",
}


def load_font():
    f = TTFont(FONT)
    return instancer.instantiateVariableFont(f, {"wght": 300, "FILL": 0, "GRAD": 0, "opsz": 24})


def ligature_glyph(font, name):
    """Resolve a Material Symbols ligature (e.g. 'home') to its glyph name."""
    cmap = font.getBestCmap()
    seq = [cmap[ord(c)] for c in name]
    for lookup in font["GSUB"].table.LookupList.Lookup:
        for st in lookup.SubTable:
            if lookup.LookupType == 7:
                st = st.ExtSubTable
            ligs = getattr(st, "ligatures", None)
            if not ligs:
                continue
            for lig in ligs.get(seq[0], []):
                if lig.Component == seq[1:]:
                    return lig.LigGlyph
    raise KeyError(name)


def glyph_path(font, name, x, y, size):
    """SVG path of a symbol drawn in a size x size box at (x, y)."""
    gs = font.getGlyphSet()
    upm = font["head"].unitsPerEm
    s = size / upm
    pen = SVGPathPen(gs)
    # Material glyphs sit in [0, upm] horizontally and [-descent .. upm-descent] vertically;
    # their visual box is y in [-0.125*upm, 0.875*upm] → baseline at 0.875 of the box.
    gs[ligature_glyph(font, name)].draw(TransformPen(pen, (s, 0, 0, -s, x, y + size * 0.875)))
    return pen.getCommands()


def folder_svg(font, symbol, open_=False):
    back = ('<path d="M6 14a5 5 0 0 1 5-5h13.5a4 4 0 0 1 2.9 1.2L31 14h22a5 5 0 0 1 5 5v31a5 5 0 0 1-5 5'
            'H11a5 5 0 0 1-5-5z" fill="#1a1a1a"/>')
    if open_:
        front = ('<path d="M4.5 25a4 4 0 0 1 3.9-3.1h48.2a3 3 0 0 1 2.9 3.7l-5.2 26.2A5 5 0 0 1 49.4 56'
                 'H11a5 5 0 0 1-4.9-4z" fill="#2c2c2c" stroke="#3a3a3a" stroke-width="0.8"/>')
    else:
        front = '<rect x="6" y="20" width="52" height="35" rx="5" fill="#2a2a2a" stroke="#383838" stroke-width="0.8"/>'
    glyph = ""
    if symbol and symbol != "__open__":
        glyph = f'<path d="{glyph_path(font, symbol, 22, 27.5, 20)}" fill="#ffffff"/>'
    dot = '<circle cx="51" cy="26.5" r="1.6" fill="#d71921"/>' if symbol == "favorite" else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'
            f'{back}{front}{glyph}{dot}</svg>')


def trash_svg(font, symbol):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'
            f'<circle cx="32" cy="32" r="26" fill="#1c1c1c" stroke="#383838" stroke-width="0.8"/>'
            f'<path d="{glyph_path(font, symbol, 18, 18, 28)}" fill="#ffffff"/></svg>')


INDEX = """[Icon Theme]
Name=Nothing
Comment=Monochrome Nothing places and app icons on top of Papirus-Dark
Inherits=Papirus-Dark,breeze-dark,hicolor
Example=folder
Directories=scalable/places,scalable/apps,22/apps

[scalable/places]
Size=64
MinSize=16
MaxSize=512
Type=Scalable
Context=Places

[scalable/apps]
Size=64
MinSize=25
MaxSize=512
Type=Scalable
Context=Applications

[22/apps]
Size=22
MinSize=16
MaxSize=24
Type=Scalable
Context=Applications
"""

if __name__ == "__main__":
    font = load_font()
    shutil.rmtree(OUT, ignore_errors=True)
    d = os.path.join(OUT, "scalable", "places")
    os.makedirs(d)
    for names, sym in PLACES.items():
        for n in names:
            svg = trash_svg(font, sym) if n.startswith("user-trash") else folder_svg(font, sym, sym == "__open__")
            with open(os.path.join(d, n + ".svg"), "w") as f:
                f.write(svg)
    with open(os.path.join(OUT, "index.theme"), "w") as f:
        f.write(INDEX)
    print("wrote", len(os.listdir(d)), "place icons to", OUT)
    import appicons
    rep = appicons.build(OUT)
    nb = sum("brand:" in l for l in rep["symbol"])
    print(f"apps: {nb} brand marks, {len(rep['symbol']) - nb} Material symbols, {len(rep['dot'])} dot-letter fallbacks, "
          f"{rep['dock_icons']} dock icons; not themed in the dock: {', '.join(rep['dock_skipped'])}")
    for line in rep["dot"]:
        print("  dot:", line)
