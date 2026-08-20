shader_type canvas_item;

uniform float time_scale : hint_range(0.0, 2.0) = 0.12;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec2 uv = UV;
    float t = TIME * time_scale;

    float n1 = noise(uv * 3.2 + vec2(t, -t * 0.55));
    float n2 = noise(uv * 7.0 + vec2(-t * 0.7, t * 0.3));
    float mist = smoothstep(0.38, 0.78, n1 * 0.72 + n2 * 0.28);

    float vignette = smoothstep(0.86, 0.18, distance(uv, vec2(0.5)));
    float cold_light = exp(-length((uv - vec2(0.16, 0.43)) * vec2(2.2, 1.4))) * 0.18;
    float cold_light_2 = exp(-length((uv - vec2(0.86, 0.36)) * vec2(2.8, 1.6))) * 0.12;

    vec3 base = vec3(0.008, 0.015, 0.020);
    vec3 haze = vec3(0.055, 0.105, 0.13) * mist * 0.34;
    vec3 glow = vec3(0.18, 0.48, 0.65) * (cold_light + cold_light_2);

    COLOR = vec4((base + haze + glow) * vignette, 1.0);
}
