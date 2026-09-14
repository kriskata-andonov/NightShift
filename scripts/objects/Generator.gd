class_name Generator
extends Node3D

@onready var interactable = $Geometry/StaticBody3D

func _ready() -> void:
	if interactable:
		interactable.interacted.connect(_on_interacted)
	LevelState.power_restored.connect(_on_power_restored)
	_update_prompt()

func _on_interacted(_player: Node3D) -> void:
	if LevelState.is_power_on:
		return
		
	if LevelState.fuses_installed >= LevelState.fuses_required:
		LevelState.turn_on_power.rpc()
	else:
		print("Cannot turn on generator, fuses are missing!")
		interactable.prompt_text = "Missing Fuses!"
		get_tree().create_timer(2.0).timeout.connect(_update_prompt)

func _on_power_restored() -> void:
	_update_prompt()

func _update_prompt() -> void:
	if interactable:
		if LevelState.is_power_on:
			interactable.prompt_text = "Generator Running"
		else:
			interactable.prompt_text = "Turn On Generator"
