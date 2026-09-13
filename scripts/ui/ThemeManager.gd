class_name ThemeManager
extends RefCounted

const BASE_BG = Color(0.05, 0.05, 0.08, 0.7)
const NEON_BLUE = Color(0.2, 0.8, 1.0)
const NEON_HOVER = Color(0.4, 0.9, 1.0)
const TEXT_COLOR = Color(0.9, 0.9, 0.9)

static func get_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = BASE_BG
	style.set_corner_radius_all(12)
	style.set_border_width_all(2)
	style.border_color = Color(0.1, 0.2, 0.3, 0.5)
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.content_margin_left = 12
	style.content_margin_right = 12
	return style

static func get_list_style() -> StyleBoxFlat:
	var style = get_panel_style()
	style.bg_color = Color(0, 0, 0, 0.4)
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.content_margin_left = 6
	style.content_margin_right = 6
	return style

static func get_btn_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.25, 0.8)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = NEON_BLUE * 0.5
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.content_margin_left = 15
	style.content_margin_right = 15
	return style

static func get_btn_hover_style() -> StyleBoxFlat:
	var style = get_btn_style()
	style.bg_color = Color(0.15, 0.25, 0.4, 0.9)
	style.border_color = NEON_HOVER
	style.shadow_color = NEON_BLUE * 0.5
	style.shadow_size = 8
	return style

static func apply_button_theme(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", get_btn_style())
	btn.add_theme_stylebox_override("hover", get_btn_hover_style())
	btn.add_theme_stylebox_override("pressed", get_btn_style())
	btn.add_theme_stylebox_override("focus", get_btn_hover_style())
	btn.add_theme_color_override("font_color", TEXT_COLOR)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	
	# Global UI Audio Hooks
	if not btn.mouse_entered.is_connected(NetworkManager.play_ui_hover):
		btn.mouse_entered.connect(NetworkManager.play_ui_hover)
	if not btn.pressed.is_connected(NetworkManager.play_ui_click):
		btn.pressed.connect(NetworkManager.play_ui_click)

static func _on_btn_hover(btn: BaseButton) -> void:
	if not btn.disabled: NetworkManager.play_ui_hover()

static func _on_btn_click(btn: BaseButton) -> void:
	if not btn.disabled: NetworkManager.play_ui_click()

static func connect_audio_to_buttons(node: Node) -> void:
	if node is BaseButton:
		if not node.mouse_entered.is_connected(_on_btn_hover.bind(node)):
			node.mouse_entered.connect(_on_btn_hover.bind(node))
		if not node.pressed.is_connected(_on_btn_click.bind(node)):
			node.pressed.connect(_on_btn_click.bind(node))
			
		if node is OptionButton:
			if not node.item_selected.is_connected(NetworkManager.play_ui_click.unbind(1)):
				node.item_selected.connect(NetworkManager.play_ui_click.unbind(1))
				
	elif node is TabContainer or node is TabBar:
		if not node.tab_changed.is_connected(NetworkManager.play_ui_click.unbind(1)):
			node.tab_changed.connect(NetworkManager.play_ui_click.unbind(1))
		if not node.tab_hovered.is_connected(NetworkManager.play_ui_hover.unbind(1)):
			node.tab_hovered.connect(NetworkManager.play_ui_hover.unbind(1))
	
	for child in node.get_children():
		connect_audio_to_buttons(child)
