extends SpotLight3D

@export var max_battery: float = 60.0
@export var drain_rate: float = 1.0

var current_battery: float = 60.0
var is_on: bool = true

func _ready() -> void:
	current_battery = max_battery

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_flashlight"):
		if is_on:
			# Always allow turning OFF
			is_on = false
			visible = false
		elif current_battery > 0:
			# Only allow turning ON if there's battery left
			is_on = true
			visible = true
		
	if is_on and current_battery > 0:
		current_battery -= drain_rate * delta
		if current_battery <= 0:
			current_battery = 0
			is_on = false
			visible = false

## Recharge the flashlight battery by the given amount.
## If the flashlight was dead, this turns it back on.
func recharge(amount: float) -> void:
	current_battery = minf(current_battery + amount, max_battery)
	if current_battery > 0 and not is_on:
		is_on = true
		visible = true

