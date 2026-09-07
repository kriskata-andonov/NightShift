extends Interactable
class_name PickupItem
## A world-placed item that players can pick up using the interaction system.
## Holds an ItemData resource and removes itself from the scene on pickup.

@export var item_data: ItemData

var mesh_node: CSGBox3D = null

func _ready() -> void:
	# Tint the mesh to match the item's pickup color
	if item_data:
		mesh_node = get_node_or_null("Mesh")
		if mesh_node:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = item_data.pickup_color
			mat.emission_enabled = true
			mat.emission = item_data.pickup_color * 0.3
			mat.emission_energy_multiplier = 0.5
			mesh_node.material = mat

func can_interact(_player: Node) -> bool:
	return item_data != null

func interact(player: Node) -> void:
	if not item_data:
		return
	# Try to add to the player's inventory
	var inventory := _get_inventory(player)
	if not inventory:
		return
	if inventory.add_item(item_data):
		queue_free()

func get_interaction_text() -> String:
	if item_data:
		return "Pick Up " + item_data.item_name
	return "Pick Up"

## Find the PlayerInventory node on the player.
func _get_inventory(player: Node) -> Node:
	return player.get_node_or_null("PlayerInventory")
