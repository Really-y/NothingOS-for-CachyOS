// Nothing "Glyph field" — one full-screen pass draws the whole wallpaper.
//  * background: coarse dot grid (pitch, dot = 0.65 x pitch), every dot lit from its cell
//    centre so a dot is always one flat level, like a Glyph LED
//  * figure: an original anime portrait baked into figTex/figAux (wallpapers/glyphgirl),
//    shown as a FINE dot matrix (figPitch, subdivides the coarse grid) — hair sway,
//    breathing and blinking are pure uniform-driven texture lookups
//  * one red dot (#d71921): the hair-clip bead, or bottom-right when the figure is off
//
// Build: scripts/build-wallpaper.sh  (qsb -> glyphfield.frag.qsb, committed)
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;          // item size, px
    float pitch;       // background grid pitch, px
    float dotRatio;    // dot diameter / pitch (house rule 0.65)
    float base;        // background dot luminance (0..1)
    float sweep;       // band position 0..1 along the diagonal, <0 = off
    float sweepGain;   // luminance added at the band's crest
    vec2 ripple;       // x = ring radius px, y = amplitude 0..1
    float breath;      // red dot opacity 0..1
    float redOn;       // 1 = draw the red dot
    vec2 redPos;       // red dot centre, px
    float redR;        // red dot radius, px
    vec2 mouse;        // pointer, px
    float mouseOn;     // pointer glow amount 0..1
    float figOn;       // 1 = draw the figure
    vec4 figRect;      // figure canvas on screen: x, y, w, h (px)
    float figPitch;    // fine grid pitch, px
    float swayPhase;   // hair sway phase, radians
    float swayAmp;     // hair sway amplitude at a free tip, in figure uv
    float blink;       // 0 = eyes open, 1 = closed
    float breathe;     // figure scale delta (breathing), e.g. 0..0.012
};

layout(binding = 1) uniform sampler2D figTex;   // R open, G closed, B silhouette
layout(binding = 2) uniform sampler2D figAux;   // R sway weight, G dilated silhouette

float lift(vec2 c)
{
    float l = 0.0;
    if (sweep >= 0.0) {   // Glyph sweep: diagonal band, sharp leading edge, long soft trail
        float s = (c.x * 0.8 + c.y * 0.6) / (res.x * 0.8 + res.y * 0.6);
        float k = s - mix(-0.2, 1.2, sweep);
        float w = k > 0.0 ? 0.035 : 0.16;
        l += sweepGain * exp(-(k * k) / (w * w));
    }
    if (ripple.y > 0.0) { // notification ripple: one ring out of the red dot
        float dr = length(c - redPos) - ripple.x;
        l += 0.17 * ripple.y * exp(-(dr * dr) / (pitch * pitch * 1.4));
    }
    if (mouseOn > 0.0) {  // pointer proximity (~120 px)
        float m = 1.0 - smoothstep(0.0, 120.0, length(c - mouse));
        l += 0.13 * mouseOn * m * m;
    }
    return l;
}

vec2 figUV(vec2 p)       // screen px -> figure uv, with breathing (scale about bottom centre)
{
    vec2 uv = (p - figRect.xy) / figRect.zw;
    return vec2(0.5, 1.0) + (uv - vec2(0.5, 1.0)) / (1.0 + breathe);
}

void main()
{
    vec2 p = qt_TexCoord0 * res;
    vec3 col = vec3(0.0);

    // ---- background dot ----
    vec2 c = (floor(p / pitch) + 0.5) * pitch;
    float covC = clamp(0.5 * dotRatio * pitch - length(p - c) + 0.5, 0.0, 1.0);
    if (covC > 0.0) {
        vec2 uv = c / res;
        float g = clamp(uv.x * 0.55 + uv.y * 0.45, 0.0, 1.0);
        float lum = min(0.30, base * (0.85 + 0.35 * g * g) + lift(c));   // never brighter than her hair rim
        if (figOn > 0.5) {
            vec2 fu = figUV(c);
            if (all(greaterThanEqual(fu, vec2(0.0))) && all(lessThanEqual(fu, vec2(1.0))))
                covC *= 1.0 - texture(figAux, fu).g;          // make room for her
        }
        col = vec3(lum * covC);
    }

    // ---- figure (fine dot matrix; dot SIZE and brightness follow luminance) ----
    if (figOn > 0.5) {
        vec2 f = (floor(p / figPitch) + 0.5) * figPitch;
        float dist = length(p - f);
        vec2 uv = figUV(f);
        // early out: outside the largest possible dot, or outside her canvas
        if (dist < 0.40 * figPitch + 0.5 && uv.x > -0.05 && uv.x < 1.05 && uv.y > -0.05 && uv.y < 1.0) {
            vec3 a = texture(figAux, uv).rgb;               // sway, feathered silhouette, face mask
            if (a.r > 0.0)   // hair: travelling wave from root to tip, two harmonics
                uv.x -= a.r * swayAmp * (sin(swayPhase - uv.y * 5.0 + uv.x * 2.0)
                                         + 0.35 * sin(2.0 * swayPhase - uv.y * 9.0 + 1.3));
            vec2 d = 0.25 * figPitch / figRect.zw;          // 4 taps ~ area average of the cell
            vec3 t = texture(figTex, uv + vec2(-d.x, -d.y)).rgb + texture(figTex, uv + vec2(d.x, -d.y)).rgb
                   + texture(figTex, uv + vec2(-d.x,  d.y)).rgb + texture(figTex, uv + vec2(d.x,  d.y)).rgb;
            t *= 0.25;
            float sil = smoothstep(0.30, 0.55, t.b);
            float lum = mix(t.r, t.g, blink);
            // eye highlights (1.0 in the art) bypass the area average: any tap on one -> full dot
            vec2 o = vec2(d.x, -d.y);
            float hi = max(max(mix(texture(figTex, uv - d).r, texture(figTex, uv - d).g, blink),
                               mix(texture(figTex, uv + d).r, texture(figTex, uv + d).g, blink)),
                           max(mix(texture(figTex, uv - o).r, texture(figTex, uv - o).g, blink),
                               mix(texture(figTex, uv + o).r, texture(figTex, uv + o).g, blink)));
            float face = smoothstep(0.4, 0.8, a.b);
            // in the face, dark features are MISSING dots; elsewhere keep the faint grid floor
            lum = face > 0.5 ? (lum < 0.05 ? 0.0 : lum) : max(0.055, lum);
            if (hi > 0.97) lum = 1.0;
            if (sil > 0.0 && lum > 0.0) {
                float r = 0.5 * mix(0.30, 0.80, clamp(lum, 0.0, 1.0)) * figPitch;
                float covF = clamp(r - dist + 0.5, 0.0, 1.0);
                float v = min(1.0, lum + 0.6 * lift(f));
                col = max(col, vec3(v * covF * sil));
            }
        }
    }

    // ---- the one red dot ----
    if (redOn > 0.5) {
        float cr = clamp(redR - length(p - redPos) + 0.5, 0.0, 1.0);
        col = mix(col, vec3(0.843, 0.098, 0.129), cr * breath);
    }

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
