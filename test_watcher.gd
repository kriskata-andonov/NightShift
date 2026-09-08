extends SceneTree

func _init():
	var watcher_scene = load("res://scenes/entities/Watcher.tscn")
	var watcher = watcher_scene.instantiate()
	root.add_child(watcher)
	watcher.position = Vector3(18, 1.5, -23)
	
	var player = CharacterBody3D.new()
	player.name = "TestPlayer"
	player.add_to_group("players")
	player.position = Vector3(0, 2, 0)
	
	var head = Node3D.new()
	head.name = "Head"
	player.add_child(head)
	
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	head.add_child(camera)
	
	var flashlight = SpotLight3D.new()
	flashlight.name = "Flashlight"
	camera.add_child(flashlight)
	
	root.add_child(player)
	
	print("Watcher start pos: ", watcher.position)
	
	# Wait one frame for physics nodes to register
	await process_frame
	
	# Run 60 frames
	for i in range(60):
		watcher._physics_process(0.016)
		
	print("Watcher end pos: ", watcher.position)
	quit()
