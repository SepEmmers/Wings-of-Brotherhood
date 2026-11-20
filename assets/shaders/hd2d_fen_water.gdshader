shader_type spatial;
render_mode specular_schlick_ggx, cull_back;

uniform vec3 deep_color : source_color = vec3(0.05, 0.12, 0.19);
uniform vec3 crest_color : source_color = vec3(0.11, 0.24, 0.33);
uniform vec3 foam_color : source_color = vec3(0.58, 0.72, 0.78);
uniform float wave_speed : hint_range(0.1, 4.0) = 0.95;
uniform float wave_height : hint_range(0.01, 1.0) = 0.06;
uniform float foam_threshold : hint_range(0.1, 1.0) = 0.78;

varying vec3 v_world_pos;

float wave_fn(vec2 p, float t) {
	float w1 = sin(p.x * 0.55 + t * 1.2) * cos(p.y * 0.42 - t * 0.85);
	float w2 = sin((p.x + p.y) * 0.90 - t * 1.6) * 0.40;
	return (w1 + w2) * 0.55;
}

float ripple_fn(vec2 p, float t) {
	float a = sin(p.x * 0.95 + t * 1.15) * cos(p.y * 0.85 - t * 0.95);
	float b = sin((p.x * 1.65 - p.y * 1.45) + t * 1.85) * 0.45;
	float c = cos(p.x * 3.10 + p.y * 2.65 - t * 2.35) * 0.25;
	return (a + b + c) * 0.34 + 0.5;
}

void vertex() {
	vec2 wp = VERTEX.xz;
	float h = wave_fn(wp, TIME * wave_speed);
	VERTEX.y += h * wave_height;
	v_world_pos = VERTEX;

	float eps = 0.35;
	float hx = wave_fn(wp + vec2(eps, 0.0), TIME * wave_speed) * wave_height;
	float hz = wave_fn(wp + vec2(0.0, eps), TIME * wave_speed) * wave_height;
	NORMAL = normalize(vec3(h * wave_height - hx, eps, h * wave_height - hz));
}

void fragment() {
	vec2 q_xz = floor(v_world_pos.xz * 8.0) / 8.0;
	float r = ripple_fn(q_xz, TIME * wave_speed);
	float glint = ripple_fn(q_xz * 2.3 + vec2(5.1, 3.7), TIME * wave_speed * 1.25);
	float q_band = floor(clamp(r, 0.0, 1.0) * 6.0) / 6.0;
	vec3 base = mix(deep_color, crest_color, q_band);

	float foam_mask = smoothstep(foam_threshold, foam_threshold + 0.14, r) * step(0.60, glint);
	vec3 albedo = mix(base, foam_color, foam_mask * 0.38);

	ALBEDO = albedo;
	ROUGHNESS = mix(0.18, 0.48, foam_mask);
	METALLIC = 0.14;
	ROUGHNESS = mix(0.56, 0.78, foam_mask);
	METALLIC = 0.06;
}
