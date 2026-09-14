class_name ElevatorCabin
extends RoomModule

@onready var gate_left = $GateLeft
@onready var gate_right = $GateRight
@onready var button_outside = $Geometry/ButtonPanel_Outside/Button_Outside

func _ready() -> void:
	if button_outside:
		button_outside.interacted.connect(_on_button_outside_pressed)

func _on_button_outside_pressed(_player: Node3D) -> void:
	if not LevelState.is_power_on:
		print("Elevator has no power!")
		return
	rpc("open_gates")

@rpc("any_peer", "call_local")
func open_gates() -> void:
	print("Elevator gates opening!")
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if gate_left:
		tween.tween_property(gate_left, "position", Vector3(gate_left.position.x - 2.0, gate_left.position.y, gate_left.position.z), 4.0)
	if gate_right:
		tween.tween_property(gate_right, "position", Vector3(gate_right.position.x + 2.0, gate_right.position.y, gate_right.position.z), 4.0)

@rpc("any_peer", "call_local")
func close_gates() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if gate_left:
		tween.tween_property(gate_left, "position", Vector3(-0.75, gate_left.position.y, gate_left.position.z), 4.0)
	if gate_right:
		tween.tween_property(gate_right, "position", Vector3(0.75, gate_right.position.y, gate_right.position.z), 4.0)
