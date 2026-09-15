extends Node
class_name PlayerHealth
## Manages player health with ALIVE → DOWNED → DEAD state machine.
## No HUD bar — damage is communicated through screen effects.

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

func _ready() -> void:
	current_health = max_health
	
	# Connect to CheatCodeManager if it exists
	var player = get_parent()
	if player:
		var cheat_mgr = player.get_node_or_null("CheatCodeManager")
		if cheat_mgr:
			cheat_mgr.cheat_activated.connect(_on_cheat)

func _on_cheat(code: String) -> void:
	match code:
		"dmg":
			take_damage(20.0)
		"hlt":
			heal(20.0)
		"down":
			if state == State.ALIVE:
				current_health = 0.0
				health_changed.emit(current_health, max_health)
				_enter_downed()
		"dead":
			if state != State.DEAD:
				current_health = 0.0
				health_changed.emit(current_health, max_health)
				_die()
		"undie":
			if state == State.DOWNED or state == State.DEAD:
				revive()

func _process(delta: float) -> void:
	var player = get_parent()
	if player and player is CharacterBody3D and not player.is_multiplayer_authority():
		return
		
	if state == State.DOWNED:
		bleedout_timer -= delta
		if bleedout_timer <= 0.0:
			bleedout_timer = 0.0
			_die()

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

## Server-authoritative damage — Monster AI calls this via RPC.
@rpc("authority", "call_local", "reliable")
func rpc_take_damage(amount: float) -> void:
	take_damage(amount)

## Server-authoritative heal — revive items, etc.
@rpc("authority", "call_local", "reliable")
func rpc_heal(amount: float) -> void:
	heal(amount)

## Server-authoritative revive.
@rpc("authority", "call_local", "reliable")
func rpc_revive() -> void:
	revive()
