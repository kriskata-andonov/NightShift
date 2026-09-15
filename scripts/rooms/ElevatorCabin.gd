class_name ElevatorCabin
extends RoomModule

@export var is_exit: bool = false

@onready var gate_left: Node3D = $GateLeft
@onready var gate_right: Node3D = $GateRight
@onready var button_outside: Interactable = get_node_or_null("ButtonPanel_Outside/Button_Outside")
@onready var button_portal: Interactable = get_node_or_null("ButtonPanel_Portal/Button_Portal")
@onready var panel_inside: Node3D = get_node_or_null("ButtonPanel_Inside")
@onready var button_inside: Interactable = get_node_or_null("ButtonPanel_Inside/Button_Inside")
@onready var inside_panel_light: OmniLight3D = get_node_or_null("ButtonPanel_Inside/InsidePanelLight")
@onready var inside_label: Label3D = get_node_or_null("ButtonPanel_Inside/InsideLabel")

@onready var header_label: Label3D = $Geometry/DoorFrame/HeaderBox/HeaderLabel
@onready var status_label: Label3D = $Geometry/DoorFrame/HeaderBox/StatusLabel
@onready var inside_header_label: Label3D = get_node_or_null("Geometry/DoorFrame/InsideHeaderBox/InsideHeaderLabel")
@onready var inside_status_label: Label3D = get_node_or_null("Geometry/DoorFrame/InsideHeaderBox/InsideStatusLabel")
@onready var status_light: OmniLight3D = $Geometry/DoorFrame/HeaderBox/StatusLight
@onready var status_mesh: CSGSphere3D = $Geometry/DoorFrame/HeaderBox/StatusMesh

@onready var tunnel_label: Label3D = $Geometry/TunnelEntrance/TunnelSign/TunnelLabel
@onready var tunnel_light: OmniLight3D = $Geometry/TunnelEntrance/TunnelSign/TunnelSignLight

var is_open: bool = false

func _get_level_state() -> Node:
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree and tree.root:
		return tree.root.get_node_or_null("LevelState")
	return null

func _ready() -> void:
	_init_visual_nodes()
	var state = _get_level_state()
	if state:
		if state.has_signal("power_changed"):
			state.power_changed.connect(_on_power_changed)
		if state.has_signal("power_restored"):
			state.power_restored.connect(func(): _on_power_changed(true))
	if button_outside and not button_outside.interacted.is_connected(_on_button_outside_pressed):
		button_outside.interacted.connect(_on_button_outside_pressed)
	if button_portal and not button_portal.interacted.is_connected(_on_button_outside_pressed):
		button_portal.interacted.connect(_on_button_outside_pressed)
	if button_inside and not button_inside.interacted.is_connected(_on_button_inside_pressed):
		button_inside.interacted.connect(_on_button_inside_pressed)
	_update_visuals()

func setup_elevator_type(exit_type: bool) -> void:
	is_exit = exit_type
	_update_visuals()

func _on_power_changed(powered: bool) -> void:
	_update_visuals(powered)

func _init_visual_nodes() -> void:
	if not panel_inside:
		panel_inside = get_node_or_null("ButtonPanel_Inside")
	if not button_outside:
		button_outside = get_node_or_null("ButtonPanel_Outside/Button_Outside")
	if not button_portal:
		button_portal = get_node_or_null("ButtonPanel_Portal/Button_Portal")
	if not button_inside:
		button_inside = get_node_or_null("ButtonPanel_Inside/Button_Inside")
	if not inside_panel_light:
		inside_panel_light = get_node_or_null("ButtonPanel_Inside/InsidePanelLight")
	if not inside_label:
		inside_label = get_node_or_null("ButtonPanel_Inside/InsideLabel")
	if not header_label:
		header_label = get_node_or_null("Geometry/DoorFrame/HeaderBox/HeaderLabel")
	if not status_label:
		status_label = get_node_or_null("Geometry/DoorFrame/HeaderBox/StatusLabel")
	if not inside_header_label:
		inside_header_label = get_node_or_null("Geometry/DoorFrame/InsideHeaderBox/InsideHeaderLabel")
	if not inside_status_label:
		inside_status_label = get_node_or_null("Geometry/DoorFrame/InsideHeaderBox/InsideStatusLabel")
	if not status_light:
		status_light = get_node_or_null("Geometry/DoorFrame/HeaderBox/StatusLight")
	if not status_mesh:
		status_mesh = get_node_or_null("Geometry/DoorFrame/HeaderBox/StatusMesh")
	if not tunnel_label:
		tunnel_label = get_node_or_null("Geometry/TunnelEntrance/TunnelSign/TunnelLabel")
	if not tunnel_light:
		tunnel_light = get_node_or_null("Geometry/TunnelEntrance/TunnelSign/TunnelSignLight")

func _set_status_mesh_emission(col: Color, energy: float) -> void:
	if not status_mesh: return
	var mat = status_mesh.material as StandardMaterial3D
	if not mat or mat.resource_path != "": # if shared or unassigned, duplicate/instantiate
		mat = (mat.duplicate() as StandardMaterial3D) if mat else StandardMaterial3D.new()
		status_mesh.material = mat
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy

func _set_button_emission(btn_node: Node, col: Color, energy: float) -> void:
	if not btn_node: return
	var parent = btn_node.get_parent()
	if not parent: return
	var mesh: Node3D = parent.get_node_or_null("ButtonMesh")
	if not mesh:
		mesh = parent.get_node_or_null("PortalButtonMesh")
	if not mesh:
		mesh = parent.get_node_or_null("InsideButtonMesh")
	if mesh:
		var mat: StandardMaterial3D = null
		if mesh is MeshInstance3D:
			mat = mesh.material_override as StandardMaterial3D
			if not mat:
				mat = mesh.get_active_material(0) as StandardMaterial3D
			if not mat or mat.resource_path != "":
				mat = (mat.duplicate() as StandardMaterial3D) if mat else StandardMaterial3D.new()
				mesh.material_override = mat
		elif "material" in mesh:
			mat = mesh.material as StandardMaterial3D
			if not mat or mat.resource_path != "":
				mat = (mat.duplicate() as StandardMaterial3D) if mat else StandardMaterial3D.new()
				mesh.material = mat
		if mat:
			mat.albedo_color = col
			mat.emission_enabled = true
			mat.emission = col
			mat.emission_energy_multiplier = energy

func _update_visuals(force_power: Variant = null) -> void:
	_init_visual_nodes()
	var state = _get_level_state()
	var power_on: bool = false
	if force_power != null:
		power_on = bool(force_power)
	elif state:
		power_on = state.is_power_on
	else:
		power_on = false
	
	# The evacuation button panel is removed/hidden for the hub/start elevator, and kept ONLY for the evacuation elevator
	if panel_inside:
		panel_inside.visible = is_exit
		if button_inside:
			button_inside.collision_layer = 5 if is_exit else 0
			var col = button_inside.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if col:
				col.disabled = !is_exit
	
	if is_exit:
		_update_exit_visuals(power_on)
	else:
		_update_entrance_visuals()

	_sync_inside_headers()

func _update_exit_visuals(power_on: bool) -> void:
	# --- EXIT / EXTRACTION ELEVATOR ---
	if tunnel_label:
		tunnel_label.text = "▼ EXTRACTION ELEVATOR SHAFT ▼"
		tunnel_label.modulate = Color(1.0, 0.65, 0.1)
	if tunnel_light:
		tunnel_light.light_color = Color(1.0, 0.65, 0.1)
		tunnel_light.light_energy = 1.8
		
	if header_label:
		header_label.text = "▼ EVACUATION LIFT - SECTOR EXIT ▼"
		header_label.modulate = Color(1.0, 0.65, 0.1)
		
	if power_on:
		_update_exit_powered()
	else:
		_update_exit_unpowered()

func _update_exit_powered() -> void:
	if status_label:
		status_label.text = "[ READY - POWER RESTORED ]"
		status_label.modulate = Color(0.2, 1.0, 0.4)
	if status_light:
		status_light.light_color = Color(0.2, 1.0, 0.4)
		status_light.light_energy = 2.0
	_set_status_mesh_emission(Color(0.2, 1.0, 0.4), 2.0)
			
	if inside_panel_light:
		inside_panel_light.light_color = Color(0.2, 1.0, 0.4)
		inside_panel_light.light_energy = 0.8
	if inside_label:
		inside_label.modulate = Color(0.2, 1.0, 0.4)
		inside_label.text = "EVACUATE"

	var prompt = "Close Elevator Gates" if is_open else "Open Elevator Gates"
	if button_outside:
		button_outside.prompt_text = prompt
	if button_portal:
		button_portal.prompt_text = prompt
	if button_inside:
		button_inside.prompt_text = "Activate Evacuation Lift"
	_set_button_emission(button_outside, Color(0.2, 1.0, 0.4), 2.0)
	_set_button_emission(button_portal, Color(0.2, 1.0, 0.4), 2.0)
	_set_button_emission(button_inside, Color(0.2, 1.0, 0.4), 2.0)

func _update_exit_unpowered() -> void:
	if status_label:
		status_label.text = "[ OFFLINE - RESTORE POWER AT GENERATOR ]"
		status_label.modulate = Color(1.0, 0.2, 0.2)
	if status_light:
		status_light.light_color = Color(1.0, 0.1, 0.1)
		status_light.light_energy = 1.2
	_set_status_mesh_emission(Color(1.0, 0.1, 0.1), 1.2)
	if inside_panel_light:
		inside_panel_light.light_color = Color(1.0, 0.1, 0.1)
		inside_panel_light.light_energy = 0.4
	if inside_label:
		inside_label.modulate = Color(1.0, 0.2, 0.2)
		inside_label.text = "NO POWER"

	if button_outside:
		button_outside.prompt_text = "Call Elevator (No Power)"
	if button_portal:
		button_portal.prompt_text = "Call Elevator (No Power)"
	if button_inside:
		button_inside.prompt_text = "Elevator Offline (No Power)"
	_set_button_emission(button_outside, Color(1.0, 0.1, 0.1), 1.0)
	_set_button_emission(button_portal, Color(1.0, 0.1, 0.1), 1.0)
	_set_button_emission(button_inside, Color(1.0, 0.1, 0.1), 1.0)

func _update_entrance_visuals() -> void:
	# --- ENTRANCE / SURFACE ACCESS HUB ---
	if tunnel_label:
		tunnel_label.text = "▲ SURFACE ACCESS SHAFT ▲"
		tunnel_label.modulate = Color(0.2, 1.0, 0.6)
	if tunnel_light:
		tunnel_light.light_color = Color(0.2, 1.0, 0.6)
		tunnel_light.light_energy = 1.8
		
	if header_label:
		header_label.text = "▲ LEVEL 01 - SURFACE ENTRY HUB ▲"
		header_label.modulate = Color(0.2, 1.0, 0.6)
		
	if status_label:
		status_label.text = "[ SURFACE ACCESS LIFT - ACTIVE ]"
		status_label.modulate = Color(0.2, 1.0, 0.6)
	if status_light:
		status_light.light_color = Color(0.2, 1.0, 0.6)
		status_light.light_energy = 1.5
	_set_status_mesh_emission(Color(0.2, 1.0, 0.6), 1.5)
		
	var prompt = "Close Elevator Gates" if is_open else "Open Elevator Gates"
	if button_outside:
		button_outside.prompt_text = prompt
	if button_portal:
		button_portal.prompt_text = prompt
	_set_button_emission(button_outside, Color(0.2, 1.0, 0.6), 1.5)
	_set_button_emission(button_portal, Color(0.2, 1.0, 0.6), 1.5)

func _sync_inside_headers() -> void:
	if inside_header_label and header_label:
		inside_header_label.text = header_label.text
		inside_header_label.modulate = header_label.modulate
	if inside_status_label and status_label:
		inside_status_label.text = status_label.text
		inside_status_label.modulate = status_label.modulate

func _on_button_outside_pressed(player: Node3D) -> void:
	if player and player.has_method("set_last_room"):
		var title = "Exit Elevator Shaft" if is_exit else "Surface Entry Shaft"
		var safe_pos = global_position + Vector3(0, 0.5, 0)
		player.set_last_room(title, safe_pos)

	var state = _get_level_state()
	if is_exit and state and not state.is_power_on:
		print("Elevator has no power! Restore generator first.")
		if player and player.has_method("show_toast"):
			player.show_toast("[ NO POWER: Restore Generator at Start ]", 3.0)
		return

	if is_open:
		if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
			rpc("close_gates")
		else:
			close_gates()
	else:
		if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
			rpc("open_gates")
		else:
			open_gates()

func _on_button_inside_pressed(player: Node3D) -> void:
	if not is_exit:
		return

	var state = _get_level_state()
	if is_exit and state and not state.is_power_on:
		if player and player.has_method("show_toast"):
			player.show_toast("[ NO POWER: Restore Generator at Start ]", 3.0)
		return

	print("Elevator inside evacuation button pressed!")
	if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
		rpc("close_gates")
	else:
		close_gates()

	if is_exit:
		if player and player.has_method("show_toast"):
			player.show_toast("[ EVACUATION INITIATED - FACILITY SECURED! ]", 5.0)

@rpc("any_peer", "call_local")
func open_gates() -> void:
	if is_open:
		return
	is_open = true
	_update_visuals()
	print("Elevator gates opening!")
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if gate_left:
		tween.tween_property(gate_left, "position:x", -2.15, 2.2)
	if gate_right:
		tween.tween_property(gate_right, "position:x", 2.15, 2.2)

@rpc("any_peer", "call_local")
func close_gates() -> void:
	if not is_open:
		return
	is_open = false
	_update_visuals()
	print("Elevator gates closing!")
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if gate_left:
		tween.tween_property(gate_left, "position:x", -0.75, 2.2)
	if gate_right:
		tween.tween_property(gate_right, "position:x", 0.75, 2.2)
