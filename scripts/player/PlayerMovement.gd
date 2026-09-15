extends CharacterBody3D
class_name PlayerMovement
enum PlayerClass {
	ENGINEER,
	ATHLETE,
	HOARDER,
	FRESHMAN
}

@export var character_class: PlayerClass = PlayerClass.ATHLETE:
	set(value):
		character_class = value
		_apply_character_class(value)

func _apply_character_class(value: int) -> void:
	if not is_inside_tree():
		return
	var inv = get_node_or_null("PlayerInventory")
	if inv and inv.has_method("initialize"):
		inv.initialize(value)
	normal_head_height = PlayerModel.get_eye_height(value)
	if head:
		head.position.y = normal_head_height
	var model = get_node_or_null("PlayerModel")
	if model and model.has_method("set_class_visuals"):
		model.set_class_visuals(value)

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

## Debug FreeCam settings
@export var debug_speed: float = 12.0
@export var debug_sprint_speed: float = 28.0
var is_debug_cam: bool = false
var debug_hud: Control = null

## Anti-Void & Room Tracking
var last_room: String = "Entrance Elevator"
var last_room_position: Vector3 = Vector3(0, 1.0, 0)
var void_teleport_y_threshold: float = -20.0

## Debug Ambient Light state
var _debug_ambient_enabled: bool = false
var _orig_world_env_ref: WorldEnvironment = null
var _orig_ambient_source: int = 0
var _orig_ambient_color: Color = Color.BLACK
var _orig_ambient_energy: float = 1.0
var _cached_orig_settings: bool = false

# Get the gravity from the project settings, then scale it.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var camera: Camera3D = null
var head: Node3D = null
var health_node: Node = null
var exhausted_audio: AudioStreamPlayer3D = null

func _enter_tree() -> void:
	var peer_id = name.to_int()
	if peer_id == 0:
		peer_id = 1
	set_multiplayer_authority(peer_id)
	
	if NetworkManager and NetworkManager.players.has(peer_id):
		character_class = NetworkManager.players[peer_id].get("class", character_class)
	
	var sync = get_node_or_null("MultiplayerSynchronizer")
	if sync:
		sync.set_multiplayer_authority(peer_id)

func _ready() -> void:
	add_to_group("players")
	# Cache commonly used nodes
	head = get_node_or_null("Head")
	if head:
		camera = head.get_node_or_null("Camera3D")
	
	var peer_id = name.to_int()
	if NetworkManager and NetworkManager.players.has(peer_id):
		character_class = NetworkManager.players[peer_id].get("class", character_class)
		
	_apply_character_class(character_class)
	
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

	# Connect to CheatCodeManager
	var cheat_mgr = get_node_or_null("CheatCodeManager")
	if cheat_mgr:
		cheat_mgr.cheat_activated.connect(_on_cheat)
		
	var ui = get_node_or_null("InteractionUI")
	if ui:
		debug_hud = ui.get_node_or_null("DebugHUD")

	# Connect to LevelState power changes so DebugHUD updates across all clients in freecam
	var state = get_node_or_null("/root/LevelState")
	if not state and is_inside_tree() and get_tree().root:
		state = get_tree().root.get_node_or_null("LevelState")
	if state and state.has_signal("power_changed"):
		state.power_changed.connect(_on_level_power_changed)

	# Set exact eye-level camera height based on the character model's visor
	normal_head_height = PlayerModel.get_eye_height(character_class)
	if head:
		head.position.y = normal_head_height

	# Apply Class Modifiers
	if character_class == PlayerClass.ATHLETE:
		sprint_speed *= 1.15
		max_stamina = 130.0
		current_stamina = max_stamina
		
		# Create a placeholder audio node for the Athlete's loud breathing tradeoff
		exhausted_audio = AudioStreamPlayer3D.new()
		exhausted_audio.name = "ExhaustedBreathing"
		exhausted_audio.max_distance = 30.0 # Large radius so the monster can hear it
		exhausted_audio.volume_db = 5.0
		add_child(exhausted_audio)
	elif character_class == PlayerClass.ENGINEER:
		# Engineer Tradeoff: Constant faint electrical hum
		var engineer_audio := AudioStreamPlayer3D.new()
		engineer_audio.name = "ElectricalHum"
		engineer_audio.max_distance = 15.0 # Medium radius
		engineer_audio.volume_db = -10.0
		# engineer_audio.stream = preload("res://audio/hum.ogg") # TODO: Add audio file
		# engineer_audio.autoplay = true
		add_child(engineer_audio)
	elif character_class == PlayerClass.HOARDER:
		pass
	elif character_class == PlayerClass.FRESHMAN:
		pass
		
	if camera:
		camera.current = true

	last_room_position = global_position
	last_room_position.y = maxf(last_room_position.y, 0.5)

func _exit_tree() -> void:
	if _debug_ambient_enabled:
		_apply_debug_ambient_light(false)

func _physics_process(delta: float) -> void:
	if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return
		
	# Anti-void protection: recover player if fallen/glitched below y = -20
	var current_y = global_position.y if is_inside_tree() else position.y
	if current_y < void_teleport_y_threshold:
		_recover_from_void()
		return
		
	if is_debug_cam:
		_process_debug_cam_movement(delta)
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

	# Only allow movement if mouse is captured (meaning no UI is open)
	var input_dir := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
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
	var input_dir := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
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

func _is_debug_key_down(key: Key) -> bool:
	return Input.is_physical_key_pressed(key) or Input.is_key_pressed(key)

func _unhandled_input(event: InputEvent) -> void:
	if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return
		
	if is_debug_cam and event is InputEventKey and event.pressed and not event.echo:
		var is_p = (event.keycode == KEY_P or event.physical_keycode == KEY_P or event.key_label == KEY_P)
		var is_l = (event.keycode == KEY_L or event.physical_keycode == KEY_L or event.key_label == KEY_L)
		if is_p:
			_toggle_facility_power()
		elif is_l:
			_toggle_debug_ambient_light()

func _on_cheat(code: String) -> void:
	if code == "bug":
		toggle_debug_cam()
	elif code == "pow":
		_toggle_facility_power()
	elif code == "lit":
		_toggle_debug_ambient_light()

func toggle_debug_cam() -> void:
	is_debug_cam = !is_debug_cam
	var col = get_node_or_null("CollisionShape3D")
	if col:
		col.disabled = is_debug_cam
	velocity = Vector3.ZERO
	_apply_debug_ambient_light(is_debug_cam)
	_update_debug_hud()
	print("[DEBUG] FreeCam toggled: ", is_debug_cam)

func _process_debug_cam_movement(delta: float) -> void:
	var cam_basis = camera.global_transform.basis if camera else global_transform.basis
	var move_dir = Vector3.ZERO
	
	if _is_debug_key_down(KEY_W):
		move_dir -= cam_basis.z
	if _is_debug_key_down(KEY_S):
		move_dir += cam_basis.z
	if _is_debug_key_down(KEY_A):
		move_dir -= cam_basis.x
	if _is_debug_key_down(KEY_D):
		move_dir += cam_basis.x
		
	if _is_debug_key_down(KEY_SPACE):
		move_dir += Vector3.UP
	if _is_debug_key_down(KEY_CTRL) or _is_debug_key_down(KEY_C):
		move_dir -= Vector3.UP
		
	if move_dir.length_squared() > 0.001:
		move_dir = move_dir.normalized()
		
	var speed = debug_sprint_speed if _is_debug_key_down(KEY_SHIFT) else debug_speed
	global_position += move_dir * speed * delta
	velocity = Vector3.ZERO

func _on_level_power_changed(is_on: bool) -> void:
	_update_debug_hud()
	if is_debug_cam:
		var power_txt = "ON" if is_on else "OFF"
		show_toast("[ FACILITY POWER: " + power_txt + " ]", 2.0)

func _toggle_facility_power() -> void:
	var state = get_node_or_null("/root/LevelState")
	if not state and is_inside_tree() and get_tree().root:
		state = get_tree().root.get_node_or_null("LevelState")
	if not state:
		print("LevelState singleton not found!")
		return
		
	if state.has_method("debug_toggle_power"):
		if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
			state.debug_toggle_power.rpc()
		else:
			state.debug_toggle_power()
	else:
		state.is_power_on = !state.is_power_on
		if state.is_power_on:
			state.fuses_installed = state.fuses_required
			if state.has_signal("power_restored"):
				state.power_restored.emit()
		if state.has_signal("power_changed"):
			state.power_changed.emit(state.is_power_on)

func _update_debug_hud() -> void:
	if not debug_hud:
		var ui = get_node_or_null("InteractionUI")
		if ui:
			debug_hud = ui.get_node_or_null("DebugHUD")
	if not debug_hud:
		return
		
	debug_hud.visible = is_debug_cam
	if is_debug_cam:
		var is_on = false
		var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		var state = tree.root.get_node_or_null("LevelState") if (tree and tree.root) else get_node_or_null("/root/LevelState")
		if state:
			is_on = state.is_power_on
		var label = debug_hud.get_node_or_null("DebugLabel") as Label
		if label:
			var power_str = "ON" if is_on else "OFF"
			var light_str = "ON (83,83,83 @ 2.5)" if _debug_ambient_enabled else "OFF"
			label.text = "[ DEBUG FREECAM ACTIVE ]\nFly: WASD | Up/Down: Space/Ctrl | Sprint: Shift\n[P]: Toggle Power (%s) | [L]: Ambient Light (%s)\nType 'BUG' to exit" % [power_str, light_str]

## Updates the player's last safe room checkpoint
func set_last_room(room_identifier: Variant, pos: Vector3 = Vector3.INF) -> void:
	if room_identifier is String:
		last_room = room_identifier
	elif room_identifier is Node:
		last_room = room_identifier.name
	else:
		last_room = str(room_identifier)
		
	if not pos.is_finite():
		last_room_position = global_position if is_inside_tree() else position
	else:
		last_room_position = pos
		
	last_room_position.y = maxf(last_room_position.y, 0.5)
	print("[AntiVoid] Checkpoint updated: '", last_room, "' at ", last_room_position)

## Teleports player back to the last safe room if they fall into the void
func _recover_from_void() -> void:
	velocity = Vector3.ZERO
	if is_inside_tree():
		global_position = last_room_position
		global_position.y = maxf(global_position.y, 0.5)
	else:
		position = last_room_position
		position.y = maxf(position.y, 0.5)
	print("[AntiVoid] Player fell into void (y < %.1f)! Teleporting back to '%s' at %v" % [void_teleport_y_threshold, last_room, last_room_position])
	show_toast("[ RESCUED FROM VOID: " + last_room + " ]")

## Displays on-screen notification using CheatToast
func show_toast(msg: String, duration: float = 2.5) -> void:
	var toast = get_node_or_null("InteractionUI/CheatToast") as Label
	if not toast:
		var ui = get_node_or_null("InteractionUI")
		if ui:
			toast = ui.get_node_or_null("CheatToast") as Label
	if toast:
		toast.text = msg
		toast.visible = true
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(toast) and toast.text == msg:
				toast.visible = false
		)

func _find_world_environment() -> WorldEnvironment:
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if not tree:
		return null
	if tree.current_scene:
		if tree.current_scene is WorldEnvironment:
			return tree.current_scene
		var env = tree.current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
		if env:
			return env
	if tree.root:
		for child in tree.root.get_children():
			if child is WorldEnvironment:
				return child
			var env = child.find_child("WorldEnvironment", true, false) as WorldEnvironment
			if env:
				return env
	return null

## Applies ambient light boost (Color8(83, 83, 83), energy = 2.5) during debug mode
func _apply_debug_ambient_light(enable: bool) -> void:
	_debug_ambient_enabled = enable
	var world_env: WorldEnvironment = _find_world_environment()
	if world_env and world_env.environment:
		if enable:
			if not _cached_orig_settings:
				_orig_world_env_ref = world_env
				_orig_ambient_source = world_env.environment.ambient_light_source
				_orig_ambient_color = world_env.environment.ambient_light_color
				_orig_ambient_energy = world_env.environment.ambient_light_energy
				_cached_orig_settings = true
			world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			world_env.environment.ambient_light_color = Color8(83, 83, 83)
			world_env.environment.ambient_light_energy = 2.5
			print("[DEBUG] Ambient light enabled on WorldEnvironment: Color8(83, 83, 83), energy = 2.5")
		else:
			if _cached_orig_settings and is_instance_valid(_orig_world_env_ref) and _orig_world_env_ref.environment:
				_orig_world_env_ref.environment.ambient_light_source = _orig_ambient_source
				_orig_world_env_ref.environment.ambient_light_color = _orig_ambient_color
				_orig_world_env_ref.environment.ambient_light_energy = _orig_ambient_energy
				_cached_orig_settings = false
				print("[DEBUG] Ambient light restored on WorldEnvironment")
	elif camera:
		if enable:
			var cam_env = camera.environment
			if not cam_env:
				cam_env = Environment.new()
				cam_env.background_mode = Environment.BG_CLEAR_COLOR
				camera.environment = cam_env
			cam_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			cam_env.ambient_light_color = Color8(83, 83, 83)
			cam_env.ambient_light_energy = 2.5
			print("[DEBUG] Ambient light enabled on Camera3D: Color8(83, 83, 83), energy = 2.5")
		else:
			camera.environment = null
			print("[DEBUG] Ambient light restored on Camera3D")

func _toggle_debug_ambient_light() -> void:
	_apply_debug_ambient_light(!_debug_ambient_enabled)
	_update_debug_hud()
