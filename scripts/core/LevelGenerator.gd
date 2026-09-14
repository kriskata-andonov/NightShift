class_name LevelGenerator
extends Node3D

const GRID_SIZE = 32.0

var seed_val: int = 0
var floor_num: int = 1
var rng: RandomNumberGenerator

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
	
	var grid_layout = {}
	
	# Start Elevator at (0,0), opens North
	grid_layout[Vector2i(0,0)] = FLAG_N
	var current = Vector2i(0, -1)
	grid_layout[current] = FLAG_S
	
	var target_len = 5 + floor_num * 2
	var end_pos = _random_walk(grid_layout, current, target_len)
	
	# Add branches
	var all_cells = grid_layout.keys().duplicate()
	for cell in all_cells:
		if cell != Vector2i(0,0) and cell != end_pos:
			if rng.randf() < 0.4:
				_random_walk(grid_layout, cell, rng.randi_range(1, 3))
				
	_spawn_layout(grid_layout, end_pos)
	print("Level generation complete.")

func _random_walk(layout: Dictionary, start: Vector2i, steps: int) -> Vector2i:
	var current = start
	for i in range(steps):
		var allowed = []
		for d in [DIR_N, DIR_E, DIR_W, DIR_S]:
			# Biased towards North
			if d == DIR_N:
				allowed.append(d)
				allowed.append(d)
			if not layout.has(current + d):
				allowed.append(d)
				
		if allowed.is_empty():
			break
			
		var dir = allowed[rng.randi() % allowed.size()]
		var next_cell = current + dir
		if layout.has(next_cell):
			break # Hit existing path, just connect and stop branch
			
		if not layout.has(current): layout[current] = 0
		layout[current] |= _dir_to_flag(dir)
		layout[next_cell] = _dir_to_flag(_opposite_dir(dir))
		current = next_cell
	return current

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
			if mask & FLAG_N: rot = PI
			elif mask & FLAG_S: rot = 0.0
			elif mask & FLAG_E: rot = PI/2
			elif mask & FLAG_W: rot = -PI/2
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
			_spawn_module(pos, type, rot)
			
	# After all spawned, place caps on open sockets
	for pos in grid_instances.keys():
		var room = grid_instances[pos]
		var mask = layout[pos]
		if pos != Vector2i(0,0) and pos != end_pos:
			_cap_open_sockets(room, mask)
			
	# Spawn interactive doors at chunk boundaries
	for pos in layout.keys():
		var mask = layout[pos]
		
		if (mask & FLAG_S):
			if rng.randf() < 0.6: # 60% chance for a door
				_spawn_door(pos, DIR_S)
				
		if (mask & FLAG_E):
			if rng.randf() < 0.6:
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
			
	var fuses_to_place = 8
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
		fuse.position = Vector3(rng.randf_range(-4, 4), 0.5, rng.randf_range(-4, 4))

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
		
		var socket_dir_global = room.global_transform.basis * socket_dir_local
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

func _spawn_module(grid_pos: Vector2i, type: String, rot_rad: float) -> void:
	var instance = modules[type].instantiate() as Node3D
	instance.name = "%s_%d_%d" % [type, grid_pos.x, grid_pos.y]
	add_child(instance)
	instance.position = Vector3(grid_pos.x * GRID_SIZE, 0, grid_pos.y * GRID_SIZE)
	instance.rotation.y = rot_rad
	grid_instances[grid_pos] = instance

func _clear_level() -> void:
	for child in get_children():
		child.queue_free()
	grid_instances.clear()

func get_room(grid_pos: Vector2i) -> RoomModule:
	return grid_instances.get(grid_pos) as RoomModule
