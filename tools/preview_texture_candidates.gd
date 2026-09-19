extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(512, 512)
	var room = load("res://scenes/fidelity_texture_candidates.tscn").instantiate()
	root.add_child(room)
	room.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	room.get_node("Player").hide()
	room.get_node("Player/HUD").hide()
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.0
	room.get_node("Sun").shadow_enabled = false
	for node in room.get_children():
		if node is VisualInstance3D and ("Label" in node.name or "Skirting" in node.name or String(node.name).ends_with("Return")):
			node.hide()
	var names := ["plastered_wall_04", "concrete_wall_007", "painted_metal_shutter", "red_brick", "floor_tiles_06"]
	for j in names.size():
		var x := (float(j) - 2.0) * 5.0
		camera.position = Vector3(x, 2.0, -1)
		camera.look_at(Vector3(x, 2.0, -4))
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/candidate_" + names[j] + ".png")
	print("FIDELITY PREVIEW PASS")
	quit()
