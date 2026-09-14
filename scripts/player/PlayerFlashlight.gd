extends SpotLight3D

@export var max_battery: float = 300.0
@export var drain_rate: float = 1.0

## Current battery in seconds.
var current_battery: float = 300.0
var is_on: bool = true

var _is_authority: bool = false

func _ready() -> void:
	current_battery = max_battery
	# Walk up the tree to find the root Player node for authority check
	var current: Node = get_parent()
	while current:
		if current is CharacterBody3D:
			_is_authority = current.is_multiplayer_authority()
			break
		current = current.get_parent()

func _process(delta: float) -> void:
	if not _is_authority:
		return
		
	if Input.is_action_just_pressed("toggle_flashlight"):
		if is_on:
			_rpc_set_light.rpc(false)
		elif current_battery > 0:
			_rpc_set_light.rpc(true)
		
	if is_on and current_battery > 0:
		current_battery -= drain_rate * delta
		if current_battery <= 0:
			current_battery = 0
			_rpc_set_light.rpc(false)

@rpc("any_peer", "call_local", "reliable")
func _rpc_set_light(state: bool) -> void:
	is_on = state
	visible = state
	
func set_flicker_state(state: bool) -> void:
	if _is_authority:
		_rpc_set_light_visual_only.rpc(state)

@rpc("any_peer", "call_local", "unreliable")
func _rpc_set_light_visual_only(state: bool) -> void:
	visible = state

## Recharge the flashlight battery by the given amount.
## If the flashlight was dead, this turns it back on.
func recharge(amount: float) -> void:
	current_battery = minf(current_battery + amount, max_battery)
	if current_battery > 0 and not is_on:
		if _is_authority:
			_rpc_set_light.rpc(true)
