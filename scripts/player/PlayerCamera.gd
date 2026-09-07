extends Camera3D

@export var mouse_sensitivity: float = 0.002
@export var max_pitch: float = 85.0
@export var min_pitch: float = -85.0

var player: CharacterBody3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var current: Node = get_parent()
	while current:
		if current is CharacterBody3D:
			player = current
			break
		current = current.get_parent()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate player horizontally (Yaw)
		if player:
			player.rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera vertically (Pitch)
		var pitch = rotation.x - event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		rotation.x = pitch

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
