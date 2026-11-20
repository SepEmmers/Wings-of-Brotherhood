shader_type canvas_item;

uniform float focus_y : hint_range(0.0, 1.0) = 0.50;
uniform float focus_band : hint_range(0.05, 0.5) = 0.19;
uniform float blur_strength : hint_range(0.0, 5.0) = 2.1;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.28;
uniform float warmth : hint_range(0.0, 0.3) = 0.035;
uniform float bloom_lift : hint_range(0.0, 1.0) = 0.10;

void fragment() {
	vec2 uv = UV;
	vec2 px = TEXTURE_PIXEL_SIZE;
	float dist = abs(uv.y - focus_y);
	float blur = smoothstep(focus_band, focus_band + 0.30, dist) * blur_strength;

	vec4 center = texture(TEXTURE, uv);
	vec4 col = center;
	if (blur > 0.01) {
		vec4 accum = center * 0.24;
		accum += texture(TEXTURE, clamp(uv + vec2(px.x * blur, 0.0), vec2(0.0), vec2(1.0))) * 0.11;
		accum += texture(TEXTURE, clamp(uv + vec2(-px.x * blur, 0.0), vec2(0.0), vec2(1.0))) * 0.11;
		accum += texture(TEXTURE, clamp(uv + vec2(0.0, px.y * blur), vec2(0.0), vec2(1.0))) * 0.11;
		accum += texture(TEXTURE, clamp(uv + vec2(0.0, -px.y * blur), vec2(0.0), vec2(1.0))) * 0.11;
		float d_off = blur * 0.85;
		accum += texture(TEXTURE, clamp(uv + vec2(px.x * d_off, px.y * d_off), vec2(0.0), vec2(1.0))) * 0.08;
		accum += texture(TEXTURE, clamp(uv + vec2(-px.x * d_off, px.y * d_off), vec2(0.0), vec2(1.0))) * 0.08;
		accum += texture(TEXTURE, clamp(uv + vec2(px.x * d_off, -px.y * d_off), vec2(0.0), vec2(1.0))) * 0.08;
		accum += texture(TEXTURE, clamp(uv + vec2(-px.x * d_off, -px.y * d_off), vec2(0.0), vec2(1.0))) * 0.08;
		col = accum;
	}

	// Soft warm lantern/ember highlight bloom & Octopath golden-twilight grade
	vec3 hi = max(col.rgb - vec3(0.68), vec3(0.0));
	col.rgb += hi * bloom_lift * vec3(1.10, 0.96, 0.72);
	col.r += warmth * 0.38;
	col.g += warmth * 0.18;
	col.b -= warmth * 0.08;

	float rad = distance(uv, vec2(0.5, 0.5));
	float vig = smoothstep(0.42, 0.94, rad) * vignette_strength;
	col.rgb *= (1.0 - vig);
	COLOR = vec4(col.rgb, center.a);
}
