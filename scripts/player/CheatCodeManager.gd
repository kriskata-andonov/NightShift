extends Node
class_name CheatCodeManager
## Centralized cheat code handler. Maintains a single keyboard buffer
## and dispatches cheat_activated signals. Attach as a child of the Player.
##
## Available codes:
##   bug        — Toggle Debug FreeCam (Noclip)
##   pow        — Toggle Facility Power
##   col1-col5  — Change suit color
##   cl1-cl4    — Change class
##   fear/crazy/calm — Fear system debug
##   dmg/hlt/down/dead/undie — Health system debug

signal cheat_activated(code: String)

var buffer: String = ""
var buffer_timeout: float = 2.5
var timer: float = 0.0

## All recognized cheat codes (Latin + Cyrillic phonetics)
var codes: Array[String] = [
	"crazy", "undie",
	"col1", "col2", "col3", "col4", "col5",
	"fear", "calm", "down", "dead",
	"cl1", "cl2", "cl3", "cl4",
	"dmg", "hlt",
	"bug", "pow", "lit",
	# Cyrillic phonetics support
	"буг", "пов", "лит", "феар", "калм", "цалм", "дмг", "хлт", "деад", "довн", "ундие", "црази", "крази"
]

const ALIAS_MAP = {
	"буг": "bug",
	"пов": "pow",
	"лит": "lit",
	"феар": "fear",
	"калм": "calm",
	"цалм": "calm",
	"дмг": "dmg",
	"хлт": "hlt",
	"деад": "dead",
	"довн": "down",
	"ундие": "undie",
	"црази": "crazy",
	"крази": "crazy"
}

func _process(delta: float) -> void:
	if buffer.length() > 0:
		timer += delta
		if timer >= buffer_timeout:
			buffer = ""
			timer = 0.0

func _input(event: InputEvent) -> void:
	var player = get_parent()
	if player and player is CharacterBody3D:
		if multiplayer.has_multiplayer_peer() and not player.is_multiplayer_authority():
			return
			
	if not event is InputEventKey or not event.pressed or event.echo:
		return
		
	var key_char = ""
	
	# 1. Prefer physical hardware keycode (independent of OS keyboard language)
	if event.physical_keycode != 0:
		var s = OS.get_keycode_string(event.physical_keycode).to_lower()
		if s.length() == 1:
			key_char = s
			
	# 2. Fallback to keycode
	if key_char == "" and event.keycode != 0:
		var s = OS.get_keycode_string(event.keycode).to_lower()
		if s.length() == 1:
			key_char = s
			
	# 3. Fallback to unicode character
	if key_char == "" and event.unicode != 0:
		key_char = char(event.unicode).to_lower()
		
	if key_char != "":
		buffer += key_char
		timer = 0.0
		
		# Keep buffer length bounded
		if buffer.length() > 20:
			buffer = buffer.substr(buffer.length() - 20)
			
		for code in codes:
			if buffer.ends_with(code):
				var canonical = ALIAS_MAP.get(code, code)
				print("[CHEAT ACTIVATED] Code: '", canonical, "' (from buffer: '", buffer, "')")
				cheat_activated.emit(canonical)
				_show_toast(canonical)
				buffer = ""
				timer = 0.0
				return

func _show_toast(canonical_code: String) -> void:
	var player = get_parent()
	if not player:
		return
	var toast = player.get_node_or_null("InteractionUI/CheatToast") as Label
	if not toast:
		return
		
	var msg = "[ CHEAT: " + canonical_code.to_upper() + " ]"
	if canonical_code == "bug":
		var is_cam = player.is_debug_cam if "is_debug_cam" in player else false
		msg = "[ CHEAT: FREECAM " + ("ON" if is_cam else "OFF") + " ]"
	elif canonical_code == "pow":
		msg = "[ CHEAT: FACILITY POWER TOGGLED ]"
	elif canonical_code == "lit":
		msg = "[ CHEAT: AMBIENT LIGHT TOGGLED ]"
	elif canonical_code == "fear":
		msg = "[ CHEAT: FEAR +25 ]"
	elif canonical_code == "crazy":
		msg = "[ CHEAT: MAX FEAR (PANIC) ]"
	elif canonical_code == "calm":
		msg = "[ CHEAT: FEAR RESET (0%) ]"
	elif canonical_code == "dmg":
		msg = "[ CHEAT: DAMAGE -20 HP ]"
	elif canonical_code == "hlt":
		msg = "[ CHEAT: HEAL +20 HP ]"
	elif canonical_code == "down":
		msg = "[ CHEAT: DOWNED STATE ]"
	elif canonical_code == "dead":
		msg = "[ CHEAT: INSTANT DEATH ]"
	elif canonical_code == "undie":
		msg = "[ CHEAT: REVIVED ]"
		
	toast.text = msg
	toast.visible = true
	var tree = get_tree()
	if tree:
		tree.create_timer(3.0).timeout.connect(func():
			if is_instance_valid(toast) and toast.text == msg:
				toast.visible = false
		)
