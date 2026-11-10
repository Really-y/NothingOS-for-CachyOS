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


def frame_svg(r, fill, border, prefixes=("",)):
    """Nine-slice frame with radius r. Each prefix gets its own copy."""
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
            rb = r - 0.5
            return (f'<path d="M {cx + sx * r},{cy} A {r},{r} 0 0 {sweep} {cx},{cy + sy * r} '
                    f'L {cx},{cy} Z" fill="{fill}"/>'
                    f'<path d="M {cx + sx * rb},{cy} A {rb},{rb} 0 0 {sweep} {cx},{cy + sy * rb}" '
                    f'fill="none" stroke="{border}" stroke-width="1"/>')

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
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{2 * c + 10}" height="{oy}">'
            + "".join(parts) + "</svg>")


FILES = {
    # path: (radius, fill, border, prefixes)
    "dialogs/background.svg": (30, "#000000", "#2a2a2a", ("",)),
    "widgets/background.svg": (24, "#111111", "#1f1f1f", ("",)),
    "widgets/tooltip.svg": (12, "#1c1c1c", "#2a2a2a", ("",)),
    # floating dock = card with hairline; docked top bar = pure black, no line
    "widgets/panel-background.svg": (22, "#111111", "#2a2a2a",
                                     ("", ("north", "#000000", "#000000"), "south", "east", "west")),
    "widgets/plasmoidheading.svg": (20, "#111111", "#111111", ("header", "footer")),
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
    for path, (r, fill, border, prefixes) in FILES.items():
        svg = frame_svg(r, fill, border, prefixes)
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
