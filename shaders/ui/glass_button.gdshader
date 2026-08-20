shader_type canvas_item;
render_mode unshaded;

uniform vec4 base_color : source_color = vec4(0.035, 0.075, 0.095, 0.68);
uniform vec4 hover_color : source_color = vec4(0.075, 0.145, 0.185, 0.78);
uniform vec4 rim_color : source_color = vec4(0.48, 0.78, 0.96, 1.0);
uniform float hover_amount : hint_range(0.0, 1.0) = 0.0;
uniform float press_amount : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

void fragment() {
	float n = hash21(floor(UV * 180.0));
	vec3 color = mix(base_color.rgb, hover_color.rgb, hover_amount);
	color *= 1.0 - press_amount * 0.18;
	color += (n - 0.5) * 0.025;

	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float rim = 1.0 - smoothstep(0.0, 0.045, edge);
	color += rim_color.rgb * rim * (0.10 + hover_amount * 0.16);

	COLOR = vec4(color, 0.96);
}
