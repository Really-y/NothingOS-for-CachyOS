// Nothing "Dot Image" — one full-screen pass turns a picture into a Glyph dot matrix.
//  * srcA / srcB: the picture(s), already fitted to the screen (Fill / Fit / Center) and
//    pre-shrunk by a ShaderEffectSource to ~2 texels per grid cell, so one bilinear tap at
//    the cell centre is an area average of the cell (no per-pixel detail, no aliasing)
//  * each cell = one round dot; its RADIUS follows the cell's toned luminance, quantised to
//    a few sizes (the designed Nothing look). Dark cells = missing dots, never fills.
//  * where there is no picture dot: the faint background grid (#1a1a1a-ish)
//  * animation: a diagonal Glyph sweep (brightens + slightly swells dots) and a sparse twinkle
//  * crossfade: tone is computed for A and B and blended, so dots morph size between images
//
// Build: scripts/build-dotimage.sh --shaders  (qsb -> dotimage.frag.qsb, committed)
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;          // item size, px
    float pitch;       // grid pitch, px
    float maxRatio;    // largest dot diameter / pitch
    float minDot;      // smallest visible dot diameter / pitch
    float levels;      // number of dot sizes (>= 2), 0 = continuous
    float contrast;    // around mid grey, 1 = neutral
    float brightness;  // gamma-like, 1 = neutral, >1 brighter
    vec3 lvA;          // picture A: black point, white point, auto gamma
    vec3 lvB;          // picture B: idem
    float fade;        // 0 = A, 1 = B
    float colorMode;   // 0 mono white, 1 original colour, 2 mono + red accent
    float edge;        // detail (sharpening + edge boost) 0..1
    float bgOn;        // 1 = faint background grid
    float bgLum;       // background dot luminance
    float sweep;       // band position 0..1 along the diagonal, <0 = off
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

// one picture's dot for the cell centred at c: x = dot size 0..1 (0 = none), yzw = colour
vec4 cellDot(sampler2D s, vec2 c, vec3 lv)
{
    vec2 uv = c / res;
    vec4 a = pick(s, uv);
    if (a.a < 0.5) return vec4(0.0);                       // outside the picture (Fit bars)
    float t = tone(luma(a.rgb), lv);
    if (edge > 0.0) {   // detail: unsharp mask over the 4 neighbour cells + a light edge boost
        vec2 d = vec2(pitch) / res;
        float l = tone(luma(pick(s, uv - vec2(d.x, 0.0)).rgb), lv);
        float r = tone(luma(pick(s, uv + vec2(d.x, 0.0)).rgb), lv);
        float u = tone(luma(pick(s, uv - vec2(0.0, d.y)).rgb), lv);
        float b = tone(luma(pick(s, uv + vec2(0.0, d.y)).rgb), lv);
        float g = smoothstep(0.12, 0.50, length(vec2(r - l, b - u)));
        t = clamp(t + edge * 0.6 * (t - 0.25 * (l + r + u + b)), 0.0, 1.0);
        t = max(t, edge * g * 0.55);
    }
    float q = t;
    // rounding is biased down (+0.3, not +0.5) so the darkest ~15 % become missing dots
    if (levels >= 2.0) q = floor(t * levels + 0.3) / levels;   // 0 + `levels` sizes
    else q = t < 0.12 ? 0.0 : t;                               // continuous: still drop the darkest

    vec3 col = vec3(1.0);
    if (colorMode > 0.5 && colorMode < 1.5) {              // original colour, full value
        float m = max(max(a.r, a.g), a.b);
        col = m > 0.001 ? a.rgb / m : vec3(1.0);
    } else if (colorMode > 1.5) {                          // mono + red accent
        float mx = max(max(a.r, a.g), a.b), mn = min(min(a.r, a.g), a.b);
        float sat = mx > 0.001 ? (mx - mn) / mx : 0.0;
        bool redHue = a.r >= mx - 0.001 && max(a.g, a.b) < a.r * 0.55;   // hue within ~±20° of red
        if (redHue && sat > 0.45 && mx > 0.30) {   // accent: Nothing red, at least a mid-size dot
            col = RED;
            q = max(q, levels >= 2.0 ? floor(0.65 * levels + 0.5) / levels : 0.65);
        }
    }
    return vec4(q, col);
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main()
{
    vec2 p = qt_TexCoord0 * res;
    vec2 cell = floor(p / pitch);
    vec2 c = (cell + 0.5) * pitch;
    float dist = length(p - c);

    // Glyph sweep: diagonal band, sharp leading edge, long soft trail
    float band = 0.0;
    if (sweep >= 0.0) {
        float s = (c.x * 0.8 + c.y * 0.6) / (res.x * 0.8 + res.y * 0.6);
        float k = s - mix(-0.2, 1.2, sweep);
        float w = k > 0.0 ? 0.03 : 0.14;
        band = exp(-(k * k) / (w * w));
    }

    vec4 d = vec4(0.0);
    if (fade < 0.999) d = cellDot(srcA, c, lvA);
    if (fade > 0.001) d = mix(d, cellDot(srcB, c, lvB), fade);

    vec3 col = vec3(0.0);
    if (d.x > 0.004) {
        float r = 0.5 * pitch * mix(minDot, maxRatio, d.x) * (1.0 + 0.10 * band);
        float cov = clamp(r - dist + 0.5, 0.0, 1.0);
        float v = mix(0.62, 1.0, d.x) + 0.30 * band;
        if (twinkle > 0.0) {
            float h = hash(cell);
            if (h < 0.06)   // ~6 % of dots shimmer, each on its own phase
                v *= 1.0 - twinkle * 0.32 * (0.5 + 0.5 * sin(phase * (h < 0.03 ? 1.0 : 2.0) + h * 157.0));
        }
        col = min(vec3(1.0), d.yzw * v) * cov;
    } else if (bgOn > 0.5) {
        float r = 0.5 * pitch * 0.42;
        float cov = clamp(r - dist + 0.5, 0.0, 1.0);
        col = vec3(min(0.32, bgLum + 0.20 * band) * cov);
    }

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
