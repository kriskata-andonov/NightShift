extends SceneTree

func _init() -> void:
	var root = Node3D.new()
	root.name = "LabFacility"
	root.set_script(load("res://scripts/maps/LabFacility.gd"))
	
	# Multiplayer Spawner
	var spawner = MultiplayerSpawner.new()
	spawner.name = "PlayerSpawner"
	spawner.spawn_path = NodePath("..")
	root.add_child(spawner)
	spawner.owner = root
	
	# Environment
	var env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.05, 0.05, 0.05)
	env_node.environment = env
	root.add_child(env_node)
	env_node.owner = root
	
	# Navigation Region
	var nav_region = NavigationRegion3D.new()
	nav_region.name = "NavigationRegion"
	var nav_mesh = NavigationMesh.new()
	nav_mesh.agent_radius = 0.6
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_region.navigation_mesh = nav_mesh
	root.add_child(nav_region)
	nav_region.owner = root

	# Base Map CSG Combiner
	var map = CSGCombiner3D.new()
	map.name = "MapGeometry"
	map.use_collision = true
	nav_region.add_child(map)
	map.owner = root
	
	# Standard Material for concrete
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.3)
	
	# Room 1 (Spawn / Observation)
	var room1 = CSGBox3D.new()
	room1.name = "ObservationRoom"
	room1.size = Vector3(10, 4, 10)
	room1.position = Vector3(0, 2, 0)
	room1.material = mat
	# Hollow it out
	var room1_inner = CSGBox3D.new()
	room1_inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	room1_inner.size = Vector3(9.5, 3.8, 9.5)
	room1.add_child(room1_inner)
	map.add_child(room1)
	room1_inner.owner = root # Need to set owner for packed scene
	room1.owner = root
	
	# Light for Room 1
	var light1 = OmniLight3D.new()
	light1.name = "ObsLight"
	light1.position = Vector3(0, 3.5, 0)
	light1.omni_range = 8.0
	light1.light_energy = 1.5
	room1.add_child(light1)
	light1.owner = root
	
	# Corridor 1
	var corridor1 = CSGBox3D.new()
	corridor1.name = "Corridor1"
	corridor1.size = Vector3(4, 4, 20)
	corridor1.position = Vector3(0, 2, -15)
	corridor1.material = mat
	var c1_inner = CSGBox3D.new()
	c1_inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	c1_inner.size = Vector3(3.5, 3.8, 19.5) # Leaves 0.25 wall on both ends
	corridor1.add_child(c1_inner)
	map.add_child(corridor1)
	c1_inner.owner = root
	corridor1.owner = root
	
	# Corridor 2 (Turns right)
	var corridor2 = CSGBox3D.new()
	corridor2.name = "Corridor2"
	corridor2.size = Vector3(18, 4, 4)
	corridor2.position = Vector3(11, 2, -23) # Spans x=2 to x=20
	corridor2.material = mat
	var c2_inner = CSGBox3D.new()
	c2_inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	c2_inner.size = Vector3(17.5, 3.8, 3.5) # Leaves 0.25 wall on both ends
	corridor2.add_child(c2_inner)
	map.add_child(corridor2)
	c2_inner.owner = root
	corridor2.owner = root
	
	# Door Hole 1 (to connect Room 1 and Corridor 1 at z=-5)
	var door_hole = CSGBox3D.new()
	door_hole.name = "DoorHole1"
	door_hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	door_hole.size = Vector3(2.0, 3.4, 2)
	door_hole.position = Vector3(0, 1.8, -5) # Centered perfectly at x=0
	map.add_child(door_hole)
	door_hole.owner = root
	
	# Door Hole 2 (to connect Corridor 1 and Corridor 2 at x=2, z=-23)
	var door_hole2 = CSGBox3D.new()
	door_hole2.name = "DoorHole2"
	door_hole2.operation = CSGShape3D.OPERATION_SUBTRACTION
	door_hole2.size = Vector3(2, 3.4, 2.0)
	door_hole2.position = Vector3(2, 1.8, -23) # Punches through the wall at x=2
	map.add_child(door_hole2)
	door_hole2.owner = root
	
	# A table in Room 1
	var table = CSGBox3D.new()
	table.name = "Table"
	table.size = Vector3(2, 1, 1)
	table.position = Vector3(3, 0.5, 3)
	map.add_child(table)
	table.owner = root
	
	var door_scene = load("res://scenes/props/Door.tscn")
	
	# Instantiate Door 1 at the Room 1 threshold
	var door1 = door_scene.instantiate()
	door1.name = "Door1"
	door1.position = Vector3(-0.9, 0.1, -5) # Offset by half its scaled width to center it
	door1.scale = Vector3(1.5, 1.5, 1.5)
	root.add_child(door1)
	door1.owner = root
	
	# Instantiate Door 2 at the Corridor 2 threshold
	var door2 = door_scene.instantiate()
	door2.name = "Door2"
	door2.position = Vector3(2, 0.1, -22.1) # Positioned at x=2, z=-22.1.
	door2.rotation_degrees = Vector3(0, 90, 0) # Rotate 90 degrees to face down the corridor
	door2.scale = Vector3(1.5, 1.5, 1.5)
	root.add_child(door2)
	door2.owner = root
	
	# Instantiate The Watcher at the end of Corridor 2
	var watcher_scene = load("res://scenes/entities/Watcher.tscn")
	var watcher = watcher_scene.instantiate()
	watcher.name = "Watcher"
	watcher.position = Vector3(18, 1.5, -23) # Deep in Corridor 2
	root.add_child(watcher)
	watcher.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/maps/LabFacility.tscn")
	print("Saved LabFacility.tscn!")
	quit()
