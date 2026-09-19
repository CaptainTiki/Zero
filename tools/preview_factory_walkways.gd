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
	var folder := "res://art/material_studies/factory_walkways_" + phase
	DirAccess.make_dir_recursive_absolute(folder)
	for shot in [
		["01_catwalk",Vector3(-58,5.7,-69),Vector3(-25,4,-38)],
		["02_grating",Vector3(-34,5.7,-63),Vector3(-34,3.6,-58)],
		["03_stair",Vector3(-60.75,2.7,-33),Vector3(-60.75,4.0,-41)],
		["04_marker_floor177",Vector3(-43.733,1.601,-41.592),Vector3(-45.048,0,-41.942)],
		["05_marker_floor168",Vector3(-52.81,1.601,-55.589),Vector3(-52.458,0,-56.641)],
		["06_service_mouth",Vector3(-51,-2.3,-58),Vector3(-55,-2.3,-58)],
		["07_service_corridor",Vector3(-56,-2.3,-62),Vector3(-56,-2.3,-70)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		for i in 18:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg(folder + "/" + shot[0] + ".jpg", 0.93)
	print("FACTORY WALKWAYS PREVIEW ", phase, " PASS")
	quit()
