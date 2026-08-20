shader_type canvas_item;

uniform float drift_speed: hint_range(0.0, 1.0) = 0.12;

void fragment() {
    vec2 uv = UV;
    float t = TIME * drift_speed;
    float wave_a = sin((uv.x * 5.0 + t) * 1.7) * 0.5 + 0.5;
    float wave_b = cos((uv.y * 4.0 - t * 0.7) * 1.4) * 0.5 + 0.5;
    float glow = smoothstep(0.25, 0.95, wave_a * wave_b);
    vec3 base = vec3(0.018, 0.025, 0.033);
    vec3 cool = vec3(0.045, 0.085, 0.115);
    vec3 color = mix(base, cool, glow * 0.34);
    COLOR = vec4(color, 1.0);
}
