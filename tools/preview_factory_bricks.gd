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
	var folder := "res://art/material_studies/brick_comparison"
	DirAccess.make_dir_recursive_absolute(folder)
	var walls: Array[MeshInstance3D] = []
	var reference: ShaderMaterial
	for node in level.get_children():
		if node is MeshInstance3D and node.get_meta("art_zone","") == "production_hall" and node.material_override is ShaderMaterial:
			var texture = node.material_override.get_shader_parameter("soft_texture")
			if texture is Texture2D and ("/red_brick/" in texture.resource_path or "/Bricks005/" in texture.resource_path):
				walls.append(node)
				reference = node.material_override
	if walls.is_empty():
		push_error("No hall brick walls found")
		quit(1)
		return
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var label := Label.new()
	label.position = Vector2(24,20)
	label.add_theme_font_size_override("font_size",24)
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",2)
	label.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(label)
	for candidate in [
		["A_current","Current brick | existing 2.8m repeat","red_brick",2.8],
		["B_current_scale","Current brick | source scale 1.4m","red_brick",1.4],
		["C_clean","Cleaner brick | same 2.8m repeat","Bricks005",2.8],
		["D_clean_scale","Cleaner brick | smaller bricks, 1.5m repeat","Bricks005",1.5]]:
		var material := reference.duplicate() as ShaderMaterial
		var asset: String = "res://art/material_studies/cc0_candidates/"+candidate[2]+"/"
		material.set_shader_parameter("soft_texture",load(asset+"albedo_128.png"))
		material.set_shader_parameter("normal_texture",load(asset+"normal_128.png"))
		material.set_shader_parameter("roughness_texture",load(asset+"roughness_128.png"))
		material.set_shader_parameter("repeat_metres",candidate[3])
		for wall in walls: wall.material_override = material
		label.text = candidate[1]+"\n128px | 50% filtering | 0.1 normal strength"
		for shot in [
			["wide",Vector3(-17,1.7,-57),Vector3(-8.3,6,-43)],
			["near",Vector3(-11,1.7,-43),Vector3(-8,2.3,-43)]]:
			camera.position = shot[1]
			camera.look_at(shot[2])
			for i in 120: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(folder+"/"+candidate[0]+"_"+shot[0]+".jpg",0.93)
	print("BRICK COMPARISON: PASS (",walls.size()," hall walls, 4 candidates, 8 views)")
	quit()
