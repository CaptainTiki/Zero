extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var level = load("res://scenes/levels/m01_beats_1_5.tscn").instantiate()
	root.add_child(level)
	level.process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("Player/HUD").hide()
	level.get_node("Player").hide()
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.fov = 75
	var shots := [["crash", Vector3(-2, 2.0, 5), Vector3(6, 2.5, -6)], ["lane", Vector3(13, 1.8, 2), Vector3(29, 2.8, -3)], ["checkpoint", Vector3(43, 2, -1), Vector3(49, 2.1, 7)]]
	for shot in shots:
		camera.position = shot[1]
		camera.look_at(shot[2])
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/art_" + shot[0] + ".png")
	level.queue_free()
	camera.queue_free()
	await process_frame
	quit()
