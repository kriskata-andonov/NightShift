extends Node3D
class_name Interactable
## Base class for all interactable objects in the world.
## Subclasses override these methods to define specific behavior.

## Whether this object can currently be interacted with.
func can_interact(_player: Node) -> bool:
	return true

## Perform the interaction. Called when the player presses the interact key.
func interact(_player: Node) -> void:
	pass

## Return the text shown in the interaction prompt (e.g., "Open Door").
func get_interaction_text(_player: Node = null) -> String:
	return "Interact"
