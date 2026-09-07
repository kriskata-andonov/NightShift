extends Interactable
class_name InteractableDoor
## A simple door that toggles open/closed via rotation.
## Used as the first test interactable for the interaction system.

@export var open_angle: float = 90.0
@export var open_speed: float = 4.0

var is_open: bool = false
var target_rotation_y: float = 0.0
var initial_rotation_y: float = 0.0

func _ready() -> void:
	initial_rotation_y = rotation_degrees.y
	target_rotation_y = initial_rotation_y

func _process(delta: float) -> void:
	# Smoothly rotate toward target
	if not is_equal_approx(rotation_degrees.y, target_rotation_y):
		rotation_degrees.y = lerp(rotation_degrees.y, target_rotation_y, open_speed * delta)
		# Snap when close enough to avoid endless lerping
		if absf(rotation_degrees.y - target_rotation_y) < 0.5:
			rotation_degrees.y = target_rotation_y

func interact(_player: Node) -> void:
	is_open = !is_open
	if is_open:
		target_rotation_y = initial_rotation_y + open_angle
	else:
		target_rotation_y = initial_rotation_y

func get_interaction_text() -> String:
	if is_open:
		return "Close Door"
	else:
		return "Open Door"
