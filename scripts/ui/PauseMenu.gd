extends CanvasLayer

@onready var main_panel: PanelContainer = $CenterContainer/MainPanel
@onready var settings_panel: PanelContainer = $CenterContainer/SettingsPanel
@onready var general_tab: Control = $CenterContainer/SettingsPanel/VBox/TabContainer/General

@onready var btn_resume: Button = $CenterContainer/MainPanel/VBox/BtnResume
@onready var btn_restart: Button = $CenterContainer/MainPanel/VBox/BtnRestart
@onready var btn_settings: Button = $CenterContainer/MainPanel/VBox/BtnSettings
@onready var btn_exit: Button = $CenterContainer/MainPanel/VBox/BtnExit
@onready var btn_settings_back: Button = $CenterContainer/SettingsPanel/VBox/BtnBack
@onready var device_option: OptionButton = $CenterContainer/SettingsPanel/VBox/TabContainer/Audio/DeviceOption
@onready var hear_myself_check: CheckBox = $CenterContainer/SettingsPanel/VBox/TabContainer/Audio/HearMyselfCheck
@onready var mic_boost_slider: HSlider = $CenterContainer/SettingsPanel/VBox/TabContainer/Audio/MicBoostSlider
@onready var mic_volume_bar: ProgressBar = $CenterContainer/SettingsPanel/VBox/TabContainer/Audio/MicVolumeBar

var is_open: bool = false

func _ready() -> void:
	# Hide menu initially
	hide()
	
	# Connect buttons
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	btn_settings_back.pressed.connect(_on_settings_back_pressed)
	device_option.item_selected.connect(_on_device_selected)
	hear_myself_check.toggled.connect(_on_hear_myself_toggled)
	mic_boost_slider.value_changed.connect(_on_mic_boost_changed)
	
	# Styling
	var style_panel = ThemeManager.get_panel_style()
	main_panel.add_theme_stylebox_override("panel", style_panel)
	settings_panel.add_theme_stylebox_override("panel", style_panel)
	
	ThemeManager.apply_button_theme(btn_resume)
	ThemeManager.apply_button_theme(btn_restart)
	ThemeManager.apply_button_theme(btn_settings)
	ThemeManager.apply_button_theme(btn_exit)
	ThemeManager.apply_button_theme(btn_settings_back)
	
	# Determine if player is host
	if multiplayer.is_server():
		btn_restart.text = "Restart Level"
	else:
		btn_restart.text = "Vote Restart"
		
	_setup_general_tab()
	ThemeManager.connect_audio_to_buttons(self)

func _setup_general_tab() -> void:
	for child in general_tab.get_children():
		child.queue_free()
		
	var general_vbox = VBoxContainer.new()
	general_vbox.add_theme_constant_override("separation", 10)
	general_tab.add_child(general_vbox)
	
	var general_label = Label.new()
	general_label.text = "Player Name (Cannot change during shift):"
	general_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	general_vbox.add_child(general_label)
	
	var name_input = LineEdit.new()
	name_input.text = NetworkManager.player_info.name
	name_input.editable = false
	general_vbox.add_child(name_input)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# If the settings panel is open, pressing Esc just goes back to the main pause menu
		if settings_panel.visible:
			_on_settings_back_pressed()
			get_viewport().set_input_as_handled()
		else:
			toggle_menu()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if is_open and settings_panel.visible:
		var voice = _get_local_player_voice()
		if voice and "current_volume" in voice:
			mic_volume_bar.value = voice.current_volume

func toggle_menu() -> void:
	is_open = !is_open
	visible = is_open
	
	if is_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		settings_panel.hide()
		main_panel.show()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_pressed() -> void:
	toggle_menu()

func _on_settings_pressed() -> void:
	main_panel.hide()
	settings_panel.show()
	_populate_audio_devices()
	
	hear_myself_check.button_pressed = NetworkManager.hear_myself
	mic_boost_slider.value = NetworkManager.mic_boost
	
	# Try to apply local voice volume instantly if we have one
	var voice = _get_local_player_voice()
	if voice:
		hear_myself_check.button_pressed = voice.hear_myself
		if "mic_boost" in voice:
			mic_boost_slider.value = voice.mic_boost

func _on_settings_back_pressed() -> void:
	settings_panel.hide()
	main_panel.show()

func _on_exit_pressed() -> void:
	# Disconnect and return to main menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	NetworkManager.leave_game()

func _on_restart_pressed() -> void:
	if multiplayer.is_server():
		# Host clicked restart
		NetworkManager.restart_game.rpc()
	else:
		# Client clicked restart vote
		NetworkManager.vote_restart.rpc_id(1)
		btn_restart.text = "Voted!"
		btn_restart.disabled = true

func _populate_audio_devices() -> void:
	device_option.clear()
	var devices = AudioServer.get_input_device_list()
	for i in range(devices.size()):
		device_option.add_item(devices[i], i)
		if devices[i] == AudioServer.input_device:
			device_option.select(i)

func _on_device_selected(index: int) -> void:
	var devices = AudioServer.get_input_device_list()
	if index >= 0 and index < devices.size():
		AudioServer.input_device = devices[index]

func _on_hear_myself_toggled(toggled_on: bool) -> void:
	NetworkManager.hear_myself = toggled_on
	var voice = _get_local_player_voice()
	if voice:
		voice.hear_myself = toggled_on

func _on_mic_boost_changed(value: float) -> void:
	NetworkManager.mic_boost = value
	var voice = _get_local_player_voice()
	if voice:
		voice.mic_boost = value

func _get_local_player_voice() -> Node:
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.is_multiplayer_authority():
			return p.get_node_or_null("PlayerVoice")
	return null
