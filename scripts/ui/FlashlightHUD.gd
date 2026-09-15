extends Label
class_name FlashlightHUD
## Displays flashlight battery level in the bottom-right corner.
## Shows a percentage and a simple text bar that drains visually.

var flashlight: Node = null
var _last_pct_int: int = -1
var _last_status: String = ""

func _ready() -> void:
	# Style and position — bottom-right corner
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

	anchors_preset = Control.PRESET_BOTTOM_RIGHT
	anchor_top = 1.0
	anchor_bottom = 1.0
	anchor_left = 1.0
	anchor_right = 1.0
	offset_top = -60.0
	offset_bottom = -10.0
	offset_left = -220.0
	offset_right = -10.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN

	add_theme_font_size_override("font_size", 14)
	add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.9))
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)

	_find_flashlight()

func _find_flashlight() -> void:
	var current: Node = get_parent()
	while current:
		if current is CharacterBody3D:
			var head := current.get_node_or_null("Head")
			if head:
				var cam := head.get_node_or_null("Camera3D")
				if cam:
					flashlight = cam.get_node_or_null("Flashlight")
			return
		current = current.get_parent()

func _process(_delta: float) -> void:
	if not flashlight:
		text = ""
		return

	var pct: float = 0.0
	if flashlight.max_battery > 0:
		pct = (flashlight.current_battery / flashlight.max_battery) * 100.0

	var pct_int: int = ceili(pct)

	# Color coding via prefix — check battery first, then on/off state
	var status: String
	if pct <= 0.0:
		status = "DEAD"
	elif not flashlight.is_on:
		status = "OFF"
	elif pct <= 20.0:
		status = "LOW"
	else:
		status = "ON"

	# Skip rebuild if nothing changed
	if pct_int == _last_pct_int and status == _last_status:
		return
	_last_pct_int = pct_int
	_last_status = status

	# Build a 10-segment bar: ██████████
	var filled: int = roundi(pct / 10.0)
	var bar: String = "█".repeat(filled) + "░".repeat(10 - filled)

	text = "🔦 %s  %d%%\n[%s]" % [status, pct_int, bar]

	# Tint the label based on battery state
	if pct <= 0.0:
		add_theme_color_override("font_color", Color(0.6, 0.2, 0.2, 0.9))
	elif pct <= 20.0:
		add_theme_color_override("font_color", Color(0.9, 0.6, 0.2, 0.9))
	else:
		add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.9))
