shader_type sky;
// Daytime sky: a blue gradient, soft clouds drifting with the wind and a sun disc where the
// DirectionalLight3D "Sun" points (the same light that casts the shadows). Cheap on purpose
// (three noise octaves, no loops over lights): it runs per pixel on a Quest 2.

uniform vec3 zenith_colour : source_color = vec3(0.30, 0.55, 0.92);
uniform vec3 horizon_colour : source_color = vec3(0.70, 0.84, 0.97);
uniform vec3 ground_colour : source_color = vec3(0.42, 0.48, 0.42);
uniform vec3 cloud_colour : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cloud_shadow_colour : source_color = vec3(0.72, 0.78, 0.88);
uniform float cloud_scale = 1.4;
uniform float cloud_cover = 0.52;       // lower = more cloud
uniform vec2 wind = vec2(0.010, 0.004); // cloud drift per second, in noise units

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.03 + 7.1) * 0.3 + vnoise(p * 4.1 + 3.7) * 0.15;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = clamp(dir.y, -1.0, 1.0);
	vec3 col = mix(horizon_colour, zenith_colour, pow(clamp(up, 0.0, 1.0), 0.55));
	col = mix(col, ground_colour, smoothstep(0.0, -0.25, up));
	// Clouds on a flat layer above you; they thin out and fade towards the horizon.
	vec2 p = dir.xz / (max(up, 0.0) + 0.22) * cloud_scale + wind * TIME;
	float n = fbm(p);
	float c = smoothstep(cloud_cover, cloud_cover + 0.22, n) * smoothstep(0.02, 0.22, up);
	float lit = clamp((fbm(p + vec2(0.06, 0.05)) - n) * 6.0 + 0.5, 0.0, 1.0); // dark side vs light side
	col = mix(col, mix(cloud_shadow_colour, cloud_colour, lit), c * 0.95);
	// Sun disc and glow (not covered by thick cloud).
	if (LIGHT0_ENABLED) {
		float s = max(dot(dir, normalize(LIGHT0_DIRECTION)), 0.0);
		float disc = smoothstep(0.9990, 0.9996, s);
		float glow = pow(s, 64.0) * 0.35;
		col += (disc + glow) * vec3(1.0, 0.92, 0.7) * (1.0 - c * 0.8);
	}
	COLOR = col;
}
