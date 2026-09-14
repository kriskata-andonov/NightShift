extends Node3D
class_name Interactable
## Base class for all interactable objects in the world.
## Subclasses override these methods to define specific behavior, or connect to the 'interacted' signal.

signal interacted(player: Node)

@export var prompt_text: String = "Interact"
@export var is_interactable: bool = true

## Whether this object can currently be interacted with.
func can_interact(_player: Node) -> bool:
	return is_interactable

## Perform the interaction. Called when the player presses the interact key.
func interact(_player: Node) -> void:
	interacted.emit(_player)

## Return the text shown in the interaction prompt.
func get_interaction_text(_player: Node = null) -> String:
	return prompt_text
