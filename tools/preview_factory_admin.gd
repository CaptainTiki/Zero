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
	var folder := "res://art/material_studies/factory_admin_" + phase
	DirAccess.make_dir_recursive_absolute(folder)
	for shot in [
		["01_entrance", Vector3(-69,1.7,56), Vector3(-75,2.3,48)],
		["02_reception", Vector3(-70,1.7,46), Vector3(-72,1.5,36)],
		["03_corridor", Vector3(-85,1.7,37), Vector3(-85,1.6,28)],
		["04_office", Vector3(-62,1.7,8), Vector3(-66,1.5,22)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		for i in 18:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg(folder + "/" + shot[0] + ".jpg", 0.93)
	print("FACTORY ADMIN PREVIEW ", phase, " PASS")
	quit()
