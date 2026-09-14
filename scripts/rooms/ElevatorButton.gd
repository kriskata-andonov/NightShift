class_name ElevatorButton
extends Interactable

@onready var cabin = get_parent().get_parent()

var is_pressed: bool = false

func get_interaction_text(_player: Node = null) -> String:
	if is_pressed:
		return "Starting..."
	return "Start Shift"

func can_interact(_player: Node) -> bool:
	return not is_pressed

func interact(_player: Node) -> void:
	print(">>> INTERACT CALLED ON BUTTON <<<")
	if not is_pressed:
		print(">>> SENDING START SHIFT REQUEST <<<")
		if multiplayer.is_server():
			request_start_shift()
		else:
			request_start_shift.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func request_start_shift() -> void:
	print(">>> request_start_shift EXECUTED <<<")
	if not multiplayer.is_server():
		return
	if is_pressed:
		return
	print(">>> HOST BROADCASTING sync_start_shift <<<")
	sync_start_shift.rpc()

@rpc("authority", "call_local", "reliable")
func sync_start_shift() -> void:
	print(">>> sync_start_shift EXECUTED ON CLIENT <<<")
	is_pressed = true
	if cabin and cabin.has_method("open_gates"):
		cabin.open_gates()
	else:
		print("ERROR: cabin missing open_gates! Cabin is: ", cabin)
