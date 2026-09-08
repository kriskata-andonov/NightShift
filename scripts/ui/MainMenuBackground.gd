extends Node3D

var _time: float = 0.0
var players: Array[Node3D] = []
var segments: Array[Node3D] = []
var doors: Array[Node3D] = []

const SPEED: float = 4.0
const SEGMENT_LENGTH: float = 10.0
const SEGMENT_COUNT: int = 8

func _ready() -> void:
	# 1. Setup Camera and Environment
	var cam = Camera3D.new()
	cam.position = Vector3(0, 2.5, 4.0)
	cam.fov = 70.0
	add_child(cam)
	
	var env = WorldEnvironment.new()
	var res = Environment.new()
	res.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.02, 0.02, 0.05)
	sky_mat.sky_horizon_color = Color(0.05, 0.05, 0.15)
	sky_mat.ground_bottom_color = Color(0.02, 0.02, 0.05)
	sky_mat.ground_horizon_color = Color(0.05, 0.05, 0.15)
	sky.sky_material = sky_mat
	res.sky = sky
	res.fog_enabled = true
	res.fog_density = 0.01
	res.fog_light_color = Color(0.05, 0.05, 0.15)
	env.environment = res
	add_child(env)
	
	var dir_light = DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-45, 120, 0) # Angled to show as the moon
	dir_light.light_color = Color(0.8, 0.9, 1.0)
	dir_light.light_energy = 2.0
	add_child(dir_light)
	
	# Stars Particle System
	var stars = GPUParticles3D.new()
	var p_mat = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(100, 50, 100)
	p_mat.gravity = Vector3(0, 0, 0)
	stars.process_material = p_mat
	stars.amount = 1000
	stars.lifetime = 100.0
	stars.preprocess = 100.0
	var s_mesh = QuadMesh.new()
	s_mesh.size = Vector2(0.2, 0.2)
	var s_mat = StandardMaterial3D.new()
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.albedo_color = Color(1.0, 1.0, 1.0)
	s_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	s_mesh.material = s_mat
	stars.draw_pass_1 = s_mesh
	stars.position = Vector3(0, 50, 0)
	add_child(stars)
	
	# 2. Spawn 4 Player Classes side-by-side
	var player_model_scene = load("res://scripts/player/PlayerModel.gd")
	var spacing = 1.5
	var start_x = -((4 - 1) * spacing) / 2.0
	
	for i in range(4):
		var p = Node3D.new()
		p.set_script(player_model_scene)
		p.position = Vector3(start_x + (i * spacing), 1.05, 0)
		add_child(p)
		
		# Set class visuals
		if p.has_method("set_class_visuals"):
			p.set_class_visuals(i) # 0=Engineer, 1=Athlete, 2=Hoarder, 3=Freshman
		
		# Give each player a dim point light to simulate flashlight
		var plight = OmniLight3D.new()
		plight.position = Vector3(0, 1.5, -0.5)
		plight.light_color = Color(1.0, 0.9, 0.7)
		plight.light_energy = 1.5
		plight.distance_fade_enabled = true
		plight.distance_fade_length = 10.0
		p.add_child(plight)
		
		players.append(p)
	
	# 3. Setup Treadmill Segments
	var door_scene = load("res://scenes/props/Door.tscn")
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.15, 0.15, 0.15)
	
	var wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.1, 0.1, 0.1)
	
	for i in range(SEGMENT_COUNT):
		var segment = Node3D.new()
		var z_pos = - (i * SEGMENT_LENGTH)
		segment.position = Vector3(0, 0, z_pos)
		
		# Floor
		var floor_csg = CSGBox3D.new()
		floor_csg.size = Vector3(12.0, 0.2, SEGMENT_LENGTH)
		floor_csg.position = Vector3(0, -0.1, -SEGMENT_LENGTH/2.0)
		floor_csg.material = floor_material
		segment.add_child(floor_csg)
		

		
		# Add doors for the players to walk through
		if door_scene:
			for p_idx in range(4):
				var door = door_scene.instantiate()
				# Align with each player's X position
				var door_x = start_x + (p_idx * spacing)
				door.position = Vector3(door_x - 0.6, 0, -SEGMENT_LENGTH/2.0) # offset by -0.6 because Door hinge is offset
				door.rotation_degrees = Vector3(0, 0, 0) # Doors start closed!
				if door.get_script():
					door.set_script(null)
				segment.add_child(door)
				doors.append(door)
				
		# Street Lamps
		var lamp_scene = load("res://scenes/props/StreetLamp.tscn")
		if lamp_scene:
			# Left Lamp
			var l_lamp = lamp_scene.instantiate()
			l_lamp.position = Vector3(-4.5, 0, -SEGMENT_LENGTH * 0.25)
			segment.add_child(l_lamp)
			
			# Right Lamp (rotate 180 so the light overhangs the hallway)
			var r_lamp = lamp_scene.instantiate()
			r_lamp.position = Vector3(4.5, 0, -SEGMENT_LENGTH * 0.25)
			r_lamp.rotation_degrees = Vector3(0, 180, 0)
			segment.add_child(r_lamp)
		
		add_child(segment)
		segments.append(segment)

func _process(delta: float) -> void:
	_time += delta
	
	# Move segments towards the camera
	for segment in segments:
		segment.position.z += SPEED * delta
		
		# If segment goes far behind the camera, wrap it to the back
		# Wrap at 20.0 so its lights (range 15) no longer affect the player (at Z=0)
		if segment.position.z > SEGMENT_LENGTH * 2.0:
			segment.position.z -= SEGMENT_LENGTH * SEGMENT_COUNT
	
	# Bob players to simulate walking
	for i in range(players.size()):
		var p = players[i]
		var phase = _time * SPEED * 1.5 + (i * 0.5)
		p.position.y = 1.05 + abs(sin(phase)) * 0.15
		
	# Dynamically open doors as they approach the players (players are at Z = 0)
	for door in doors:
		var global_z = door.get_parent().position.z + door.position.z
		# Start opening at Z = -1.5, fully open at Z = -0.2
		if global_z < -1.5:
			door.rotation_degrees.y = 0
		elif global_z > -0.2:
			door.rotation_degrees.y = 90
		else:
			# Calculate progress between -1.5 and -0.2 (range of 1.3)
			var progress = (global_z - (-1.5)) / 1.3
			door.rotation_degrees.y = 90 * progress
