shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.6, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(uv, center);

	// Vignette — stronger at edges, soft falloff
	float vignette = smoothstep(0.2, 0.85, dist);

	// Combine persistent vignette with damage flash
	// Flash covers more of the screen (not just edges)
	float flash = flash_intensity * 0.35;
	float edge_glow = vignette * vignette_intensity;
	float alpha = clamp(edge_glow + flash, 0.0, 0.75);

	COLOR = vec4(vignette_color.rgb, alpha);
}
