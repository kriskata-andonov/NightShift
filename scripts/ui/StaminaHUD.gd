extends Control
class_name StaminaHUD
## Thin center-bottom stamina bar that appears when sprinting or recovering,
## and fades out when stamina is full. Drawn with _draw() for clean visuals.

const BAR_WIDTH: float = 200.0
const BAR_HEIGHT: float = 3.0
const FADE_SPEED: float = 3.0
## How long to keep showing the bar after stamina starts recovering.
const LINGER_TIME: float = 1.5

var player_movement: PlayerMovement = null
var display_alpha: float = 0.0
var linger_timer: float = 0.0
var was_below_max: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	size = Vector2(BAR_WIDTH, BAR_HEIGHT)

	# Center-bottom positioning
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -BAR_WIDTH / 2.0
	offset_right = BAR_WIDTH / 2.0
	offset_top = -24.0
	offset_bottom = -24.0 + BAR_HEIGHT

	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_find_player()

func _find_player() -> void:
	var current: Node = get_parent()
	while current:
		if current is PlayerMovement:
			player_movement = current
			return
		current = current.get_parent()

func _process(delta: float) -> void:
	if not player_movement:
		return

	var stamina_pct: float = player_movement.current_stamina / player_movement.max_stamina

	# Track when stamina dips below max to trigger linger
	if stamina_pct < 1.0:
		was_below_max = true
		linger_timer = LINGER_TIME
	elif was_below_max:
		linger_timer -= delta
		if linger_timer <= 0.0:
			was_below_max = false

	# Fade in when stamina is below max, fade out after linger
	var should_show: bool = stamina_pct < 1.0 or linger_timer > 0.0
	if should_show:
		display_alpha = move_toward(display_alpha, 1.0, FADE_SPEED * delta)
	else:
		display_alpha = move_toward(display_alpha, 0.0, FADE_SPEED * delta)

	queue_redraw()

func _draw() -> void:
	if display_alpha <= 0.01:
		return
	if not player_movement:
		return

	var stamina_pct: float = player_movement.current_stamina / player_movement.max_stamina

	# Background bar (dark, semi-transparent)
	var bg_color := Color(0.1, 0.1, 0.1, 0.5 * display_alpha)
	draw_rect(Rect2(0, 0, BAR_WIDTH, BAR_HEIGHT), bg_color)

	# Filled bar — color shifts green → yellow → red
	var fill_color: Color
	if stamina_pct > 0.5:
		fill_color = Color(0.3, 0.75, 0.35)
	elif stamina_pct > 0.25:
		fill_color = Color(0.9, 0.7, 0.15)
	else:
		fill_color = Color(0.85, 0.2, 0.15)
	fill_color.a = 0.85 * display_alpha

	var fill_width: float = BAR_WIDTH * stamina_pct
	draw_rect(Rect2(0, 0, fill_width, BAR_HEIGHT), fill_color)

	# Thin border
	var border_color := Color(0.6, 0.6, 0.6, 0.3 * display_alpha)
	draw_rect(Rect2(0, 0, BAR_WIDTH, BAR_HEIGHT), border_color, false, 1.0)
