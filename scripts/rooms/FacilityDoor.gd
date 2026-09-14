extends Node3D

@onready var door_left: CSGBox3D = $DoorLeft
@onready var door_right: CSGBox3D = $DoorRight
@onready var button_front = $Panel_Front/Button_Front
@onready var button_back = $Panel_Back/Button_Back

var is_open: bool = false
var is_moving: bool = false

func _ready() -> void:
	button_front.interacted.connect(_on_button_pressed)
	button_back.interacted.connect(_on_button_pressed)

func _on_button_pressed(_player: Node3D) -> void:
	if is_moving:
		return
	
	if is_open:
		rpc("close_door")
	else:
		rpc("open_door")

@rpc("any_peer", "call_local")
func open_door() -> void:
	if is_open or is_moving:
		return
	is_moving = true
	is_open = true
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(door_left, "position:x", -2.25, 1.5)
	tween.tween_property(door_right, "position:x", 2.25, 1.5)
	
	tween.chain().tween_callback(func(): is_moving = false)
	
	# Auto-close after 5 seconds
	if multiplayer.is_server():
		get_tree().create_timer(5.0).timeout.connect(func():
			if is_open and not is_moving:
				rpc("close_door")
		)

@rpc("any_peer", "call_local")
func close_door() -> void:
	if not is_open or is_moving:
		return
	is_moving = true
	is_open = false
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(door_left, "position:x", -0.75, 1.5)
	tween.tween_property(door_right, "position:x", 0.75, 1.5)
	
	tween.chain().tween_callback(func(): is_moving = false)
