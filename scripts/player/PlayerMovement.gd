extends CharacterBody3D
class_name PlayerMovement
enum PlayerClass {
	ENGINEER,
	ATHLETE,
	HOARDER,
	FRESHMAN
}

@export var character_class: PlayerClass = PlayerClass.ATHLETE

@export var walk_speed: float = 3.5
@export var sprint_speed: float = 6.5
@export var jump_velocity: float = 5.5
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 20.0
@export var stamina_regen_rate: float = 15.0

## Gravity multiplier — default Godot gravity (9.8) feels floaty.
## 2.5x gives a snappy, grounded feel typical of FPS games.
@export var gravity_multiplier: float = 2.5

## FOV boost when sprinting for visual feedback.
@export var sprint_fov: float = 80.0
@export var normal_fov: float = 70.0
@export var fov_lerp_speed: float = 8.0

## Downed state movement settings.
@export var crawl_speed: float = 1.0
@export var downed_head_height: float = 0.15
@export var normal_head_height: float = 0.6
@export var head_lerp_speed: float = 5.0

var current_stamina: float = 100.0
var is_sprinting: bool = false
var is_exhausted: bool = false

# Get the gravity from the project settings, then scale it.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var camera: Camera3D = null
var head: Node3D = null
var health_node: Node = null
var exhausted_audio: AudioStreamPlayer3D = null

func _enter_tree() -> void:
	var peer_id = name.to_int()
	set_multiplayer_authority(peer_id)
	
	var sync = get_node_or_null("MultiplayerSynchronizer")
	if sync:
		sync.set_multiplayer_authority(peer_id)

func _ready() -> void:
	# Cache commonly used nodes
	head = get_node_or_null("Head")
	if head:
		camera = head.get_node_or_null("Camera3D")
	
	if not is_multiplayer_authority():
		var ui = get_node_or_null("InteractionUI")
		if ui:
			ui.queue_free()
		return
	
	# Only the local player captures the mouse and sets up the camera
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Initialize inventory with correct class (fallback for clients)
	var inv = get_node_or_null("PlayerInventory")
	if inv and inv.has_method("initialize"):
		inv.initialize(character_class)
		
	if camera:
		camera.fov = normal_fov
	# Find health node for downed state checks
	health_node = get_node_or_null("PlayerHealth")

	# Apply Class Modifiers
	if character_class == PlayerClass.ATHLETE:
		sprint_speed *= 1.15
		max_stamina = 130.0
		current_stamina = max_stamina
		normal_head_height *= 1.1 # Taller
		
		# Create a placeholder audio node for the Athlete's loud breathing tradeoff
		exhausted_audio = AudioStreamPlayer3D.new()
		exhausted_audio.name = "ExhaustedBreathing"
		exhausted_audio.max_distance = 30.0 # Large radius so the monster can hear it
		exhausted_audio.volume_db = 5.0
		add_child(exhausted_audio)
	elif character_class == PlayerClass.ENGINEER:
		normal_head_height *= 0.92 # Slightly shorter
		
		# Engineer Tradeoff: Constant faint electrical hum
		var engineer_audio := AudioStreamPlayer3D.new()
		engineer_audio.name = "ElectricalHum"
		engineer_audio.max_distance = 15.0 # Medium radius
		engineer_audio.volume_db = -10.0
		# engineer_audio.stream = preload("res://audio/hum.ogg") # TODO: Add audio file
		# engineer_audio.autoplay = true
		add_child(engineer_audio)
	elif character_class == PlayerClass.HOARDER:
		normal_head_height *= 0.9 # Shorter
	elif character_class == PlayerClass.FRESHMAN:
		normal_head_height *= 0.95 # Slightly shorter
		
	if camera:
		camera.current = true



func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	var is_player_downed: bool = health_node and health_node.is_downed()
	var is_player_dead: bool = health_node and health_node.state == health_node.State.DEAD

	# If dead, stop all movement
	if is_player_dead:
		velocity = Vector3.ZERO
		_update_head_height(delta, downed_head_height)
		move_and_slide()
		return

	# Apply gravity with multiplier for snappier falls.
	if not is_on_floor():
		velocity.y -= gravity * gravity_multiplier * delta

	# When downed: no jumping, no sprinting — crawl only
	if is_player_downed:
		_process_downed_movement(delta)
		return

	# Handle Jump (hold Space to auto-jump on landing).
	if Input.is_action_pressed("jump") and is_on_floor() and not is_exhausted:
		velocity.y = jump_velocity
		current_stamina -= 10.0

	# Handle Sprinting and Stamina
	# Sprint persists in the air so jumping while sprinting doesn't kill momentum.
	var wants_sprint := Input.is_action_pressed("sprint") and not is_exhausted
	var is_moving := velocity.length_squared() > 0.1
	is_sprinting = wants_sprint and is_moving

	if is_sprinting and is_on_floor():
		# Only drain stamina while grounded
		current_stamina -= stamina_drain_rate * delta
		if current_stamina <= 0:
			current_stamina = 0
			if not is_exhausted:
				is_exhausted = true
				if character_class == PlayerClass.ATHLETE:
					print("ATHLETE TRADEOFF: Loud heavy breathing started!")
					# if exhausted_audio: exhausted_audio.play()
			is_sprinting = false
	elif not is_sprinting:
		current_stamina += stamina_regen_rate * delta
		if current_stamina >= max_stamina:
			current_stamina = max_stamina
			if is_exhausted:
				is_exhausted = false
				if character_class == PlayerClass.ATHLETE:
					print("ATHLETE TRADEOFF: Loud heavy breathing stopped.")
					# if exhausted_audio: exhausted_audio.stop()

	var speed = sprint_speed if is_sprinting else walk_speed

	# Hoarder Tradeoff: Cannot reach max sprint speed if inventory is full
	if character_class == PlayerClass.HOARDER and is_sprinting:
		var inv = get_node_or_null("PlayerInventory")
		if inv:
			var full = true
			for i in range(inv.max_slots):
				if i < inv.items.size() and inv.items[i] == null:
					full = false
					break
			if full:
				speed = walk_speed * 1.2 # Capped sprint speed
				
	# Sprint FOV effect
	if camera:
		var target_fov = sprint_fov if is_sprinting else normal_fov
		camera.fov = lerp(camera.fov, target_fov, fov_lerp_speed * delta)

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Keep head at normal height when alive
	_update_head_height(delta, normal_head_height)

	move_and_slide()

## Downed movement — slow crawl, no jump, camera drops to ground level.
func _process_downed_movement(delta: float) -> void:
	# Drop camera to ground level
	_update_head_height(delta, downed_head_height)

	# Reset FOV to normal (no sprinting when downed)
	if camera:
		camera.fov = lerp(camera.fov, normal_fov, fov_lerp_speed * delta)

	# Slow crawl movement only
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * crawl_speed
		velocity.z = direction.z * crawl_speed
	else:
		velocity.x = move_toward(velocity.x, 0, crawl_speed)
		velocity.z = move_toward(velocity.z, 0, crawl_speed)

	move_and_slide()

## Smoothly lerp the head (camera parent) to a target Y height.
func _update_head_height(delta: float, target_y: float) -> void:
	if head:
		var pos := head.position
		pos.y = lerp(pos.y, target_y, head_lerp_speed * delta)
		head.position = pos

## Returns the multiplier for how long an interaction should take (Engineer buff).
func get_interaction_time_multiplier() -> float:
	if character_class == PlayerClass.ENGINEER:
		return 0.7
	return 1.0
