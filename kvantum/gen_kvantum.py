#!/usr/bin/env python3
"""Nothing Kvantum theme generator  ->  kvantum/Nothing/{Nothing.svg,Nothing.kvconfig}

Qt Widgets styled as Nothing OS: pure black, flat fills (no hairlines, no
gradients, no shadows), pill buttons, white selection with black text, dot
checkboxes/radios, dot-row progress bars, slim round scrollbars.

Every "box" element is the usual Kvantum nine-slice (interior + 4 edges +
4 corners).  Corners are quarter discs, edges/interior plain rects of the same
fill, so a frame of size N px gives a rounded rect of radius N; with
frame.expansion the radius grows up to half the widget height (= pill).
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "Nothing")

# ── palette (ARCHITECTURE.md) ────────────────────────────────────────────
BLACK = "#000000"
S1 = "#111111"     # menus, cards
S2 = "#1a1a1a"     # buttons, fields
S3 = "#262626"     # hover
S4 = "#2a2a2a"     # focus / thumb
S5 = "#3a3a3a"
WHITE = "#ffffff"
WHITE2 = "#e6e6e6"  # white, pressed
GREY = "#8e8e8e"
DIM = "#5e5e5e"
RED = "#d71921"
NONE = None        # transparent element (exists, draws nothing)

# Kvantum hard limits for item views (checked in its source): [ItemView] frames are capped at 6px
# (ThemeConfig.cpp) and frame.expansion is clamped to h/2 while expansion needs min(w,h) <= it,
# so view selections can never be pills nor have radius > 6px.  6px radius, no inset, is the max.
STATES = ("normal", "focused", "pressed", "toggled", "disabled")

svg = []
_cursor = [0, 0]


def _place(w, h):
    """Simple shelf packer so elements never overlap in the SVG canvas."""
    x, y = _cursor
    if x + w > 2000:
        x, y = 0, y + 120
    _cursor[0], _cursor[1] = x + w + 10, y
    return x, y


def _fill(c):
    if c is None:
        return 'fill="#000" fill-opacity="0"'
    if ";" in c:  # "colour;opacity"
        col, op = c.split(";")
        return f'fill="{col}" fill-opacity="{op}"'
    return f'fill="{c}"'


def box(name, state, fill, u=10):
    """Nine-slice rounded box; u = SVG size of one corner piece."""
    ox, oy = _place(3 * u, 3 * u)
    f = _fill(fill)
    p = f"{name}-{state}"
    svg.append(f'<rect id="{p}" x="{ox+u}" y="{oy+u}" width="{u}" height="{u}" {f}/>')
    svg.append(f'<rect id="{p}-top" x="{ox+u}" y="{oy}" width="{u}" height="{u}" {f}/>')
    svg.append(f'<rect id="{p}-bottom" x="{ox+u}" y="{oy+2*u}" width="{u}" height="{u}" {f}/>')
    svg.append(f'<rect id="{p}-left" x="{ox}" y="{oy+u}" width="{u}" height="{u}" {f}/>')
    svg.append(f'<rect id="{p}-right" x="{ox+2*u}" y="{oy+u}" width="{u}" height="{u}" {f}/>')
    # quarter discs; each path's bbox is exactly u x u
    x0, y0, x1, y1 = ox, oy, ox + 2 * u, oy + 2 * u
    svg.append(f'<path id="{p}-topleft" d="M{x0+u},{y0} V{y0+u} H{x0} A{u},{u} 0 0 1 {x0+u},{y0} Z" {f}/>')
    svg.append(f'<path id="{p}-topright" d="M{x1},{y0} V{y0+u} H{x1+u} A{u},{u} 0 0 0 {x1},{y0} Z" {f}/>')
    svg.append(f'<path id="{p}-bottomleft" d="M{x0+u},{y1+u} V{y1} H{x0} A{u},{u} 0 0 0 {x0+u},{y1+u} Z" {f}/>')
    svg.append(f'<path id="{p}-bottomright" d="M{x1},{y1+u} V{y1} H{x1+u} A{u},{u} 0 0 1 {x1},{y1+u} Z" {f}/>')


def inset_box(name, state, fill, u=10, a=2):
    """Square nine-slice whose shape sits a/u inside every outer edge (transparent band), so a
    selection never touches the view edge.  Corners are true quarter circles of radius u-a, so the
    shape stays circular when Kvantum scales the corners (frame.expansion -> full pills)."""
    ox, oy = _place(3 * u, 3 * u)
    f = _fill(fill)
    T = 'fill="#000" fill-opacity="0"'
    p = f"{name}-{state}"
    c = u - a
    svg.append(f'<rect id="{p}" x="{ox+u}" y="{oy+u}" width="{u}" height="{u}" {f}/>')
    edges = {"top": (ox+u, oy, u, u, ox+u, oy+a, u, c), "bottom": (ox+u, oy+2*u, u, u, ox+u, oy+2*u, u, c),
             "left": (ox, oy+u, u, u, ox+a, oy+u, c, u), "right": (ox+2*u, oy+u, u, u, ox+2*u, oy+u, c, u)}
    for side, (bx, by, bw, bh, x, y, w, h) in edges.items():
        svg.append(f'<g id="{p}-{side}"><rect x="{bx}" y="{by}" width="{bw}" height="{bh}" {T}/>'
                   f'<rect x="{x}" y="{y}" width="{w}" height="{h}" {f}/></g>')
    # corner piece box (bx,by); circle centre = inner corner (cx,cy)
    corners = {"topleft": (ox, oy, ox+u, oy+u, -1, -1), "topright": (ox+2*u, oy, ox+2*u, oy+u, 1, -1),
               "bottomleft": (ox, oy+2*u, ox+u, oy+2*u, -1, 1), "bottomright": (ox+2*u, oy+2*u, ox+2*u, oy+2*u, 1, 1)}
    for k, (bx, by, cx, cy, sx, sy) in corners.items():
        sweep = 1 if sx * sy > 0 else 0
        d = f"M{cx+sx*c},{cy} A{c},{c} 0 0 {sweep} {cx},{cy+sy*c} L{cx},{cy} Z"
        svg.append(f'<g id="{p}-{k}"><rect x="{bx}" y="{by}" width="{u}" height="{u}" {T}/><path d="{d}" {f}/></g>')


def ring(name, state, color, sw=1.6, u=10):
    """Nine-slice outline (for the default-button ring); interior transparent."""
    ox, oy = _place(3 * u, 3 * u)
    p = f"{name}-{state}"
    t = f'fill="{color}"'
    h = sw / 2
    svg.append(f'<rect id="{p}" x="{ox+u}" y="{oy+u}" width="{u}" height="{u}" fill="#000" fill-opacity="0"/>')
    for side, (x, y, w, hh) in {"top": (ox+u, oy, u, sw), "bottom": (ox+u, oy+3*u-sw, u, sw),
                                "left": (ox, oy+u, sw, u), "right": (ox+3*u-sw, oy+u, sw, u)}.items():
        bx = {"top": (ox+u, oy), "bottom": (ox+u, oy+2*u), "left": (ox, oy+u), "right": (ox+2*u, oy+u)}[side]
        svg.append(f'<g id="{p}-{side}"><rect x="{bx[0]}" y="{bx[1]}" width="{u}" height="{u}" fill="#000" fill-opacity="0"/>'
                   f'<rect x="{x}" y="{y}" width="{w}" height="{hh}" {t}/></g>')
    ri = u - sw  # inner radius; corner = quarter annulus (filled, no stroke caps)
    for corner, (cx, cy, sx, sy) in {"topleft": (ox+u, oy+u, -1, -1), "topright": (ox+2*u, oy+u, 1, -1),
                                     "bottomleft": (ox+u, oy+2*u, -1, 1), "bottomright": (ox+2*u, oy+2*u, 1, 1)}.items():
        bx, by = min(cx, cx+sx*u), min(cy, cy+sy*u)
        sweep = 1 if sx * sy > 0 else 0
        d = (f"M{cx+sx*u},{cy} A{u},{u} 0 0 {sweep} {cx},{cy+sy*u} "
             f"L{cx},{cy+sy*ri} A{ri},{ri} 0 0 {1-sweep} {cx+sx*ri},{cy} Z")
        svg.append(f'<g id="{p}-{corner}"><rect x="{bx}" y="{by}" width="{u}" height="{u}" fill="#000" fill-opacity="0"/>'
                   f'<path d="{d}" {t}/></g>')


def boxes(name, fills, u=10):
    for st, c in fills.items():
        box(name, st, c, u)


def icon(eid, body, size=24):
    """Indicator element: a group whose bbox is exactly size x size."""
    ox, oy = _place(size, size)
    svg.append(f'<g id="{eid}" transform="translate({ox},{oy})">'
               f'<rect width="{size}" height="{size}" fill="#000" fill-opacity="0"/>{body}</g>')


def chevron(d, c, w=2.2):
    pts = {"down": "7,10 12,15 17,10", "up": "7,14 12,9 17,14",
           "left": "14,7 9,12 14,17", "right": "10,7 15,12 10,17"}[d]
    return (f'<polyline points="{pts}" fill="none" stroke="{c}" stroke-width="{w}" '
            f'stroke-linecap="round" stroke-linejoin="round"/>')


# ── frames ───────────────────────────────────────────────────────────────
# push buttons: grey pill, hover lighter, pressed / checked = white
boxes("button", {"normal": S2, "focused": S3, "pressed": WHITE, "toggled": WHITE,
                 "disabled": "#0d0d0d"})
# default button (drawn OVER every state; Kvantum cannot recolour its label):
# a 7% white veil (#1a1a1a -> ~#2a2a2a, white stays white) + bold label + a small dot
boxes("button", {"default": "#ffffff;0.07"})
# tool buttons (toolbars, Dolphin navigator): invisible until hovered
boxes("tbutton", {"normal": NONE, "focused": S2, "pressed": S3, "toggled": WHITE,
                  "disabled": NONE})
# line edits / editable combos: flat round field, focus = lighter fill
boxes("lineedit", {"normal": S2, "focused": S4, "pressed": S4, "toggled": S4,
                   "disabled": "#0d0d0d"})
boxes("combo", {"normal": S2, "focused": S3, "pressed": S4, "toggled": S4,
                "disabled": "#0d0d0d"})
# item views: hover = faint pill, selection = white pill (black text)
# ("pressed" = selected in the focused view, i.e. Dolphin's normal selection -> white too)
for _st, _c in {"normal": NONE, "focused": S2, "pressed": WHITE, "toggled": WHITE, "disabled": NONE,
                "toggled-inactive": WHITE2, "pressed-inactive": WHITE2, "focused-inactive": S2}.items():
    inset_box("itemview", _st, _c, a=0)  # no room for an inset: see note below
# tabs: pills; active = white
boxes("tab", {"normal": NONE, "focused": S2, "pressed": S3, "toggled": WHITE,
              "disabled": NONE})
boxes("tabframe", {"normal": NONE})
boxes("tabbarframe", {"normal": NONE})
# scrollbars: slim thumb, no track
boxes("scrollbarslider", {"normal": S4, "focused": S5, "pressed": GREY, "toggled": GREY,
                          "disabled": NONE})
boxes("scrollbargroove", {"normal": NONE})
# sliders: thick pill groove, white fill
boxes("slider", {"normal": S4, "focused": S4, "pressed": S4, "toggled": WHITE, "disabled": S2})
# menus / popups
boxes("menu", {"normal": S2})   # one surface grey for popups and cards
boxes("menuitem", {"normal": NONE, "focused": WHITE, "pressed": WHITE2, "toggled": WHITE})
boxes("menubar", {"normal": NONE})
boxes("menubaritem", {"normal": NONE, "focused": S2, "pressed": S3, "toggled": S3})
boxes("tooltip", {"normal": S2})
boxes("group", {"normal": S2})
boxes("common", {"normal": NONE, "focused": NONE})
boxes("header", {"normal": NONE, "focused": S1, "pressed": S2, "toggled": NONE})
boxes("toolbar", {"normal": NONE})
boxes("dock", {"normal": NONE})
boxes("splitter", {"normal": NONE, "focused": NONE, "pressed": NONE})
boxes("focus", {"normal": NONE})
boxes("statusbar", {"normal": NONE})
boxes("window", {"normal": BLACK})

# progress: dot rows (tiled interior patterns; 1 tile = one dot)
# groove: dim dot tiles + its right frame piece = one whole dim dot, so the bar always ends on a dot;
# fill: white dot tiles + its right frame piece ("tip") = one whole white dot, so a cut falls inside
# NOTE: one-dot end pieces were tried (round 3) and rejected: Kvantum forces the groove's
# left = right frame width and tiles the interior from the left, so an end piece lands off the
# 12px grid and merges with a clipped interior dot.  Plain tiling is the cleanest available.
for eid, c in [(f"{base}{side}", col) for base, col in (("progress-normal", S4), ("progress-pattern-normal", WHITE),
                                                      ("progress-pattern-disabled", DIM), ("progress-pattern-focused", WHITE))
               for side in ("", "-left", "-right")]:
    ox, oy = _place(12, 12)
    svg.append(f'<g id="{eid}" transform="translate({ox},{oy})">'
               f'<rect width="12" height="12" fill="#000" fill-opacity="0"/>'
               f'<circle cx="3" cy="6" r="3" fill="{c}"/></g>')  # 6px dot at the tile's left, 6px gap
# progress bar groove rendered via frame=false / interior = dot pattern; see kvconfig

# ── indicators ───────────────────────────────────────────────────────────
# focused (hover) arrows are grey: they must read on #262626 buttons AND on the white menu hover pill
ARROW = {"normal": WHITE, "focused": GREY, "pressed": BLACK, "toggled": BLACK, "disabled": DIM}
for d in ("down", "up", "left", "right"):
    for st, c in ARROW.items():
        icon(f"arrow-{d}-{st}", chevron(d, c))
        icon(f"tarrow-{d}-{st}", chevron(d, GREY if st == "normal" else WHITE if st != "disabled" else DIM, 2))
for st, c in ARROW.items():
    # drop-down indicators are looked up as <element>-<state> (no direction)
    icon(f"carrow-{st}", chevron("down", DIM if st == "disabled" else GREY if st == "normal" else WHITE))
    # tree expanders: chevrons in grey
    cc = DIM if st == "disabled" else GREY if st == "normal" else WHITE
    icon(f"tree-plus-{st}", chevron("right", cc, 2))
    icon(f"tree-minus-{st}", chevron("down", cc, 2))
    icon(f"arrow-plus-{st}", chevron("right", cc, 2))
    icon(f"arrow-minus-{st}", chevron("down", cc, 2))
    # spin indicators: + / -
    plus = f'<path d="M12,7 V17 M7,12 H17" stroke="{c}" stroke-width="2" stroke-linecap="round"/>'
    minus = f'<path d="M7,12 H17" stroke="{c}" stroke-width="2" stroke-linecap="round"/>'
    icon(f"spin-plus-{st}", plus)
    icon(f"spin-minus-{st}", minus)
    icon(f"spin-up-{st}", chevron("up", c))
    icon(f"spin-down-{st}", chevron("down", c))
    # tab close: x
    xc = {"normal": GREY, "focused": WHITE, "pressed": WHITE, "toggled": BLACK, "disabled": DIM}[st]
    icon(f"tab-close-{st}", f'<path d="M8,8 L16,16 M16,8 L8,16" stroke="{xc}" stroke-width="2" stroke-linecap="round"/>')

# checkboxes: rounded squares; checked = white with black tick
TICK = '<polyline points="7.5,12.5 10.8,15.6 16.5,9" fill="none" stroke="#000" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>'
for st, off, on in (("normal", S4, WHITE), ("focused", S5, WHITE), ("pressed", GREY, WHITE2),
                    ("toggled", S4, WHITE), ("disabled", S2, DIM)):
    sq = lambda c: f'<rect x="2" y="2" width="20" height="20" rx="7" fill="{c}"/>'
    icon(f"checkbox-{st}", sq(off))
    icon(f"checkbox-checked-{st}", sq(on) + TICK)
    icon(f"checkbox-tristate-{st}", sq(on) + '<path d="M8,12 H16" stroke="#000" stroke-width="2.4" stroke-linecap="round"/>')
    # radios: dots; checked = white dot with black core
    dot = lambda c: f'<circle cx="12" cy="12" r="10" fill="{c}"/>'
    icon(f"radio-{st}", dot(off))
    icon(f"radio-checked-{st}", dot(on) + '<circle cx="12" cy="12" r="4" fill="#000"/>')
    # menu check/radio: on #111 popups, inverted on the white hover pill
    if st in ("focused", "pressed"):
        mo, mon, mk = "#d0d0d0", BLACK, WHITE
    else:
        mo, mon, mk = off, on, BLACK
    mtick = TICK.replace('stroke="#000"', f'stroke="{mk}"')
    icon(f"menu-checkbox-{st}", sq(mo))
    icon(f"menu-checkbox-checked-{st}", sq(mon) + mtick)
    icon(f"menu-radio-{st}", dot(mo))
    icon(f"menu-radio-checked-{st}", dot(mon) + f'<circle cx="12" cy="12" r="4" fill="{mk}"/>')

# slider handle: white disc (black core ring keeps it legible over the white fill)
for st, c in (("normal", WHITE), ("focused", WHITE), ("pressed", WHITE2), ("disabled", DIM)):
    disc = f'<circle cx="12" cy="12" r="11" fill="{c}"/><circle cx="12" cy="12" r="4" fill="#000"/>'
    icon(f"slidercursor-{st}", disc)
    icon(f"slidercursor-tickless-{st}", disc)

# separators / misc (all invisible: no hairlines)
for eid in ("header-separator", "toolbar-separator", "menu-separator", "menuitem-separator"):
    icon(eid, "", 4)
icon("splitter-grip-normal", "", 4)
icon("grip-normal", "", 4)
icon("toolbar-handle", f'<circle cx="12" cy="6" r="1.6" fill="{DIM}"/><circle cx="12" cy="12" r="1.6" fill="{DIM}"/><circle cx="12" cy="18" r="1.6" fill="{DIM}"/>')
icon("resize-grip-normal", "".join(f'<circle cx="{x}" cy="{y}" r="1.5" fill="{DIM}"/>'
                                    for x, y in ((18, 18), (12, 18), (18, 12))))
icon("flat-button-default-indicator", "", 4)
# default-button dot: Kvantum aligns this box bottom-right; the dot sits in its upper half
icon("button-default-indicator", f'<circle cx="8" cy="7" r="2.6" fill="{WHITE}"/>', 14)

# ── kvconfig ─────────────────────────────────────────────────────────────
KV = f"""[%General]
author=NothingOS for CachyOS
comment=Nothing OS for Qt Widgets: pure black, flat pills, white selection, dot controls
x11drag=menubar_and_primary_toolbar
alt_mnemonic=true
left_tabs=true
center_doc_tabs=false
center_normal_tabs=false
attach_active_tab=false
mirror_doc_tabs=false
joined_inactive_tabs=false
no_inactive_tab_expansion=true
group_toolbar_buttons=false
toolbar_item_spacing=4
toolbar_interior_spacing=6
toolbar_separator_thickness=0
slim_toolbars=false
spread_progressbar=true
spread_menuitems=false
spread_header=true
composite=true
translucent_windows=false
blurring=false
popup_blurring=false
menu_shadow_depth=0
tooltip_shadow_depth=0
shadowless_popup=true
menu_separator_height=9
splitter_width=6
scroll_width=8
scroll_arrows=false
scroll_min_extent=48
center_scrollbar_indicator=false
transient_scrollbar=false
transient_groove=false
scrollbar_in_view=true
slider_width=8
slider_handle_width=22
slider_handle_length=22
tickless_slider_handle_size=22
check_size=20
textless_progressbar=false
progressbar_thickness=12
menubar_mouse_tracking=true
toolbutton_style=0
double_click=false
fill_rubberband=true
merge_menubar_with_toolbar=false
small_icon_size=16
large_icon_size=32
button_icon_size=16
toolbar_icon_size=22
combo_as_lineedit=true
square_combo_button=false
combo_menu=true
hide_combo_checkboxes=true
combo_focus_rect=false
groupbox_top_label=true
inline_spin_indicators=true
inline_spin_separator=false
vertical_spin_indicators=false
spin_button_width=24
animate_states=true
button_contents_shift=false
layout_spacing=8
layout_margin=8
submenu_overlap=0
submenu_delay=150
tooltip_delay=-1
tree_branch_line=false
no_window_pattern=true
respect_DE=true
dialog_button_layout=0
reduce_window_opacity=0
reduce_menu_opacity=0
scrollable_menu=false
click_behavior=0
contrast=1.00
intensity=1.00
saturation=1.00
bold_active_tab=false
remove_extra_frames=true
drag_from_buttons=false

[GeneralColors]
window.color={BLACK}
base.color={BLACK}
alt.base.color=#0a0a0a
button.color={S2}
light.color={S4}
mid.light.color={S3}
dark.color={BLACK}
mid.color={S1}
shadow.color={BLACK}
highlight.color={WHITE}
inactive.highlight.color={WHITE2}
text.color={WHITE}
window.text.color={WHITE}
button.text.color={WHITE}
disabled.text.color={DIM}
tooltip.base.color={S2}
tooltip.text.color={WHITE}
highlight.text.color={BLACK}
inactive.highlight.text.color={BLACK}
link.color={RED}
link.visited.color={GREY}
progress.indicator.text.color={WHITE}
progress.inactive.indicator.text.color={WHITE}

[Hacks]
transparent_ktitle_label=true
transparent_dolphin_view=true
transparent_pcmanfm_sidepane=true
transparent_pcmanfm_view=true
transparent_menutitle=true
transparent_arrow_button=true
respect_darkness=true
kcapacitybar_as_progressbar=true
force_size_grip=false
iconless_pushbutton=false
iconless_menu=false
disabled_icon_opacity=50
normal_default_pushbutton=false
single_top_toolbar=true
tint_on_mouseover=0
no_selection_tint=true
middle_click_scroll=false
centered_forms=false
style_vertical_toolbars=false
blur_translucent=false

[PanelButtonCommand]
frame=true
frame.element=button
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
frame.expansion=64
interior=true
interior.element=button
indicator.element=arrow
indicator.size=14
text.normal.color={WHITE}
text.focus.color={WHITE}
text.press.color={BLACK}
text.toggle.color={BLACK}
text.disabled.color={DIM}
text.shadow=0
text.margin.top=2
text.margin.bottom=2
text.margin.left=12
text.margin.right=12
text.iconspacing=6
min_width=+2font
min_height=0

[PanelButtonTool]
inherits=PanelButtonCommand
frame.element=tbutton
interior.element=tbutton
indicator.element=tarrow
text.press.color={WHITE}
text.toggle.color={BLACK}
text.margin.left=6
text.margin.right=6
min_width=0
min_height=0

[ToolbarButton]
inherits=PanelButtonTool
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
frame.expansion=64
text.margin.top=2
text.margin.bottom=2
text.margin.left=4
text.margin.right=4

[Dock]
inherits=PanelButtonCommand
frame.element=dock
interior.element=dock
frame.expansion=0
text.normal.color={GREY}

[DockTitle]
inherits=PanelButtonCommand
frame=false
interior=false
text.normal.color={GREY}
text.focus.color={GREY}
text.bold=false

[IndicatorSpinBox]
inherits=PanelButtonCommand
frame=true
interior=true
frame.element=tbutton
interior.element=tbutton
frame.expansion=64
indicator.element=spin
indicator.size=14
text.press.color={WHITE}
text.toggle.color={WHITE}

[RadioButton]
inherits=PanelButtonCommand
frame=false
interior.element=radio
text.press.color={WHITE}
text.toggle.color={WHITE}
text.margin.left=4
text.margin.right=4
min_width=0
min_height=0

[CheckBox]
inherits=RadioButton
interior.element=checkbox

[Focus]
frame=false
interior=false

[GenericFrame]
inherits=PanelButtonCommand
frame=true
interior=false
frame.element=common
interior.element=common
frame.expansion=0
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1

[LineEdit]
inherits=PanelButtonCommand
frame.element=lineedit
interior.element=lineedit
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
frame.expansion=64
text.press.color={WHITE}
text.toggle.color={WHITE}
text.margin.top=2
text.margin.bottom=2
text.margin.left=8
text.margin.right=8

[ToolbarLineEdit]
inherits=LineEdit

[DropDownButton]
inherits=PanelButtonCommand
indicator.element=carrow

[IndicatorArrow]
indicator.element=arrow
indicator.size=14

[ComboBox]
inherits=PanelButtonCommand
frame.element=combo
interior.element=combo
indicator.element=carrow
text.press.color={WHITE}
text.toggle.color={WHITE}
text.margin.left=11
text.margin.right=6

[ToolbarComboBox]
inherits=ComboBox

[ToolboxTab]
inherits=PanelButtonCommand
frame.element=tab
interior.element=tab

[Tab]
inherits=PanelButtonCommand
frame.element=tab
interior.element=tab
indicator.element=tab
indicator.size=16
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
frame.expansion=64
text.normal.color={GREY}
text.focus.color={WHITE}
text.press.color={WHITE}
text.toggle.color={BLACK}
text.margin.top=4
text.margin.bottom=4
text.margin.left=12
text.margin.right=12
min_width=+2font
min_height=+0.6font

[TabFrame]
inherits=PanelButtonCommand
frame=false
interior=false
frame.element=tabframe
interior.element=tabframe
frame.expansion=0

[TabBarFrame]
inherits=GenericFrame
frame=false
interior=false

[TreeExpander]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=tree
indicator.size=14

[HeaderSection]
inherits=PanelButtonCommand
frame.element=header
interior.element=header
frame.top=4
frame.bottom=4
frame.left=4
frame.right=4
frame.expansion=0
text.normal.color={GREY}
text.focus.color={WHITE}
text.press.color={WHITE}
text.toggle.color={GREY}
text.margin.top=4
text.margin.bottom=4
text.margin.left=8
text.margin.right=8
indicator.element=carrow
indicator.size=12
min_width=0
min_height=0

[SizeGrip]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=resize-grip
indicator.size=14

[Toolbar]
inherits=PanelButtonCommand
frame=false
interior=false
frame.element=toolbar
interior.element=toolbar
indicator.element=toolbar
indicator.size=16
text.margin=0
text.press.color={WHITE}
text.toggle.color={WHITE}
frame.expansion=0

[MenuBar]
inherits=PanelButtonCommand
frame=false
interior=false
frame.element=menubar
interior.element=menubar
frame.expansion=0

[MenuBarItem]
inherits=PanelButtonCommand
frame.element=menubaritem
interior.element=menubaritem
text.press.color={WHITE}
text.toggle.color={WHITE}
text.margin.top=3
text.margin.bottom=3
text.margin.left=8
text.margin.right=8
min_width=0
min_height=0

[Slider]
inherits=PanelButtonCommand
frame.element=slider
interior.element=slider
frame.top=4
frame.bottom=4
frame.left=4
frame.right=4
frame.expansion=64
focusFrame=false

[SliderCursor]
inherits=PanelButtonCommand
frame=false
interior.element=slidercursor

[Progressbar]
inherits=PanelButtonCommand
frame=false
interior=true
frame.element=progress
interior.element=progress
interior.x.patternsize=12
interior.y.patternsize=12
frame.expansion=0
text.margin=0
text.normal.color={WHITE}
text.focus.color={WHITE}
text.press.color={WHITE}
text.toggle.color={WHITE}
text.bold=false

[ProgressbarContents]
inherits=PanelButtonCommand
frame=false
interior=true
frame.element=progress-pattern
interior.element=progress-pattern
interior.x.patternsize=12
interior.y.patternsize=12
frame.expansion=0

[ItemView]
inherits=PanelButtonCommand
frame.element=itemview
interior.element=itemview
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
frame.expansion=0
text.normal.color={WHITE}
text.focus.color={WHITE}
text.press.color={BLACK}
text.toggle.color={BLACK}
text.margin.top=2
text.margin.bottom=2
text.margin.left=6
text.margin.right=6
min_width=0
min_height=+0.6font

[Splitter]
frame=false
interior=false
indicator.size=0

[Scrollbar]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=arrow
indicator.size=0

[ScrollbarSlider]
inherits=PanelButtonCommand
frame.element=scrollbarslider
interior.element=scrollbarslider
frame.top=4
frame.bottom=4
frame.left=4
frame.right=4
frame.expansion=64
indicator.element=grip
indicator.size=0

[ScrollbarTransientSlider]
inherits=ScrollbarSlider

[ScrollbarGroove]
inherits=PanelButtonCommand
frame=false
interior=false
frame.element=scrollbargroove
interior.element=scrollbargroove

[Menu]
inherits=PanelButtonCommand
frame.element=menu
interior.element=menu
frame.top=10
frame.bottom=10
frame.left=10
frame.right=10
frame.expansion=0
text.press.color={WHITE}
text.toggle.color={WHITE}

[MenuItem]
inherits=PanelButtonCommand
frame.element=menuitem
interior.element=menuitem
indicator.element=arrow
indicator.size=14
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
frame.expansion=48
text.normal.color={WHITE}
text.focus.color={BLACK}
text.press.color={BLACK}
text.toggle.color={BLACK}
text.margin.top=2
text.margin.bottom=2
text.margin.left=6
text.margin.right=8
min_width=0
min_height=0

[TitleBar]
inherits=PanelButtonCommand
frame=false
interior=false
text.normal.color={GREY}
text.focus.color={WHITE}

[GroupBox]
inherits=GenericFrame
frame=true
interior=true
frame.element=group
interior.element=group
frame.top=16
frame.bottom=16
frame.left=16
frame.right=16
frame.expansion=0
text.normal.color={GREY}
text.focus.color={GREY}
text.press.color={GREY}
text.toggle.color={GREY}
text.bold=false
text.margin=0

[ToolTip]
inherits=GenericFrame
frame=true
interior=true
frame.element=tooltip
interior.element=tooltip
frame.top=6
frame.bottom=6
frame.left=10
frame.right=10
frame.expansion=64
text.margin=2
text.normal.color={WHITE}

[StatusBar]
inherits=GenericFrame
frame=false
interior=false

[Window]
interior=false
frame=false

[WindowTranslucent]
inherits=Window
"""


def files_variant(doc, kv):
    """NothingFiles: the theme Kvantum gives to Dolphin (kvantum.kvconfig [Applications]).

    Dolphin's KItemListView ignores HighlightedText: a selected row/tile is drawn with
    QPalette::Text (white here; HighlightedText only while the mouse is pressed) and a
    Normal-mode icon.  A white selection pill therefore hides the label and glyph
    (live bug in the Places panel).  So in Dolphin the selection is a light-grey pill
    (#3a3a3a) that white text and white glyphs read on; everything else is unchanged.
    """
    global svg
    keep = [e for e in svg if 'id="itemview-' not in e]
    svg = []
    for st, c in {"normal": NONE, "focused": S2, "pressed": S5, "toggled": S5, "disabled": NONE,
                  "toggled-inactive": S4, "pressed-inactive": S4, "focused-inactive": S2}.items():
        inset_box("itemview", st, c, a=0)
    doc = _doc(keep + svg)
    sec = kv.index("[ItemView]")
    end = kv.index("\n[", sec + 1)
    body = kv[sec:end].replace(f"text.press.color={BLACK}", f"text.press.color={WHITE}") \
                      .replace(f"text.toggle.color={BLACK}", f"text.toggle.color={WHITE}")
    kv = kv[:sec] + body + kv[end:]
    kv = re.sub(r"^comment=.*$", "comment=Nothing OS for Dolphin: as Nothing, but a #3a3a3a selection pill "
                "(Dolphin draws selected labels in the Text colour, so white-on-white otherwise)", kv, count=1, flags=re.M)
    return doc, kv


def _doc(elements):
    w, h = 2010, _cursor[1] + 130
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n'
            + "\n".join(elements) + "\n</svg>\n")


def write(folder, name, doc, kv):
    d = os.path.join(HERE, folder)
    os.makedirs(d, exist_ok=True)
    # <name>Dark.* in the same folder: the session runs QT_STYLE_OVERRIDE=kvantum-dark,
    # which looks up "<theme>Dark" first; ship the identical theme under that name too.
    for n in (name, name + "Dark"):
        with open(os.path.join(d, f"{n}.svg"), "w") as f:
            f.write(doc)
        with open(os.path.join(d, f"{n}.kvconfig"), "w") as f:
            f.write(kv)
    print(d)


def main():
    doc = _doc(svg)
    write("Nothing", "Nothing", doc, KV)
    write("NothingFiles", "NothingFiles", *files_variant(doc, KV))


if __name__ == "__main__":
    main()
