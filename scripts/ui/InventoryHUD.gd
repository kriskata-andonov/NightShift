extends Label
class_name InventoryHUD
## Minimal inventory display — shows slot contents at the bottom-left of the screen.
## Updates when PlayerInventory emits inventory_changed.

var inventory: PlayerInventory = null

func _ready() -> void:
	# Style and position
	horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	
	anchors_preset = Control.PRESET_BOTTOM_LEFT
	anchor_top = 1.0
	anchor_bottom = 1.0
	anchor_left = 0.0
	anchor_right = 0.0
	offset_top = -100.0
	offset_bottom = -10.0
	offset_left = 10.0
	offset_right = 400.0
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.9))
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	
	# Find the PlayerInventory node
	_find_inventory()
	_update_display()

func _find_inventory() -> void:
	# Walk up to find the Player root, then get PlayerInventory
	var current: Node = get_parent()
	while current:
		if current is CharacterBody3D:
			inventory = current.get_node_or_null("PlayerInventory") as PlayerInventory
			if inventory:
				inventory.inventory_changed.connect(_update_display)
				inventory.item_used.connect(_on_item_used)
			return
		current = current.get_parent()

func _update_display() -> void:
	if not inventory:
		text = ""
		return
	
	var lines: PackedStringArray = PackedStringArray()
	for i in range(inventory.max_slots):
		var item = null
		if i < inventory.items.size():
			item = inventory.items[i]
			
		var slot_text: String
		if item:
			slot_text = "[%d] %s" % [i + 1, item.item_name]
		else:
			slot_text = "[%d] ---" % [i + 1]
		lines.append(slot_text)
	
	lines.append("")
	lines.append("[Q] Drop")
	text = "\n".join(lines)

func _on_item_used(item_name: String) -> void:
	_update_display()
