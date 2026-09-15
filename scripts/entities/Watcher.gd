extends CharacterBody3D

enum State { STALKING, OBSERVING, FLEEING }

var current_state: State = State.STALKING
var target_player: Node3D = null
var hover_time: float = 0.0

# User Settings
var stalking_speed: float = 1.0 # Very slow creeping
var flee_speed: float = 15.0 # Fly backwards very quickly
var flee_duration: float = 1.0
var _flee_timer: float = 0.0

@onready var pupil: MeshInstance3D = $Pupil
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
var los_raycast: RayCast3D

func _ready() -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		set_physics_process(false)
		return
		
	# Dynamically create LOS raycast to avoid modifying tscn
	los_raycast = RayCast3D.new()
	los_raycast.collision_mask = 1 | 3 # World and Player
	add_child(los_raycast)

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
		
	_find_nearest_player()
	_update_state()
	
	match current_state:
		State.STALKING:
			_process_stalking(delta)
		State.OBSERVING:
			velocity = Vector3.ZERO # Freeze
		State.FLEEING:
			_process_fleeing(delta)
			
	# Hover effect
	hover_time += delta
	# Add vertical hover to velocity instead of manually setting position.y
	# We want a target hover velocity
	var hover_vel = cos(hover_time * 2.0) * 1.0
	velocity.y = hover_vel
	
	if target_player:
		_look_at_target()

	move_and_slide()

func _find_nearest_player() -> void:
	var players = get_tree().get_nodes_in_group("players")
	var nearest_dist = INF
	target_player = null
	
	for p in players:
		var dist = global_position.distance_to(p.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			target_player = p

func _update_state() -> void:
	if not target_player:
		velocity = Vector3.ZERO
		return
		
	# If currently fleeing on a timer, don't interrupt it immediately
	if current_state == State.FLEEING and _flee_timer > 0.0:
		return
		
	if not _has_line_of_sight(target_player):
		current_state = State.STALKING
		return
		
	var is_looking = _is_player_looking(target_player)
	var is_lit = _is_illuminated(target_player)
	var dist = global_position.distance_to(target_player.global_position)
	
	if is_lit or (is_looking and dist < 7.0):
		current_state = State.FLEEING
		_flee_timer = flee_duration
	elif is_looking:
		current_state = State.OBSERVING
	else:
		current_state = State.STALKING

func _process_stalking(delta: float) -> void:
	if target_player == null:
		return
	
	nav_agent.target_position = target_player.global_position
	var next_pos = nav_agent.get_next_path_position()
	
	var dir = global_position.direction_to(next_pos)
	dir.y = 0 
	if dir.length_squared() > 0:
		dir = dir.normalized()
		
	var dist = global_position.distance_to(target_player.global_position)
	# The further away, the faster it goes. Maxes out at 5x speed at 20 meters.
	# Slows down to 0.2x speed when very close.
	var speed_multiplier = clamp(dist / 4.0, 0.2, 5.0)
	var dynamic_speed = stalking_speed * speed_multiplier
		
	velocity.x = dir.x * dynamic_speed
	velocity.z = dir.z * dynamic_speed

func _process_fleeing(delta: float) -> void:
	if target_player == null:
		return
	_flee_timer -= delta
	
	# For fleeing, we just fly straight backwards away from the player
	# We don't pathfind fleeing to avoid getting stuck in complex logic
	var dir = target_player.global_position.direction_to(global_position) # Away from player
	dir.y = 0
	if dir.length_squared() > 0:
		dir = dir.normalized()
	velocity.x = dir.x * flee_speed
	velocity.z = dir.z * flee_speed

func _look_at_target() -> void:
	# Point pupil at target
	var target_pos = target_player.global_position + Vector3.UP * 1.5
	# Avoid look_at error if directly above/below
	if global_position.is_equal_approx(target_pos): return
	look_at(target_pos, Vector3.UP)

# --- AI SENSORS ---

func _has_line_of_sight(player: Node3D) -> bool:
	var head_pos = player.global_position + Vector3.UP * 1.5
	los_raycast.target_position = to_local(head_pos)
	los_raycast.force_raycast_update()
	if los_raycast.is_colliding():
		var collider = los_raycast.get_collider()
		if collider == player:
			return true
		return false
	return true

func _is_player_looking(player: Node3D) -> bool:
	var head = player.get_node_or_null("Head")
	if not head: return false
	
	var look_dir = -head.global_transform.basis.z.normalized()
	var dir_to_me = player.global_position.direction_to(global_position)
	# Dot product > 0.6 means approx 50 degrees FOV
	return look_dir.dot(dir_to_me) > 0.6

func _is_illuminated(player: Node3D) -> bool:
	var head = player.get_node_or_null("Head")
	if not head: return false
	var camera = head.get_node_or_null("Camera3D")
	if not camera: return false
	var flashlight = camera.get_node_or_null("Flashlight")
	if not flashlight or not flashlight.is_on: return false
	
	# Check if we are inside the flashlight's cone
	var light_dir = -flashlight.global_transform.basis.z.normalized()
	var dir_to_me = player.global_position.direction_to(global_position)
	var dot_val = clamp(light_dir.dot(dir_to_me), -1.0, 1.0)
	var angle_to_me = rad_to_deg(acos(dot_val))
	
	# Flashlight spot_angle is the total cone, so angle_to_me should be less than half of it?
	# In Godot, spot_angle is the half-angle! So angle_to_me < spot_angle is correct.
	return angle_to_me < flashlight.spot_angle
