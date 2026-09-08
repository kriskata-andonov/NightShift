extends SceneTree

func _init() -> void:
	var root = AnimatableBody3D.new()
	root.name = "Watcher"
	root.collision_layer = 4 # Enemy layer
	root.collision_mask = 1 | 2 # World and Player
	
	# Sclera (White Eye)
	var sclera_mesh = MeshInstance3D.new()
	sclera_mesh.name = "Sclera"
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sclera_mesh.mesh = sphere
	var sclera_mat = StandardMaterial3D.new()
	sclera_mat.albedo_color = Color.WHITE
	sclera_mat.roughness = 0.2
	sphere.material = sclera_mat
	root.add_child(sclera_mesh)
	sclera_mesh.owner = root
	
	# Pupil (Black Center)
	var pupil_mesh = MeshInstance3D.new()
	pupil_mesh.name = "Pupil"
	var pupil_sphere = SphereMesh.new()
	pupil_sphere.radius = 0.4
	pupil_sphere.height = 0.8
	pupil_mesh.mesh = pupil_sphere
	var pupil_mat = StandardMaterial3D.new()
	pupil_mat.albedo_color = Color.BLACK
	pupil_mat.roughness = 0.1
	pupil_sphere.material = pupil_mat
	pupil_mesh.position = Vector3(0, 0, -0.8) # Forward is -Z in Godot
	root.add_child(pupil_mesh)
	pupil_mesh.owner = root
	
	# Collision Shape
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape = SphereShape3D.new()
	shape.radius = 1.0
	collision.shape = shape
	root.add_child(collision)
	collision.owner = root
	
	# Networking Sync
	var sync = MultiplayerSynchronizer.new()
	sync.name = "MultiplayerSynchronizer"
	
	var rep_config = SceneReplicationConfig.new()
	rep_config.add_property(NodePath(":position"))
	rep_config.add_property(NodePath(":rotation"))
	sync.replication_config = rep_config
	
	root.add_child(sync)
	sync.owner = root
	
	# Script
	root.set_script(load("res://scripts/entities/Watcher.gd"))
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/entities/Watcher.tscn")
	print("Saved Watcher.tscn successfully!")
	quit()
