shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.035, 0.075, 0.095, 0.62);
uniform vec4 rim : source_color = vec4(0.48, 0.78, 0.96, 1.0);
uniform float blur_radius : hint_range(0.0, 6.0) = 2.2;
uniform float distortion : hint_range(0.0, 0.02) = 0.0035;
uniform float noise_amount : hint_range(0.0, 0.08) = 0.025;
uniform float scratch_amount : hint_range(0.0, 0.10) = 0.025;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
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

float scratch(vec2 uv) {
	float a = abs(sin(uv.x * 420.0 + uv.y * 71.0));
	float b = abs(sin(uv.x * 91.0 - uv.y * 530.0));
	return max(smoothstep(0.985, 1.0, a), smoothstep(0.992, 1.0, b));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float n = noise(UV * 170.0 + TIME * 0.012);
	vec2 warp = vec2(
		noise(UV * 70.0 + 11.0) - 0.5,
		noise(UV * 70.0 + 31.0) - 0.5
	) * distortion;

	vec2 px = SCREEN_PIXEL_SIZE * blur_radius;
	vec4 c = vec4(0.0);
	c += texture(screen_texture, uv + warp + vec2(-px.x, 0.0));
	c += texture(screen_texture, uv + warp + vec2(px.x, 0.0));
	c += texture(screen_texture, uv + warp + vec2(0.0, -px.y));
	c += texture(screen_texture, uv + warp + vec2(0.0, px.y));
	c += texture(screen_texture, uv + warp);
	c /= 5.0;

	vec3 glass = mix(c.rgb, tint.rgb, tint.a);
	glass += (n - 0.5) * noise_amount;
	glass += rim.rgb * scratch(UV) * scratch_amount;

	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float edge_mask = 1.0 - smoothstep(0.0, 0.055, edge);
	glass += rim.rgb * edge_mask * 0.12;

	COLOR = vec4(glass, 0.96);
}
