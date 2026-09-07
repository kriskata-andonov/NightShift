shader_type canvas_item;

uniform float fear_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_time : hint_range(0.0, 1000.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(uv, center);

	// Dark tunnel vision vignette — tighter than damage vignette
	// At max fear the visible area shrinks significantly
	float inner_edge = mix(0.3, 0.1, fear_intensity);
	float outer_edge = mix(0.85, 0.5, fear_intensity);
	float vignette = smoothstep(inner_edge, outer_edge, dist);

	// Breathing pulse — slow at low fear, faster at high fear
	float pulse_speed = mix(1.5, 4.0, fear_intensity);
	float pulse = sin(pulse_time * pulse_speed) * 0.5 + 0.5;
	float pulse_strength = fear_intensity * 0.12 * pulse;

	float alpha = vignette * fear_intensity + pulse_strength;
	alpha = clamp(alpha, 0.0, 0.9);

	// Dark grey/black vignette (not red — that's the damage overlay)
	COLOR = vec4(0.0, 0.0, 0.02, alpha);
}
