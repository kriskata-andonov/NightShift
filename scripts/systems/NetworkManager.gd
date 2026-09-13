extends Node

signal players_updated
signal game_started
signal player_disconnected(id: int)

const DEFAULT_PORT = 7777
const MAX_CLIENTS = 4

var players = {} # Dictionary of peer_id -> { "name": String, "class": int }
var player_info = {"name": "Player", "class": 1} # Local player info

var audio_hover: AudioStreamPlayer
var audio_click: AudioStreamPlayer

func _ready() -> void:
	# Setup Audio Players
	audio_hover = AudioStreamPlayer.new()
	audio_hover.stream = preload("res://assets/audio/ui/ui_hover.tres")
	add_child(audio_hover)
	
	audio_click = AudioStreamPlayer.new()
	audio_click.stream = preload("res://assets/audio/ui/ui_click.tres")
	add_child(audio_click)
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func play_ui_hover() -> void:
	if audio_hover: audio_hover.play()

func play_ui_click() -> void:
	if audio_click: audio_click.play()

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to host game: ", err)
		return err
	multiplayer.multiplayer_peer = peer
	
	players[1] = player_info
	players_updated.emit()
	print("Hosting game on port ", port)
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	address = address.strip_edges()
	if ":" in address:
		var parts = address.split(":")
		address = parts[0]
		port = parts[1].to_int() # Support custom ports if they typed it!
		
	if address.is_empty():
		address = "127.0.0.1"
		
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(address, port)
	if err != OK:
		push_error("Failed to create client: ", err)
		return err
	multiplayer.multiplayer_peer = peer
	print("Joining game at ", address, ":", port)
	return OK

func leave_game() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	players_updated.emit()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_player_connected(id: int) -> void:
	print("Player connected: ", id)
	_register_player.rpc_id(id, player_info)

func _on_player_disconnected(id: int) -> void:
	print("Player disconnected: ", id)
	players.erase(id)
	players_updated.emit()
	player_disconnected.emit(id)

func _on_connected_ok() -> void:
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	players_updated.emit()

func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	players_updated.emit()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

@rpc("any_peer", "reliable")
func _register_player(new_player_info: Dictionary) -> void:
	var new_player_id = multiplayer.get_remote_sender_id()
	# Validate client data to prevent invalid class IDs or names
	var safe_info = {
		"name": str(new_player_info.get("name", "Player")).substr(0, 20),
		"class": clampi(int(new_player_info.get("class", 1)), 0, 3)
	}
	players[new_player_id] = safe_info
	players_updated.emit()

@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	game_started.emit()
	get_tree().change_scene_to_file("res://scenes/maps/LabFacility.tscn")

var restart_votes = []

@rpc("any_peer", "reliable")
func vote_restart() -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if not sender_id in restart_votes:
		restart_votes.append(sender_id)
		print("Player ", sender_id, " voted to restart.")

@rpc("authority", "call_local", "reliable")
func restart_game() -> void:
	restart_votes.clear()
	# Optional: Reset player states if persistent, but reloading scene usually works
	get_tree().change_scene_to_file("res://scenes/maps/LabFacility.tscn")
