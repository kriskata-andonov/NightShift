extends Label
class_name InteractionPrompt
## Minimal HUD label for showing interaction prompts.
## Controlled by PlayerInteraction.gd — no logic needed here,
## just styling defaults.

func _ready() -> void:
	# Styling defaults
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position at lower-center of screen
	anchors_preset = Control.PRESET_CENTER_BOTTOM
	anchor_top = 1.0
	anchor_bottom = 1.0
	anchor_left = 0.5
	anchor_right = 0.5
	offset_top = -80.0
	offset_bottom = -40.0
	offset_left = -200.0
	offset_right = 200.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	
	# Text appearance
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	
	visible = false
