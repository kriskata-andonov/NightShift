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
var _initialized_class: int = -1

func _process(_delta: float) -> void:
	var player := get_parent()
	if player and "character_class" in player:
		if player.character_class != _initialized_class:
			initialize(player.character_class)

func initialize(p_class: int) -> void:
	_initialized_class = p_class
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
		# Drop the first occupied slot (or last used — keep it simple for now)
		_drop_first_item()

## Try to add an item to the inventory. Returns true if successful.
func add_item(item: ItemData) -> bool:
	for i in range(max_slots):
		if items[i] == null:
			items[i] = item
			inventory_changed.emit()
			return true
	# Inventory full
	return false

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

	# Spawn the pickup in the world globally
	var player: CharacterBody3D = get_parent() as CharacterBody3D
	if player and item.resource_path:
		var forward := -player.global_transform.basis.z.normalized()
		var spawn_pos := player.global_position + forward * 1.5
		spawn_pos.y = player.global_position.y - 0.5  # Roughly ground level
		_rpc_spawn_drop.rpc(item.resource_path, spawn_pos)

@rpc("any_peer", "call_local", "reliable")
func _rpc_spawn_drop(res_path: String, spawn_pos: Vector3) -> void:
	if not pickup_scene:
		return
	var pickup = pickup_scene.instantiate()
	pickup.item_data = load(res_path)
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(pickup)
		pickup.global_position = spawn_pos

## Check if the inventory contains an item with the given name.
func has_item(item_name: String) -> bool:
	for item in items:
		if item and item.item_name == item_name:
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
