shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;
// A red tint that is strongest at the screen edges and fades to nothing towards the middle.

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint : source_color = vec3(0.95, 0.05, 0.05);
uniform float max_alpha = 0.6;

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float r = max(abs(c.x), abs(c.y)) * 0.6 + length(c) * 0.4; // rounded-square falloff
	float edge = smoothstep(0.45, 1.05, r);
	ALBEDO = tint;
	ALPHA = edge * edge * max_alpha * amount;
}
