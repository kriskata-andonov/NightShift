extends Control

var ip_input: LineEdit
var host_btn: Button
var join_btn: Button
var leave_btn: Button
var start_btn: Button
var status_label: Label
var players_list: ItemList
var margin_root: MarginContainer

# Settings UI
var settings_panel: CenterContainer
var device_option: OptionButton
var hear_myself_check: CheckBox
var mic_boost_slider: HSlider
var mic_volume_bar: ProgressBar
var mic_capture_effect: AudioEffectCapture
var mic_current_volume: float = 0.0

func _ready() -> void:
	# Add 3D Background
	var bg_scene = load("res://scenes/ui/MainMenuBackground.tscn")
	if bg_scene:
		var bg = bg_scene.instantiate()
		add_child(bg)
		
	# --- Premium Styling ---
	var style_panel = ThemeManager.get_panel_style()
	var style_list = ThemeManager.get_list_style()
	var style_btn = ThemeManager.get_btn_style()
	var style_hover = ThemeManager.get_btn_hover_style()
	var text_color = ThemeManager.TEXT_COLOR
	
	# Pressed Button Style
	var style_pressed = style_btn.duplicate()
	style_pressed.bg_color = ThemeManager.NEON_BLUE * 0.3
	style_pressed.border_color = ThemeManager.NEON_BLUE
	
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
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", ThemeManager.NEON_HOVER)
	title.add_theme_color_override("font_shadow_color", ThemeManager.NEON_BLUE * 0.5)
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
	
	leave_btn = Button.new()
	leave_btn.text = "Leave"
	leave_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leave_btn.add_theme_font_size_override("font_size", 14)
	leave_btn.pressed.connect(_on_leave_pressed)
	leave_btn.hide()
	hbox_btns.add_child(leave_btn)
	
	start_btn = Button.new()
	start_btn.text = "START SHIFT"
	start_btn.disabled = true
	start_btn.add_theme_font_size_override("font_size", 24)
	start_btn.add_theme_color_override("font_color", ThemeManager.NEON_HOVER)
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
	lobby_title.text = "CONNECTED PLAYERS"
	lobby_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby_title.add_theme_font_size_override("font_size", 20)
	lobby_title.add_theme_color_override("font_color", ThemeManager.NEON_HOVER)
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

	_setup_settings_ui()
	
	ThemeManager.connect_audio_to_buttons(self)

func _on_host_pressed() -> void:
	if NetworkManager.host_game() == OK:
		status_label.text = "Hosting..."
		host_btn.hide()
		join_btn.hide()
		leave_btn.show()
		ip_input.editable = false
		start_btn.disabled = false

func _on_join_pressed() -> void:
	if NetworkManager.join_game(ip_input.text) == OK:
		status_label.text = "Joining..."
		host_btn.hide()
		join_btn.hide()
		leave_btn.show()
		ip_input.editable = false

func _on_leave_pressed() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	NetworkManager.players.clear()
	_on_players_updated()
	status_label.text = "NOT CONNECTED"
	host_btn.show()
	host_btn.disabled = false
	join_btn.show()
	join_btn.disabled = false
	leave_btn.hide()
	ip_input.editable = true
	start_btn.disabled = true

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
	NetworkManager.update_player_class(index)

func _setup_settings_ui() -> void:
	# Top Right Settings Button
	var top_right_margin = MarginContainer.new()
	top_right_margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	top_right_margin.add_theme_constant_override("margin_top", 20)
	top_right_margin.add_theme_constant_override("margin_right", 20)
	add_child(top_right_margin)
	
	var btn_settings = Button.new()
	btn_settings.text = "⚙"
	btn_settings.custom_minimum_size = Vector2(40, 40)
	btn_settings.add_theme_font_size_override("font_size", 32)
	btn_settings.flat = true
	btn_settings.add_theme_color_override("font_color", ThemeManager.TEXT_COLOR)
	btn_settings.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	btn_settings.add_theme_constant_override("outline_size", 2)
	
	btn_settings.pivot_offset = Vector2(20, 20)
	btn_settings.mouse_entered.connect(func():
		btn_settings.add_theme_color_override("font_color", ThemeManager.NEON_HOVER)
		btn_settings.add_theme_color_override("font_outline_color", ThemeManager.NEON_BLUE * 0.8)
		var t = create_tween()
		t.tween_property(btn_settings, "rotation", deg_to_rad(90), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn_settings.mouse_exited.connect(func():
		btn_settings.add_theme_color_override("font_color", ThemeManager.TEXT_COLOR)
		btn_settings.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
		var t = create_tween()
		t.tween_property(btn_settings, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	
	var empty_style = StyleBoxEmpty.new()
	btn_settings.add_theme_stylebox_override("focus", empty_style)
	btn_settings.add_theme_stylebox_override("hover", empty_style)
	btn_settings.add_theme_stylebox_override("pressed", empty_style)
	btn_settings.add_theme_stylebox_override("normal", empty_style)
	
	btn_settings.pressed.connect(_on_settings_pressed)
	top_right_margin.add_child(btn_settings)

	# Settings Panel
	settings_panel = CenterContainer.new()
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_panel.hide()
	add_child(settings_panel)
	
	var actual_panel = PanelContainer.new()
	actual_panel.custom_minimum_size = Vector2(400, 300)
	var style_panel = ThemeManager.get_panel_style()
	actual_panel.add_theme_stylebox_override("panel", style_panel)
	settings_panel.add_child(actual_panel)
	
	var settings_vbox = VBoxContainer.new()
	settings_vbox.add_theme_constant_override("separation", 15)
	actual_panel.add_child(settings_vbox)
	
	var settings_title = Label.new()
	settings_title.text = "SETTINGS"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_font_size_override("font_size", 24)
	settings_vbox.add_child(settings_title)
	
	settings_vbox.add_child(HSeparator.new())
	
	var tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_vbox.add_child(tab_container)
	
	var general_tab = VBoxContainer.new()
	general_tab.name = "General"
	general_tab.add_theme_constant_override("separation", 10)
	tab_container.add_child(general_tab)
	
	var general_label = Label.new()
	general_label.text = "Player Name:"
	general_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	general_tab.add_child(general_label)
	
	var name_input = LineEdit.new()
	name_input.text = NetworkManager.player_info.name
	name_input.max_length = 20
	name_input.text_changed.connect(_on_player_name_changed)
	general_tab.add_child(name_input)
	
	var audio_tab = VBoxContainer.new()
	audio_tab.name = "Audio"
	audio_tab.add_theme_constant_override("separation", 10)
	tab_container.add_child(audio_tab)
	
	var lbl_device = Label.new()
	lbl_device.text = "Audio Device:"
	lbl_device.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	audio_tab.add_child(lbl_device)
	
	device_option = OptionButton.new()
	device_option.item_selected.connect(_on_device_selected)
	audio_tab.add_child(device_option)
	
	hear_myself_check = CheckBox.new()
	hear_myself_check.text = "Hear Myself (Debug)"
	hear_myself_check.toggled.connect(_on_hear_myself_toggled)
	audio_tab.add_child(hear_myself_check)
	
	var lbl_boost = Label.new()
	lbl_boost.text = "Mic Boost:"
	lbl_boost.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	audio_tab.add_child(lbl_boost)
	
	mic_boost_slider = HSlider.new()
	mic_boost_slider.min_value = 1.0
	mic_boost_slider.max_value = 10.0
	mic_boost_slider.step = 0.5
	mic_boost_slider.value_changed.connect(_on_mic_boost_changed)
	audio_tab.add_child(mic_boost_slider)
	
	var lbl_activity = Label.new()
	lbl_activity.text = "Mic Activity:"
	lbl_activity.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	audio_tab.add_child(lbl_activity)
	
	mic_volume_bar = ProgressBar.new()
	mic_volume_bar.max_value = 1.0
	mic_volume_bar.show_percentage = false
	audio_tab.add_child(mic_volume_bar)
	
	var btn_back = Button.new()
	btn_back.text = "Back"
	btn_back.pressed.connect(_on_settings_back_pressed)
	ThemeManager.apply_button_theme(btn_back)
	settings_vbox.add_child(btn_back)
	
	# Temporary mic capture for the volume bar
	var mic_player = AudioStreamPlayer.new()
	mic_player.stream = AudioStreamMicrophone.new()
	mic_player.bus = "Record"
	mic_player.autoplay = true
	add_child(mic_player)
	
	var record_bus_idx = AudioServer.get_bus_index("Record")
	if record_bus_idx >= 0:
		for i in range(AudioServer.get_bus_effect_count(record_bus_idx)):
			if AudioServer.get_bus_effect(record_bus_idx, i) is AudioEffectCapture:
				mic_capture_effect = AudioServer.get_bus_effect(record_bus_idx, i)
				break

func _on_settings_pressed() -> void:
	margin_root.hide()
	settings_panel.show()
	
	device_option.clear()
	var devices = AudioServer.get_input_device_list()
	for i in range(devices.size()):
		device_option.add_item(devices[i], i)
		if devices[i] == AudioServer.input_device:
			device_option.select(i)
			
	hear_myself_check.button_pressed = NetworkManager.hear_myself
	mic_boost_slider.value = NetworkManager.mic_boost

func _on_settings_back_pressed() -> void:
	settings_panel.hide()
	margin_root.show()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_panel.visible:
			_on_settings_back_pressed()
			get_viewport().set_input_as_handled()
		elif leave_btn.visible:
			_on_leave_pressed()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if settings_panel.visible and mic_capture_effect:
		var frames = mic_capture_effect.get_frames_available()
		if frames > 0:
			var buffer = mic_capture_effect.get_buffer(frames)
			var peak = 0.0
			for i in range(buffer.size()):
				buffer[i] *= NetworkManager.mic_boost
				var p = max(abs(buffer[i].x), abs(buffer[i].y))
				if p > peak:
					peak = p
			mic_current_volume = lerp(mic_current_volume, peak, 0.5)
		else:
			mic_current_volume = lerp(mic_current_volume, 0.0, 0.2)
			
		mic_volume_bar.value = mic_current_volume

func _on_device_selected(index: int) -> void:
	var devices = AudioServer.get_input_device_list()
	if index >= 0 and index < devices.size():
		AudioServer.input_device = devices[index]

func _on_hear_myself_toggled(toggled_on: bool) -> void:
	NetworkManager.hear_myself = toggled_on

func _on_mic_boost_changed(value: float) -> void:
	NetworkManager.mic_boost = value

func _on_player_name_changed(new_text: String) -> void:
	new_text = new_text.strip_edges()
	if new_text.is_empty():
		new_text = "Player"
	NetworkManager.update_player_name(new_text)
