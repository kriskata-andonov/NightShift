extends Node3D
class_name PlayerModel
## Procedurally generates a low-poly stylized character rig based on PlayerClass.

var hazmat_mat: StandardMaterial3D = null
var cheat_buffer: String = ""

func _ready() -> void:
	# Default to Layer 1 (visible to everyone)
	var p_class = 1 # ATHLETE by default for Dummy testing
	
	if get_parent() and get_parent() is CharacterBody3D:
		if "character_class" in get_parent():
			p_class = get_parent().character_class
			
	set_class_visuals(p_class)

func set_class_visuals(new_class: int) -> void:
	# Clear existing meshes if rebuilding
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	var body_layer := 1
	var parent = get_parent()
	if parent and parent is CharacterBody3D:
		if parent.is_multiplayer_authority():
			body_layer = 2
		
	if new_class == 1: # ATHLETE
		_build_athlete(body_layer)
	elif new_class == 0: # ENGINEER
		_build_engineer(body_layer)
	elif new_class == 2: # HOARDER
		_build_hoarder(body_layer)
	elif new_class == 3: # FRESHMAN
		_build_freshman(body_layer)

func _build_athlete(body_layer: int) -> void:
	# Base Hazmat Material (Slightly lighter yellow for Athlete)
	hazmat_mat = StandardMaterial3D.new()
	hazmat_mat.albedo_color = Color(0.9, 0.85, 0.3)
	hazmat_mat.roughness = 0.6
	
	# Dark Visor Material
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.1, 0.1, 0.12)
	visor_mat.roughness = 0.2
	visor_mat.metallic = 0.8
	
	# Darker Material for boots/gloves/pack
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.2, 0.2, 0.2)
	dark_mat.roughness = 0.8
	
	# --- BODY PARTS ---
	
	# Torso (Box)
	var torso := MeshInstance3D.new()
	var t_mesh := BoxMesh.new()
	t_mesh.size = Vector3(0.50, 0.85, 0.25)
	torso.mesh = t_mesh
	torso.position.y = 0.15
	torso.material_override = hazmat_mat
	torso.layers = body_layer
	add_child(torso)
	
	# Head (Box)
	var head := MeshInstance3D.new()
	var h_mesh := BoxMesh.new()
	h_mesh.size = Vector3(0.36, 0.35, 0.3)
	head.mesh = h_mesh
	head.position.y = 0.75
	head.material_override = hazmat_mat
	head.layers = body_layer
	add_child(head)
	
	# Visor (Front of head)
	var visor := MeshInstance3D.new()
	var v_mesh := BoxMesh.new()
	v_mesh.size = Vector3(0.29, 0.12, 0.05)
	visor.mesh = v_mesh
	visor.position = Vector3(0, 0.8, -0.16)
	visor.material_override = visor_mat
	visor.layers = body_layer
	add_child(visor)
	
	# Oxygen Tank / Backpack
	var pack := MeshInstance3D.new()
	var p_mesh := BoxMesh.new()
	p_mesh.size = Vector3(0.25, 0.5, 0.15)
	pack.mesh = p_mesh
	# Move higher up the back (but not too high)
	pack.position = Vector3(0, 0.25, 0.18)
	pack.material_override = dark_mat
	pack.layers = body_layer
	add_child(pack)

	# Left Arm (Capsule)
	var arm_l := MeshInstance3D.new()
	var al_mesh := CapsuleMesh.new()
	al_mesh.radius = 0.1
	al_mesh.height = 0.7
	arm_l.mesh = al_mesh
	arm_l.position = Vector3(-0.35, 0.2, 0)
	arm_l.rotation_degrees.z = -15.0
	arm_l.material_override = hazmat_mat
	arm_l.layers = body_layer
	add_child(arm_l)

	# Right Arm (Capsule)
	var arm_r := MeshInstance3D.new()
	var ar_mesh := CapsuleMesh.new()
	ar_mesh.radius = 0.1
	ar_mesh.height = 0.7
	arm_r.mesh = ar_mesh
	arm_r.position = Vector3(0.35, 0.2, 0)
	arm_r.rotation_degrees.z = 15.0
	arm_r.material_override = hazmat_mat
	arm_r.layers = body_layer
	add_child(arm_r)
	
	# Left Leg (Capsule)
	var leg_l := MeshInstance3D.new()
	var ll_mesh := CapsuleMesh.new()
	ll_mesh.radius = 0.12
	ll_mesh.height = 0.9
	leg_l.mesh = ll_mesh
	leg_l.position = Vector3(-0.15, -0.6, 0)
	leg_l.material_override = hazmat_mat
	leg_l.layers = body_layer
	add_child(leg_l)

	# Right Leg (Capsule)
	var leg_r := MeshInstance3D.new()
	var lr_mesh := CapsuleMesh.new()
	lr_mesh.radius = 0.12
	lr_mesh.height = 0.9
	leg_r.mesh = lr_mesh
	leg_r.position = Vector3(0.15, -0.6, 0)
	leg_r.material_override = hazmat_mat
	leg_r.layers = body_layer
	add_child(leg_r)
	
	# Slightly taller and broader overall
	self.scale = Vector3(1.05, 1.1, 1.05)

func _unhandled_input(event: InputEvent) -> void:
	var parent = get_parent()
	if parent and parent is CharacterBody3D and not parent.is_multiplayer_authority():
		return
		
	if not event is InputEventKey or not event.pressed:
		return
	
	if event.unicode != 0:
		cheat_buffer += char(event.unicode).to_lower()
		
		# Keep buffer size manageable
		if cheat_buffer.length() > 20:
			cheat_buffer = cheat_buffer.substr(cheat_buffer.length() - 20)
			
		if not hazmat_mat:
			return
			
		if cheat_buffer.ends_with("col1"):
			hazmat_mat.albedo_color = Color(0.9, 0.85, 0.3) # Yellow
			cheat_buffer = ""
		elif cheat_buffer.ends_with("col2"):
			hazmat_mat.albedo_color = Color(0.3, 0.8, 0.3) # Green
			cheat_buffer = ""
		elif cheat_buffer.ends_with("col3"):
			hazmat_mat.albedo_color = Color(0.2, 0.5, 0.9) # Blue
			cheat_buffer = ""
		elif cheat_buffer.ends_with("col4"):
			hazmat_mat.albedo_color = Color(0.9, 0.2, 0.2) # Red
			cheat_buffer = ""
		elif cheat_buffer.ends_with("col5"):
			hazmat_mat.albedo_color = Color(0.9, 0.2, 0.9) # Magenta
			cheat_buffer = ""
		elif cheat_buffer.ends_with("cl1"):
			if parent and "character_class" in parent: parent.character_class = 0
			set_class_visuals(0) # Engineer
			cheat_buffer = ""
		elif cheat_buffer.ends_with("cl2"):
			if parent and "character_class" in parent: parent.character_class = 1
			set_class_visuals(1) # Athlete
			cheat_buffer = ""
		elif cheat_buffer.ends_with("cl3"):
			if parent and "character_class" in parent: parent.character_class = 2
			set_class_visuals(2) # Hoarder
			cheat_buffer = ""
		elif cheat_buffer.ends_with("cl4"):
			if parent and "character_class" in parent: parent.character_class = 3
			set_class_visuals(3) # Freshman
			cheat_buffer = ""

func _build_engineer(body_layer: int) -> void:
	hazmat_mat = StandardMaterial3D.new()
	hazmat_mat.albedo_color = Color(0.85, 0.5, 0.1) # Orange tint
	hazmat_mat.roughness = 0.6
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.1, 0.1, 0.12)
	visor_mat.roughness = 0.2; visor_mat.metallic = 0.8
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.2, 0.2, 0.2)
	dark_mat.roughness = 0.8
	# Torso
	var torso := MeshInstance3D.new(); var t_mesh := BoxMesh.new(); t_mesh.size = Vector3(0.42, 0.9, 0.28)
	torso.mesh = t_mesh; torso.position.y = 0.15; torso.material_override = hazmat_mat; torso.layers = body_layer; add_child(torso)
	# Head
	var head := MeshInstance3D.new(); var h_mesh := BoxMesh.new(); h_mesh.size = Vector3(0.36, 0.35, 0.3)
	head.mesh = h_mesh; head.position.y = 0.75; head.material_override = hazmat_mat; head.layers = body_layer; add_child(head)
	# Visor
	var visor := MeshInstance3D.new(); var v_mesh := BoxMesh.new(); v_mesh.size = Vector3(0.29, 0.12, 0.05)
	visor.mesh = v_mesh; visor.position = Vector3(0, 0.8, -0.16); visor.material_override = visor_mat; visor.layers = body_layer; add_child(visor)
	# Pack (Tools shape)
	var pack := MeshInstance3D.new(); var p_mesh := BoxMesh.new(); p_mesh.size = Vector3(0.4, 0.55, 0.2)
	pack.mesh = p_mesh; pack.position = Vector3(0, 0.2, 0.2); pack.material_override = dark_mat; pack.layers = body_layer; add_child(pack)
	# Arms
	var arm_l := MeshInstance3D.new(); var al_mesh := CapsuleMesh.new(); al_mesh.radius = 0.1; al_mesh.height = 0.7
	arm_l.mesh = al_mesh; arm_l.position = Vector3(-0.31, 0.2, 0); arm_l.rotation_degrees.z = -15.0; arm_l.material_override = hazmat_mat; arm_l.layers = body_layer; add_child(arm_l)
	var arm_r := MeshInstance3D.new(); var ar_mesh := CapsuleMesh.new(); ar_mesh.radius = 0.1; ar_mesh.height = 0.7
	arm_r.mesh = ar_mesh; arm_r.position = Vector3(0.31, 0.2, 0); arm_r.rotation_degrees.z = 15.0; arm_r.material_override = hazmat_mat; arm_r.layers = body_layer; add_child(arm_r)
	# Legs
	var leg_l := MeshInstance3D.new(); var ll_mesh := CapsuleMesh.new(); ll_mesh.radius = 0.12; ll_mesh.height = 0.9
	leg_l.mesh = ll_mesh; leg_l.position = Vector3(-0.13, -0.6, 0); leg_l.material_override = hazmat_mat; leg_l.layers = body_layer; add_child(leg_l)
	var leg_r := MeshInstance3D.new(); var lr_mesh := CapsuleMesh.new(); lr_mesh.radius = 0.12; lr_mesh.height = 0.9
	leg_r.mesh = lr_mesh; leg_r.position = Vector3(0.13, -0.6, 0); leg_r.material_override = hazmat_mat; leg_r.layers = body_layer; add_child(leg_r)
	
	# Slightly shorter engineer
	self.scale = Vector3(1.0, 0.92, 1.0)

func _build_hoarder(body_layer: int) -> void:
	hazmat_mat = StandardMaterial3D.new()
	hazmat_mat.albedo_color = Color(0.6, 0.6, 0.1) # Dingy yellow
	hazmat_mat.roughness = 0.6
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.1, 0.1, 0.12)
	visor_mat.roughness = 0.2; visor_mat.metallic = 0.8
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.2, 0.2, 0.2)
	dark_mat.roughness = 0.8
	# Torso (Chubby)
	var torso := MeshInstance3D.new(); var t_mesh := BoxMesh.new(); t_mesh.size = Vector3(0.55, 0.9, 0.4)
	torso.mesh = t_mesh; torso.position.y = 0.15; torso.material_override = hazmat_mat; torso.layers = body_layer; add_child(torso)
	# Head
	var head := MeshInstance3D.new(); var h_mesh := BoxMesh.new(); h_mesh.size = Vector3(0.36, 0.35, 0.3)
	head.mesh = h_mesh; head.position.y = 0.75; head.material_override = hazmat_mat; head.layers = body_layer; add_child(head)
	# Visor
	var visor := MeshInstance3D.new(); var v_mesh := BoxMesh.new(); v_mesh.size = Vector3(0.29, 0.12, 0.05)
	visor.mesh = v_mesh; visor.position = Vector3(0, 0.8, -0.16); visor.material_override = visor_mat; visor.layers = body_layer; add_child(visor)
	# Huge Pack
	var pack := MeshInstance3D.new(); var p_mesh := BoxMesh.new(); p_mesh.size = Vector3(0.6, 0.8, 0.45)
	pack.mesh = p_mesh; pack.position = Vector3(0, 0.25, 0.4); pack.material_override = dark_mat; pack.layers = body_layer; add_child(pack)
	# Arms
	var arm_l := MeshInstance3D.new(); var al_mesh := CapsuleMesh.new(); al_mesh.radius = 0.12; al_mesh.height = 0.7
	arm_l.mesh = al_mesh; arm_l.position = Vector3(-0.38, 0.2, 0); arm_l.rotation_degrees.z = -20.0; arm_l.material_override = hazmat_mat; arm_l.layers = body_layer; add_child(arm_l)
	var arm_r := MeshInstance3D.new(); var ar_mesh := CapsuleMesh.new(); ar_mesh.radius = 0.12; ar_mesh.height = 0.7
	arm_r.mesh = ar_mesh; arm_r.position = Vector3(0.38, 0.2, 0); arm_r.rotation_degrees.z = 20.0; arm_r.material_override = hazmat_mat; arm_r.layers = body_layer; add_child(arm_r)
	# Legs
	var leg_l := MeshInstance3D.new(); var ll_mesh := CapsuleMesh.new(); ll_mesh.radius = 0.14; ll_mesh.height = 0.9
	leg_l.mesh = ll_mesh; leg_l.position = Vector3(-0.16, -0.6, 0); leg_l.material_override = hazmat_mat; leg_l.layers = body_layer; add_child(leg_l)
	var leg_r := MeshInstance3D.new(); var lr_mesh := CapsuleMesh.new(); lr_mesh.radius = 0.14; lr_mesh.height = 0.9
	leg_r.mesh = lr_mesh; leg_r.position = Vector3(0.16, -0.6, 0); leg_r.material_override = hazmat_mat; leg_r.layers = body_layer; add_child(leg_r)
	
	# Shorter height
	self.scale = Vector3(1.0, 0.9, 1.0)

func _build_freshman(body_layer: int) -> void:
	hazmat_mat = StandardMaterial3D.new()
	hazmat_mat.albedo_color = Color(0.6, 0.8, 0.2) # Greenish
	hazmat_mat.roughness = 0.6
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.1, 0.1, 0.12)
	visor_mat.roughness = 0.2; visor_mat.metallic = 0.8
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.2, 0.2, 0.2)
	dark_mat.roughness = 0.8
	# Torso (Scrawny)
	var torso := MeshInstance3D.new(); var t_mesh := BoxMesh.new(); t_mesh.size = Vector3(0.28, 0.8, 0.22)
	torso.mesh = t_mesh; torso.position.y = 0.1; torso.material_override = hazmat_mat; torso.layers = body_layer; add_child(torso)
	# Head (Looks big)
	var head := MeshInstance3D.new(); var h_mesh := BoxMesh.new(); h_mesh.size = Vector3(0.36, 0.35, 0.3)
	head.mesh = h_mesh; head.position.y = 0.65; head.material_override = hazmat_mat; head.layers = body_layer; add_child(head)
	# Visor
	var visor := MeshInstance3D.new(); var v_mesh := BoxMesh.new(); v_mesh.size = Vector3(0.29, 0.12, 0.05)
	visor.mesh = v_mesh; visor.position = Vector3(0, 0.7, -0.16); visor.material_override = visor_mat; visor.layers = body_layer; add_child(visor)
	# Pack
	var pack := MeshInstance3D.new(); var p_mesh := BoxMesh.new(); p_mesh.size = Vector3(0.2, 0.4, 0.15)
	pack.mesh = p_mesh; pack.position = Vector3(0, 0.2, 0.18); pack.material_override = dark_mat; pack.layers = body_layer; add_child(pack)
	# Arms
	var arm_l := MeshInstance3D.new(); var al_mesh := CapsuleMesh.new(); al_mesh.radius = 0.08; al_mesh.height = 0.65
	arm_l.mesh = al_mesh; arm_l.position = Vector3(-0.22, 0.15, 0); arm_l.rotation_degrees.z = -10.0; arm_l.material_override = hazmat_mat; arm_l.layers = body_layer; add_child(arm_l)
	var arm_r := MeshInstance3D.new(); var ar_mesh := CapsuleMesh.new(); ar_mesh.radius = 0.08; ar_mesh.height = 0.65
	arm_r.mesh = ar_mesh; arm_r.position = Vector3(0.22, 0.15, 0); arm_r.rotation_degrees.z = 10.0; arm_r.material_override = hazmat_mat; arm_r.layers = body_layer; add_child(arm_r)
	# Legs
	var leg_l := MeshInstance3D.new(); var ll_mesh := CapsuleMesh.new(); ll_mesh.radius = 0.1; ll_mesh.height = 0.8
	leg_l.mesh = ll_mesh; leg_l.position = Vector3(-0.08, -0.6, 0); leg_l.material_override = hazmat_mat; leg_l.layers = body_layer; add_child(leg_l)
	var leg_r := MeshInstance3D.new(); var lr_mesh := CapsuleMesh.new(); lr_mesh.radius = 0.1; lr_mesh.height = 0.8
	leg_r.mesh = lr_mesh; leg_r.position = Vector3(0.08, -0.6, 0); leg_r.material_override = hazmat_mat; leg_r.layers = body_layer; add_child(leg_r)
	
	# Slightly shorter height and skinnier
	self.scale = Vector3(0.95, 0.95, 0.95)
