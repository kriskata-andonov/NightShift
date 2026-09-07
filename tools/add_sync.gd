@tool
extends SceneTree

func _init():
	var packed_scene = load("res://scenes/player/Player.tscn")
	var player = packed_scene.instantiate()
	
	var sync = MultiplayerSynchronizer.new()
	sync.name = "MultiplayerSynchronizer"
	
	var config = SceneReplicationConfig.new()
	config.add_property(NodePath(":position"))
	config.property_set_spawn(NodePath(":position"), true)
	config.property_set_sync(NodePath(":position"), true)
	
	config.add_property(NodePath(":rotation"))
	config.property_set_spawn(NodePath(":rotation"), true)
	config.property_set_sync(NodePath(":rotation"), true)
	
	config.add_property(NodePath("Head:rotation"))
	config.property_set_spawn(NodePath("Head:rotation"), true)
	config.property_set_sync(NodePath("Head:rotation"), true)
	
	config.add_property(NodePath(":character_class"))
	config.property_set_spawn(NodePath(":character_class"), true)
	config.property_set_sync(NodePath(":character_class"), true)
	
	sync.replication_config = config
	player.add_child(sync)
	sync.owner = player
	
	var new_packed = PackedScene.new()
	new_packed.pack(player)
	ResourceSaver.save(new_packed, "res://scenes/player/Player.tscn")
	print("Successfully embedded MultiplayerSynchronizer into Player.tscn!")
	quit()
