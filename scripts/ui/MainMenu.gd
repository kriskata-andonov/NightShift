extends Control

var ip_input: LineEdit
var host_btn: Button
var join_btn: Button
var start_btn: Button
var status_label: Label
var players_list: ItemList

func _ready() -> void:
	# Build simple UI programmatically for the Lobby
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -150
	vbox.offset_top = -100
	vbox.offset_right = 150
	vbox.offset_bottom = 200
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "NIGHT SHIFT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	status_label = Label.new()
	status_label.text = "Not Connected"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)
	
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "IP Address (Leave blank for local)"
	vbox.add_child(ip_input)
	
	var class_selector = OptionButton.new()
	class_selector.add_item("Engineer (Fixes fast, electric hum)", 0)
	class_selector.add_item("Athlete (Fast, loud breathing)", 1)
	class_selector.add_item("Hoarder (Big inventory, slow sprint)", 2)
	class_selector.add_item("Freshman (Gets scared easily)", 3)
	class_selector.selected = 1 # Default to Athlete
	class_selector.item_selected.connect(_on_class_selected)
	vbox.add_child(class_selector)
	
	host_btn = Button.new()
	host_btn.text = "Host Server"
	host_btn.pressed.connect(_on_host_pressed)
	vbox.add_child(host_btn)
	
	join_btn = Button.new()
	join_btn.text = "Join Server"
	join_btn.pressed.connect(_on_join_pressed)
	vbox.add_child(join_btn)
	
	players_list = ItemList.new()
	players_list.custom_minimum_size.y = 100
	vbox.add_child(players_list)
	
	start_btn = Button.new()
	start_btn.text = "Start Shift (Host Only)"
	start_btn.pressed.connect(_on_start_pressed)
	start_btn.disabled = true
	vbox.add_child(start_btn)
	
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
