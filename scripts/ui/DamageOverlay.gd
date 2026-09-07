extends ColorRect
class_name DamageOverlay
## Full-screen overlay that shows a red vignette when health is low,
## flashes red on damage, and pulses heavily when downed.
## No health bar — this IS the health feedback.

var health_node: Node = null
var flash_intensity: float = 0.0
var flash_decay: float = 2.5
var pulse_time: float = 0.0

func _ready() -> void:
	# Cover the full screen
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Set up transparent base color — shader handles all rendering
	color = Color(1, 1, 1, 1)

	# Apply the vignette shader
	var shader := preload("res://materials/damage_vignette.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("vignette_intensity", 0.0)
	mat.set_shader_parameter("flash_intensity", 0.0)
	material = mat

	_find_health()

func _find_health() -> void:
	var current: Node = get_parent()
	while current:
		if current is CharacterBody3D:
			health_node = current.get_node_or_null("PlayerHealth")
			if health_node:
				health_node.damage_taken.connect(_on_damage_taken)
			return
		current = current.get_parent()

func _process(delta: float) -> void:
	var mat: ShaderMaterial = material as ShaderMaterial
	if not mat:
		return

	# Decay flash over time
	flash_intensity = move_toward(flash_intensity, 0.0, flash_decay * delta)
	mat.set_shader_parameter("flash_intensity", flash_intensity)

	if not health_node:
		return

	pulse_time += delta

	var is_downed: bool = health_node.is_downed()
	var is_dead: bool = health_node.state == health_node.State.DEAD

	var vignette: float = 0.0

	if is_dead:
		# Full heavy vignette when dead
		vignette = 0.95
	elif is_downed:
		# Heavy pulsing vignette when downed — heartbeat rhythm
		var pulse: float = (sin(pulse_time * 3.5) + 1.0) * 0.5
		vignette = lerp(0.5, 0.85, pulse)
	else:
		# Persistent vignette based on health — ramps up below 50%
		var health_pct: float = health_node.get_health_percent()
		if health_pct < 0.5:
			# 50% HP → 0.0 vignette, 0% HP → 0.8 vignette
			vignette = (1.0 - health_pct * 2.0) * 0.8

	mat.set_shader_parameter("vignette_intensity", vignette)

func _on_damage_taken(_amount: float) -> void:
	flash_intensity = 1.0
