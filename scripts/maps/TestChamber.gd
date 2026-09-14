extends Node3D

var player_scene = preload("res://scenes/player/Player.tscn")

func _ready() -> void:
	var state = get_tree().root.get_node_or_null("LevelState")
	if state and state.has_method("reset"):
		state.reset()
		
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	# Register spawnable scenes explicitly in code. This avoids any Godot 4 UID/path serialization bugs.
	var spawner = get_node_or_null("PlayerSpawner")
	if spawner:
		spawner.add_spawnable_scene(player_scene.resource_path)
		
	if not multiplayer.is_server():
		return
	
	# Spawn all connected players inside the Start Elevator (X=-12)
	var spawn_points = [Vector3(-12, 2, 0), Vector3(-11, 2, 1), Vector3(-13, 2, -1), Vector3(-12, 2, -2)]
	var i = 0
	
	var peer_ids = NetworkManager.players.keys()
	
	# Fix for solo testing: if you hit "Play Current Scene" on TestChamber directly, players array is empty.
	if peer_ids.is_empty():
		peer_ids = [1]
		NetworkManager.players[1] = { "name": "SoloTester", "class": 1 }
		
	peer_ids.sort()
	for peer_id in peer_ids:
		var pinfo = NetworkManager.players[peer_id]
		var p = player_scene.instantiate()
		p.name = str(peer_id)
		p.position = spawn_points[i % spawn_points.size()]
		p.character_class = pinfo.class
		add_child(p)
		# Explicitly initialize inventory after class is set (fixes race condition)
		var inv = p.get_node_or_null("PlayerInventory")
		if inv:
			inv.initialize(pinfo.class)
		i += 1
		
	# Automatically open the start elevator in the test chamber
	var elevator = get_node_or_null("StartElevator")
	if elevator and elevator.has_method("open_gates"):
		# Add a small delay for dramatic effect or open immediately
		get_tree().create_timer(1.0).timeout.connect(func(): elevator.open_gates())

func _on_player_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var p = get_node_or_null(str(id))
		if p:
			p.queue_free()

@rpc("authority", "call_local", "reliable")
func rpc_spawn_drop_global(res_path: String, spawn_pos: Vector3, drop_name: String) -> void:
	var pickup_scene = preload("res://scenes/items/PickupItem.tscn")
	var pickup = pickup_scene.instantiate()
	pickup.item_data = load(res_path)
	pickup.name = drop_name
	add_child(pickup)
	pickup.global_position = spawn_pos
