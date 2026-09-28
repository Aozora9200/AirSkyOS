#extension GL_OES_standard_derivatives : enable

#define LG_SAMPLE(tex, coord) texture2D(tex, coord)
#define LG_OUT gl_FragColor

// Aozora Glass — SDF helpers

#ifndef AOZORAGLASS_SDF_GLSL
#define AOZORAGLASS_SDF_GLSL

uniform vec2 blurSize;

float lgRoundedRectDistance(vec2 p, vec2 halfSize, vec4 cornerRadius)
{
    float r = p.x > 0.0
        ? (p.y > 0.0 ? cornerRadius.y : cornerRadius.w)
        : (p.y > 0.0 ? cornerRadius.x : cornerRadius.z);
    vec2 q = abs(p) - halfSize + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

vec2 lgRoundedRectNormal(vec2 p, vec2 halfSize, vec4 cornerRadius)
{
    float r = p.x > 0.0
        ? (p.y > 0.0 ? cornerRadius.y : cornerRadius.w)
        : (p.y > 0.0 ? cornerRadius.x : cornerRadius.z);
    vec2 q = abs(p) - halfSize + r;
    vec2 qc = max(q, 0.0);
    float ql = length(qc);
    vec2 n = (ql > 0.001)
        ? qc / ql
        : (q.x > q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0));
    return n * sign(p + 0.0001);
}

#endif

// Aozora Glass — blur helpers

#ifndef AOZORAGLASS_BLUR_GLSL
#define AOZORAGLASS_BLUR_GLSL

// Shared SAMPLES×SAMPLES tap grid used by every kernel below.
#define LG_BLUR_SAMPLES 9
#define LG_GAUSS_SIGMA 0.33

// Blur type IDs — must mirror the AcrylicGlassType enum order in glass.kcfg.
#define LG_BLUR_GAUSSIAN 0
#define LG_BLUR_BOX      1
#define LG_BLUR_LENS     2

// Box and Lens reach further than Gaussian so their kernel shape can dominate
// the already-Kawase-smoothed input. Tuned so the three modes are clearly
// distinguishable at the same BlurStrength.
#define LG_BOX_RADIUS_SCALE  6.0
#define LG_LENS_RADIUS_SCALE 7.0
// Bokeh highlight boost: brighter taps weigh more, producing the lens-blur
// signature glow on out-of-focus highlights.
#define LG_LENS_HIGHLIGHT_GAIN 12.0
#define LG_LENS_HIGHLIGHT_POW  4.0

// Gaussian: per-tap weight falls off with distance from center.
vec3 lgGaussianBlur(sampler2D texUnit, vec2 texel, vec2 uvCenter, vec2 rect)
{
    vec4 total = vec4(0.0);
    float weightSum = 0.0;
    float step = inversesqrt(float(LG_BLUR_SAMPLES));

    for (float i = -0.5; i <= 0.5; i += step)
    for (float j = -0.5; j <= 0.5; j += step)
    {
        float weight = exp(-(i * i + j * j) / (2.0 * LG_GAUSS_SIGMA * LG_GAUSS_SIGMA));
        vec2 coord = uvCenter + vec2(i, j) * rect * texel;
        total += LG_SAMPLE(texUnit, clamp(coord, 0.0, 1.0)) * weight;
        weightSum += weight;
    }

    return (total / max(weightSum, 0.0001)).rgb;
}

// Box: every tap inside a wider square contributes equally — flatter, frosted look.
vec3 lgBoxBlur(sampler2D texUnit, vec2 texel, vec2 uvCenter, vec2 rect)
{
    vec4 total = vec4(0.0);
    float weightSum = 0.0;
    float step = inversesqrt(float(LG_BLUR_SAMPLES));
    vec2 wideRect = rect * LG_BOX_RADIUS_SCALE;

    for (float i = -0.5; i <= 0.5; i += step)
    for (float j = -0.5; j <= 0.5; j += step)
    {
        vec2 coord = uvCenter + vec2(i, j) * wideRect * texel;
        total += LG_SAMPLE(texUnit, clamp(coord, 0.0, 1.0));
        weightSum += 1.0;
    }

    return (total / max(weightSum, 0.0001)).rgb;
}

// Lens (bokeh): disc kernel with brightness-weighted taps so highlights bloom.
vec3 lgLensBlur(sampler2D texUnit, vec2 texel, vec2 uvCenter, vec2 rect)
{
    vec4 total = vec4(0.0);
    float weightSum = 0.0;
    float step = inversesqrt(float(LG_BLUR_SAMPLES));
    vec2 wideRect = rect * LG_LENS_RADIUS_SCALE;

    for (float i = -0.5; i <= 0.5; i += step)
    for (float j = -0.5; j <= 0.5; j += step)
    {
        if ((i * i + j * j) > 0.25) continue;
        vec2 coord = uvCenter + vec2(i, j) * wideRect * texel;
        vec4 s = LG_SAMPLE(texUnit, clamp(coord, 0.0, 1.0));
        float luma = dot(s.rgb, vec3(0.299, 0.587, 0.114));
        float weight = 1.0 + pow(luma, LG_LENS_HIGHLIGHT_POW) * LG_LENS_HIGHLIGHT_GAIN;
        total += s * weight;
        weightSum += weight;
    }

    return (total / max(weightSum, 0.0001)).rgb;
}

vec3 lgBlurDispatch(int blurType, sampler2D texUnit, vec2 texel, vec2 uvCenter, vec2 rect)
{
    if (blurType == LG_BLUR_BOX)  return lgBoxBlur(texUnit, texel, uvCenter, rect);
    if (blurType == LG_BLUR_LENS) return lgLensBlur(texUnit, texel, uvCenter, rect);
    return lgGaussianBlur(texUnit, texel, uvCenter, rect);
}

#endif

// Aozora Glass — lens + chromatic distortion helpers

#ifndef AOZORAGLASS_DISTORT_GLSL
#define AOZORAGLASS_DISTORT_GLSL

vec2 lgLensUV(vec2 uv, float magnifyGlassStrength, float edgeQ)
{
    // Edge-gated lens. The previous formula
    //   totalMag = magnifyGlassStrength * (1.0 + edgeQ * 3.5)
    // bled the magnification into the centre of the window — at the
    // default magnifyGlassStrength=0.03 every pixel got a 3% inward
    // pull, so ~30 screen pixels collapsed to ~29 source texels. With
    // GL_LINEAR + the per-fragment snap-to-texel passthrough, that
    // produced the "crisp but temporally unstable, looks like 0.5"
    // artifact whenever the window moved by a single device pixel.
    //
    // Multiplying by edgeQ instead of adding 1.0 to it means the centre
    // (edgeQ=0) is now identity → snap returns the exact source texel,
    // pixel-perfect across frames. The rim (edgeQ≈1) still gets the
    // full magnification (4.5×, matching the previous peak value at
    // the edge: 1.0 + 3.5*1 = 4.5).
    vec2 center = vec2(0.5);
    float totalMag = magnifyGlassStrength * edgeQ * 4.5;
    return center + (uv - center) * (1.0 - totalMag);
}

vec3 lgApplyRgbDrift(sampler2D texUnit,
                     vec3 baseColor,
                     vec2 lensUV,
                     vec2 outwardNormal,
                     vec2 blurSizePx,
                     float rgbDriftStrength,
                     float edgeQ)
{
    vec2 safeSize = max(blurSizePx, vec2(1.0));
    vec2 drift = outwardNormal * (rgbDriftStrength / safeSize);

    float r = LG_SAMPLE(texUnit, clamp(lensUV + drift, 0.0, 1.0)).r;
    float g = LG_SAMPLE(texUnit, clamp(lensUV + drift * 0.30, 0.0, 1.0)).g;
    float b = LG_SAMPLE(texUnit, clamp(lensUV - drift * 0.25, 0.0, 1.0)).b;

    return mix(baseColor, vec3(r, g, b), edgeQ);
}

#endif

// Aozora Glass — highlight helpers

#ifndef AOZORAGLASS_HIGHLIGHT_GLSL
#define AOZORAGLASS_HIGHLIGHT_GLSL

// Y-axis-agnostic angular weight: brighter where outNorm faces "up",
// softer at the sides, dimmer on the bottom. Reference shader uses
// sin(atan(y, x) - phase) which is the same idea, simplified here to
// a direct dot product against a fixed "up" direction in normal-space
// (rim is in normalised coords already after the SDF normal call).
// 0.65..1.20 envelope keeps the rim visible everywhere but lit on top.
float lgRimAngularWeight(vec2 outNorm)
{
    // outNorm.y > 0 means the surface point sits on the upper half of
    // the rim. We don't know KWin's Y convention statically (varies by
    // GL profile / framebuffer orientation), so the envelope is gentle
    // enough that an inverted Y still reads as "slightly directional"
    // rather than "rim is on the wrong side". If the lit side ends up
    // visually inverted we can flip the sign here.
    return 0.65 + 0.55 * clamp(outNorm.y * 0.5 + 0.5, 0.0, 1.0);
}

vec3 lgApplyHighlight(vec3 color, float inside, vec2 outNorm,
                      float highlightWidth, float highlightStrength)
{
    float band = max(highlightWidth, 1.0);
    float rim = exp(-inside * (3.0 / band)) * smoothstep(0.0, 2.0, inside);
    float intensity = rim * highlightStrength * lgRimAngularWeight(outNorm);
    return mix(color, vec3(0.87, 0.93, 1.0), clamp(intensity, 0.0, 0.95));
}

#endif


uniform sampler2D texUnit;
uniform mat4 colorMatrix;
uniform float offset;
uniform vec2 halfpixel;
uniform vec4 box;
uniform vec4 cornerRadius;
uniform float opacity;
uniform float rgbDriftStrength;
uniform float magnifyGlassStrength;
uniform float refractionWidth;
uniform float highlightWidth;
uniform float highlightStrength;
uniform int blurType;

varying vec2 uv;
varying vec2 vertex;

void main(void)
{
    vec2 halfSize = blurSize * 0.5;
    vec2 pos = uv * blurSize - halfSize;

    // Inset by 1 px so highlight/refraction never bleed outside the window.
    vec2 insetHalf = max(halfSize - vec2(1.0), vec2(0.5));
    float d = lgRoundedRectDistance(pos, insetHalf, cornerRadius);
    if (d > 0.0) {
        discard;
    }

    vec2 outNorm = lgRoundedRectNormal(pos, insetHalf, cornerRadius);
    float inside = -d;

    float refrBand = max(refractionWidth, 1.0);
    float edgeT = smoothstep(-refrBand, 0.0, d);
    // Cubic rim concentration — refraction / RGB drift / lens distortion fall
    // off sharply away from the edge, leaving the centre of the glass clean.
    // The day9 reference shader uses pow(...,20) for the same intent on its
    // SDF demo; cubic is the conservative analogue for a window-sized effect.
    float edgeQ = edgeT * edgeT * edgeT;

    vec2 lensUV = (magnifyGlassStrength > 0.0)
        ? lgLensUV(uv, magnifyGlassStrength, edgeQ)
        : uv;
    vec2 texel = halfpixel * 2.0;
    vec3 col;
    if (offset > 0.0) {
        col = lgBlurDispatch(blurType, texUnit, texel, lensUV, vec2(offset * 3.0));
    } else {
        // Pixel-exact passthrough: snap to texel center so GL_LINEAR returns
        // the underlying texel exactly instead of a sub-pixel bilinear blend.
        vec2 snapped = (floor(lensUV / texel) + 0.5) * texel;
        col = LG_SAMPLE(texUnit, clamp(snapped, 0.0, 1.0)).rgb;
    }
    if (rgbDriftStrength > 0.0) {
        col = lgApplyRgbDrift(texUnit, col, lensUV, outNorm, blurSize, rgbDriftStrength, edgeQ);
    }
    if (highlightStrength > 0.0) {
        col = lgApplyHighlight(col, inside, outNorm, highlightWidth, highlightStrength);
    }

    float mask = 1.0 - smoothstep(-3.0, 0.0, d);
    LG_OUT = vec4(col, mask) * colorMatrix * opacity;
}
