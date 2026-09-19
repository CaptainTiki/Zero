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
	var folder := "res://art/material_studies/factory_hall_" + phase
	if "--brick-approved" in OS.get_cmdline_user_args():
		folder = "res://art/material_studies/factory_brick_approved"
	DirAccess.make_dir_recursive_absolute(folder)
	for shot in [
		["01_floor", Vector3(-29,1.7,-29), Vector3(-43,6,-66)],
		["02_brick_wall", Vector3(-17,1.7,-57), Vector3(-8.3,6,-43)],
		["03_catwalk", Vector3(-58,5.7,-69), Vector3(-25,4,-38)],
		["04_upper_wall", Vector3(-18.5,9.7,-61), Vector3(-43,8,-69.8)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		for i in 120:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg(folder + "/" + shot[0] + ".jpg", 0.93)
	print("FACTORY HALL PREVIEW ", phase, " PASS")
	quit()
