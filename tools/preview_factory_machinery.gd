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
	var phase := "machinery"
	var folder := "res://art/material_studies/factory_machinery"
	DirAccess.make_dir_recursive_absolute(folder)
	for shot in [
		["01_press",Vector3(-29,3.0,-28),Vector3(-22.5,2.6,-37.5)],
		["02_washer",Vector3(-41.5,-1.6,-51),Vector3(-47,-2.4,-56.5)],
		["03_conveyor",Vector3(-29,2.8,-59),Vector3(-39,0.8,-65)],
		["04_hoppers",Vector3(-49,7,-53),Vector3(-57,3.5,-62)],
		["05_cases",Vector3(-52.5,2.7,-38),Vector3(-48,1.5,-30)],
		["06_room",Vector3(-58,5.7,-53),Vector3(-35,5.5,-26.3)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		for i in 120:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg(folder + "/" + shot[0] + ".jpg", 0.93)
	print("FACTORY MACHINERY PREVIEW ", phase, " PASS")
	quit()
