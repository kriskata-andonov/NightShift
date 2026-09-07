extends Node
class_name CheatCodeManager
## Centralized cheat code handler. Maintains a single keyboard buffer
## and dispatches cheat_activated signals. Attach as a child of the Player.
##
## Available codes:
##   col1-col5  — Change suit color
##   cl1-cl4    — Change class
##   fear/crazy/calm — Fear system debug
##   dmg/hlt/down/dead/undie — Health system debug

signal cheat_activated(code: String)

var buffer: String = ""

## All recognized cheat codes, longest first to avoid prefix collisions
var codes: Array[String] = [
	"crazy", "undie",
	"col1", "col2", "col3", "col4", "col5",
	"fear", "calm", "down", "dead",
	"cl1", "cl2", "cl3", "cl4",
	"dmg", "hlt",
]

func _unhandled_input(event: InputEvent) -> void:
	var player = get_parent()
	if player and player is CharacterBody3D and not player.is_multiplayer_authority():
		return
		
	if not event is InputEventKey or not event.pressed:
		return
	
	if event.unicode != 0:
		buffer += char(event.unicode).to_lower()
		
		# Keep buffer size manageable
		if buffer.length() > 20:
			buffer = buffer.substr(buffer.length() - 20)
		
		for code in codes:
			if buffer.ends_with(code):
				cheat_activated.emit(code)
				buffer = ""
				return
