extends Label
class_name DownedHUD
## Center-screen overlay when the player is downed.
## Shows bleedout timer countdown and status messages.
## Fades in when downed, fades out on revive/death.

var health_node: Node = null
var display_alpha: float = 0.0
var pulse_time: float = 0.0

const FADE_SPEED: float = 4.0

func _ready() -> void:
	# Center of screen
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	anchors_preset = Control.PRESET_CENTER
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -200.0
	offset_right = 200.0
	offset_top = 40.0
	offset_bottom = 120.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_find_health()

func _find_health() -> void:
	var current: Node = get_parent()
	while current:
		if current is CharacterBody3D:
			health_node = current.get_node_or_null("PlayerHealth")
			if health_node:
				health_node.downed.connect(_on_downed)
				health_node.revived.connect(_on_revived)
				health_node.died.connect(_on_died)
			return
		current = current.get_parent()

func _process(delta: float) -> void:
	if not health_node:
		return

	var is_downed: bool = health_node.is_downed()
	var is_dead: bool = health_node.state == health_node.State.DEAD

	# Fade in/out
	if is_downed or is_dead:
		display_alpha = move_toward(display_alpha, 1.0, FADE_SPEED * delta)
	else:
		display_alpha = move_toward(display_alpha, 0.0, FADE_SPEED * delta)

	visible = display_alpha > 0.01

	if not visible:
		return

	pulse_time += delta

	if is_dead:
		# Death message
		add_theme_color_override("font_color", Color(0.7, 0.1, 0.1, display_alpha))
		text = "YOU DIED"
	elif is_downed:
		# Bleedout timer — pulsing red text
		var timer_secs: float = health_node.bleedout_timer
		var timer_int: int = ceili(timer_secs)
		var pulse: float = (sin(pulse_time * 4.0) + 1.0) * 0.5
		var r: float = lerp(0.7, 1.0, pulse)
		add_theme_color_override("font_color", Color(r, 0.15, 0.15, display_alpha))
		text = "DOWNED\n%d" % timer_int
		add_theme_font_size_override("font_size", 22)

func _on_downed() -> void:
	pulse_time = 0.0

func _on_revived() -> void:
	pass

func _on_died() -> void:
	pass
