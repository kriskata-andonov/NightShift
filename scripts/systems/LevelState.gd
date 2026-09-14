extends Node

signal power_restored
signal power_changed(is_on: bool)
signal fuse_added(count: int, required: int)

var fuses_installed: int = 0
var fuses_required: int = 3
var is_power_on: bool = false

func reset() -> void:
	fuses_installed = 0
	fuses_required = 3
	is_power_on = false
	power_changed.emit(false)

@rpc("any_peer", "call_local")
func add_fuse() -> void:
	if fuses_installed < fuses_required:
		fuses_installed += 1
		fuse_added.emit(fuses_installed, fuses_required)
		print("Fuse added! ", fuses_installed, "/", fuses_required)

@rpc("any_peer", "call_local")
func turn_on_power() -> void:
	if fuses_installed >= fuses_required and not is_power_on:
		is_power_on = true
		power_restored.emit()
		power_changed.emit(true)
		print("POWER RESTORED!")

@rpc("any_peer", "call_local")
func debug_toggle_power() -> void:
	is_power_on = !is_power_on
	if is_power_on:
		fuses_installed = fuses_required
		power_restored.emit()
	else:
		fuses_installed = 0
	power_changed.emit(is_power_on)
	fuse_added.emit(fuses_installed, fuses_required)
	print("[DEBUG] Facility power toggled: ", is_power_on)
