@tool
extends SceneTree

func _init():
	var packed_scene = load("res://scenes/maps/TestChamber.tscn")
	var map = packed_scene.instantiate()
	
	var spawner = MultiplayerSpawner.new()
	spawner.name = "PlayerSpawner"
	spawner.spawn_path = NodePath("..")
	spawner.add_spawnable_scene("res://scenes/player/Player.tscn")
	
	map.add_child(spawner)
	spawner.owner = map
	
	var new_packed = PackedScene.new()
	new_packed.pack(map)
	ResourceSaver.save(new_packed, "res://scenes/maps/TestChamber.tscn")
	print("Successfully embedded MultiplayerSpawner into TestChamber.tscn!")
	quit()
