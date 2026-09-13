extends Node
class_name PlayerVoice

@export var hear_myself: bool = false
@export var mic_boost: float = 1.0

@onready var player: CharacterBody3D = get_parent()

var mic_player: AudioStreamPlayer
var playback_3d: AudioStreamPlayer3D
var capture_effect: AudioEffectCapture
var playback_generator: AudioStreamGeneratorPlayback

var current_volume: float = 0.0

var tick_rate: float = 20.0
var time_since_last_send: float = 0.0

func _ready() -> void:
	hear_myself = NetworkManager.hear_myself
	mic_boost = NetworkManager.mic_boost

	if player.is_multiplayer_authority():
		mic_player = AudioStreamPlayer.new()
		mic_player.stream = AudioStreamMicrophone.new()
		mic_player.bus = "Record"
		add_child(mic_player)
		mic_player.play()
		
		var record_bus_idx = AudioServer.get_bus_index("Record")
		if record_bus_idx >= 0:
			for i in range(AudioServer.get_bus_effect_count(record_bus_idx)):
				if AudioServer.get_bus_effect(record_bus_idx, i) is AudioEffectCapture:
					capture_effect = AudioServer.get_bus_effect(record_bus_idx, i) as AudioEffectCapture
					break

	# Attach playback node to Head for accurate 3D positioning
	var head = player.get_node_or_null("Head")
	var parent_node = head if head else player
	
	playback_3d = AudioStreamPlayer3D.new()
	var gen = AudioStreamGenerator.new()
	gen.buffer_length = 0.4
	
	# Try to match the output mix rate for smooth playback
	gen.mix_rate = AudioServer.get_mix_rate() 
	playback_3d.stream = gen
	playback_3d.bus = "Voice"
	
	# Proximity audio settings
	playback_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	playback_3d.max_distance = 25.0
	playback_3d.unit_size = 2.0
	
	parent_node.add_child(playback_3d)
	playback_3d.play()
	
	playback_generator = playback_3d.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(delta: float) -> void:
	if not player.is_multiplayer_authority() or not capture_effect:
		return
		
	time_since_last_send += delta
	if time_since_last_send >= (1.0 / tick_rate):
		time_since_last_send = 0.0
		
		var is_radio = Input.is_action_pressed("push_to_talk")
		
		var frames = capture_effect.get_frames_available()
		if frames > 0:
			var buffer = capture_effect.get_buffer(frames)
			
			var peak = 0.0
			for i in range(buffer.size()):
				buffer[i] *= mic_boost
				var p = max(abs(buffer[i].x), abs(buffer[i].y))
				if p > peak:
					peak = p
			
			current_volume = lerp(current_volume, peak, 0.5)
			
			if peak > 0.005:
				_rpc_receive_audio.rpc(buffer, is_radio)
		else:
			current_volume = lerp(current_volume, 0.0, 0.2)

@rpc("any_peer", "unreliable", "call_local")
func _rpc_receive_audio(buffer: PackedVector2Array, is_radio: bool) -> void:
	# Ignore our own voice (unless debugging locally or hear_myself is true)
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == multiplayer.get_unique_id() and not hear_myself:
		return
		
	if playback_generator and playback_generator.can_push_buffer(buffer.size()):
		playback_generator.push_buffer(buffer)
		
	# Walkie-talkie logic
	if is_radio:
		# Bypass 3D attenuation
		playback_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	else:
		playback_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
