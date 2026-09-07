extends Resource
class_name ItemData
## Data-driven item definition. Create .tres resources for each item type.

enum ItemType {
	CONSUMABLE,  ## Single-use items (battery, medkit, glow stick)
	MISSION,     ## Objective items (fuse, repair kit)
	EQUIPMENT    ## Persistent gear (radio, camera)
}

@export var item_name: String = "Item"
@export var description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var is_stackable: bool = false
@export var max_stack: int = 1
## Identifier used to dispatch use logic (e.g., "battery", "medkit").
@export var use_action: String = ""
## Color tint for the world pickup mesh when no model is available.
@export var pickup_color: Color = Color(0.8, 0.8, 0.8, 1.0)
