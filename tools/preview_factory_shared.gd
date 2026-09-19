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
	var folder := "res://art/material_studies/factory_shared_finishes"
	DirAccess.make_dir_recursive_absolute(folder)
	for shot in [
		["01_tank_house",Vector3(-18.5,9.6,-89),Vector3(-25,6,-108)],
		["02_tank_lower",Vector3(-32,1.6,-91),Vector3(-19,7,-111)],
		["03_mixing",Vector3(-13,-2.4,-133),Vector3(-10,0,-152)],
		["04_compressor",Vector3(19,-2.4,-141),Vector3(46,0,-155)],
		["05_service_tunnel",Vector3(8,-2.4,-92),Vector3(8,-2.4,-81)],
		["06_plant",Vector3(68,1.6,-118),Vector3(47,6,-96)],
		["07_round_platform",Vector3(47.25,9.6,-86),Vector3(47,8,-99)],
		["08_warehouse",Vector3(48,9.6,-60),Vector3(66,4,-37)],
		["09_dock",Vector3(36,2.8,2),Vector3(67,3,-8)],
		["10_yard",Vector3(-25,1.6,8),Vector3(-30,4,-26)]]:
		if "--round-only" in OS.get_cmdline_user_args() and shot[0]!="07_round_platform": continue
		camera.position = shot[1]
		camera.look_at(shot[2])
		for i in 120:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg(folder + "/" + shot[0] + ".jpg", 0.93)
	print("FACTORY SHARED FINISHES PREVIEW PASS")
	quit()
