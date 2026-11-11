#!/usr/bin/env python3
"""Render terminal previews (previews/terminal-*.png) from palette.json with PIL: a tiny ANSI
emulator (SGR, cursor forward/column) so starship / fastfetch / ls / git-diff output is shown
exactly as a Nothing terminal would draw it. Needs gen_terminal.py to have run first."""
import json, os, re, shutil, subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
OUT = HERE / "out"
PREV = ROOT / "previews"
P = json.load(open(HERE / "palette.json"))
NAMES = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
ANSI = [P["normal"][n] for n in NAMES] + [P["bright"][n] for n in NAMES]
FD = os.path.expanduser("~/.local/share/fonts/nothingos/")
S = 2  # supersample
FS = 11 * S * 1.3333
F = ImageFont.truetype(FD + "SpaceMono-Regular.ttf", round(FS))
FB = ImageFont.truetype(FD + "SpaceMono-Bold.ttf", round(FS))
FALL = ImageFont.truetype(subprocess.run(["fc-match", "-f", "%{file}", "Noto Sans Mono"], capture_output=True, text=True).stdout, round(FS))
from fontTools.ttLib import TTFont
CMAP = TTFont(FD + "SpaceMono-Regular.ttf").getBestCmap()
CW = F.getlength("M")
LH = round(FS * 1.42)
PAD = 16 * S * 1.3333


def rgb(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lum(c):
    f = lambda v: (v / 255 / 12.92) if v / 255 <= 0.03928 else ((v / 255 + 0.055) / 1.055) ** 2.4
    r, g, b = c; return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True); return (la + 0.05) / (lb + 0.05)


FG, BG = rgb(P["foreground"]), rgb(P["background"])


def emulate(text, cols=100):
    grid = [[]]; r = c = 0; fg, bg, bold, rev = FG, None, False, False
    def put(ch):
        nonlocal c
        row = grid[r]
        while len(row) <= c: row.append((" ", None, None, False))
        row[c] = (ch, fg, bg, bold, rev) if rev else (ch, fg, bg, bold); c += 1
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "\x1b" and text[i + 1:i + 2] == "[":
            m = re.match(r"\x1b\[([0-9;?]*)([A-Za-z])", text[i:])
            if not m: i += 1; continue
            args, cmd = m.group(1), m.group(2); i += m.end()
            n = [int(x) if x.isdigit() else 0 for x in args.split(";")] if args and "?" not in args else [0]
            if cmd == "m":
                j = 0
                while j < len(n):
                    v = n[j]
                    if v == 0: fg, bg, bold, rev = FG, None, False, False
                    elif v == 1: bold = True
                    elif v == 7: rev = True
                    elif v == 22: bold = False
                    elif 30 <= v <= 37: fg = rgb(ANSI[v - 30 + (8 if False else 0)])
                    elif 90 <= v <= 97: fg = rgb(ANSI[v - 90 + 8])
                    elif 40 <= v <= 47: bg = rgb(ANSI[v - 40])
                    elif 100 <= v <= 107: bg = rgb(ANSI[v - 100 + 8])
                    elif v in (38, 48) and n[j + 1] == 2:
                        col = tuple(n[j + 2:j + 5]); (fg if v == 38 else bg).__class__  # noqa
                        if v == 38: fg = col
                        else: bg = col
                        j += 4
                    elif v == 39: fg = FG
                    elif v == 49: bg = None
                    j += 1
            elif cmd == "C": c += max(n[0], 1)
            elif cmd == "G": c = max(n[0], 1) - 1
            elif cmd == "A":
                r = max(0, r - max(n[0], 1))
            elif cmd == "B":
                r += max(n[0], 1)
                while len(grid) <= r: grid.append([])
            continue
        if ch == "\n":
            r += 1; c = 0
            while len(grid) <= r: grid.append([])
        elif ch == "\r": c = 0
        elif ch == "\t": c = (c // 8 + 1) * 8
        else: put(ch)
        i += 1
    return grid


def draw_grid(grid, width_cols, title=None):
    h = int(len(grid) * LH + PAD * 2)
    w = int(width_cols * CW + PAD * 2)
    im = Image.new("RGB", (w, h), BG); d = ImageDraw.Draw(im)
    for y, row in enumerate(grid):
        for x, cell in enumerate(row):
            ch, fg, bg, bold = cell[:4]; rev = len(cell) > 4
            if rev: fg, bg = (bg or BG), (fg or FG)
            px, py = PAD + x * CW, PAD + y * LH
            if bg: d.rectangle([px, py, px + CW, py + LH], fill=bg)
            if ch == " ": continue
            font = FB if bold else F
            if ord(ch) not in CMAP: font = FALL
            d.text((px, py + (LH - FS) / 2 - 2), ch, font=font, fill=fg)
    return im


def sgr(i): return f"\x1b[{30 + i if i < 8 else 90 + i - 8}m"
R = "\x1b[0m"
tc = lambda h: "\x1b[38;2;%d;%d;%dm" % rgb(h)


def sample():
    t = []
    t.append(f"{tc(P['dim'])}# 16 colours{R}")
    t.append("".join(f"\x1b[{40 + i if i < 8 else 100 + i - 8}m  {R}" for i in range(16)) + "   " + "".join(f"{sgr(i)}●{R} " for i in range(16)))
    t.append("")
    t.append(f"{tc(P['dim'])}$ ls --color -l{R}")
    fx = HERE / "out/_fx"; shutil.rmtree(fx, ignore_errors=True); (fx / "Terminal").mkdir(parents=True); (fx / "wallpapers").mkdir()
    for n, m in (("install.sh", 0o755), ("backup.tar.gz", 0o644), ("banner.png", 0o644), ("NOTES.md", 0o644)): (fx / n).write_text("x" * 1800); (fx / n).chmod(m)
    os.symlink("wallpapers", fx / "latest"); os.symlink("gone", fx / "broken"); os.mkfifo(fx / "pipe")
    lsc = subprocess.run(["dircolors", "-b", str(OUT / "nothing/dircolors")], capture_output=True, text=True).stdout
    lsc = re.search(r"LS_COLORS='([^']*)'", lsc).group(1)
    ls = subprocess.run(["ls", "-l", "--color=always", "--time-style=+%b %d", str(fx)], capture_output=True, text=True, env=dict(os.environ, LS_COLORS=lsc)).stdout
    t += [l.replace("baron baron", "baron baron") for l in ls.splitlines()[1:]]
    shutil.rmtree(fx)
    t.append("")
    t.append(f"{tc(P['dim'])}$ git diff{R}")
    t.append(f"{tc('#ffffff')}\x1b[1mdiff --git a/terminal/palette.json b/terminal/palette.json{R}")
    t.append(f"{tc('#8e8e8e')}@@ -4,7 +4,7 @@{R} {tc('#5e5e5e')}def palette():{R}")
    t.append(f"{tc('#8e8e8e')} \"background\": \"#000000\",{R}")
    t.append(f"{tc('#d71921')}-  \"red\": \"#ff0000\",{R}")
    t.append(f"{tc('#ffffff')}+  \"red\": \"#d71921\",{R}")
    t.append(f"{tc('#8e8e8e')} \"foreground\": \"#ffffff\",{R}")
    t.append("")
    t.append(f"{tc(P['dim'])}$ htop{R}")
    bar = lambda lab, n, col: f"{tc(P['secondary'])}{lab}{R} [{sgr(col)}{'|' * n}{tc(P['dim'])}{'|' * (30 - n)}{R}] {n * 3}%"
    t.append(bar("CPU", 11, 10)); t.append(bar("MEM", 22, 12)); t.append(bar("SWP", 3, 11))
    t.append(f"\x1b[7m  PID USER      CPU% MEM%  Command                  {R}")
    t.append(f"\x1b[47m\x1b[30m 1204 baron     12.3  4.1  plasmashell              {R}")
    t.append(f"{tc(P['selection_fg'])}{tc(P['selection_bg'], True) if False else ''}\x1b[48;2;255;255;255m\x1b[38;2;0;0;0m  selected text: white background / black text      {R}")
    t.append("")
    for ok in (True, False):
        env = dict(os.environ, STARSHIP_CONFIG=str(OUT / "starship.toml"))
        pr = subprocess.run(["starship", "prompt", "--path", str(ROOT)] + ([] if ok else ["--status", "1"]), capture_output=True, text=True, env=env).stdout.strip("\n")
        pr = pr.replace("\\[", "").replace("\\]", "")
        t.append(pr + " " + ("make" if ok else "make nothing") + (" \x1b[48;2;255;255;255m \x1b[0m" if ok else ""))
        t.append("")
    return "\n".join(t)


def main():
    PREV.mkdir(exist_ok=True)
    # contrast report
    print("contrast on #000000:")
    for i, c in enumerate(ANSI): print(f"  {i:2d} {c} {contrast(rgb(c), BG):5.1f}")
    print(f"  fg {contrast(FG, BG):.1f}  secondary {contrast(rgb(P['secondary']), BG):.1f}  dim {contrast(rgb(P['dim']), BG):.1f}  selection {contrast(rgb(P['selection_fg']), rgb(P['selection_bg'])):.1f}")
    # 1. ANSI sample
    g = emulate(sample()); draw_grid(g, 76).save(PREV / "terminal-ansi.png")
    # 2. fastfetch
    cfg = json.load(open(OUT / "fastfetch/config.jsonc"))
    cfg["logo"]["source"] = str(OUT / "fastfetch/nothing-logo.txt")
    tmp = OUT / "fastfetch/_preview.jsonc"; tmp.write_text(json.dumps(cfg))
    txt = subprocess.run(["fastfetch", "--config", str(tmp), "--pipe", "false"], capture_output=True, text=True).stdout
    tmp.unlink()
    g = emulate(txt); draw_grid(g, 120).save(PREV / "terminal-fastfetch.png")
    # 3. palette swatches
    sw = 120 * S; W = 8 * sw + 40 * S; H = 2 * (sw + 100 * S) + 130 * S
    im = Image.new("RGB", (W, H), BG); d = ImageDraw.Draw(im)
    f1 = ImageFont.truetype(FD + "SpaceMono-Regular.ttf", 13 * S); f2 = ImageFont.truetype(FD + "SpaceMono-Bold.ttf", 15 * S)
    d.text((20 * S, 20 * S), "NOTHING / TERMINAL PALETTE", font=f2, fill=FG)
    for i, c in enumerate(ANSI):
        x = 20 * S + (i % 8) * sw; y = 70 * S + (i // 8) * (sw + 100 * S)
        d.rounded_rectangle([x, y, x + sw - 16 * S, y + sw - 16 * S], radius=18 * S, fill=rgb(c), outline=rgb(P["hairline"]), width=S)
        d.text((x, y + sw - 6 * S), f"{i:02d} {(['black','red','green','yellow','blue','magenta','cyan','white'][i % 8])}", font=f1, fill=FG)
        d.text((x, y + sw + 14 * S), c, font=f1, fill=rgb(P["secondary"]))
        d.text((x, y + sw + 34 * S), f"{contrast(rgb(c), BG):.1f}:1", font=f1, fill=rgb(P["dim"]) if False else rgb(P["secondary"]))
    y = H - 36 * S
    d.rectangle([20 * S, y - 4 * S, 20 * S + 200 * S, y + 22 * S], fill=rgb(P["selection_bg"]))
    d.text((28 * S, y), "SELECTION", font=f1, fill=rgb(P["selection_fg"]))
    d.text((260 * S, y), "foreground 21:1   secondary #8e8e8e   dim #5e5e5e   accent #d71921", font=f1, fill=rgb(P["secondary"]))
    im.save(PREV / "terminal-palette.png")
    print("previews written")


main()
