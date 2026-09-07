extends Node
class_name PlayerHealth
## Manages player health with ALIVE → DOWNED → DEAD state machine.
## No HUD bar — damage is communicated through screen effects.
##
## DEBUG KEYS (remove before shipping):
##   H = Take 20 damage
##   K = Instant down
##   J = Self-revive

signal damage_taken(amount: float)
signal healed(amount: float)
signal downed
signal revived
signal died
signal health_changed(current: float, maximum: float)

enum State { ALIVE, DOWNED, DEAD }

@export var max_health: float = 100.0
@export var bleedout_time: float = 30.0
## What percentage of max HP the player gets back on revive.
@export var revive_health_percent: float = 0.3

var current_health: float = 100.0
var state: State = State.ALIVE
var bleedout_timer: float = 0.0

# Buffer for typing cheat codes
var cheat_buffer: String = ""

func _ready() -> void:
	current_health = max_health

func _process(delta: float) -> void:
	if state == State.DOWNED:
		bleedout_timer -= delta
		if bleedout_timer <= 0.0:
			bleedout_timer = 0.0
			_die()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	
	if event.unicode != 0:
		cheat_buffer += char(event.unicode).to_lower()
		
		# Keep buffer size manageable
		if cheat_buffer.length() > 20:
			cheat_buffer = cheat_buffer.substr(cheat_buffer.length() - 20)
			
		if cheat_buffer.ends_with("dmg"):
			take_damage(20.0)
			cheat_buffer = ""
		elif cheat_buffer.ends_with("hlt"):
			heal(20.0)
			cheat_buffer = ""
		elif cheat_buffer.ends_with("down"):
			if state == State.ALIVE:
				current_health = 0.0
				health_changed.emit(current_health, max_health)
				_enter_downed()
			cheat_buffer = ""
		elif cheat_buffer.ends_with("dead"):
			if state != State.DEAD:
				current_health = 0.0
				health_changed.emit(current_health, max_health)
				_die()
			cheat_buffer = ""
		elif cheat_buffer.ends_with("undie"):
			if state == State.DOWNED or state == State.DEAD:
				revive()
			cheat_buffer = ""

func take_damage(amount: float) -> void:
	if state != State.ALIVE:
		return
	current_health = maxf(current_health - amount, 0.0)
	damage_taken.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_enter_downed()

func heal(amount: float) -> void:
	if state != State.ALIVE:
		return
	var old_health := current_health
	current_health = minf(current_health + amount, max_health)
	var healed_amount := current_health - old_health
	if healed_amount > 0:
		healed.emit(healed_amount)
		health_changed.emit(current_health, max_health)

func revive() -> void:
	if state != State.DOWNED and state != State.DEAD:
		return
	state = State.ALIVE
	current_health = max_health * revive_health_percent
	bleedout_timer = 0.0
	health_changed.emit(current_health, max_health)
	revived.emit()

func get_health_percent() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health

func get_bleedout_percent() -> float:
	if bleedout_time <= 0.0:
		return 0.0
	return bleedout_timer / bleedout_time

func is_downed() -> bool:
	return state == State.DOWNED

func _enter_downed() -> void:
	state = State.DOWNED
	bleedout_timer = bleedout_time
	downed.emit()

func _die() -> void:
	state = State.DEAD
	died.emit()
