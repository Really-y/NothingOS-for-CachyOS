#!/usr/bin/env python3
"""Synthetic, license-free test card for org.nothing.dotimage previews.

A dark, anime-ish portrait drawn from primitives (dark hair, light face, big eyes,
a red ribbon, line-art strokes) plus a grey ramp and a colour strip, so a preview
shows tone mapping, dark-art handling, colour and the red accent at once.
usage: python3 tools/dotimage_testcard.py previews/assets/dotimage-testcard.png
"""
import math, sys
from PIL import Image, ImageDraw, ImageFilter

W, H = 1600, 900
img = Image.new("RGB", (W, H))
px = img.load()
for y in range(H):                      # dark blue-violet backdrop, slightly lighter top-right
    for x in range(W):
        g = 0.5 * x / W + 0.5 * (1 - y / H)
        px[x, y] = (int(18 + 30 * g), int(16 + 22 * g), int(34 + 48 * g))
d = ImageDraw.Draw(img)

cx, cy = 1060, 470                      # head centre
# hair back (dark, with a lighter sheen band)
d.ellipse([cx - 290, cy - 330, cx + 290, cy + 260], fill=(38, 30, 52))
d.polygon([(cx - 290, cy - 40), (cx - 330, H), (cx - 120, H), (cx - 160, cy)], fill=(38, 30, 52))
d.polygon([(cx + 290, cy - 40), (cx + 330, H), (cx + 120, H), (cx + 160, cy)], fill=(38, 30, 52))
d.arc([cx - 250, cy - 300, cx + 250, cy + 150], 200, 340, fill=(120, 105, 150), width=22)
# neck + shoulders (a dark top)
d.rectangle([cx - 55, cy + 170, cx + 55, cy + 290], fill=(214, 186, 170))
d.ellipse([cx - 260, cy + 260, cx + 260, cy + 700], fill=(60, 60, 72))
d.polygon([(cx - 70, cy + 270), (cx + 70, cy + 270), (cx, cy + 360)], fill=(214, 186, 170))
# face
d.ellipse([cx - 175, cy - 210, cx + 175, cy + 220], fill=(236, 214, 200))
# bangs
for i, ox in enumerate(range(-200, 220, 70)):
    d.polygon([(cx + ox - 60, cy - 260), (cx + ox + 70, cy - 260), (cx + ox + 10 + (i % 2) * 20, cy - 70 - (i % 3) * 30)],
              fill=(38, 30, 52))
d.ellipse([cx - 230, cy - 340, cx + 230, cy - 170], fill=(38, 30, 52))
# eyes: dark iris, big highlight
for ex in (cx - 80, cx + 80):
    d.ellipse([ex - 48, cy - 20, ex + 48, cy + 70], fill=(30, 26, 60))
    d.ellipse([ex - 30, cy, ex + 22, cy + 60], fill=(90, 70, 150))
    d.ellipse([ex - 26, cy + 2, ex - 4, cy + 26], fill=(255, 255, 255))
    d.line([(ex - 60, cy - 22), (ex + 56, cy - 30)], fill=(20, 16, 30), width=10)      # lash line
    d.line([(ex - 40, cy - 70), (ex + 40, cy - 78)], fill=(60, 48, 70), width=8)       # brow
d.line([(cx - 4, cy + 110), (cx + 6, cy + 128)], fill=(170, 130, 120), width=6)        # nose
d.arc([cx - 36, cy + 140, cx + 36, cy + 180], 20, 160, fill=(150, 60, 70), width=7)    # mouth
d.ellipse([cx - 150, cy + 90, cx - 95, cy + 120], fill=(240, 180, 175))                # blush
d.ellipse([cx + 95, cy + 90, cx + 150, cy + 120], fill=(240, 180, 175))
# red ribbon (the accent)
d.polygon([(cx + 150, cy - 250), (cx + 260, cy - 320), (cx + 250, cy - 190)], fill=(215, 30, 40))
d.polygon([(cx + 150, cy - 250), (cx + 60, cy - 330), (cx + 70, cy - 190)], fill=(215, 30, 40))
d.ellipse([cx + 130, cy - 275, cx + 175, cy - 225], fill=(180, 20, 30))

img = img.filter(ImageFilter.GaussianBlur(1.2))
d = ImageDraw.Draw(img)
# left: line-art panel (white strokes on dark), grey ramp, colour strip
for k in range(6):
    r = 60 + 34 * k
    d.arc([260 - r, 300 - r, 260 + r, 300 + r], 200 + 10 * k, 340 - 10 * k, fill=(235, 235, 235), width=5)
for k in range(10):
    v = int(255 * k / 9)
    d.rectangle([60 + 46 * k, 620, 60 + 46 * (k + 1), 700], fill=(v, v, v))
cols = [(230, 40, 40), (240, 150, 30), (240, 230, 60), (60, 200, 90), (40, 140, 230), (150, 70, 210)]
for k, c in enumerate(cols):
    d.rectangle([60 + 77 * k, 730, 60 + 77 * (k + 1), 810], fill=c)
img.save(sys.argv[1] if len(sys.argv) > 1 else "dotimage-testcard.png")
