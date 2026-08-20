shader_type canvas_item;
render_mode unshaded;

uniform float blur_radius : hint_range(0.0, 8.0) = 2.8;
uniform float opacity : hint_range(0.0, 1.0) = 0.22;
uniform vec4 tint : source_color = vec4(0.08, 0.14, 0.18, 0.42);

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
    vec2 px = 1.0 / vec2(textureSize(screen_texture, 0));
    vec2 step_uv = px * blur_radius;

    vec3 blurred = vec3(0.0);
    blurred += textureLod(screen_texture, SCREEN_UV + vec2(-step_uv.x, -step_uv.y), 0.0).rgb;
    blurred += textureLod(screen_texture, SCREEN_UV + vec2(0.0, -step_uv.y), 0.0).rgb;
    blurred += textureLod(screen_texture, SCREEN_UV + vec2(step_uv.x, -step_uv.y), 0.0).rgb;
    blurred += textureLod(screen_texture, SCREEN_UV + vec2(-step_uv.x, 0.0), 0.0).rgb;
    blurred += textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
    blurred += textureLod(screen_texture, SCREEN_UV + vec2(step_uv.x, 0.0), 0.0).rgb;
    blurred += textureLod(screen_texture, SCREEN_UV + vec2(-step_uv.x, step_uv.y), 0.0).rgb;
    blurred += textureLod(screen_texture, SCREEN_UV + vec2(0.0, step_uv.y), 0.0).rgb;
    blurred += textureLod(screen_texture, SCREEN_UV + vec2(step_uv.x, step_uv.y), 0.0).rgb;
    blurred /= 9.0;

    vec3 color = mix(blurred, tint.rgb, tint.a);
    COLOR = vec4(color, opacity);
}
