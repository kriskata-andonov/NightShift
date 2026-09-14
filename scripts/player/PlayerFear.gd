extends Node
class_name PlayerFear
## Internal fear system (0–100). Fear accumulates in darkness and decays
## in light. Triggers visual/audio effects at threshold tiers:
##   25%+ Uneasy   — subtle dark vignette
##   50%+ Distressed — camera jitter, stronger vignette
##   75%+ Panic     — flashlight auto-flickers, heavy tunnel vision

signal fear_changed(level: float)
signal threshold_entered(tier: int)

enum Tier { CALM, UNEASY, DISTRESSED, PANIC }

@export var max_fear: float = 100.0
## How fast fear rises when the flashlight is off or dead.
@export var darkness_rate: float = 1.0
## How fast fear decays when the flashlight is on.
@export var light_decay_rate: float = 6.0
## Slow natural decay even in darkness (so fear doesn't stay pegged).
@export var natural_decay_rate: float = 0.2

var current_fear: float = 0.0
var current_tier: int = Tier.CALM

# Flashlight flicker state (Panic tier)
var flicker_timer: float = 0.0
var is_flickering: bool = false

# Camera jitter (Distressed+ tiers)
var jitter_offset_h: float = 0.0
var jitter_offset_v: float = 0.0

# Node references
var flashlight: Node = null
var camera: Camera3D = null
var health_node: Node = null

func _ready() -> void:
	_find_nodes()
	
	# Connect to CheatCodeManager if it exists
	var player = get_parent()
	if player:
		var cheat_mgr = player.get_node_or_null("CheatCodeManager")
		if cheat_mgr:
			cheat_mgr.cheat_activated.connect(_on_cheat)

func _on_cheat(code: String) -> void:
	match code:
		"fear":
			current_fear = minf(current_fear + 25.0, max_fear)
			fear_changed.emit(current_fear)
		"crazy":
			current_fear = max_fear
			fear_changed.emit(current_fear)
		"calm":
			current_fear = 0.0
			fear_changed.emit(current_fear)

func _find_nodes() -> void:
	var player := get_parent()
	if not player:
		return
	health_node = player.get_node_or_null("PlayerHealth")
	var head := player.get_node_or_null("Head")
	if head:
		camera = head.get_node_or_null("Camera3D")
		if camera:
			flashlight = camera.get_node_or_null("Flashlight")

func _process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	var player = get_parent()
	if player and player is CharacterBody3D and not player.is_multiplayer_authority():
		return
		
	# Don't accumulate fear when downed or dead
	if health_node and (health_node.is_downed() or health_node.state == health_node.State.DEAD):
		return

	_update_fear(delta)
	_update_tier()
	_update_flashlight_flicker(delta)
	_update_camera_jitter(delta)

## Core fear accumulation / decay logic.
func _update_fear(delta: float) -> void:
	var drate := darkness_rate
	
	# Freshman Tradeoff: Fear fills 20% faster when separated (MP proximity not built yet, always active for now)
	var player := get_parent()
	if player and "character_class" in player and player.character_class == PlayerMovement.PlayerClass.FRESHMAN:
		drate *= 1.2
		
	if _is_in_darkness():
		current_fear += drate * delta
	else:
		current_fear -= light_decay_rate * delta

	current_fear = clampf(current_fear, 0.0, max_fear)
	fear_changed.emit(current_fear)

## Returns true if the player's flashlight is off or dead.
func _is_in_darkness() -> bool:
	if not flashlight:
		return true
	if flashlight.is_on and flashlight.current_battery > 0:
		return false
	return true

func get_fear_percent() -> float:
	if max_fear <= 0.0:
		return 0.0
	return current_fear / max_fear

## Determine which tier we're in and emit signal on change.
func _update_tier() -> void:
	var pct := get_fear_percent()
	var new_tier: int
	if pct >= 0.75:
		new_tier = Tier.PANIC
	elif pct >= 0.50:
		new_tier = Tier.DISTRESSED
	elif pct >= 0.25:
		new_tier = Tier.UNEASY
	else:
		new_tier = Tier.CALM

	if new_tier != current_tier:
		current_tier = new_tier
		threshold_entered.emit(current_tier)
		# Stop flickering if we drop below Panic
		if current_tier < Tier.PANIC and is_flickering:
			is_flickering = false
			if flashlight and flashlight.is_on:
				if flashlight.has_method("set_flicker_state"):
					flashlight.set_flicker_state(true)
				else:
					flashlight.visible = true

## At Panic tier, the flashlight flickers autonomously.
func _update_flashlight_flicker(delta: float) -> void:
	if current_tier < Tier.PANIC or not flashlight:
		return
	if not flashlight.is_on or flashlight.current_battery <= 0:
		return

	flicker_timer -= delta
	if flicker_timer <= 0.0:
		is_flickering = not is_flickering
		if flashlight.has_method("set_flicker_state"):
			flashlight.set_flicker_state(not is_flickering)
		else:
			flashlight.visible = not is_flickering
		# Random interval — rapid, erratic flickers
		if is_flickering:
			flicker_timer = randf_range(0.03, 0.12)
		else:
			flicker_timer = randf_range(0.1, 0.4)

## At Distressed+, apply subtle camera jitter via h/v offset.
func _update_camera_jitter(delta: float) -> void:
	if not camera:
		return

	if current_tier >= Tier.DISTRESSED:
		var intensity: float
		if current_tier == Tier.PANIC:
			intensity = 0.015
		else:
			intensity = 0.005

		# Random target offsets
		var target_h := randf_range(-intensity, intensity)
		var target_v := randf_range(-intensity, intensity)
		jitter_offset_h = lerpf(jitter_offset_h, target_h, 8.0 * delta)
		jitter_offset_v = lerpf(jitter_offset_v, target_v, 8.0 * delta)
		camera.h_offset = jitter_offset_h
		camera.v_offset = jitter_offset_v
	else:
		# Smooth back to zero
		jitter_offset_h = lerpf(jitter_offset_h, 0.0, 5.0 * delta)
		jitter_offset_v = lerpf(jitter_offset_v, 0.0, 5.0 * delta)
		camera.h_offset = jitter_offset_h
		camera.v_offset = jitter_offset_v
