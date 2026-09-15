class_name LevelGenerator
extends Node3D

const GRID_SIZE = 32.0

var seed_val: int = 0
var floor_num: int = 1
var rng: RandomNumberGenerator

## Tuning parameters — adjust in Inspector or from code
@export var branch_chance: float = 0.4
@export var door_chance: float = 0.6
@export var loop_chance: float = 0.3
@export var fuses_per_level: int = 8

var grid_instances: Dictionary = {}

var modules = {
	"elevator": preload("res://scenes/rooms/modules/ElevatorCabin.tscn"),
	"corridor": preload("res://scenes/rooms/modules/Room_Corridor.tscn"),
	"turn": preload("res://scenes/rooms/modules/Room_Turn.tscn"),
	"tjunction": preload("res://scenes/rooms/modules/Room_TJunction.tscn"),
	"cross": preload("res://scenes/rooms/modules/Room_Cross.tscn"),
	"wall_cap": preload("res://scenes/rooms/modules/Wall_Cap.tscn"),
	"door": preload("res://scenes/rooms/modules/FacilityDoor.tscn")
}

const DIR_N = Vector2i(0, -1)
const DIR_E = Vector2i(1, 0)
const DIR_S = Vector2i(0, 1)
const DIR_W = Vector2i(-1, 0)

const FLAG_N = 1
const FLAG_E = 2
const FLAG_S = 4
const FLAG_W = 8

func generate_level(new_seed: int, new_floor: int) -> void:
	seed_val = new_seed
	floor_num = new_floor
	if seed_val == 0:
		randomize()
		seed_val = randi()
	rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	_clear_level()
	print("Generating Level with seed: ", seed_val)
	
	var target_len = 5 + floor_num * 2
	var min_cells = 4 + floor_num * 2
	var grid_layout = {}
	var attempts = 0
	
	# Attempt main walk with validation for minimum path length
	while attempts < 10:
		attempts += 1
		grid_layout.clear()
		
		# Start Elevator at (0,0), opens North
		grid_layout[Vector2i(0,0)] = FLAG_N
		var current = Vector2i(0, -1)
		grid_layout[current] = FLAG_S
		
		_random_walk(grid_layout, current, target_len)
		if grid_layout.size() >= min_cells:
			break
	
	# Add branches
	var all_cells = grid_layout.keys().duplicate()
	for cell in all_cells:
		if cell != Vector2i(0,0):
			if rng.randf() < branch_chance:
				_random_walk(grid_layout, cell, rng.randi_range(1, 3))
				
	# Calculate topological BFS distances from start (0,0) to place exit elevator
	var distances = _calculate_bfs_distances(grid_layout, Vector2i(0, 0))
	var end_pos = _select_exit_position(grid_layout, distances)
	
	# Add loops between adjacent rooms (excludes start and exit elevators)
	_add_loops(grid_layout, end_pos, loop_chance)
	
	_spawn_layout(grid_layout, end_pos)
	print("Level generation complete. Total rooms: ", grid_layout.size(), " Exit at: ", end_pos)

func _random_walk(layout: Dictionary, start: Vector2i, steps: int) -> Vector2i:
	var current = start
	for i in range(steps):
		var allowed = []
		for d in [DIR_N, DIR_E, DIR_W, DIR_S]:
			if not layout.has(current + d):
				allowed.append(d)
				# Biased towards North only if North is truly available
				if d == DIR_N:
					allowed.append(d)
					allowed.append(d)
				
		if allowed.is_empty():
			break
			
		var dir = allowed[rng.randi() % allowed.size()]
		var next_cell = current + dir
		
		if not layout.has(current): layout[current] = 0
		layout[current] |= _dir_to_flag(dir)
		layout[next_cell] = _dir_to_flag(_opposite_dir(dir))
		current = next_cell
	return current

func _calculate_bfs_distances(layout: Dictionary, start: Vector2i) -> Dictionary:
	var distances = { start: 0 }
	var queue: Array[Vector2i] = [start]
	
	while not queue.is_empty():
		var curr = queue.pop_front()
		var mask = layout.get(curr, 0)
		var current_dist = distances[curr]
		
		for d in [DIR_N, DIR_E, DIR_S, DIR_W]:
			var flag = _dir_to_flag(d)
			if (mask & flag) != 0:
				var neighbor = curr + d
				if layout.has(neighbor) and not distances.has(neighbor):
					distances[neighbor] = current_dist + 1
					queue.append(neighbor)
					
	return distances

func _select_exit_position(layout: Dictionary, distances: Dictionary) -> Vector2i:
	var best_end_pos = Vector2i.ZERO
	var max_dist = -1
	
	# Prefer dead-end rooms (rooms with only 1 connection) for the elevator
	for cell in layout.keys():
		if cell == Vector2i(0, 0) or cell == Vector2i(0, -1):
			continue
		var mask = layout[cell]
		if mask in [FLAG_N, FLAG_E, FLAG_S, FLAG_W]:
			var dist = distances.get(cell, -1)
			if dist > max_dist:
				max_dist = dist
				best_end_pos = cell
				
	# Fallback if no dead-end was found: pick the furthest room and append an elevator cell
	if best_end_pos == Vector2i.ZERO:
		for cell in layout.keys():
			if cell == Vector2i(0, 0) or cell == Vector2i(0, -1):
				continue
			var dist = distances.get(cell, -1)
			if dist > max_dist:
				max_dist = dist
				best_end_pos = cell
				
		var mask = layout.get(best_end_pos, 0)
		if not (mask in [FLAG_N, FLAG_E, FLAG_S, FLAG_W]):
			for d in [DIR_N, DIR_E, DIR_S, DIR_W]:
				var cand = best_end_pos + d
				if not layout.has(cand):
					layout[best_end_pos] |= _dir_to_flag(d)
					layout[cand] = _dir_to_flag(_opposite_dir(d))
					best_end_pos = cand
					break
					
	return best_end_pos

func _add_loops(layout: Dictionary, end_pos: Vector2i, loop_chance: float = 0.3) -> void:
	var cells = layout.keys().duplicate()
	for cell in cells:
		if cell == Vector2i(0, 0) or cell == end_pos:
			continue
			
		# Check East and South neighbors so each boundary is checked once
		for d in [DIR_E, DIR_S]:
			var neighbor = cell + d
			if neighbor == Vector2i(0, 0) or neighbor == end_pos:
				continue
				
			if layout.has(neighbor):
				var flag = _dir_to_flag(d)
				var is_connected = (layout[cell] & flag) != 0
				if not is_connected:
					if rng.randf() < loop_chance:
						layout[cell] |= flag
						layout[neighbor] |= _dir_to_flag(_opposite_dir(d))

func _dir_to_flag(dir: Vector2i) -> int:
	if dir == DIR_N: return FLAG_N
	if dir == DIR_E: return FLAG_E
	if dir == DIR_S: return FLAG_S
	if dir == DIR_W: return FLAG_W
	return 0

func _opposite_dir(dir: Vector2i) -> Vector2i:
	return Vector2i(-dir.x, -dir.y)

func _spawn_layout(layout: Dictionary, end_pos: Vector2i) -> void:
	for pos in layout.keys():
		var mask = layout[pos]
		var type = ""
		var rot = 0.0
		
		if pos == Vector2i(0,0):
			type = "elevator"
			rot = 0.0
		elif pos == end_pos:
			type = "elevator"
			if mask & FLAG_N: rot = 0.0
			elif mask & FLAG_S: rot = PI
			elif mask & FLAG_E: rot = -PI / 2.0
			elif mask & FLAG_W: rot = PI / 2.0
		else:
			match mask:
				1, 4, 5: # N, S, N|S
					type = "corridor"
					rot = 0.0
				2, 8, 10: # E, W, E|W
					type = "corridor"
					rot = PI/2
				3: # N|E
					type = "turn"
					rot = 0.0
				6: # E|S
					type = "turn"
					rot = -PI/2
				12: # S|W
					type = "turn"
					rot = PI
				9: # W|N
					type = "turn"
					rot = PI/2
				7: # N|E|S
					type = "tjunction"
					rot = 0.0
				14: # E|S|W
					type = "tjunction"
					rot = -PI/2
				13: # S|W|N
					type = "tjunction"
					rot = PI
				11: # W|N|E
					type = "tjunction"
					rot = PI/2
				15: # N|E|S|W
					type = "cross"
					rot = 0.0
				_:
					type = "corridor"
		
		if type != "":
			var is_exit_elev = (type == "elevator" and pos == end_pos)
			var inst = _spawn_module(pos, type, rot, is_exit_elev)
			if type == "elevator" and inst.has_method("setup_elevator_type"):
				inst.setup_elevator_type(is_exit_elev)
			
	# After all spawned, place caps on open sockets
	for pos in grid_instances.keys():
		var room = grid_instances[pos]
		var mask = layout[pos]
		if pos != Vector2i(0,0) and pos != end_pos:
			_cap_open_sockets(room, mask)
			
	# Spawn interactive doors at chunk boundaries (between standard rooms)
	for pos in layout.keys():
		if pos == Vector2i(0, 0) or pos == end_pos:
			continue
		var mask = layout[pos]
		
		if (mask & FLAG_S):
			var neighbor = pos + DIR_S
			if neighbor != Vector2i(0, 0) and neighbor != end_pos:
				if rng.randf() < door_chance: # 60% chance for a door
					_spawn_door(pos, DIR_S)
				
		if (mask & FLAG_E):
			var neighbor = pos + DIR_E
			if neighbor != Vector2i(0, 0) and neighbor != end_pos:
				if rng.randf() < door_chance:
					_spawn_door(pos, DIR_E)
				
	_spawn_power_objects(end_pos)

func _spawn_power_objects(end_pos: Vector2i) -> void:
	var start_room = grid_instances.get(Vector2i(0, -1))
	if start_room:
		var gen = preload("res://scenes/objects/Generator.tscn").instantiate()
		start_room.add_child(gen)
		gen.position = Vector3(1.5, 0, 0)
		
		var panel = preload("res://scenes/objects/FusePanel.tscn").instantiate()
		start_room.add_child(panel)
		panel.position = Vector3(-2.9, 0, 0)
		panel.rotation.y = PI / 2.0
		
	var available = []
	for k in grid_instances.keys():
		if k != Vector2i(0,0) and k != end_pos and k != Vector2i(0, -1):
			available.append(k)
			
	var fuses_to_place = fuses_per_level
	for i in range(fuses_to_place):
		if available.is_empty():
			break
		var idx = rng.randi_range(0, available.size() - 1)
		var pos = available[idx]
		available.remove_at(idx)
		
		var room = grid_instances[pos]
		var fuse = preload("res://scenes/items/PickupItem.tscn").instantiate()
		fuse.item_data = load("res://resources/items/Fuse.tres")
		fuse.name = "Fuse_%d_%d" % [pos.x, pos.y]
		room.add_child(fuse)
		var offset_x = rng.randf_range(-1.5, 1.5)
		var offset_z = rng.randf_range(-6.0, 6.0)
		fuse.position = Vector3(offset_x, 0.5, offset_z)

func _spawn_door(grid_pos: Vector2i, dir: Vector2i) -> void:
	var door = modules["door"].instantiate() as Node3D
	door.name = "Door_%d_%d_%d_%d" % [grid_pos.x, grid_pos.y, dir.x, dir.y]
	add_child(door)
	
	var base_pos = Vector3(grid_pos.x * GRID_SIZE, 0, grid_pos.y * GRID_SIZE)
	if dir == DIR_S:
		door.position = base_pos + Vector3(0, 0, GRID_SIZE / 2.0)
		door.rotation.y = 0.0
	elif dir == DIR_E:
		door.position = base_pos + Vector3(GRID_SIZE / 2.0, 0, 0)
		door.rotation.y = PI / 2.0

	var next_pos = grid_pos + dir
	var room_a = grid_instances.get(grid_pos)
	var room_b = grid_instances.get(next_pos)
	
	if "room_a_name" in door:
		door.room_a_name = room_a.name if room_a else ("Room_%d_%d" % [grid_pos.x, grid_pos.y])
	if "room_b_name" in door:
		door.room_b_name = room_b.name if room_b else ("Room_%d_%d" % [next_pos.x, next_pos.y])
	if "room_a_pos" in door:
		door.room_a_pos = Vector3(grid_pos.x * GRID_SIZE, 0.5, grid_pos.y * GRID_SIZE)
	if "room_b_pos" in door:
		door.room_b_pos = Vector3(next_pos.x * GRID_SIZE, 0.5, next_pos.y * GRID_SIZE)

func _cap_open_sockets(room: Node3D, mask: int) -> void:
	var sockets = room.get_node_or_null("Sockets")
	if not sockets: return
	
	for child in sockets.get_children():
		var socket_dir_local = Vector3.ZERO
		if child.name.ends_with("_N"): socket_dir_local = Vector3(0, 0, -1)
		elif child.name.ends_with("_S"): socket_dir_local = Vector3(0, 0, 1)
		elif child.name.ends_with("_E"): socket_dir_local = Vector3(1, 0, 0)
		elif child.name.ends_with("_W"): socket_dir_local = Vector3(-1, 0, 0)
		
		if socket_dir_local == Vector3.ZERO: continue
		
		var socket_dir_global = room.transform.basis * socket_dir_local
		var global_dir_flag = 0
		if socket_dir_global.z < -0.5: global_dir_flag = FLAG_N
		elif socket_dir_global.z > 0.5: global_dir_flag = FLAG_S
		elif socket_dir_global.x > 0.5: global_dir_flag = FLAG_E
		elif socket_dir_global.x < -0.5: global_dir_flag = FLAG_W
		
		var is_connected = (mask & global_dir_flag) != 0
		if not is_connected:
			var cap = modules["wall_cap"].instantiate()
			room.add_child(cap)
			cap.transform = child.transform
			
			if child.name.ends_with("_E") or child.name.ends_with("_W"):
				cap.rotation.y += PI / 2.0

func _spawn_module(grid_pos: Vector2i, type: String, rot_rad: float, is_exit_elev: bool = false) -> Node3D:
	var instance = modules[type].instantiate() as Node3D
	instance.name = "%s_%d_%d" % [type, grid_pos.x, grid_pos.y]
	if type == "elevator" and "is_exit" in instance:
		instance.is_exit = is_exit_elev
	add_child(instance)
	instance.position = Vector3(grid_pos.x * GRID_SIZE, 0, grid_pos.y * GRID_SIZE)
	instance.rotation.y = rot_rad
	grid_instances[grid_pos] = instance
	return instance

func _clear_level() -> void:
	for child in get_children():
		child.free()
	grid_instances.clear()

func get_room(grid_pos: Vector2i) -> RoomModule:
	return grid_instances.get(grid_pos) as RoomModule
