extends "res://tools/art_kit.gd"
## Editable comparison room; regenerate to replace the saved test scene.
func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	art.name = "TextureCandidates"
	var plain := StandardMaterial3D.new()
	plain.albedo_color = Color(0.24, 0.25, 0.25)
	plain.roughness = 1.0
	_mats["floor_test"] = plain
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color(0.12, 0.25, 0.24)
	trim.roughness = 1.0
	_mats["trim_test"] = trim
	var names := ["plastered_wall_04", "concrete_wall_007", "painted_metal_shutter", "red_brick", "floor_tiles_06"]
	var labels := ["PLASTER 04", "CONCRETE 007", "METAL SHUTTER", "RED BRICK", "FLOOR TILES 06"]
	for i in names.size():
		var material := ShaderMaterial.new()
		material.shader = load("res://materials/fidelity/filter_blend.gdshader")
		var texture = load("res://art/material_studies/cc0_candidates/" + names[i] + "/albedo_128.png")
		material.set_shader_parameter("soft_texture", texture)
		material.set_shader_parameter("softness", 0.5)
		_mats[names[i]] = material
		var x := (float(i) - 2.0) * 5.0
		material.set_shader_parameter("sample_origin", Vector3(x, 0, 0))
		box(names[i] + "Wall", Vector3(x, 2, -4), Vector3(4.8, 4, 0.25), names[i], 0, true)
		box(names[i] + "Return", Vector3(x - 2.3, 2, -2.5), Vector3(0.2, 4, 3), names[i], 0, true)
		box(names[i] + "Skirting", Vector3(x, 0.3, -3.84), Vector3(4.6, 0.6, 0.08), "trim_test")
		box(names[i] + "ReturnSkirting", Vector3(x - 2.16, 0.3, -2.5), Vector3(0.08, 0.6, 3), "trim_test")
		sign_board(names[i] + "Label", labels[i], Vector3(x, 3.4, -3.7), 3.8, 0, "trim_test", Color(0.95, 0.9, 0.75), 0.35)
	box("Floor", Vector3(0, -0.15, 0), Vector3(32, 0.3, 15), "floor_test", 0, true)
	box("BackWall", Vector3(0, 2, 7.4), Vector3(32, 4, 0.2), "floor_test", 0, true)
	for x in [-15.9, 15.9]:
		box("Boundary" + str(x), Vector3(x, 2, 1.7), Vector3(0.2, 4, 11.5), "floor_test", 0, true)
	var environment_node := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.23, 0.26, 0.29)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.9, 0.93, 1.0)
	settings.ambient_light_energy = 0.45
	environment_node.environment = settings
	add(environment_node, "WorldEnvironment")
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -25, 0)
	sun.light_energy = 0.35
	sun.shadow_enabled = true
	add(sun, "Sun")
	var player = load("res://scenes/player/player.tscn").instantiate()
	player.position = Vector3(0, 0.1, 4)
	add(player, "Player")
	save_scene("res://scenes/fidelity_texture_candidates.tscn")
	quit()
