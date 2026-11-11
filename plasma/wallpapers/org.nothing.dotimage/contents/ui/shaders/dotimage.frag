// Nothing "Dot Image" — one full-screen pass turns a picture into Nothing dot art.
//  * srcA / srcB: the picture(s), already framed on the screen (Fill / Fit / Center) and
//    rendered by a ShaderEffectSource at ~2 texels per (fine) dot cell, with mipmaps.
//    One bilinear tap at a cell centre = the cell's average; a high mip = a soft blur.
//  * look 0 "Glyph field" (the org.nothing.dots language):
//      - a dim coarse field (fieldPitch 24 px, dot 0.65 x pitch, #141414..#1c1c1c), everywhere
//      - the picture as a FINE dot matrix (fine = 3/4/6/8 px, divides 24 so grids share an
//        origin); dot size AND brightness follow luminance: r = mix(0.30, 0.80, lum) x pitch
//      - a blurred, thresholded luminance mask (= dilated silhouette) fades the coarse field
//        under the picture's bright parts and lays a faint fine floor there: soft edges
//      - Glyph sweep across both grids; a ripple ring out of the red accent (mono + red)
//  * look 1 "Halftone": one grid; dot RADIUS follows toned luminance quantised to a few
//    sizes, faint background grid where the picture is dark, sweep + sparse twinkle
//  * crossfade: tone is computed for A and B and blended, so dots morph between images
//
// Build: scripts/build-dotimage.sh --shaders  (qsb -> dotimage.frag.qsb, committed)
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;          // item size, px
    float look;        // 0 glyph field, 1 halftone
    float pitch;       // halftone grid pitch / glyph FINE pitch, px
    float fieldPitch;  // glyph coarse field pitch, px (24)
    float maskLod;     // mip level for the glyph mask blur
    float maxRatio;    // halftone: largest dot diameter / pitch
    float minDot;      // halftone: smallest visible dot diameter / pitch
    float levels;      // halftone: number of dot sizes (>= 2), 0 = continuous
    float contrast;    // around mid grey, 1 = neutral
    float brightness;  // gamma-like, 1 = neutral, >1 brighter
    vec3 lvA;          // picture A: black point, white point, auto gamma
    vec3 lvB;          // picture B: idem
    float fade;        // 0 = A, 1 = B
    float colorMode;   // 0 mono white, 1 original colour, 2 mono + red accent
    float edge;        // detail (sharpening + edge boost) 0..1
    float bgOn;        // halftone: 1 = faint background grid
    float bgLum;       // halftone: background dot luminance
    float base;        // glyph: field dot luminance
    float sweep;       // band position 0..1 along the diagonal, <0 = off
    vec2 ripple;       // glyph: x = ring radius px, y = amplitude 0..1
    vec2 redPos;       // glyph: ripple centre (red accent centroid), px
    float twinkle;     // twinkle amount 0..1 (0 = off)
    float phase;       // twinkle phase, radians (loops cleanly)
};

layout(binding = 1) uniform sampler2D srcA;
layout(binding = 2) uniform sampler2D srcB;

const vec3 RED = vec3(0.843, 0.098, 0.129);   // Nothing red #d71921

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// picture at uv (premultiplied texture) -> rgb, coverage
vec4 pick(sampler2D s, vec2 uv)
{
    vec4 t = texture(s, uv);
    return vec4(t.a > 0.004 ? t.rgb / t.a : vec3(0.0), t.a);
}

// raw luminance -> 0..1 tone (levels stretch, auto gamma, user brightness / contrast)
float tone(float l, vec3 lv)
{
    float t = clamp((l - lv.x) / max(0.02, lv.y - lv.x), 0.0, 1.0);
    t = pow(t, lv.z / max(0.1, brightness));
    return clamp((t - 0.5) * contrast + 0.5, 0.0, 1.0);
}

// one picture at the cell centred at c (cell size cp): x = tone 0..1 (-1 = no picture), yzw = colour
vec4 cellTone(sampler2D s, vec2 c, vec3 lv, float cp)
{
    vec2 uv = c / res;
    vec4 a = pick(s, uv);
    if (a.a < 0.5) return vec4(-1.0, 0.0, 0.0, 0.0);      // outside the picture (Fit bars)
    float t = tone(luma(a.rgb), lv);
    if (edge > 0.0) {   // detail: unsharp mask over the 4 neighbour cells + a light edge boost
        vec2 d = vec2(cp) / res;
        float l = tone(luma(pick(s, uv - vec2(d.x, 0.0)).rgb), lv);
        float r = tone(luma(pick(s, uv + vec2(d.x, 0.0)).rgb), lv);
        float u = tone(luma(pick(s, uv - vec2(0.0, d.y)).rgb), lv);
        float b = tone(luma(pick(s, uv + vec2(0.0, d.y)).rgb), lv);
        float g = smoothstep(0.12, 0.50, length(vec2(r - l, b - u)));
        t = clamp(t + edge * 0.6 * (t - 0.25 * (l + r + u + b)), 0.0, 1.0);
        t = max(t, edge * g * 0.55);
    }
    vec3 col = vec3(1.0);
    if (colorMode > 0.5 && colorMode < 1.5) {              // original colour, full value
        float m = max(max(a.r, a.g), a.b);
        col = m > 0.001 ? a.rgb / m : vec3(1.0);
    } else if (colorMode > 1.5) {                          // mono + red accent
        float mx = max(max(a.r, a.g), a.b), mn = min(min(a.r, a.g), a.b);
        float sat = mx > 0.001 ? (mx - mn) / mx : 0.0;
        bool redHue = a.r >= mx - 0.001 && max(a.g, a.b) < a.r * 0.55;   // hue within ~±20° of red
        if (redHue && sat > 0.45 && mx > 0.30) { col = RED; t = max(t, 0.65); }
    }
    return vec4(t, col);
}

// glyph look: soft, dilated "where the picture is" mask at screen point c (0..1)
float maskAt(sampler2D s, vec2 c, vec3 lv)
{
    vec4 m = textureLod(s, c / res, maskLod);
    if (m.a < 0.02) return 0.0;
    return m.a * smoothstep(0.06, 0.24, tone(luma(m.rgb / m.a), lv));
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float sweepBand(vec2 c)   // Glyph sweep: diagonal band, sharp leading edge, long soft trail
{
    if (sweep < 0.0) return 0.0;
    float s = (c.x * 0.8 + c.y * 0.6) / (res.x * 0.8 + res.y * 0.6);
    float k = s - mix(-0.2, 1.2, sweep);
    float w = k > 0.0 ? 0.035 : 0.16;
    return exp(-(k * k) / (w * w));
}

float glyphLift(vec2 c)  // as glyphfield.frag: sweep crest + ripple ring
{
    float l = 0.215 * sweepBand(c);
    if (ripple.y > 0.0) {
        float dr = length(c - redPos) - ripple.x;
        l += 0.17 * ripple.y * exp(-(dr * dr) / (fieldPitch * fieldPitch * 1.4));
    }
    return l;
}

float twinkleGain(vec2 cell)
{
    if (twinkle <= 0.0) return 1.0;
    float h = hash(cell);
    if (h >= 0.06) return 1.0;   // ~6 % of dots shimmer, each on its own phase
    return 1.0 - twinkle * 0.32 * (0.5 + 0.5 * sin(phase * (h < 0.03 ? 1.0 : 2.0) + h * 157.0));
}

vec4 mixTone(vec2 c, float cp)   // A/B crossfade of cellTone; x < 0 = no picture
{
    vec4 d = fade < 0.999 ? cellTone(srcA, c, lvA, cp) : vec4(-1.0, 0.0, 0.0, 0.0);
    if (fade <= 0.001) return d;
    vec4 e = cellTone(srcB, c, lvB, cp);
    if (fade >= 0.999 || (d.x < 0.0 && e.x < 0.0)) return e;
    const vec4 none = vec4(0.0, 1.0, 1.0, 1.0);          // "no picture" blends as an empty dot
    return mix(d.x < 0.0 ? none : d, e.x < 0.0 ? none : e, fade);
}

float mixMask(vec2 c)
{
    float m = fade < 0.999 ? maskAt(srcA, c, lvA) : 0.0;
    if (fade > 0.001) m = mix(m, maskAt(srcB, c, lvB), fade);
    return m;
}

void main()
{
    vec2 p = qt_TexCoord0 * res;
    vec3 col = vec3(0.0);

    if (look < 0.5) {
        // ---- coarse Glyph field, fading out under the picture ----
        vec2 cF = (floor(p / fieldPitch) + 0.5) * fieldPitch;
        float covC = clamp(0.5 * 0.65 * fieldPitch - length(p - cF) + 0.5, 0.0, 1.0);
        if (covC > 0.0) {
            vec2 uv = cF / res;
            float g = clamp(uv.x * 0.55 + uv.y * 0.45, 0.0, 1.0);
            float lum = min(0.30, base * (0.85 + 0.35 * g * g) + glyphLift(cF));
            col = vec3(lum * covC * (1.0 - mixMask(cF)));
        }
        // ---- the picture as a fine dot matrix ----
        vec2 cell = floor(p / pitch);
        vec2 f = (cell + 0.5) * pitch;
        float dist = length(p - f);
        if (dist < 0.40 * pitch + 0.5) {
            vec4 d = mixTone(f, pitch);
            if (d.x >= 0.0) {
                float m = mixMask(f);
                float lum = d.x;
                vec3 tint = d.yzw;
                if (lum < 0.06) { lum = 0.055 * smoothstep(0.0, 0.5, m); tint = vec3(1.0); }  // faint floor
                if (lum > 0.0) {
                    float r = 0.5 * mix(0.30, 0.80, clamp(lum, 0.0, 1.0)) * pitch;
                    float cov = clamp(r - dist + 0.5, 0.0, 1.0);
                    float v = min(1.0, (lum + 0.6 * glyphLift(f)) * twinkleGain(cell));
                    if (colorMode > 1.5 && tint.g < 0.5) v = max(v, 0.95);   // the red accent stays vivid
                    col = max(col, min(vec3(1.0), tint * v) * cov);
                }
            }
        }
    } else {
        // ---- halftone: one grid, radius follows quantised tone ----
        vec2 cell = floor(p / pitch);
        vec2 c = (cell + 0.5) * pitch;
        float dist = length(p - c);
        float band = sweepBand(c);
        vec4 d = mixTone(c, pitch);
        float q = max(d.x, 0.0);
        // rounding is biased down (+0.3, not +0.5) so the darkest ~15 % become missing dots
        if (levels >= 2.0) q = floor(q * levels + 0.3) / levels;   // 0 + `levels` sizes
        else q = q < 0.12 ? 0.0 : q;                               // continuous: still drop the darkest
        if (q > 0.004) {
            float r = 0.5 * pitch * mix(minDot, maxRatio, q) * (1.0 + 0.10 * band);
            float cov = clamp(r - dist + 0.5, 0.0, 1.0);
            float v = (mix(0.62, 1.0, q) + 0.30 * band) * twinkleGain(cell);
            col = min(vec3(1.0), d.yzw * v) * cov;
        } else if (bgOn > 0.5) {
            float r = 0.5 * pitch * 0.42;
            float cov = clamp(r - dist + 0.5, 0.0, 1.0);
            col = vec3(min(0.32, bgLum + 0.20 * band) * cov);
        }
    }

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
