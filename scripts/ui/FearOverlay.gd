extends ColorRect
class_name FearOverlay
## Full-screen dark vignette overlay driven by the fear system.
## Creates tunnel vision that tightens with fear, separate from
## the red damage vignette.

var fear_node: Node = null
var elapsed_time: float = 0.0

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

	# Transparent base — shader handles rendering
	color = Color(1, 1, 1, 1)

	# Apply the fear vignette shader
	var shader := preload("res://materials/fear_vignette.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("fear_intensity", 0.0)
	mat.set_shader_parameter("pulse_time", 0.0)
	material = mat

	_find_fear()

func _find_fear() -> void:
	var current: Node = get_parent()
	while current:
		if current is CharacterBody3D:
			fear_node = current.get_node_or_null("PlayerFear")
			return
		current = current.get_parent()

func _process(delta: float) -> void:
	elapsed_time += delta

	var mat: ShaderMaterial = material as ShaderMaterial
	if not mat:
		return

	mat.set_shader_parameter("pulse_time", elapsed_time)

	if not fear_node:
		mat.set_shader_parameter("fear_intensity", 0.0)
		return

	var fear_pct: float = fear_node.get_fear_percent()
	mat.set_shader_parameter("fear_intensity", fear_pct)
