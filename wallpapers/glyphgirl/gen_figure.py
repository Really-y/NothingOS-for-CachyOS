#!/usr/bin/env python3
"""Bake girl.svg into the two textures the org.nothing.dots shader samples.

figure.png      R = luminance, eyes open      G = luminance, eyes closed
                B = silhouette (coverage)
                (a 1-dot jaw/cheek contour at 0.45 is baked into R and G)
figure-aux.png  R = hair sway weight (0 = rigid, 1 = free tip), dilated past the silhouette
                G = silhouette, dilated + feathered over ~1 coarse dot (fades the background grid)
                B = face mask (skin + eyes): dark features there become missing dots

Needs rsvg-convert, numpy, Pillow. Run after editing girl.svg:
    python3 wallpapers/glyphgirl/gen_figure.py
"""
import io
import os
import re
import subprocess

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "plasma", "wallpapers", "org.nothing.dots", "contents", "ui")
SVG = open(os.path.join(HERE, "girl.svg")).read()
W, H = 600, 800          # canvas
TW, TH = 600, 800        # texture (1 canvas px per texel: 1-dot features survive)
GROUPS = ["hair-back", "neck", "body", "hair-curtain", "face", "eyes-open", "eyes-closed",
          "hair-side", "bangs", "ahoge", "clip"]


def variant(show):
    s = SVG
    for g in GROUPS:
        s = re.sub(r'<g id="%s"( display="none")?' % g,
                   '<g id="%s"%s' % (g, "" if g in show else ' display="none"'), s)
    return s


def render(show):
    png = subprocess.run(["rsvg-convert", "-w", str(W), "-h", str(H)],
                         input=variant(show).encode(), capture_output=True, check=True).stdout
    im = Image.open(io.BytesIO(png)).convert("RGBA")
    a = np.asarray(im, dtype=np.float32) / 255.0
    return a[..., 0] * a[..., 3], a[..., 3]          # luminance on black, alpha


def small(x, f=Image.Resampling.BOX):
    return np.asarray(Image.fromarray(np.uint8(np.clip(x, 0, 1) * 255)).resize((TW, TH), f), np.float32) / 255


def blur(x, r):
    return np.asarray(Image.fromarray(np.uint8(np.clip(x, 0, 1) * 255)).filter(ImageFilter.GaussianBlur(r)), np.float32) / 255


def dilate(x, n):
    return np.asarray(Image.fromarray(np.uint8(np.clip(x, 0, 1) * 255)).filter(ImageFilter.MaxFilter(n)), np.float32) / 255


base = [g for g in GROUPS if g != "eyes-closed"]
lum_open, sil = render(base)
lum_closed, _ = render([g for g in GROUPS if g != "eyes-open"])

# visible hair = hair group alpha not covered by anything painted later
alpha = {g: render([g])[1] for g in GROUPS if g not in ("eyes-closed",)}
order = [g for g in GROUPS if g != "eyes-closed"]


def visible(g, through=()):
    v = alpha[g].copy()
    for later in order[order.index(g) + 1:]:
        if later not in through:
            v *= 1 - alpha[later]
    return v


def erode(x, n):
    return np.asarray(Image.fromarray(np.uint8(np.clip(x, 0, 1) * 255)).filter(ImageFilter.MinFilter(n)), np.float32) / 255


y = np.linspace(0, 1, H, dtype=np.float32)[:, None] * H


def ramp(y0, y1):
    t = np.clip((y - y0) / (y1 - y0), 0, 1)
    return t * t * (3 - 2 * t)


sway = np.maximum.reduce([
    visible("hair-back") * ramp(300, 720) * 1.0,
    visible("hair-curtain") * ramp(300, 720) * 1.0,
    visible("hair-side") * ramp(260, 490) * 0.45,
    visible("bangs") * ramp(170, 322) * 0.15,
    visible("ahoge") * ramp(92, 48) * 1.6,
])
sway = small(sway)
sway = np.maximum(blur(sway, 4), blur(dilate(sway, 17), 10) * 0.9)   # reach past the tips

# 1-dot jaw/cheek contour (~5 canvas px) where the face meets neck / hair
face_region = visible("face", through=("eyes-open",))
contour = np.clip(face_region - erode(face_region, 11), 0, 1) * ramp(300, 330)
lum_open = lum_open * (1 - contour) + 0.45 * contour
lum_closed = lum_closed * (1 - contour) + 0.45 * contour
face_mask = small(np.clip(face_region + visible("neck"), 0, 1))

S = small(sil)
fig = np.dstack([small(lum_open), small(lum_closed), S])
aux = np.dstack([sway, blur(dilate(S, 13), 12), face_mask])
Image.fromarray(np.uint8(np.clip(fig, 0, 1) * 255)).save(os.path.join(OUT, "figure.png"), optimize=True)
Image.fromarray(np.uint8(np.clip(aux, 0, 1) * 255)).save(os.path.join(OUT, "figure-aux.png"), optimize=True)
print("ok", os.path.relpath(os.path.join(OUT, "figure.png")))
