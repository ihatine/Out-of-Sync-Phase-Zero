shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.08;

void fragment() {
    vec2 uv = UV;
    float line = sin(uv.y * 900.0) * scanline_strength * intensity;
    float shift = sin(uv.y * 180.0 + TIME * 7.0) * 0.004 * intensity;
    vec4 color = texture(TEXTURE, uv);
    vec4 shifted = texture(TEXTURE, vec2(uv.x + shift, uv.y));
    COLOR = mix(color, shifted, intensity * 0.35);
    COLOR.rgb -= line;
}
