extends Node3D

@onready var door_left: CSGBox3D = $DoorLeft
@onready var door_right: CSGBox3D = $DoorRight
@onready var button_front = $Panel_Front/Button_Front
@onready var button_back = $Panel_Back/Button_Back

var is_open: bool = false
var is_moving: bool = false

var room_a_name: String = ""
var room_b_name: String = ""
var room_a_pos: Vector3 = Vector3.INF
var room_b_pos: Vector3 = Vector3.INF

func _ready() -> void:
	button_front.interacted.connect(func(p): _on_button_pressed(p, "front"))
	button_back.interacted.connect(func(p): _on_button_pressed(p, "back"))

func _on_button_pressed(player: Node3D, side: String = "front") -> void:
	if player and player.has_method("set_last_room"):
		var target_name = ""
		var target_pos = Vector3.INF
		if side == "front":
			target_name = room_a_name if room_a_name != "" else ("Room behind " + name)
			target_pos = room_a_pos if room_a_pos.is_finite() else player.global_position
		else:
			target_name = room_b_name if room_b_name != "" else ("Room ahead of " + name)
			target_pos = room_b_pos if room_b_pos.is_finite() else player.global_position
		player.set_last_room(target_name, target_pos)

	if is_moving:
		return
	
	if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
		if is_open:
			rpc("close_door")
		else:
			rpc("open_door")
	else:
		if is_open:
			close_door()
		else:
			open_door()

@rpc("any_peer", "call_local")
func open_door() -> void:
	if is_open or is_moving:
		return
	is_moving = true
	is_open = true
	
	if door_left and door_right:
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(door_left, "position:x", -2.25, 1.5)
		tween.tween_property(door_right, "position:x", 2.25, 1.5)
		tween.chain().tween_callback(func(): is_moving = false)
	else:
		is_moving = false
	
	# Auto-close after 5 seconds
	var is_srv = not is_inside_tree() or not multiplayer or not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	if is_srv:
		var tree = get_tree()
		if tree:
			tree.create_timer(5.0).timeout.connect(func():
				if is_open and not is_moving:
					if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
						rpc("close_door")
					else:
						close_door()
			)

@rpc("any_peer", "call_local")
func close_door() -> void:
	if not is_open or is_moving:
		return
	is_moving = true
	is_open = false
	
	if door_left and door_right:
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(door_left, "position:x", -0.75, 1.5)
		tween.tween_property(door_right, "position:x", 0.75, 1.5)
		tween.chain().tween_callback(func(): is_moving = false)
	else:
		is_moving = false
