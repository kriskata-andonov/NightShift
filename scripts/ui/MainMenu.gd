extends Control

var ip_input: LineEdit
var host_btn: Button
var join_btn: Button
var start_btn: Button
var status_label: Label
var players_list: ItemList
var margin_root: MarginContainer

func _ready() -> void:
	# Add 3D Background
	var bg_scene = load("res://scenes/ui/MainMenuBackground.tscn")
	if bg_scene:
		var bg = bg_scene.instantiate()
		add_child(bg)
		
	# --- Premium Styling ---
	var base_bg = Color(0.05, 0.05, 0.08, 0.7) # Dark glassy background
	var neon_blue = Color(0.2, 0.8, 1.0)
	var neon_hover = Color(0.4, 0.9, 1.0)
	var text_color = Color(0.9, 0.9, 0.9)
	
	# Base Panel Style
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = base_bg
	style_panel.set_corner_radius_all(12)
	style_panel.set_border_width_all(2)
	style_panel.border_color = Color(0.1, 0.2, 0.3, 0.5)
	style_panel.content_margin_top = 12
	style_panel.content_margin_bottom = 12
	style_panel.content_margin_left = 12
	style_panel.content_margin_right = 12
	
	# Item List Style
	var style_list = style_panel.duplicate()
	style_list.bg_color = Color(0, 0, 0, 0.4)
	style_list.content_margin_top = 6
	style_list.content_margin_bottom = 6
	style_list.content_margin_left = 6
	style_list.content_margin_right = 6
	
	# Normal Button Style
	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0.1, 0.15, 0.25, 0.8)
	style_btn.set_corner_radius_all(8)
	style_btn.set_border_width_all(2)
	style_btn.border_color = neon_blue * 0.5
	style_btn.content_margin_top = 8
	style_btn.content_margin_bottom = 8
	style_btn.content_margin_left = 15
	style_btn.content_margin_right = 15
	
	# Hover Button Style (Glowing)
	var style_hover = style_btn.duplicate()
	style_hover.bg_color = Color(0.15, 0.25, 0.4, 0.9)
	style_hover.border_color = neon_hover
	style_hover.shadow_color = neon_blue * 0.5
	style_hover.shadow_size = 8
	
	# Pressed Button Style
	var style_pressed = style_btn.duplicate()
	style_pressed.bg_color = neon_blue * 0.3
	style_pressed.border_color = neon_blue
	
	# Input Style
	var style_input = style_btn.duplicate()
	style_input.bg_color = Color(0.05, 0.05, 0.1, 0.8)
	style_input.border_color = Color(0.2, 0.3, 0.4)
	
	var theme = Theme.new()
	theme.set_stylebox("normal", "Button", style_btn)
	theme.set_stylebox("hover", "Button", style_hover)
	theme.set_stylebox("pressed", "Button", style_pressed)
	theme.set_stylebox("disabled", "Button", style_panel)
	theme.set_stylebox("normal", "LineEdit", style_input)
	theme.set_stylebox("focus", "LineEdit", style_hover)
	theme.set_stylebox("normal", "OptionButton", style_btn)
	theme.set_stylebox("hover", "OptionButton", style_hover)
	theme.set_stylebox("pressed", "OptionButton", style_pressed)
	theme.set_stylebox("panel", "PanelContainer", style_panel)
	theme.set_stylebox("panel", "ItemList", style_list)
	theme.set_color("font_color", "Label", text_color)
	theme.set_color("font_color", "Button", text_color)
	
	# --- Main Layout ---
	margin_root = MarginContainer.new()
	margin_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_root.add_theme_constant_override("margin_left", 20)
	margin_root.add_theme_constant_override("margin_right", 20)
	margin_root.add_theme_constant_override("margin_top", 40)
	margin_root.add_theme_constant_override("margin_bottom", 40)
	margin_root.theme = theme
	add_child(margin_root)
	
	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 15)
	margin_root.add_child(root_vbox)
	
	# Title (Top Center)
	var title = Label.new()
	title.text = "NIGHT SHIFT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", neon_hover)
	title.add_theme_color_override("font_shadow_color", neon_blue * 0.5)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.add_theme_constant_override("shadow_outline_size", 4)
	root_vbox.add_child(title)
	
	# HBox for Left (Controls) and Right (Players)
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(main_hbox)
	
	# --- LEFT COLUMN (Actions) ---
	var left_margin = MarginContainer.new()
	left_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(left_margin)
	
	var controls_vbox = VBoxContainer.new()
	controls_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	controls_vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	controls_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	controls_vbox.custom_minimum_size.x = 220
	controls_vbox.add_theme_constant_override("separation", 10)
	left_margin.add_child(controls_vbox)
	
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "IP Address (Leave blank)"
	ip_input.add_theme_font_size_override("font_size", 12)
	controls_vbox.add_child(ip_input)
	
	var class_selector = OptionButton.new()
	class_selector.add_item("Engineer", 0)
	class_selector.add_item("Athlete", 1)
	class_selector.add_item("Hoarder", 2)
	class_selector.add_item("Freshman", 3)
	class_selector.selected = 1
	class_selector.item_selected.connect(_on_class_selected)
	class_selector.add_theme_font_size_override("font_size", 12)
	controls_vbox.add_child(class_selector)
	
	var hbox_btns = HBoxContainer.new()
	hbox_btns.add_theme_constant_override("separation", 10)
	controls_vbox.add_child(hbox_btns)
	
	host_btn = Button.new()
	host_btn.text = "Host"
	host_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_btn.add_theme_font_size_override("font_size", 14)
	host_btn.pressed.connect(_on_host_pressed)
	hbox_btns.add_child(host_btn)
	
	join_btn = Button.new()
	join_btn.text = "Join"
	join_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_btn.add_theme_font_size_override("font_size", 14)
	join_btn.pressed.connect(_on_join_pressed)
	hbox_btns.add_child(join_btn)
	
	start_btn = Button.new()
	start_btn.text = "START SHIFT"
	start_btn.disabled = true
	start_btn.add_theme_font_size_override("font_size", 16)
	start_btn.add_theme_color_override("font_color", neon_hover)
	start_btn.pressed.connect(_on_start_pressed)
	controls_vbox.add_child(start_btn)
	
	# --- RIGHT COLUMN (Lobby) ---
	var right_margin = MarginContainer.new()
	right_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_margin)
	
	var lobby_panel = PanelContainer.new()
	lobby_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	lobby_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lobby_panel.custom_minimum_size.x = 220
	lobby_panel.custom_minimum_size.y = 200
	right_margin.add_child(lobby_panel)
	
	var lobby_vbox = VBoxContainer.new()
	lobby_vbox.add_theme_constant_override("separation", 8)
	lobby_panel.add_child(lobby_vbox)
	
	var lobby_title = Label.new()
	lobby_title.text = "CREW LOBBY"
	lobby_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby_title.add_theme_font_size_override("font_size", 16)
	lobby_title.add_theme_color_override("font_color", neon_hover)
	lobby_title.add_theme_constant_override("shadow_offset_y", 2)
	lobby_vbox.add_child(lobby_title)
	
	players_list = ItemList.new()
	players_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	players_list.add_theme_font_size_override("font_size", 12)
	lobby_vbox.add_child(players_list)
	
	status_label = Label.new()
	status_label.text = "NOT CONNECTED"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	lobby_vbox.add_child(status_label)
	
	NetworkManager.players_updated.connect(_on_players_updated)

func _on_host_pressed() -> void:
	if NetworkManager.host_game() == OK:
		status_label.text = "Hosting..."
		host_btn.disabled = true
		join_btn.disabled = true
		ip_input.editable = false
		start_btn.disabled = false

func _on_join_pressed() -> void:
	if NetworkManager.join_game(ip_input.text) == OK:
		status_label.text = "Joining..."
		host_btn.disabled = true
		join_btn.disabled = true
		ip_input.editable = false

func _on_players_updated() -> void:
	players_list.clear()
	for peer_id in NetworkManager.players:
		var info = NetworkManager.players[peer_id]
		players_list.add_item(info.name + " (Class: " + str(info.class) + ")")
		
	if multiplayer.is_server():
		status_label.text = "Hosting - " + str(NetworkManager.players.size()) + " Players"
	else:
		status_label.text = "Connected - " + str(NetworkManager.players.size()) + " Players"



func _on_start_pressed() -> void:
	if multiplayer.is_server():
		NetworkManager.start_game.rpc()

func _on_class_selected(index: int) -> void:
	var class_id = index
	NetworkManager.player_info.class = class_id
