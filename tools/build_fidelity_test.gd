extends "res://tools/art_kit.gd"
## Reception / loading room base. The public fidelity_test scene retains editor dressing.
## See docs/LEVEL_EDITING.md; only scenes/generated/fidelity_test.tscn is replaced.
func _initialize() -> void:
	call_deferred("build")

func surface(key: String, asset: String, repeat_size: float, tint := Color.WHITE) -> void:
	var material := ShaderMaterial.new()
	material.shader = load("res://materials/fidelity/room_surface.gdshader")
	material.set_shader_parameter("soft_texture", load("res://art/material_studies/cc0_candidates/" + asset + "/albedo_128.png"))
	material.set_shader_parameter("softness", 0.5)
	material.set_shader_parameter("repeat_metres", repeat_size)
	material.set_shader_parameter("tint", tint)
	_mats[key] = material

func plain(key: String, tint: Color, glowing := false) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.9
	if glowing:
		material.emission_enabled = true
		material.emission = tint
		material.emission_energy_multiplier = 1.3
	_mats[key] = material

func patch(label: String, at: Vector3, size: Vector2, angle: Vector3, chip: bool, tint: Color, variation: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = load("res://materials/fidelity/placed_wear.gdshader")
	material.set_shader_parameter("undercoat", load("res://art/material_studies/cc0_candidates/concrete_wall_007/albedo_128.png"))
	material.set_shader_parameter("pigment", tint)
	material.set_shader_parameter("chipped", chip)
	material.set_shader_parameter("seed", variation)
	var mesh := QuadMesh.new()
	mesh.size = size
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.rotation_degrees = angle
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_to_group("surface_wear", true)
	add(node, label)

func lamp(label: String, at: Vector3, tint: Color, energy: float) -> void:
	var housing := box(label+"Housing", at, Vector3(1.6, 0.13, 0.4), "dark")
	housing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var diffuser := box(label+"Diffuser", at-Vector3(0, 0.075, 0), Vector3(1.4, 0.04, 0.28), "light")
	diffuser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light := OmniLight3D.new()
	light.position = at-Vector3(0, 0.35, 0)
	light.light_color = tint
	light.light_energy = energy
	light.omni_range = 9.0
	light.shadow_enabled = true
	add(light, label+"Light")

func build() -> void:
	art.name = "FidelityRoom"
	surface("plaster", "plastered_wall_04", 3.2, Color(1.0, 0.95, 0.84))
	surface("concrete", "Concrete034", 3.2, Color(0.48, 0.51, 0.51))
	mat("concrete").set_shader_parameter("rectangular_texture", true)
	surface("brick", "red_brick", 2.8)
	surface("shutter", "painted_metal_shutter", 2.0, Color(0.64, 0.78, 0.76))
	surface("tiles", "floor_tiles_06", 3.0)
	surface("teal", "Metal038", 0.8, Color(0.23, 0.43, 0.39))
	mat("teal").set_shader_parameter("painted_finish", true)
	surface("dark", "Metal038", 0.7, Color(0.15, 0.18, 0.19))
	mat("dark").set_shader_parameter("painted_finish", true)
	surface("rim", "Metal038", 0.6, Color(0.32, 0.47, 0.43))
	mat("rim").set_shader_parameter("painted_finish", true)
	plain("paper", Color(0.75, 0.7, 0.55))
	surface("light", "Concrete034", 0.5, Color(1.0, 0.92, 0.77))
	mat("light").set_shader_parameter("emission_strength", 1.0)
	mat("light").set_shader_parameter("diffuser_ribs", true)
	for key in ["brick","teal","dark","rim"]:
		var asset := "red_brick" if key=="brick" else "Metal038"
		var material := mat(key) as ShaderMaterial
		material.set_shader_parameter("normal_texture",load("res://art/material_studies/cc0_candidates/"+asset+"/normal_128.png"))
		material.set_shader_parameter("roughness_texture",load("res://art/material_studies/cc0_candidates/"+asset+"/roughness_128.png"))
		material.set_shader_parameter("surface_maps",true)
		material.set_shader_parameter("bump_strength",0.1)
		material.set_shader_parameter("roughness_range",Vector2(0.88,1.0) if key=="brick" else Vector2(0.5,0.85))
	# Flush floor regions; the seam is a material change, not a movement lip.
	box("ReceptionFloor", Vector3(-3, -0.15, 0), Vector3(6, 0.3, 14), "tiles", 0, true)
	box("LoadingFloor", Vector3(3, -0.15, 0), Vector3(6, 0.3, 14), "concrete", 0, true)
	box("WestPlaster", Vector3(-6, 2, 0), Vector3(0.3, 4, 14), "plaster", 0, true)
	box("EastPlaster", Vector3(6, 2, 0), Vector3(0.3, 4, 14), "plaster", 0, true)
	box("EntryPlaster", Vector3(0, 2, 7), Vector3(12, 4, 0.3), "plaster", 0, true)
	box("NorthBrick", Vector3(0, 2, -7), Vector3(12, 4, 0.3), "brick", 0, true)
	box("Ceiling", Vector3(0, 4.15, 0), Vector3(12, 0.3, 14), "plaster", 0, true)
	for x in [-5.81, 5.81]:
		box("Skirting"+str(x), Vector3(x, 0.12, 0), Vector3(0.08, 0.24, 13.7), "teal")
		box("Dado"+str(x), Vector3(x, 1.05, 0), Vector3(0.04, 0.055, 13.7), "teal")
	# Reception desk and a support pier split the room without closing the walk.
	box("ReceptionCounter", Vector3(-3.8, 0.58, -1.8), Vector3(3.0, 1.16, 0.85), "teal", 0, true)
	box("CounterTop", Vector3(-3.8, 1.19, -1.8), Vector3(3.15, 0.09, 1.0), "dark")
	box("Ledger", Vector3(-3.65, 1.26, -1.8), Vector3(0.42, 0.045, 0.3), "paper")
	box("Pier", Vector3(-0.1, 2, -3.6), Vector3(0.45, 4, 0.6), "concrete", 0, true)
	box("ShutterFrame", Vector3(2.5, 1.7, -6.72), Vector3(4.1, 3.4, 0.2), "dark")
	box("ClosedShutter", Vector3(2.5, 1.6, -6.58), Vector3(3.65, 3.0, 0.08), "shutter")
	box("ShutterHandle", Vector3(2.5, 0.5, -6.47), Vector3(0.5, 0.08, 0.08), "dark")
	for z in [-4.5, 1.5]:
		box("RoofBeam"+str(z), Vector3(0, 3.86, z), Vector3(11.7, 0.24, 0.18), "teal")
	pipe("ServicePipe", Vector3(5.60, 1.95, -4.6), 3.9, 0.10, "teal")
	for y in [0.6, 2.0, 3.35]:
		box("PipeBracket"+str(y), Vector3(5.68, y, -4.6), Vector3(0.3, 0.08, 0.3), "dark")
	box("ElectricalCabinet", Vector3(5.62, 1.6, -1.6), Vector3(0.42, 1.15, 0.8), "teal", 0, true)
	sign_board("ReceptionSign", "JOHN & JOHN / RECEPTION", Vector3(-3.1, 2.8, -6.65), 4.3, 0, "teal", Color(0.91, 0.85, 0.64), 0.48)
	sign_board("ShutterSign", "GOODS IN / NOTHING OUT", Vector3(2.5, 3.55, -6.5), 3.9, 0, "dark", Color(0.91, 0.85, 0.64), 0.35)
	# Only soft grime overlays remain. Cracks are opaque wall materials below.
	patch("PipeDampHalo", Vector3(5.835, 1.15, -4.6), Vector2(1.3, 2.3), Vector3(0,-90,0), false, Color(0.18,0.17,0.12,0.30), 2)
	patch("CabinetContact", Vector3(5.833, 1.6, -1.6), Vector2(1.12,1.5), Vector3(0,-90,0), false, Color(0.06,0.07,0.06,0.48), 4)
	patch("ReceptionChairScuff", Vector3(-5.83, 0.8, -2.7), Vector2(1.8,0.9), Vector3(0,90,0), false, Color(0.20,0.18,0.14,0.28), 14)
	patch("FloorPipeStain", Vector3(5.5,0.006,-4.6), Vector2(1.0,1.4), Vector3(-90,0,0), false, Color(0.16,0.14,0.10,0.28), 5)
	patch("CounterFootContact", Vector3(-3.8,0.005,-1.8), Vector2(4.1,1.65), Vector3(-90,0,0), false, Color(0.08,0.08,0.06,0.35), 6)
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.12,0.15,0.18)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.80,0.86,1.0)
	settings.ambient_light_energy = 0.42
	env.environment = settings
	add(env,"WorldEnvironment")
	lamp("ReceptionLamp",Vector3(-3,3.65,0),Color(1,0.88,0.7),1.6)
	lamp("LoadingLamp",Vector3(3,3.65,-3.6),Color(0.78,0.88,1),1.4)
	lamp("EntryLamp",Vector3(2,3.65,4.5),Color(1,0.91,0.78),1.4)
	refine_props()
	add_cracked_wall_panels()
	var player = load("res://scenes/player/player.tscn").instantiate()
	player.position = Vector3(-1.8,0.1,4.8)
	add(player,"Player")
	save_scene("res://scenes/generated/fidelity_test.tscn")
	quit()

func beveled_mesh(size: Vector3, amount: float, material: Material) -> ArrayMesh:
	return preload("res://tools/fidelity_mesh.gd").beveled_mesh(size, amount, material)

func tube(label: String, at: Vector3, height: float, radius: float, material: String, angles := Vector3.ZERO) -> void:
	var node := pipe(label,at,height,radius,material)
	(node.mesh as CylinderMesh).radial_segments = 12
	node.rotation_degrees = angles

func add_cracked_wall_panels() -> void:
	# Split visible surfaces only. Original wall collision stays intact.
	for spec in [["WestPlaster",-6.0,-2.9,1],["EastPlaster",6.0,-4.5,2]]:
		var old := art.get_node(String(spec[0])) as MeshInstance3D
		old.hide()
		var x: float = spec[1]
		var crack_z: float = spec[2]
		var variant := mat("plaster").duplicate() as ShaderMaterial
		variant.set_shader_parameter("crack_variant",spec[3])
		variant.set_shader_parameter("crack_origin",Vector3(x,1.6,crack_z))
		var key := String(spec[0])+"Cracked"
		_mats[key] = variant
		var low := crack_z-0.8
		var high := crack_z+0.8
		box(key+"Before",Vector3(x,2,(-7.0+low)*0.5),Vector3(0.3,4,low+7.0),"plaster")
		box(key+"Panel",Vector3(x,2,crack_z),Vector3(0.3,4,1.6),key)
		box(key+"After",Vector3(x,2,(high+7.0)*0.5),Vector3(0.3,4,7.0-high),"plaster")

func refine_props() -> void:
	# A little silhouette detail; collision remains the original simple boxes.
	var counter := art.get_node("ReceptionCounter") as MeshInstance3D
	counter.mesh = counter.mesh.duplicate()
	(counter.mesh as BoxMesh).size = Vector3(2.9,1.04,0.81)
	counter.position.y = 0.61
	box("CounterPlinth",Vector3(-3.8,0.075,-1.8),Vector3(2.88,0.15,0.78),"dark")
	for x in [-4.75,-3.8,-2.85]:
		box("CounterPanel"+str(x),Vector3(x,0.63,-1.367),Vector3(0.88,0.85,0.035),"rim")
		box("CounterInset"+str(x),Vector3(x,0.63,-1.34),Vector3(0.77,0.72,0.028),"teal")
	box("CounterLip",Vector3(-3.8,1.14,-1.3),Vector3(3.05,0.06,0.045),"rim")
	# Low wall panelling under the rail: seams establish construction and scale.
	for side in [-1.0,1.0]:
		box("PanelBacking"+str(side),Vector3(side*5.838,0.63,0),Vector3(0.018,0.77,13.7),"dark")
		for i in 9:
			var z := -6.1+float(i)*1.5
			box("WallPanel"+str(side)+"_"+str(i),Vector3(side*5.81,0.63,z),Vector3(0.045,0.77,1.44),"teal")
	# Door frame, recessed panel, lock and hinges on the inward face.
	box("CabinetGasket",Vector3(5.397,1.6,-1.6),Vector3(0.035,1.06,0.72),"dark")
	box("CabinetDoor",Vector3(5.37,1.6,-1.6),Vector3(0.038,0.99,0.65),"rim")
	box("CabinetInset",Vector3(5.345,1.60,-1.6),Vector3(0.018,0.88,0.55),"teal")
	for y in [1.26,1.92]:
		tube("CabinetHinge"+str(y),Vector3(5.33,y,-1.92),0.12,0.027,"dark")
	tube("CabinetLock",Vector3(5.32,1.59,-1.35),0.03,0.035,"dark",Vector3(0,0,90))
	for i in 4:
		box("CabinetVent"+str(i),Vector3(5.33,1.28+float(i)*0.055,-1.63),Vector3(0.015,0.023,0.29),"dark")
	# Pipe collars and capped fasteners. Twelve-sided pipe rather than eight.
	(art.get_node("ServicePipe").mesh as CylinderMesh).radial_segments = 12
	for y in [0.18,1.12,2.65,3.68]:
		tube("PipeCollar"+str(y),Vector3(5.60,y,-4.6),0.14,0.135,"rim")
	for y in [0.6,2.0,3.35]:
		for z in [-4.71,-4.49]:
			tube("BracketBolt"+str(y)+str(z),Vector3(5.51,y,z),0.035,0.023,"rim",Vector3(0,0,90))
	tube("PipeFoot",Vector3(5.60,0.07,-4.6),0.12,0.18,"dark")
	# Fixture rims, end caps, ribbed diffuser and ceiling mounts.
	for label in ["ReceptionLamp","LoadingLamp","EntryLamp"]:
		var at: Vector3 = art.get_node(label+"Housing").position
		for sign_value in [-1.0,1.0]:
			box(label+"End"+str(sign_value),at+Vector3(sign_value*0.74,-0.04,0),Vector3(0.14,0.15,0.43),"rim")
			box(label+"Rim"+str(sign_value),at+Vector3(0,-0.085,sign_value*0.17),Vector3(1.4,0.065,0.045),"teal")
			box(label+"Mount"+str(sign_value),at+Vector3(sign_value*0.48,0.18,0),Vector3(0.13,0.3,0.13),"dark")
	# Chamfer props only, leaving room shells and flat trim panels simple.
	var triangles := 0
	var bevels := 0
	for node in art.get_children():
		if node is MeshInstance3D and node.mesh is BoxMesh:
			var mesh := node.mesh as BoxMesh
			var label := String(node.name)
			if label.begins_with("Counter") or label.begins_with("Cabinet") or label=="ElectricalCabinet" or label=="ReceptionCounter" or "Lamp" in label or label=="ShutterHandle":
				node.mesh = beveled_mesh(mesh.size,0.025,mesh.material)
				if "Lamp" in label:
					node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				bevels += 1
				triangles += 44
	print("Refined props: ",bevels," chamfered meshes, ",triangles," triangles in those meshes; 12-sided pipe/collars.")
