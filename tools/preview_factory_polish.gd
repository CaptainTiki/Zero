extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var level: Node = load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(level)
	level.process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("Player").hide()
	level.get_node("Player/HUD").hide()
	for node in level.get_children():
		if node is CanvasLayer:
			node.hide()
	for enemy in get_nodes_in_group("enemies"):
		if enemy is Node3D:
			enemy.hide()
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.fov = 75
	var phase := "before" if "--before" in OS.get_cmdline_user_args() else "after"
	var folder := "res://art/material_studies/factory_polish/"+phase
	DirAccess.make_dir_recursive_absolute(folder)
	var markers: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/material_studies/factory_polish/markers.json"))
	for marker in markers:
		camera.position = Vector3(marker.camera_position[0],marker.camera_position[1],marker.camera_position[2])
		camera.look_at(camera.position+Vector3(marker.facing[0],marker.facing[1],marker.facing[2]))
		for i in 120:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg(folder + "/" + marker.label + ".jpg", 0.93)
	print("FACTORY POLISH PREVIEW PASS")
	quit()
