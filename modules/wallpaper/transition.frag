#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    int transitionType;
    vec2 resolution;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D target;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float p = clamp(progress, 0.0, 1.0);
    float mixVal = p;
    
    float aspect = resolution.x / max(resolution.y, 1.0);
    vec2 uvAspect = vec2((uv.x - 0.5) * aspect, uv.y - 0.5);
    float dist = length(uvAspect);
    float maxDist = length(vec2(0.5 * aspect, 0.5));
    
    if (transitionType == 0) {
        // circle_expand
        float edge = p * maxDist * 1.05;
        mixVal = 1.0 - smoothstep(edge - 0.04, edge + 0.02, dist);
    } else if (transitionType == 1) {
        // circle_contract
        float edge = (1.0 - p) * maxDist * 1.05;
        mixVal = smoothstep(edge - 0.02, edge + 0.04, dist);
    } else if (transitionType == 2) {
        // diamond_expand
        float d = abs(uvAspect.x) + abs(uvAspect.y);
        float maxD = 0.5 * aspect + 0.5;
        float edge = p * maxD * 1.05;
        mixVal = 1.0 - smoothstep(edge - 0.04, edge + 0.02, d);
    } else if (transitionType == 3) {
        // clock_wipe
        float angle = atan(uvAspect.y, uvAspect.x);
        float normAngle = (angle + 3.14159265) / (2.0 * 3.14159265);
        mixVal = smoothstep(normAngle - 0.02, normAngle + 0.02, p);
    } else if (transitionType == 4) {
        // spiral
        float angle = atan(uvAspect.y, uvAspect.x) / (2.0 * 3.14159265) + 0.5;
        float spiralVal = fract(angle + dist * 2.0);
        mixVal = smoothstep(spiralVal - 0.05, spiralVal + 0.05, p);
    } else if (transitionType == 5) {
        // wipe_left
        float edge = 1.0 - p;
        mixVal = 1.0 - smoothstep(edge - 0.03, edge + 0.03, uv.x);
    } else if (transitionType == 6) {
        // wipe_right
        mixVal = smoothstep(uv.x - 0.03, uv.x + 0.03, p);
    } else if (transitionType == 7) {
        // wipe_up
        float edge = 1.0 - p;
        mixVal = 1.0 - smoothstep(edge - 0.03, edge + 0.03, uv.y);
    } else if (transitionType == 8) {
        // wipe_down
        mixVal = smoothstep(uv.y - 0.03, uv.y + 0.03, p);
    } else if (transitionType == 9) {
        // diagonal_tl_br
        float d = (uv.x + uv.y) * 0.5;
        mixVal = smoothstep(d - 0.03, d + 0.03, p);
    } else if (transitionType == 10) {
        // diagonal_tr_bl
        float d = ((1.0 - uv.x) + uv.y) * 0.5;
        mixVal = smoothstep(d - 0.03, d + 0.03, p);
    } else if (transitionType == 11) {
        // diagonal_bl_tr
        float d = (uv.x + (1.0 - uv.y)) * 0.5;
        mixVal = smoothstep(d - 0.03, d + 0.03, p);
    } else if (transitionType == 12) {
        // diagonal_br_tl
        float d = ((1.0 - uv.x) + (1.0 - uv.y)) * 0.5;
        mixVal = smoothstep(d - 0.03, d + 0.03, p);
    } else if (transitionType == 13) {
        // split_horizontal
        float d = abs(uv.x - 0.5) * 2.0;
        mixVal = 1.0 - smoothstep(p - 0.03, p + 0.03, d);
    } else if (transitionType == 14) {
        // split_vertical
        float d = abs(uv.y - 0.5) * 2.0;
        mixVal = 1.0 - smoothstep(p - 0.03, p + 0.03, d);
    } else if (transitionType == 15) {
        // venetian_blinds_h
        float bars = fract(uv.y * 14.0);
        mixVal = smoothstep(bars - 0.02, bars + 0.02, p);
    } else if (transitionType == 16) {
        // venetian_blinds_v
        float bars = fract(uv.x * 24.0);
        mixVal = smoothstep(bars - 0.02, bars + 0.02, p);
    } else if (transitionType == 17) {
        // wave_ripple
        float wave = sin(dist * 35.0 - p * 6.28) * 0.05 * (1.0 - p);
        float edge = p * maxDist * 1.1;
        mixVal = 1.0 - smoothstep(edge - 0.05, edge + 0.05, dist + wave);
    } else if (transitionType == 18) {
        // checkerboard
        vec2 grid = floor(uv * vec2(16.0 * aspect, 16.0));
        float check = fract((grid.x + grid.y) * 0.5);
        float delay = (check > 0.25) ? 0.2 : 0.0;
        mixVal = clamp((p - delay) / 0.8, 0.0, 1.0);
    } else if (transitionType == 19) {
        // noise_dissolve
        float n = hash(floor(uv * resolution * 0.15));
        mixVal = smoothstep(n - 0.1, n + 0.1, p * 1.2);
    } else if (transitionType == 20) {
        // cross_zoom
        vec2 center = vec2(0.5);
        vec2 uvTarget = center + (uv - center) * mix(1.2, 1.0, p);
        vec2 uvSource = center + (uv - center) * mix(1.0, 0.8, p);
        vec4 c1 = texture(source, clamp(uvSource, 0.0, 1.0));
        vec4 c2 = texture(target, clamp(uvTarget, 0.0, 1.0));
        fragColor = mix(c1, c2, smoothstep(0.0, 1.0, p)) * qt_Opacity;
        return;
    } else {
        // soft_dissolve (type 21)
        mixVal = smoothstep(0.0, 1.0, p);
    }
    
    vec4 c1 = texture(source, uv);
    vec4 c2 = texture(target, uv);
    fragColor = mix(c1, c2, clamp(mixVal, 0.0, 1.0)) * qt_Opacity;
}
