extends Node3D

var player_scene = preload("res://scenes/player/Player.tscn")

func _ready() -> void:
	var state = get_tree().root.get_node_or_null("LevelState")
	if state and state.has_method("reset"):
		state.reset()

	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	# Dynamically bake the nav mesh for the map geometry
	var nav_region = get_node_or_null("NavigationRegion")
	if nav_region:
		nav_region.bake_navigation_mesh(false) # false = synchronous, block until baked
	
	var spawner = get_node_or_null("PlayerSpawner")
	if spawner:
		spawner.add_spawnable_scene(player_scene.resource_path)
		
	if not multiplayer.is_server():
		return
	
	var spawn_points = [Vector3(0, 2, 0), Vector3(2, 2, 0), Vector3(-2, 2, 0), Vector3(0, 2, -2)]
	var i = 0
	
	var peer_ids = NetworkManager.players.keys()
	
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
		var inv = p.get_node_or_null("PlayerInventory")
		if inv:
			inv.initialize(pinfo.class)
		i += 1
		
	_spawn_initial_items()

func _spawn_initial_items() -> void:
	# Spawn a Battery on the table
	rpc_spawn_drop_global("res://resources/items/Battery.tres", Vector3(3, 1.2, 3), "Battery_1")
	# Spawn Sanity Pills on the table next to it
	rpc_spawn_drop_global("res://resources/items/SanityPills.tres", Vector3(3.5, 1.2, 3), "Pills_1")

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
