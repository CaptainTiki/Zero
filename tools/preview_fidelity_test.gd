extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	var room = load("res://scenes/fidelity_test.tscn").instantiate()
	root.add_child(room)
	room.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	room.get_node("Player").hide()
	room.get_node("Player/HUD").hide()
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.fov = 75
	var folder := "res://art/material_studies/room_previews_v2"
	DirAccess.make_dir_recursive_absolute(folder)
	var shots := [
		["01_room",Vector3(-1.8,1.7,4.8),Vector3(0.0,1.65,-4.5)],
		["02_reception",Vector3(1.5,1.7,0.8),Vector3(-4,1.3,-3.5)],
		["03_wear",Vector3(2.3,1.65,-1.5),Vector3(5.7,1.25,-4.4)],
		["04_cabinet",Vector3(3.65,1.65,0.0),Vector3(5.55,1.65,-1.6)],
		["05_counter",Vector3(-2.2,1.65,0.2),Vector3(-3.9,0.9,-1.8)]]
	for shot in shots:
		camera.position = shot[1]
		camera.look_at(shot[2])
		for i in 12:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg(folder+"/"+shot[0]+".jpg",0.93)
	print("FIDELITY ROOM PREVIEW PASS")
	quit()
