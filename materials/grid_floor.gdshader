shader_type spatial;

uniform vec4 grid_color : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform vec4 bg_color : source_color = vec4(0.15, 0.15, 0.15, 1.0);
uniform vec4 major_grid_color : source_color = vec4(0.55, 0.55, 0.55, 1.0);
uniform float grid_size : hint_range(0.1, 10.0) = 1.0;
uniform float line_thickness : hint_range(0.001, 0.1) = 0.02;
uniform float major_line_thickness : hint_range(0.001, 0.15) = 0.035;
uniform int major_grid_interval : hint_range(1, 20) = 5;

void fragment() {
	// Use world-space XZ coordinates for the grid
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv_world = world_pos.xz;

	// Minor grid lines (every grid_size meters)
	vec2 grid_uv = abs(fract(uv_world / grid_size - 0.5) - 0.5);
	vec2 line = grid_uv * grid_size;
	float minor_line = step(line.x, line_thickness) + step(line.y, line_thickness);
	minor_line = clamp(minor_line, 0.0, 1.0);

	// Major grid lines (every major_grid_interval meters)
	float major_size = grid_size * float(major_grid_interval);
	vec2 major_uv = abs(fract(uv_world / major_size - 0.5) - 0.5);
	vec2 major_line_dist = major_uv * major_size;
	float major_line = step(major_line_dist.x, major_line_thickness) + step(major_line_dist.y, major_line_thickness);
	major_line = clamp(major_line, 0.0, 1.0);

	// Origin axis highlight (lines through world origin)
	float origin_x = step(abs(uv_world.x), major_line_thickness * 1.5);
	float origin_z = step(abs(uv_world.y), major_line_thickness * 1.5);

	// Compose final color
	vec3 color = bg_color.rgb;
	color = mix(color, grid_color.rgb, minor_line);
	color = mix(color, major_grid_color.rgb, major_line);
	// Red for X-axis, Blue for Z-axis at origin
	color = mix(color, vec3(0.7, 0.2, 0.2), origin_x);
	color = mix(color, vec3(0.2, 0.2, 0.7), origin_z);

	ALBEDO = color;
	ROUGHNESS = 0.9;
}
