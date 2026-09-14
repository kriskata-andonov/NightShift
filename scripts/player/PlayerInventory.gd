extends Node
class_name PlayerInventory
## Slot-based inventory for the player. Items are added via PickupItem interaction
## and can be used or dropped with hotkeys.

signal inventory_changed
signal item_used(item_name: String)

@export var max_slots: int = 3

## The PickupItem scene used when dropping items into the world.
var pickup_scene: PackedScene = preload("res://scenes/items/PickupItem.tscn")

var items: Array = []  # Array of ItemData (or null for empty slots)

func _ready() -> void:
	# Default initialization so items array is never empty
	items.resize(max_slots)
	for i in range(max_slots):
		items[i] = null

## Called explicitly by TestChamber after spawning the player and setting character_class.
func initialize(p_class: int) -> void:
	if p_class == 2: # HOARDER
		max_slots = 4
	else:
		max_slots = 3
		
	# Initialize empty slots
	items.resize(max_slots)
	for i in range(max_slots):
		items[i] = null
		
	inventory_changed.emit.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	var player = get_parent()
	if player and player is CharacterBody3D and not player.is_multiplayer_authority():
		return
		
	if event.is_action_pressed("use_slot_1"):
		use_item(0)
	elif event.is_action_pressed("use_slot_2"):
		use_item(1)
	elif event.is_action_pressed("use_slot_3"):
		use_item(2)
	elif InputMap.has_action("use_slot_4") and event.is_action_pressed("use_slot_4"):
		use_item(3)
	elif event is InputEventKey and event.keycode == KEY_4 and event.pressed and not event.is_echo():
		use_item(3)
	elif event.is_action_pressed("drop_item"):
		_drop_first_item()

## Try to add an item to the inventory. Returns true if successful.
func add_item(item: ItemData) -> bool:
	if is_full():
		return false
		
	for i in range(max_slots):
		if items[i] == null:
			items[i] = item
			inventory_changed.emit()
			return true
	return false

## Returns true if all slots are occupied.
func is_full() -> bool:
	if items.size() < max_slots:
		return false
	for i in range(max_slots):
		if items[i] == null:
			return false
	return true

## Remove and return the item at the given slot index.
func remove_item(index: int) -> ItemData:
	if index < 0 or index >= max_slots:
		return null
	var item: ItemData = items[index]
	items[index] = null
	inventory_changed.emit()
	return item

## Use the item in the given slot.
func use_item(index: int) -> void:
	if index < 0 or index >= max_slots:
		return
	var item: ItemData = items[index]
	if item == null:
		return

	# Dispatch use logic based on the item's use_action
	var used := _execute_use_action(item)
	if used:
		# Consumables are removed after use; mission items stay
		if item.item_type == ItemData.ItemType.CONSUMABLE:
			items[index] = null
			inventory_changed.emit()
		item_used.emit(item.item_name)

## Drop the item at the given slot, spawning it in front of the player.
func drop_item(index: int) -> void:
	if index < 0 or index >= max_slots:
		return
	var item: ItemData = items[index]
	if item == null:
		return

	items[index] = null
	inventory_changed.emit()

	# Request the server to spawn the dropped item so it gets proper network identity
	var player: CharacterBody3D = get_parent() as CharacterBody3D
	if player and item.resource_path:
		var forward := -player.global_transform.basis.z.normalized()
		var spawn_pos := player.global_position + forward * 1.5
		spawn_pos.y = player.global_position.y - 0.5  # Roughly ground level
		if not multiplayer.has_multiplayer_peer():
			var drop_name = "drop_solo_%d" % Time.get_ticks_msec()
			get_tree().current_scene.rpc_spawn_drop_global(item.resource_path, spawn_pos, drop_name)
		elif multiplayer.is_server():
			var drop_name = "drop_%d_%d" % [multiplayer.get_unique_id(), Time.get_ticks_msec()]
			get_tree().current_scene.rpc_spawn_drop_global.rpc(item.resource_path, spawn_pos, drop_name)
		else:
			_rpc_request_drop.rpc_id(1, item.resource_path, spawn_pos)

## Client requests the server to spawn a dropped item.
@rpc("any_peer", "reliable")
func _rpc_request_drop(res_path: String, spawn_pos: Vector3) -> void:
	if not multiplayer.is_server():
		return
	var peer_id = multiplayer.get_remote_sender_id()
	var drop_name = "drop_%d_%d" % [peer_id, Time.get_ticks_msec()]
	get_tree().current_scene.rpc_spawn_drop_global.rpc(res_path, spawn_pos, drop_name)

## Check if the inventory contains an item with the given name.
func has_item(item_name: String) -> bool:
	for item in items:
		if item and item.item_name == item_name:
			return true
	return false

## Remove the first occurrence of an item by name and return true if successful.
func remove_item_by_name(item_name: String) -> bool:
	for i in range(max_slots):
		if items[i] and items[i].item_name == item_name:
			remove_item(i)
			return true
	return false

## Count how many of a given item name are in the inventory.
func get_item_count(item_name: String) -> int:
	var count := 0
	for item in items:
		if item and item.item_name == item_name:
			count += 1
	return count

## Execute the use action for an item. Returns true if successfully used.
func _execute_use_action(item: ItemData) -> bool:
	match item.use_action:
		"battery":
			return _use_battery()
		"fuse":
			# Fuses are used at fuse boxes, not from inventory directly
			return false
		_:
			return false

## Recharge the player's flashlight.
func _use_battery() -> bool:
	var player := get_parent()
	if not player:
		return false
	# Find the flashlight node
	var head := player.get_node_or_null("Head")
	if not head:
		return false
	var camera := head.get_node_or_null("Camera3D")
	if not camera:
		return false
	var flashlight := camera.get_node_or_null("Flashlight")
	if flashlight and flashlight.has_method("recharge"):
		flashlight.recharge(flashlight.max_battery)
		return true
	return false

## Drop the first occupied item slot.
func _drop_first_item() -> void:
	for i in range(max_slots):
		if items[i] != null:
			drop_item(i)
			return
