extends RayCast3D
class_name PlayerInteraction
## Casts a ray from the camera to detect Interactable objects.
## Shows/hides the interaction prompt and dispatches interact() on input.

@export var interaction_range: float = 2.5

var current_target: Interactable = null
var prompt_label: Label = null

func _ready() -> void:
	# Configure the raycast
	target_position = Vector3(0, 0, -interaction_range)
	enabled = true
	
	# Find the interaction prompt label in the player scene tree
	# Expected path: Player/InteractionUI/InteractionPrompt
	var player := _get_player()
	if player:
		prompt_label = player.get_node_or_null("InteractionUI/InteractionPrompt")
	
	if prompt_label:
		prompt_label.visible = false

func _physics_process(_delta: float) -> void:
	var player = _get_player()
	if player and not player.is_multiplayer_authority():
		return
		
	# Clear stale references to freed or dying nodes (e.g. picked-up items)
	if current_target and (not is_instance_valid(current_target) or current_target.is_queued_for_deletion()):
		current_target = null
		_update_prompt()
	
	var new_target: Interactable = null
	
	if is_colliding():
		var collider := get_collider()
		if collider and not collider.is_queued_for_deletion():
			# Walk up the tree to find an Interactable ancestor
			new_target = _find_interactable(collider)
	
	if new_target != current_target:
		current_target = new_target
		_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	var player = _get_player()
	if player and not player.is_multiplayer_authority():
		return
		
	if event.is_action_pressed("interact") and current_target:
		if current_target.can_interact(_get_player()):
			current_target.interact(_get_player())
			# If the interaction freed the target (e.g. item pickup), clear it now
			if not is_instance_valid(current_target) or current_target.is_queued_for_deletion():
				current_target = null
			_update_prompt()

## Walk up the scene tree from a collider to find an Interactable node.
func _find_interactable(node: Node) -> Interactable:
	var current := node
	while current:
		if current.is_queued_for_deletion():
			return null
		if current is Interactable:
			if current.can_interact(_get_player()):
				return current
			else:
				return null
		current = current.get_parent()
	return null

## Get the root Player (CharacterBody3D) node.
func _get_player() -> Node:
	var current: Node = get_parent()
	while current:
		if current is CharacterBody3D:
			return current
		current = current.get_parent()
	return null

## Show or hide the interaction prompt based on current_target.
func _update_prompt() -> void:
	if not prompt_label:
		return
	if current_target and is_instance_valid(current_target) and not current_target.is_queued_for_deletion() and current_target.can_interact(_get_player()):
		prompt_label.text = "[E] " + current_target.get_interaction_text(_get_player())
		prompt_label.visible = true
	else:
		prompt_label.visible = false
