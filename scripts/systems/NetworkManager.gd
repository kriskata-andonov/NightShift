extends Node

signal players_updated
signal game_started
signal player_disconnected(id: int)

const DEFAULT_PORT = 7777
const MAX_CLIENTS = 4

var players = {} # Dictionary of peer_id -> { "name": String, "class": int }
var player_info = {"name": "TestSubject", "class": 1} # Local player info

# Global Settings
var hear_myself: bool = false
var mic_boost: float = 1.0

var audio_hover: AudioStreamPlayer
var audio_click: AudioStreamPlayer

func _ready() -> void:
	# Setup Audio Players
	audio_hover = AudioStreamPlayer.new()
	audio_hover.stream = _create_hover_sound()
	audio_hover.volume_db = -5.0
	add_child(audio_hover)
	
	audio_click = AudioStreamPlayer.new()
	audio_click.stream = _create_click_sound()
	audio_click.volume_db = -5.0
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

func update_player_class(class_id: int) -> void:
	player_info.class = class_id
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var my_id = multiplayer.get_unique_id()
		players[my_id] = player_info
		_register_player.rpc(player_info)
		players_updated.emit()

func update_player_name(new_name: String) -> void:
	player_info.name = new_name
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var my_id = multiplayer.get_unique_id()
		players[my_id] = player_info
		_register_player.rpc(player_info)
		players_updated.emit()

@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	game_started.emit()
	get_tree().change_scene_to_file("res://scenes/maps/FacilityLevel.tscn")

func _create_hover_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	var data = PackedByteArray()
	var num_samples = int(44100.0 * 0.04)
	for i in range(num_samples):
		var t = float(i) / 44100.0
		var progress = float(i) / num_samples
		var freq = lerp(300.0, 400.0, progress)
		var env = 1.0
		if progress < 0.1: env = progress / 0.1
		elif progress > 0.9: env = (1.0 - progress) / 0.1
		var val = sin(2.0 * PI * freq * t) * 0.3 * env
		var int_val = int(val * 32767.0)
		data.append(int_val & 0xFF)
		data.append((int_val >> 8) & 0xFF)
	stream.data = data
	return stream

func _create_click_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	var data = PackedByteArray()
	var num_samples = int(44100.0 * 0.015) # 15ms
	var phase = 0.0
	for i in range(num_samples):
		var progress = float(i) / num_samples
		var freq = 2500.0 * pow(400.0 / 2500.0, progress)
		phase += 2.0 * PI * freq / 44100.0
		var env = 1.0 - progress
		var val = sin(phase) * 0.4 * env
		var int_val = int(val * 32767.0)
		data.append(int_val & 0xFF)
		data.append((int_val >> 8) & 0xFF)
	stream.data = data
	return stream

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
	get_tree().change_scene_to_file("res://scenes/maps/FacilityLevel.tscn")
