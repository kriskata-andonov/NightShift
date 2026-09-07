extends Node3D

var player_scene = preload("res://scenes/player/Player.tscn")

func _ready() -> void:
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	# Register spawnable scenes explicitly in code. This avoids any Godot 4 UID/path serialization bugs.
	var spawner = get_node_or_null("PlayerSpawner")
	if spawner:
		spawner.add_spawnable_scene(player_scene.resource_path)
		
	if not multiplayer.is_server():
		return
	
	# Spawn all connected players
	var spawn_points = [Vector3(0, 2, 0), Vector3(2, 2, 0), Vector3(-2, 2, 0), Vector3(0, 2, -2)]
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

func _on_player_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var p = get_node_or_null(str(id))
		if p:
			p.queue_free()
