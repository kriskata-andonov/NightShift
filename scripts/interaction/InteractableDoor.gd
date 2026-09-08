extends Interactable
class_name InteractableDoor
## A simple door that toggles open/closed via rotation.
## Server-authoritative: clients request, server decides and broadcasts.

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
	if multiplayer.has_multiplayer_peer():
		# Multiplayer: ask the server to toggle
		if multiplayer.is_server():
			# We ARE the server, just toggle directly
			_rpc_set_door_state.rpc(not is_open)
		else:
			_rpc_request_toggle.rpc_id(1)
	else:
		# No multiplayer: toggle locally
		_set_door_state(not is_open)

## Client requests the server to toggle the door.
@rpc("any_peer", "reliable")
func _rpc_request_toggle() -> void:
	if not multiplayer.is_server():
		return
	# Server decides the new state and broadcasts it
	_rpc_set_door_state.rpc(not is_open)

## Server broadcasts the authoritative door state to all clients.
@rpc("authority", "call_local", "reliable")
func _rpc_set_door_state(open: bool) -> void:
	_set_door_state(open)

## Local door state setter — used by both RPC and direct calls.
func _set_door_state(open: bool) -> void:
	is_open = open
	if is_open:
		target_rotation_y = initial_rotation_y + open_angle
	else:
		target_rotation_y = initial_rotation_y

func get_interaction_text(_player: Node = null) -> String:
	if is_open:
		return "Close Door"
	else:
		return "Open Door"
