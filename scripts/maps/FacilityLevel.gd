class_name FacilityLevel
extends Node3D

var player_scene = preload("res://scenes/player/Player.tscn")

@onready var generator = $NavigationRegion3D/LevelGenerator

func _ready() -> void:
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	var spawner = get_node_or_null("PlayerSpawner")
	if spawner:
		spawner.add_spawnable_scene(player_scene.resource_path)
		
	if multiplayer.is_server():
		randomize()
		var seed_val = randi()
		var floor_num = 1
		sync_level_seed.rpc(seed_val, floor_num)
		generator.generate_level(seed_val, floor_num)
		
		# Give clients time to receive the seed and build CSG collision
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(_finalize_level_setup)

@rpc("authority", "call_remote", "reliable")
func sync_level_seed(seed_val: int, floor_num: int) -> void:
	print("Received seed from host: ", seed_val)
	generator.generate_level(seed_val, floor_num)
	call_deferred("_bake_nav_mesh")

func _finalize_level_setup() -> void:
	if multiplayer.is_server():
		var nav_region = get_node_or_null("NavigationRegion3D")
		if nav_region:
			_bake_nav_mesh()
		
		# Give a small delay to let clients load the initial chunks
		await get_tree().create_timer(1.0).timeout
		_spawn_players()
		
		# Wait 10 seconds, then open the start elevator gates for everyone
		get_tree().create_timer(10.0).timeout.connect(_open_start_elevator)

func _open_start_elevator() -> void:
	if multiplayer.is_server():
		rpc_open_start_elevator.rpc()

@rpc("authority", "call_local", "reliable")
func rpc_open_start_elevator() -> void:
	print("Timer finished! Opening start elevator gates...")
	var start_elevator = get_node_or_null("NavigationRegion3D/LevelGenerator/elevator_0_0")
	if start_elevator and start_elevator.has_method("open_gates"):
		start_elevator.open_gates()

func _bake_nav_mesh() -> void:
	var nav_region = $NavigationRegion3D
	if nav_region:
		nav_region.bake_navigation_mesh(false)

func _spawn_players() -> void:
	# Spawn around the center of the elevator cabin (0,0,0) with extra height to avoid floor clipping
	var spawn_points = [Vector3(0, 3.0, -2), Vector3(2.0, 3.0, 0), Vector3(-2.0, 3.0, 0), Vector3(0, 3.0, 2)]
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
