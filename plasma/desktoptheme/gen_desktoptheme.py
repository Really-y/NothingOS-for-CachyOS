#!/usr/bin/env python3
"""Nothing Plasma desktop theme: solid rounded cards with hairline border.

Only the frames are overridden; everything else falls back to Breeze
('default'), which already follows the Nothing colour scheme.
"""
import os
import shutil

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "Nothing")
COLORS = os.path.join(HERE, "..", "colors", "Nothing.colors")


def frame_svg(r, fill, border, prefixes=("",), hints=()):
    """Nine-slice frame with radius r. Each prefix gets its own copy.

    hints: extra invisible elements (id, w, h) such as "base-hint-left-margin" (its width is
    the content margin, decoupled from the corner size) or "hint-scrollbar-size".
    """
    parts, oy = [], 0
    c, gap = r, 2
    base_fill, base_border = fill, border
    for p in prefixes:
        # a prefix may be (name, fill, border) to override colours for that edge
        fill, border = base_fill, base_border
        if isinstance(p, tuple):
            p, fill, border = p
        pre = f"{p}-" if p else ""

        def g(name, x, y, w, h, body):
            parts.append(f'<g id="{pre}{name}" transform="translate({x},{y + oy})">'
                         f'<rect width="{w}" height="{h}" fill="#000" fill-opacity="0.002"/>{body}</g>')

        def corner(sx, sy):
            # quarter disk; its centre sits at the inner corner of the piece
            cx, cy = (c if sx < 0 else 0), (c if sy < 0 else 0)
            sweep = 1 if sx * sy > 0 else 0
            # hairline = filled 1px ring, not a stroke: a stroke grows the element's bounding
            # box by half its width, KSvg then squeezes the corner into its slot and leaves a
            # translucent seam between corner and edge pieces.
            ri = r - 1
            return (f'<path d="M {cx + sx * r},{cy} A {r},{r} 0 0 {sweep} {cx},{cy + sy * r} '
                    f'L {cx},{cy} Z" fill="{fill}"/>'
                    f'<path d="M {cx + sx * r},{cy} A {r},{r} 0 0 {sweep} {cx},{cy + sy * r} '
                    f'L {cx},{cy + sy * ri} A {ri},{ri} 0 0 {1 - sweep} {cx + sx * ri},{cy} Z" '
                    f'fill="{border}"/>')

        x2 = c + 2 * gap + 1
        g("topleft", 0, 0, c, c, corner(-1, -1))
        g("top", c + gap, 0, 1, c, f'<rect width="1" height="{c}" fill="{fill}"/>'
                                   f'<rect width="1" height="1" fill="{border}"/>')
        g("topright", x2, 0, c, c, corner(1, -1))
        g("left", 0, c + gap, c, 1, f'<rect width="{c}" height="1" fill="{fill}"/>'
                                    f'<rect width="1" height="1" fill="{border}"/>')
        g("center", c + gap, c + gap, 1, 1, f'<rect width="1" height="1" fill="{fill}"/>')
        g("right", x2, c + gap, c, 1, f'<rect width="{c}" height="1" fill="{fill}"/>'
                                      f'<rect x="{c - 1}" width="1" height="1" fill="{border}"/>')
        g("bottomleft", 0, x2, c, c, corner(-1, 1))
        g("bottom", c + gap, x2, 1, c, f'<rect width="1" height="{c}" fill="{fill}"/>'
                                       f'<rect y="{c - 1}" width="1" height="1" fill="{border}"/>')
        g("bottomright", x2, x2, c, c, corner(1, 1))
        oy += 3 * c + 3 * gap + 4
    hx = 0
    for hid, w, h in hints:
        parts.append(f'<rect id="{hid}" x="{hx}" y="{oy}" width="{w}" height="{h}" '
                     f'fill="#000" fill-opacity="0"/>')
        hx += max(w, 1) + 2
    if hints:
        oy += max(h for _, _, h in hints) + 2
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{max(2 * c + 10, hx)}" height="{oy}">'
            + "".join(parts) + "</svg>")


def margins(prefix, left, top, right, bottom, kind="margin"):
    """hint-{left,top,right,bottom}-{margin|inset} elements for one prefix (0 -> 0.001 like Breeze)."""
    z = lambda v: v or 0.001
    pre = f"{prefix}-" if prefix else ""
    return ((f"{pre}hint-left-{kind}", z(left), 1), (f"{pre}hint-top-{kind}", 1, z(top)),
            (f"{pre}hint-right-{kind}", z(right), 1), (f"{pre}hint-bottom-{kind}", 1, z(bottom)))


FILES = {
    # path: (radius, fill, border, prefixes[, hints])
    "dialogs/background.svg": (30, "#000000", "#2a2a2a", ("",)),
    "widgets/background.svg": (24, "#111111", "#1f1f1f", ("",)),
    "widgets/tooltip.svg": (12, "#1c1c1c", "#2a2a2a", ("",)),
    # docked top bar = pure black, no line. Bottom ("south") = the dock: the panel itself is
    # invisible and org.nothing.dock draws its own pill; mask-south keeps the input/blur region.
    "widgets/panel-background.svg": (22, "#111111", "#2a2a2a",
                                     ("", ("north", "#000000", "#000000"), ("south", "none", "none"),
                                      ("mask-south", "#000000", "#000000"), "east", "west")),
    "widgets/plasmoidheading.svg": (20, "#111111", "#111111", ("header", "footer")),
    # PlasmaComponents3.TextField (KRunner query, every plasmoid search field): borderless
    # #1a1a1a pill. Corners 15 = half of the usual 30px field (KSvg shrinks them on shorter
    # fields); content margins come from the hints, not the corner size. hover/focus are
    # same-size overlays (0 margins) drawn over base: no glow ring, no red focus colour.
    "widgets/lineedit.svg": (15, "#1a1a1a", "#1a1a1a",
                             ("base", ("hover", "#1f1f1f", "#1f1f1f"), ("focus", "#222222", "#222222")),
                             margins("base", 14, 6, 14, 6) + margins("hover", 0, 0, 0, 0)
                             + margins("focus", 0, 0, 0, 0) + (("hint-focus-over-base", 1, 1),)),
    # Row highlight (PlasmaExtras.Highlight, MenuItem, KRunner/Milou results, clipboard,
    # calendar). Plasma's text stays textColor (white) on "hover"/"normal" and switches to
    # highlightedTextColor (black) only on "selected*" (pressed) -> hover dark, selected white.
    "widgets/viewitem.svg": (12, "#1a1a1a", "#1a1a1a",
                             ("normal", "hover", ("selected", "#ffffff", "#ffffff"),
                              ("selected+hover", "#ffffff", "#ffffff")),
                             sum((margins(p, 5, 5, 5, 5) for p in
                                  ("normal", "hover", "selected", "selected+hover")), ())),
    # Slim rounded thumb, no groove (backgrounds transparent), no separator hint.
    "widgets/scrollbar.svg": (3, "#2a2a2a", "#2a2a2a",
                              (("background-vertical", "none", "none"),
                               ("background-horizontal", "none", "none"),
                               "slider", ("mouseover-slider", "#5e5e5e", "#5e5e5e")),
                              (("hint-scrollbar-size", 6, 6),)
                              + margins("slider", 2, 2, 2, 2, "inset")
                              + margins("mouseover-slider", 2, 2, 2, 2, "inset")
                              + margins("background-vertical", 0, 0, 0, 0, "inset")
                              + margins("background-horizontal", 0, 0, 0, 0, "inset")),
}

# Plain (non-frame) SVGs. widgets/line = separators (Milou/KRunner section lines, popups):
# a #2a2a2a hairline instead of Breeze's text-coloured line.
PLAIN = {
    "widgets/line.svg": ('<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8">'
                         '<rect id="horizontal-line" x="0" y="0" width="4" height="1" fill="#2a2a2a"/>'
                         '<rect id="vertical-line" x="6" y="0" width="1" height="4" fill="#2a2a2a"/>'
                         '</svg>'),
}

METADATA = """{
    "KPlugin": {
        "Authors": [{"Name": "NothingOS for CachyOS"}],
        "Description": "Black, solid cards, hairlines",
        "Id": "Nothing",
        "License": "GPL-2.0-or-later",
        "Name": "Nothing",
        "Version": "1.0"
    },
    "X-Plasma-API-Minimum-Version": "6.0"
}
"""

if __name__ == "__main__":
    shutil.rmtree(OUT, ignore_errors=True)
    svgs = {path: frame_svg(r, fill, border, prefixes, *hints)
            for path, (r, fill, border, prefixes, *hints) in FILES.items()}
    svgs.update(PLAIN)
    for path, svg in svgs.items():
        for sub in ("", "solid/", "translucent/"):
            dst = os.path.join(OUT, sub + path)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            with open(dst, "w") as f:
                f.write(svg)
    with open(os.path.join(OUT, "metadata.json"), "w") as f:
        f.write(METADATA)
    shutil.copy(COLORS, os.path.join(OUT, "colors"))
    with open(os.path.join(OUT, "plasmarc"), "w") as f:
        f.write("[ContrastEffect]\nenabled=false\n\n[BlurBehindEffect]\nenabled=false\n\n"
                "[AdaptiveTransparency]\nenabled=false\n")
    print("wrote", OUT)
