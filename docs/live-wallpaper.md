# Nothing live wallpaper — how the character art is made

The live wallpaper `org.nothing.dots` draws a dim Glyph dot field and an
illustrated character on top of it, both as round dots. No image generator is
involved: the character is **hand-written SVG vector art**, baked into two small
textures, and a GPU fragment shader turns those textures into dots every frame.

```
 wallpapers/glyphgirl/<style>.svg          (vector art, greyscale, named <g> groups)
        │  python3 wallpapers/glyphgirl/gen_figure.py <style>
        ▼
 plasma/wallpapers/org.nothing.dots/contents/ui/
        figure-<style>.png      R = luminance, eyes open
                                G = luminance, eyes closed
                                B = silhouette coverage
        figure-<style>-aux.png  R = hair sway weight (0 rigid … 1 free tip)
                                G = dilated, feathered silhouette (fades the background grid)
                                B = face mask (dark features here become missing dots)
        │  scripts/build-wallpaper.sh   (install with kpackagetool6)
        ▼
 GlyphField.qml + shaders/glyphfield.frag(.qsb)
        dots: size and brightness follow luminance, blink swaps R/G,
        hair sways by the aux R weight, Glyph sweep + ripple, red bead
```

## 1. The SVG (`wallpapers/glyphgirl/*.svg`)

- **Canvas:** 600 × 800 px, black background, the figure standing on the bottom edge.
- **Greyscale only.** Luminance is the only thing baked (red channel × alpha), so
  draw in greys from `#000` to `#fff`. Colour in the SVG is ignored.
- **The one red accent is not in the SVG.** The shader draws it at a fixed canvas
  point per style (`clipUV` in `GlyphField.qml`, e.g. the glam earring).
- **Named groups are required.** `gen_figure.py` renders the file several times with
  different groups hidden, so every element must live in one of these
  `<g id="…">` groups (order = paint order):

  | group | meaning |
  |---|---|
  | `hair-back` | hair behind the head and body |
  | `neck`, `body` | neck, torso, clothing |
  | `rim` | thin bright rim light along the silhouette (optional) |
  | `hair-curtain` | long hair in front; **sways** (weight ramps down the canvas) |
  | `hand` | a raised hand, drawn over the hair (optional) |
  | `face` | skin, nose, mouth, brows, blush |
  | `eyes-open` / `eyes-closed` | the two blink states (baked into R and G) |
  | `hair-side`, `bangs`, `ahoge` | front hair; `bangs`/`ahoge` sway lightly |
  | `clip` | accessories at the red-accent position |

- **Stroke rule:** dots are 5–8 px apart, so no feature thinner than ~2 dots
  (≈10–12 canvas px) survives. Highlights ≥ 22 px. Separate shapes (arm vs. torso,
  fingers) need a gap of at least one dot.
- **Value bands that read well:** hair ≈ 0.28 with strand highlights ≈ 0.5,
  skin ≈ 0.8–0.88, clothing at least one step above the background (≈ 0.23 or
  more, with lighter folds), liner / brows / lip line 0. Never leave large flat
  near-black areas: they turn into holes.

Two styles ship: `glam.svg` (portrait) and `girl.svg` (cute). Each is drawn whole in
one file. A new style can reuse the glam head by copying it into a new SVG and
drawing a different body.

## 2. Baking (`gen_figure.py`)

```bash
python3 wallpapers/glyphgirl/gen_figure.py glam      # or: cute
```

Needs `rsvg-convert`, `numpy` and `Pillow`. It renders the SVG with eyes open and
closed, builds the silhouette, sway weights and face mask, bakes a one-dot
jaw/cheek contour, and writes `figure-<style>.png` and `figure-<style>-aux.png`
into the plugin package.

## 3. Rendering (`GlyphField.qml` + `shaders/glyphfield.frag`)

- One fragment shader draws everything. The figure's dot pitch is set per style
  (`figurePitch`: glam 8, cute 5 — divisors of the 24 px field).
- Dot **size** follows luminance (`mix(0.30, 0.80, lum) × pitch`), so dark features
  become missing dots. Highlights flagged in the face mask are forced to full size.
- Animation is driven by one time uniform: breathing (scale), hair sway (aux R),
  blink (R ↔ G), a Glyph sweep across the field and figure, and a ripple from the
  red accent. 12–24 fps, paused when hidden.
- After editing the `.frag`, recompile: `scripts/build-wallpaper.sh --shaders`
  (uses `/usr/lib/qt6/bin/qsb`).

## 4. Adding a new style

1. Draw `wallpapers/glyphgirl/<name>.svg` following section 1 (or a `make_<name>.py`
   that combines an existing head with a new body fragment).
2. Add it to `STYLES` in `gen_figure.py` and bake it.
3. In `GlyphField.qml`, add `<name>` to the `_style` list, give it a `figurePitch`
   and a `clipUV` (red accent position, canvas coords / 600 and / 800).
4. Add it to the Style combo box in `contents/ui/config.qml`
   (`CharacterStyle` in `contents/config/main.xml`).
5. `scripts/build-wallpaper.sh` to install. To load the new code, switch the
   desktop wallpaper away and back, or restart plasmashell.

## 5. Previewing without a screen

```bash
QT_QPA_PLATFORMTHEME=kde tools/render.sh previews/LiveWallpaperPreview.qml previews/livewallpaper.png 1600 900
QT_QPA_PLATFORMTHEME=kde tools/render.sh previews/LiveWallpaperDetail.qml  previews/livewallpaper-detail.png 1600 900
```

Preview files starting with `// render: rhi` render through offscreen OpenGL so
the real shader is used.
