class_name FusePanel
extends Node3D

@onready var interactable = $Geometry/StaticBody3D

func _ready() -> void:
	if interactable:
		interactable.interacted.connect(_on_interacted)
	LevelState.fuse_added.connect(_on_fuse_added)
	_update_prompt()

func _on_interacted(player: Node3D) -> void:
	if LevelState.fuses_installed >= LevelState.fuses_required:
		return
		
	var inv = player.get_node_or_null("PlayerInventory")
	if inv:
		if inv.has_item("Industrial Fuse"):
			inv.remove_item_by_name("Industrial Fuse")
			LevelState.add_fuse.rpc()
		elif inv.has_item("Fuse"):
			inv.remove_item_by_name("Fuse")
			LevelState.add_fuse.rpc()
		else:
			print("Player does not have a fuse!")
			# Optional: visual/audio feedback for missing fuse

func _on_fuse_added(count: int, req: int) -> void:
	_update_prompt()

func _update_prompt() -> void:
	if interactable:
		if LevelState.fuses_installed >= LevelState.fuses_required:
			interactable.prompt_text = "Fuses fully restored."
		else:
			interactable.prompt_text = "Insert Fuse (" + str(LevelState.fuses_installed) + "/" + str(LevelState.fuses_required) + ")"
