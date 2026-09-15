class_name FacilityLevel
extends Node3D

var player_scene = preload("res://scenes/player/Player.tscn")

@onready var generator = $NavigationRegion3D/LevelGenerator

var level_seed: int = 0
var floor_number: int = 1
var _players_spawned: bool = false
var _ready_peers: Dictionary = {}

func _ready() -> void:
	var state = get_tree().root.get_node_or_null("LevelState")
	if state and state.has_method("reset"):
		state.reset()
		
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	var spawner = get_node_or_null("PlayerSpawner")
	if spawner:
		spawner.add_spawnable_scene(player_scene.resource_path)
		
	if multiplayer.is_server():
		randomize()
		level_seed = randi()
		floor_number = 1
		print("[FacilityLevel] Server generating level with seed: ", level_seed)
		generator.generate_level(level_seed, floor_number)
		_bake_nav_mesh()
		_ready_peers[1] = true
		
		# If solo, spawn immediately
		if NetworkManager.players.size() <= 1:
			_spawn_and_start_elevator()
		else:
			# Safety fallback: with 4 instances on 1 machine, allow up to 8.0s for all to generate
			get_tree().create_timer(8.0).timeout.connect(_on_spawn_safety_timeout)
	else:
		# Client scene is now fully loaded! Request seed from server
		print("[FacilityLevel] Client loaded scene, requesting level seed from server...")
		rpc_id(1, "request_level_seed")

## Client calls this on server once its FacilityLevel scene is ready
@rpc("any_peer", "call_remote", "reliable")
func request_level_seed() -> void:
	if not multiplayer.is_server():
		return
	var peer_id = multiplayer.get_remote_sender_id()
	print("[FacilityLevel] Peer %d requested seed, sending seed: %d" % [peer_id, level_seed])
	sync_level_seed.rpc_id(peer_id, level_seed, floor_number)

## Server sends the seed to the client
@rpc("authority", "call_remote", "reliable")
func sync_level_seed(seed_val: int, floor_num: int) -> void:
	print("[FacilityLevel] Client received seed from server: ", seed_val)
	level_seed = seed_val
	floor_number = floor_num
	generator.generate_level(seed_val, floor_num)
	call_deferred("_bake_nav_mesh")
	
	# Wait for physics frame to settle before confirming ready
	if not multiplayer.is_server():
		await get_tree().process_frame
		rpc_id(1, "client_map_ready")

## Client notifies server that level generation is complete
@rpc("any_peer", "call_remote", "reliable")
func client_map_ready() -> void:
	if not multiplayer.is_server():
		return
	var peer_id = multiplayer.get_remote_sender_id()
	print("[FacilityLevel] Peer %d finished level generation and is ready!" % peer_id)
	_ready_peers[peer_id] = true
	_check_all_peers_ready_and_spawn()

func _check_all_peers_ready_and_spawn() -> void:
	if _players_spawned or not multiplayer.is_server():
		return
		
	for peer_id in NetworkManager.players.keys():
		if not _ready_peers.get(peer_id, false):
			return # Still waiting for peer_id
			
	print("[FacilityLevel] All players ready! Spawning players inside elevator.")
	_spawn_and_start_elevator()

func _on_spawn_safety_timeout() -> void:
	if not _players_spawned and multiplayer.is_server():
		print("[FacilityLevel] Safety timeout reached, spawning players...")
		_spawn_and_start_elevator()

func _spawn_and_start_elevator() -> void:
	if _players_spawned:
		return
	_players_spawned = true
	_spawn_players()
	# Wait 10 seconds, then open the start elevator gates for everyone
	get_tree().create_timer(10.0).timeout.connect(_open_start_elevator)

func _open_start_elevator() -> void:
	if multiplayer.is_server():
		rpc_open_start_elevator.rpc()

@rpc("authority", "call_local", "reliable")
func rpc_open_start_elevator() -> void:
	print("[FacilityLevel] Opening start elevator gates...")
	var start_elevator = get_node_or_null("NavigationRegion3D/LevelGenerator/elevator_0_0")
	if start_elevator and start_elevator.has_method("open_gates"):
		start_elevator.open_gates()

func _bake_nav_mesh() -> void:
	var nav_region = $NavigationRegion3D
	if nav_region:
		nav_region.bake_navigation_mesh(false)

func _spawn_players() -> void:
	# Elevator cabin interior floor is at Y=0 and ceiling at Y=4.
	# With player capsule height 2.0 (feet at -1.0), Y=1.0 puts feet exactly on the floor at Y=0.0 with zero fall.
	# Wide 4-corner spacing prevents any capsule overlap, pushing, or ceiling clipping:
	var spawn_points = [
		Vector3(-2.2, 1.0, -1.8),
		Vector3(2.2, 1.0, -1.8),
		Vector3(-2.2, 1.0, 1.8),
		Vector3(2.2, 1.0, 1.8)
	]
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
		var s_pos = spawn_points[i % spawn_points.size()]
		p.position = s_pos
		p.character_class = pinfo.class
		if p.has_method("set_last_room"):
			p.set_last_room("Start Elevator", s_pos)
		add_child(p)
		
		var inv = p.get_node_or_null("PlayerInventory")
		if inv:
			inv.initialize(pinfo.class)
		i += 1

func _on_player_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var p = get_node_or_null(str(id))
		if p:
			var sync = p.get_node_or_null("MultiplayerSynchronizer")
			if sync:
				sync.process_mode = Node.PROCESS_MODE_DISABLED
			p.queue_free()

@rpc("authority", "call_local", "reliable")
func rpc_spawn_drop_global(res_path: String, spawn_pos: Vector3, drop_name: String) -> void:
	var pickup_scene = preload("res://scenes/items/PickupItem.tscn")
	var pickup = pickup_scene.instantiate()
	pickup.item_data = load(res_path)
	pickup.name = drop_name
	add_child(pickup)
	pickup.global_position = spawn_pos
