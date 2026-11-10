#!/usr/bin/env python3
"""Nothing wallpapers: black with a faint dot grid and a red accent dot."""
import os
from PIL import Image, ImageDraw

OUT = os.path.dirname(os.path.abspath(__file__))
W, H, STEP = 3840, 2160, 48


def grid(name, bg, dot, accent=True, fade=False):
    img = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(img)
    for y in range(STEP // 2, H, STEP):
        for x in range(STEP // 2, W, STEP):
            r = 2.6
            c = dot
            if fade:  # dots grow brighter toward the lower right, like a Glyph sweep
                t = max(0.0, (x / W + y / H) / 2 - 0.35) / 0.65
                v = int(dot[0] + (70 - dot[0]) * t ** 2)
                c = (v, v, v)
            d.ellipse((x - r, y - r, x + r, y + r), fill=c)
    if accent:
        x, y = W - STEP * 4 - STEP // 2, H - STEP * 3 - STEP // 2
        d.ellipse((x - 7, y - 7, x + 7, y + 7), fill=(215, 25, 33))
    img.save(os.path.join(OUT, name), optimize=True)


if __name__ == "__main__":
    grid("nothing-dots.png", (0, 0, 0), (22, 22, 22))
    grid("nothing-sweep.png", (0, 0, 0), (16, 16, 16), fade=True)
    grid("nothing-grey.png", (17, 17, 17), (38, 38, 38), accent=False)
    print("ok")
