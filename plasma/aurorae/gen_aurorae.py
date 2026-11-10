#!/usr/bin/env python3
"""Nothing Aurorae window decoration generator.

Black title bar, 1px hairline border, rounded top corners, soft shadow,
and dot-style buttons (close = Nothing red).
"""
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Nothing")
S = 18          # shadow padding
R = 12          # top corner radius
C = S + R       # corner piece size
BG = "#000000"

STATES = {
    # prefix: (border colour, shadow strength)
    "decoration": ("#2a2a2a", 0.55),
    "decoration-inactive": ("#1a1a1a", 0.35),
}


def shadow_alpha(d, strength):
    """Opacity of the shadow ring at distance d (1..S) outside the border."""
    t = 1 - (d - 0.5) / S
    return round(strength * t * t * 0.32, 4)


def bounds(x, y, w, h):
    # near-invisible rect so the element's bounding box is exactly the piece size
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#000" fill-opacity="0.002"/>'


def frame(prefix, border, strength, ox, oy):
    """SVG for the nine frame pieces of one state, placed at offset (ox, oy)."""
    out = []

    def piece(name, x, y, w, h, body):
        out.append(f'<g id="{prefix}-{name}" transform="translate({ox + x},{oy + y})">'
                   f'{bounds(0, 0, w, h)}{body}</g>')

    # rounded top corner; arc centre at (C, C); flip mirrors for the right side
    def corner(flip):
        b = []
        for d in range(1, S + 1):
            r = R + d - 0.5
            b.append(f'<path d="M {C - r},{C} A {r},{r} 0 0 1 {C},{C - r}" fill="none" '
                     f'stroke="#000" stroke-width="1" stroke-opacity="{shadow_alpha(d, strength)}"/>')
        b.append(f'<path d="M {C - R},{C} A {R},{R} 0 0 1 {C},{C - R} L {C},{C} Z" fill="{BG}"/>')
        b.append(f'<path d="M {C - R + 0.5},{C} A {R - 0.5},{R - 0.5} 0 0 1 {C},{C - R + 0.5}" '
                 f'fill="none" stroke="{border}" stroke-width="1"/>')
        tf = f'transform="matrix(-1,0,0,1,{C},0)"' if flip else ""
        return f'<g {tf}>{"".join(b)}</g>'

    piece("topleft", 0, 0, C, C, corner(False))
    piece("topright", C + 2, 0, C, C, corner(True))

    # top edge: 1px wide vertical strip (shadow, border row at y=S, fill below)
    b = [f'<rect x="0" y="{S - d}" width="1" height="1" fill="#000" fill-opacity="{shadow_alpha(d, strength)}"/>'
         for d in range(1, S + 1)]
    b.append(f'<rect x="0" y="{S}" width="1" height="1" fill="{border}"/>')
    b.append(f'<rect x="0" y="{S + 1}" width="1" height="{R - 1}" fill="{BG}"/>')
    piece("top", C, 0, 1, C, "".join(b))

    # left / right edges: 1px tall horizontal strips of width C
    def side(flip):
        if flip:   # fill | border at R-1 | shadow outward
            b = [f'<rect x="0" y="0" width="{R - 1}" height="1" fill="{BG}"/>',
                 f'<rect x="{R - 1}" y="0" width="1" height="1" fill="{border}"/>']
            b += [f'<rect x="{R - 1 + d}" y="0" width="1" height="1" fill="#000" '
                  f'fill-opacity="{shadow_alpha(d, strength)}"/>' for d in range(1, S + 1)]
        else:      # shadow outward | border at S | fill
            b = [f'<rect x="{S - d}" y="0" width="1" height="1" fill="#000" '
                 f'fill-opacity="{shadow_alpha(d, strength)}"/>' for d in range(1, S + 1)]
            b += [f'<rect x="{S}" y="0" width="1" height="1" fill="{border}"/>',
                  f'<rect x="{S + 1}" y="0" width="{R - 1}" height="1" fill="{BG}"/>']
        return "".join(b)

    piece("left", 0, C + 2, C, 1, side(False))
    piece("right", C + 2, C + 2, C, 1, side(True))
    piece("center", C, C + 2, 1, 1, f'<rect width="1" height="1" fill="{BG}"/>')

    # bottom edge and square bottom corners (height S + 1, border row at y=0)
    H = S + 1
    b = [f'<rect x="0" y="0" width="1" height="1" fill="{border}"/>']
    b += [f'<rect x="0" y="{d}" width="1" height="1" fill="#000" fill-opacity="{shadow_alpha(d, strength)}"/>'
          for d in range(1, S + 1)]
    piece("bottom", C, C + 4, 1, H, "".join(b))

    def bcorner(flip):
        b = []
        for d in range(1, S + 1):   # rounded shadow around the square corner point (S, 0)
            rr = d - 0.5
            b.append(f'<path d="M {S - rr},0 A {rr},{rr} 0 0 0 {S},{rr} L {C},{rr}" fill="none" '
                     f'stroke="#000" stroke-width="1" stroke-opacity="{shadow_alpha(d, strength)}"/>')
        b.append(f'<rect x="{S}" y="0" width="{R}" height="1" fill="{border}"/>')
        tf = f'transform="matrix(-1,0,0,1,{C},0)"' if flip else ""
        return f'<g {tf}>{"".join(b)}</g>'

    piece("bottomleft", 0, C + 4, C, H, bcorner(False))
    piece("bottomright", C + 2, C + 4, C, H, bcorner(True))
    return "".join(out)


def maximized(prefix, ox, oy):
    out = []
    for i, n in enumerate(["topleft", "top", "topright", "left", "center", "right",
                           "bottomleft", "bottom", "bottomright"]):
        x, y = ox + (i % 3) * 2, oy + (i // 3) * 2
        out.append(f'<g id="{prefix}-{n}" transform="translate({x},{y})">'
                   f'<rect width="1" height="1" fill="{BG}"/></g>')
    return "".join(out)


def write_decoration():
    parts, ox = [], 0
    for prefix, (border, strength) in STATES.items():
        parts.append(frame(prefix, border, strength, ox, 0))
        ox += 2 * C + 10
    parts.append(maximized("decoration-maximized", ox, 0))
    parts.append(maximized("decoration-maximized-inactive", ox + 10, 0))
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{ox + 20}" height="{2 * C + 30}">'
           + "".join(parts) + "</svg>")
    with open(os.path.join(OUT, "decoration.svg"), "w") as f:
        f.write(svg)


# ---------------------------------------------------------------- buttons
BW, BH = 24, 32
GLYPHS = {
    "close": '<path d="M -2.6,-2.6 L 2.6,2.6 M 2.6,-2.6 L -2.6,2.6"/>',
    "minimize": '<path d="M -3,0 L 3,0"/>',
    "maximize": '<path d="M -3,0 L 3,0 M 0,-3 L 0,3"/>',
    "restore": '<path d="M -2.6,-2.6 L 2.6,2.6 M 2.6,-2.6 L -2.6,2.6"/>',
    "alldesktops": '<circle r="1.6" fill="#000" stroke="none"/>',
    "keepabove": '<path d="M -3,1.5 L 0,-1.5 L 3,1.5"/>',
    "keepbelow": '<path d="M -3,-1.5 L 0,1.5 L 3,-1.5"/>',
    "shade": '<path d="M -3,-1 L 3,-1"/>',
    "help": '<circle r="1.2" fill="#000" stroke="none"/>',
}
GLYPHS["restore"] = '<path d="M -3,0 L 3,0"/>' + '<circle r="3.2"/>'


def button(name):
    main = "#d71921" if name == "close" else "#8e8e8e"
    hover = "#ff2a33" if name == "close" else "#ffffff"
    states = [  # (state, colour, dot diameter, show glyph)
        ("active", main, 10, False),
        ("hover", hover, 16, True),
        ("pressed", hover, 13, True),
        ("inactive", "#2e2e2e", 10, False),
        ("deactivated", "#1c1c1c", 10, False),
    ]
    parts = []
    for i, (st, col, size, glyph) in enumerate(states):
        cx, cy = BW / 2, BH / 2
        g = (f'<g transform="translate({cx},{cy})" stroke="#000" stroke-width="1.5" '
             f'stroke-linecap="round" fill="none">{GLYPHS[name]}</g>') if glyph else ""
        parts.append(f'<g id="{st}-center" transform="translate({i * (BW + 4)},0)">'
                     f'{bounds(0, 0, BW, BH)}<circle cx="{cx}" cy="{cy}" r="{size / 2}" fill="{col}"/>{g}</g>')
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{len(states) * (BW + 4)}" height="{BH}">'
           + "".join(parts) + "</svg>")
    with open(os.path.join(OUT, f"{name}.svg"), "w") as f:
        f.write(svg)


RC = f"""[General]
ActiveTextColor=255,255,255
InactiveTextColor=94,94,94
ActiveFocusedTabColor=255,255,255
ActiveUnfocusedTabColor=142,142,142
InactiveFocusedTabColor=142,142,142
InactiveUnfocusedTabColor=94,94,94
Shadow=true
Animation=160
TitleAlignment=Center
TitleVerticalAlignment=Center

[Layout]
BorderLeft=1
BorderRight=1
BorderBottom=1
BorderTop=1
TitleEdgeTop=0
TitleEdgeBottom=0
TitleEdgeLeft=10
TitleEdgeRight=10
TitleEdgeTopMaximized=0
TitleEdgeBottomMaximized=0
TitleEdgeLeftMaximized=10
TitleEdgeRightMaximized=10
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight={BH}
ButtonWidth={BW}
ButtonHeight={BH}
ButtonSpacing=0
ButtonMarginTop=0
ExplicitButtonSpacer=8
PaddingTop={S}
PaddingBottom={S}
PaddingLeft={S}
PaddingRight={S}
"""

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    write_decoration()
    for n in GLYPHS:
        button(n)
    with open(os.path.join(OUT, "Nothingrc"), "w") as f:
        f.write(RC)
    with open(os.path.join(OUT, "metadata.desktop"), "w") as f:
        f.write("[Desktop Entry]\nName=Nothing\nComment=Black, hairline, dot buttons\n"
                "X-KDE-PluginInfo-Name=Nothing\nX-KDE-PluginInfo-License=GPL\n")
    print("wrote", OUT)
