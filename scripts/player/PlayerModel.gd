extends Node3D
class_name PlayerModel
## Procedurally generates a low-poly stylized character rig based on PlayerClass.
## Uses a data-driven config so all 4 classes share one build function.

var hazmat_mat: StandardMaterial3D = null

## Per-class visual configuration. Each entry defines the body proportions,
## colors, and overall scale that give each class its unique silhouette.
const CLASS_CONFIG = {
	PlayerMovement.PlayerClass.ENGINEER: {
		"color": Color(0.85, 0.5, 0.1), # Orange tint
		"torso_size": Vector3(0.42, 0.9, 0.28),
		"torso_y": 0.15,
		"head_size": Vector3(0.36, 0.35, 0.3),
		"head_y": 0.75,
		"visor_y": 0.8,
		"pack_size": Vector3(0.4, 0.55, 0.2),
		"pack_pos": Vector3(0, 0.2, 0.2),
		"arm_radius": 0.1,
		"arm_height": 0.7,
		"arm_x_offset": 0.31,
		"arm_y": 0.2,
		"arm_angle": 15.0,
		"leg_radius": 0.12,
		"leg_height": 0.9,
		"leg_x_offset": 0.13,
		"scale": Vector3(1.0, 0.92, 1.0), # Slightly shorter
	},
	PlayerMovement.PlayerClass.ATHLETE: {
		"color": Color(0.9, 0.85, 0.3), # Lighter yellow
		"torso_size": Vector3(0.50, 0.85, 0.25),
		"torso_y": 0.15,
		"head_size": Vector3(0.36, 0.35, 0.3),
		"head_y": 0.75,
		"visor_y": 0.8,
		"pack_size": Vector3(0.25, 0.5, 0.15),
		"pack_pos": Vector3(0, 0.25, 0.18),
		"arm_radius": 0.1,
		"arm_height": 0.7,
		"arm_x_offset": 0.35,
		"arm_y": 0.2,
		"arm_angle": 15.0,
		"leg_radius": 0.12,
		"leg_height": 0.9,
		"leg_x_offset": 0.15,
		"scale": Vector3(1.05, 1.1, 1.05), # Taller and broader
	},
	PlayerMovement.PlayerClass.HOARDER: {
		"color": Color(0.6, 0.6, 0.1), # Dingy yellow
		"torso_size": Vector3(0.55, 0.9, 0.4), # Chubby
		"torso_y": 0.15,
		"head_size": Vector3(0.36, 0.35, 0.3),
		"head_y": 0.75,
		"visor_y": 0.8,
		"pack_size": Vector3(0.6, 0.8, 0.45), # Huge backpack
		"pack_pos": Vector3(0, 0.25, 0.4),
		"arm_radius": 0.12,
		"arm_height": 0.7,
		"arm_x_offset": 0.38,
		"arm_y": 0.2,
		"arm_angle": 20.0,
		"leg_radius": 0.14,
		"leg_height": 0.9,
		"leg_x_offset": 0.16,
		"scale": Vector3(1.0, 0.9, 1.0), # Shorter
	},
	PlayerMovement.PlayerClass.FRESHMAN: {
		"color": Color(0.6, 0.8, 0.2), # Greenish
		"torso_size": Vector3(0.28, 0.8, 0.22), # Scrawny
		"torso_y": 0.1,
		"head_size": Vector3(0.36, 0.35, 0.3), # Looks big on scrawny body
		"head_y": 0.65,
		"visor_y": 0.7,
		"pack_size": Vector3(0.2, 0.4, 0.15),
		"pack_pos": Vector3(0, 0.2, 0.18),
		"arm_radius": 0.08,
		"arm_height": 0.65,
		"arm_x_offset": 0.22,
		"arm_y": 0.15,
		"arm_angle": 10.0,
		"leg_radius": 0.1,
		"leg_height": 0.8,
		"leg_x_offset": 0.08,
		"scale": Vector3(0.95, 0.95, 0.95), # Smaller overall
	},
}

## Returns the exact eye level (visor height in player local space) for a given class.
static func get_eye_height(p_class: int) -> float:
	var cfg = CLASS_CONFIG.get(p_class, CLASS_CONFIG[PlayerMovement.PlayerClass.ATHLETE])
	var foot_local_y: float = -0.6 - (cfg.leg_height * 0.5)
	var scaled_foot_y: float = foot_local_y * cfg.scale.y
	var model_y_offset: float = -1.0 - scaled_foot_y
	return cfg.visor_y * cfg.scale.y + model_y_offset

func _ready() -> void:
	var p_class = 1 # Fallback if standalone test
	
	var parent = get_parent()
	if parent and parent is CharacterBody3D:
		if "character_class" in parent:
			p_class = parent.character_class
		var peer_id = parent.name.to_int()
		if NetworkManager and NetworkManager.players.has(peer_id):
			p_class = NetworkManager.players[peer_id].get("class", p_class)
			
	set_class_visuals(p_class)
	
	# Connect to CheatCodeManager if it exists
	var cheat_mgr = _find_cheat_manager()
	if cheat_mgr:
		cheat_mgr.cheat_activated.connect(_on_cheat)

func _find_cheat_manager() -> Node:
	var player = get_parent()
	if player:
		return player.get_node_or_null("CheatCodeManager")
	return null

func _on_cheat(code: String) -> void:
	var parent = get_parent()
	match code:
		"col1":
			if hazmat_mat: hazmat_mat.albedo_color = Color(0.9, 0.85, 0.3) # Yellow
		"col2":
			if hazmat_mat: hazmat_mat.albedo_color = Color(0.3, 0.8, 0.3) # Green
		"col3":
			if hazmat_mat: hazmat_mat.albedo_color = Color(0.2, 0.5, 0.9) # Blue
		"col4":
			if hazmat_mat: hazmat_mat.albedo_color = Color(0.9, 0.2, 0.2) # Red
		"col5":
			if hazmat_mat: hazmat_mat.albedo_color = Color(0.9, 0.2, 0.9) # Magenta
		"cl1":
			if parent and "character_class" in parent:
				parent.character_class = PlayerMovement.PlayerClass.ENGINEER
			set_class_visuals(PlayerMovement.PlayerClass.ENGINEER)
		"cl2":
			if parent and "character_class" in parent:
				parent.character_class = PlayerMovement.PlayerClass.ATHLETE
			set_class_visuals(PlayerMovement.PlayerClass.ATHLETE)
		"cl3":
			if parent and "character_class" in parent:
				parent.character_class = PlayerMovement.PlayerClass.HOARDER
			set_class_visuals(PlayerMovement.PlayerClass.HOARDER)
		"cl4":
			if parent and "character_class" in parent:
				parent.character_class = PlayerMovement.PlayerClass.FRESHMAN
			set_class_visuals(PlayerMovement.PlayerClass.FRESHMAN)

func set_class_visuals(new_class: int) -> void:
	# Clear existing meshes immediately
	for child in get_children():
		if child is MeshInstance3D:
			remove_child(child)
			child.queue_free()
			
	var body_layer := 1
	var parent = get_parent()
	if parent and parent is CharacterBody3D:
		if parent.is_multiplayer_authority():
			body_layer = 2
	
	var config = CLASS_CONFIG.get(new_class, CLASS_CONFIG[PlayerMovement.PlayerClass.ATHLETE])
	_build_character(config, body_layer)

func _build_character(cfg: Dictionary, body_layer: int) -> void:
	# --- Materials ---
	hazmat_mat = StandardMaterial3D.new()
	hazmat_mat.albedo_color = cfg.color
	hazmat_mat.roughness = 0.6
	
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.1, 0.1, 0.12)
	visor_mat.roughness = 0.2
	visor_mat.metallic = 0.8
	
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.2, 0.2, 0.2)
	dark_mat.roughness = 0.8
	
	# --- Torso ---
	var torso := MeshInstance3D.new()
	var t_mesh := BoxMesh.new()
	t_mesh.size = cfg.torso_size
	torso.mesh = t_mesh
	torso.position.y = cfg.torso_y
	torso.material_override = hazmat_mat
	torso.layers = body_layer
	add_child(torso)
	
	# --- Head ---
	var head := MeshInstance3D.new()
	var h_mesh := BoxMesh.new()
	h_mesh.size = cfg.head_size
	head.mesh = h_mesh
	head.position.y = cfg.head_y
	head.material_override = hazmat_mat
	head.layers = body_layer
	add_child(head)
	
	# --- Visor ---
	var visor := MeshInstance3D.new()
	var v_mesh := BoxMesh.new()
	v_mesh.size = Vector3(0.29, 0.12, 0.05)
	visor.mesh = v_mesh
	visor.position = Vector3(0, cfg.visor_y, -0.16)
	visor.material_override = visor_mat
	visor.layers = body_layer
	add_child(visor)
	
	# --- Backpack / Oxygen Tank ---
	var pack := MeshInstance3D.new()
	var p_mesh := BoxMesh.new()
	p_mesh.size = cfg.pack_size
	pack.mesh = p_mesh
	pack.position = cfg.pack_pos
	pack.material_override = dark_mat
	pack.layers = body_layer
	add_child(pack)

	# --- Arms ---
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var a_mesh := CapsuleMesh.new()
		a_mesh.radius = cfg.arm_radius
		a_mesh.height = cfg.arm_height
		arm.mesh = a_mesh
		arm.position = Vector3(side * cfg.arm_x_offset, cfg.arm_y, 0)
		arm.rotation_degrees.z = side * cfg.arm_angle
		arm.material_override = hazmat_mat
		arm.layers = body_layer
		add_child(arm)
	
	# --- Legs ---
	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var l_mesh := CapsuleMesh.new()
		l_mesh.radius = cfg.leg_radius
		l_mesh.height = cfg.leg_height
		leg.mesh = l_mesh
		leg.position = Vector3(side * cfg.leg_x_offset, -0.6, 0)
		leg.material_override = hazmat_mat
		leg.layers = body_layer
		add_child(leg)
	
	# --- Class-specific scale and ground alignment ---
	self.scale = cfg.scale
	var foot_local_y: float = -0.6 - (cfg.leg_height * 0.5)
	var scaled_foot_y: float = foot_local_y * cfg.scale.y
	self.position.y = -1.0 - scaled_foot_y
