extends Camera3D

@export var mouse_sensitivity: float = 0.002
@export var max_pitch: float = 85.0
@export var min_pitch: float = -85.0

var player: CharacterBody3D

func _ready() -> void:
	var curr_node: Node = get_parent()
	while curr_node:
		if curr_node is CharacterBody3D:
			player = curr_node
			break
		curr_node = curr_node.get_parent()

func _unhandled_input(event: InputEvent) -> void:
	if player and not player.is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate player horizontally (Yaw)
		if player:
			player.rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera vertically (Pitch)
		var pitch = rotation.x - event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		rotation.x = pitch
