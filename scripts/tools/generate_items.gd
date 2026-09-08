extends SceneTree

func _init() -> void:
	# Battery
	var battery = ItemData.new()
	battery.item_name = "Battery"
	battery.description = "Recharges flashlight."
	battery.item_type = ItemData.ItemType.CONSUMABLE
	battery.use_action = "battery"
	battery.pickup_color = Color.YELLOW
	ResourceSaver.save(battery, "res://resources/items/Battery.tres")
	
	# Sanity Pills
	var pills = ItemData.new()
	pills.item_name = "Sanity Pills"
	pills.description = "Calms your nerves."
	pills.item_type = ItemData.ItemType.CONSUMABLE
	pills.use_action = "sanity_pills"
	pills.pickup_color = Color.CYAN
	ResourceSaver.save(pills, "res://resources/items/SanityPills.tres")
	
	print("Items generated!")
	quit()
