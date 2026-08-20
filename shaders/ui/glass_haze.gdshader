shader_type canvas_item;

uniform vec4 tint: source_color = vec4(0.30, 0.50, 0.62, 0.10);
uniform float speed: hint_range(0.0, 1.0) = 0.08;

void fragment() {
    vec2 uv = UV;
    float t = TIME * speed;
    float a = sin((uv.x * 7.0) + t) * 0.5 + 0.5;
    float b = sin((uv.y * 9.0) - t * 1.4) * 0.5 + 0.5;
    float mask = smoothstep(0.2, 0.9, a * b);
    COLOR = vec4(tint.rgb, tint.a * mask);
}
