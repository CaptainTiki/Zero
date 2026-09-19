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
	var phase := "feedback"
	var folder := "res://art/material_studies/factory_hall_feedback"
	DirAccess.make_dir_recursive_absolute(folder)
	for shot in [
		["01_cases",Vector3(-52.244,1.601,-34.84),Vector3(-49.787,1.578,-32)],
		["02_press_open",Vector3(-21.47,1.601,-31.404),Vector3(-22.357,2.216,-35)],
		["03_production_sign",Vector3(-32.989,1.601,-61.306),Vector3(-37,6.6,-69.72)],
		["04_delivery",Vector3(-41.06,1.601,-60.111),Vector3(-44.406,-1,-57.005)],
		["05_incident_sign",Vector3(-42.121,1.601,-31.599),Vector3(-42.433,5.8,-26.2)],
		["06_doorway",Vector3(-31.492,1.601,-31.394),Vector3(-30.623,3.427,-26.2)],
		["07_forklift",Vector3(-31.5,-1.7,-45.5),Vector3(-28,-2.5,-50.5)],
		["08_press_down",Vector3(-29,3,-28),Vector3(-22.5,3.3,-37.5)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		var press := level.get_node("HallMachinery/Blocker51PressA")
		press.set_pose(1.0 if shot[0]=="08_press_down" else 0.0)
		for i in 120:
			await process_frame
		if shot[0]=="08_press_down":
			var steam := press.get_node("ExhaustSteam")
			steam.process_mode = Node.PROCESS_MODE_ALWAYS
			steam.restart()
			for i in 25: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg(folder + "/" + shot[0] + ".jpg", 0.93)
	print("FACTORY MACHINERY PREVIEW ", phase, " PASS")
	quit()
