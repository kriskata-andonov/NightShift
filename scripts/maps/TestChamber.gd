extends Node3D

var player_scene = preload("res://scenes/player/Player.tscn")

func _ready() -> void:
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	if not multiplayer.is_server():
		return
	
	# Spawn all connected players
	var spawn_points = [Vector3(0, 2, 0), Vector3(2, 2, 0), Vector3(-2, 2, 0), Vector3(0, 2, -2)]
	var i = 0
	
	var peer_ids = NetworkManager.players.keys()
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
