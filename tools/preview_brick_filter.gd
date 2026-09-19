extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(896, 560)
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
	if phase == "before":
		# Reproduce the old forced-base-level shader in this transient preview only.
		var code := FileAccess.get_file_as_string("res://materials/fidelity/factory_surface.gdshader")
		code = code.replace("filter_linear_mipmap_anisotropic", "filter_linear")
		var start := code.find("    // Preserve the chosen pixel blend")
		var finish := code.find("\n}",start)
		code = code.substr(0,start)+"    return mix(textureLod(soft_texture, center, 0.0).rgb, textureLod(soft_texture, uv, 0.0).rgb, softness);"+code.substr(finish)
		for tex in ["normal_texture","roughness_texture"]:
			for uv in ["uvx","uvy","uvz"]:
				code = code.replace("texture("+tex+","+uv+")","textureLod("+tex+","+uv+",0.0)")
		var legacy := Shader.new()
		legacy.code = code
		for node in level.find_children("*","MeshInstance3D",true,false):
			var material = node.material_override
			if material is ShaderMaterial and material.shader.resource_path.ends_with("factory_surface.gdshader"):
				node.material_override = material.duplicate()
				node.material_override.shader = legacy
	var folder := "res://art/material_studies/brick_filter_"+phase
	DirAccess.make_dir_recursive_absolute(folder)
	for shot in [
		["01_distance",Vector3(-59,5.7,-60),Vector3(-40,5.5,-26.3)],
		["02_angle",Vector3(-17,1.7,-57),Vector3(-8.3,6,-43)],
		["03_close",Vector3(-8.9,1.7,-43),Vector3(-8,1.7,-43)],
		["04_distance_step",Vector3(-58.96,5.7,-60),Vector3(-39.96,5.5,-26.3)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		for i in 120:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder + "/" + shot[0] + ".png")
	print("BRICK DISTANCE FILTER PREVIEW ", phase, " PASS")
	quit()
