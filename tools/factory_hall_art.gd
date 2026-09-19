extends "res://tools/factory_admin_art.gd"
## Large-wall review sample. Reuses the approved palette helpers, not the admin layout.
func inside(p: Vector3) -> bool:
	return p.x >= -62.21 and p.x <= -7.79 and p.z >= -70.21 and p.z <= -25.79

func apply(builder: SceneTree) -> void:
	kit = builder
	details = Node3D.new()
	kit.add(details, "HallArt")
	make_palette()
	var originals: Array = kit.art.get_children()
	for node in originals:
		if not node is MeshInstance3D or not inside(node.position):
			continue
		var p: Vector3 = node.position
		var label := str(node.name)
		# The service tunnel under the hall is outside this room's visual sample.
		if p.y < -0.4 and not (p.x >= -52.21 and p.x <= -23.79 and p.z >= -60.21 and p.z <= -41.79):
			continue
		var key := ""
		if label.begins_with("Wall"):
			key = "brick" if is_equal_approx(p.x,-62.0) or is_equal_approx(p.x,-8.0) or is_equal_approx(p.z,-26.0) else "plaster"
		elif label.begins_with("Floor"):
			key = "pit" if p.y < -1.0 else ("dark" if p.y > 1.0 else "concrete")
		elif label.begins_with("Roof"):
			key = "ceiling"
		elif label.begins_with("Rail") or label.begins_with("Stair"):
			key = "teal"
		elif label.begins_with("Blocker"):
			key = "teal"
			if node.mesh is BoxMesh:
				var size: Vector3 = node.mesh.size
				node.mesh = MeshKit.beveled_mesh(size,0.035,materials.teal)
		elif label.begins_with("Sign"):
			key = "teal" if node.mesh is BoxMesh and node.mesh.material.resource_path.ends_with("/teal.tres") else "cream"
		if key != "":
			node.material_override = materials[key]
			node.set_meta("art_zone","production_hall")
	for node in originals:
		if node is OmniLight3D and inside(node.position) and node.position.y > 10.0:
			node.shadow_enabled = true
			node.light_energy = 5.2
			high_fixture(str(node.name),node.position)
	structure()
	signs_and_doorways()
	preload("res://tools/factory_hall_machinery.gd").new().build_machinery(self)
	preload("res://tools/factory_hall_walkways.gd").new().build_walkways(self, JSON.parse_string(FileAccess.get_file_as_string("res://docs/factory_plan/plan.json")))
	print("FACTORY HALL ART: ", details.get_child_count(), " saved details; large wall spans retained")

func structure() -> void:
	# Narrow ribs frame full-height expanses rather than masking repeated textures.
	for x in [-61.88,-8.12]:
		for z in [-69.65,-59.0,-48.0,-37.0,-26.35]:
			block("WallColumn"+str(x)+str(z),Vector3(x,6.45,z),Vector3(0.24,12.9,0.25),"dark",0.015)
	for x in [-61.0,-49.0,-37.0,-25.0]:
		block("NorthColumn"+str(x),Vector3(x,6.45,-69.88),Vector3(0.25,12.9,0.24),"dark",0.015)
	for z in [-59.0,-48.0,-37.0]:
		block("RoofBeam"+str(z),Vector3(-35,12.75,z),Vector3(53.5,0.42,0.24),"dark")
	# Upper horizontal beam above every doorway; nothing spans walkable openings.
	block("NorthHeader",Vector3(-35,12.7,-69.85),Vector3(53.5,0.25,0.3),"rim")
	for x in [-61.85,-8.15]:
		block("SideHeader"+str(x),Vector3(x,12.7,-48),Vector3(0.3,0.25,43.5),"rim")

func high_fixture(label: String, at: Vector3) -> void:
	kit.art.get_node(label+"Fix").hide()
	kit.art.get_node(label+"Fix").set_meta("fixture_replaced",true)
	var node: Node3D=load("res://scenes/props/factory/fittings/fixture_high.tscn").instantiate()
	node.position=at
	kit.add(node,label+"Fixture",details)

func signs_and_doorways() -> void:
	# Sign assets own their board dimensions, materials and lettering.
	var parent := details
	details = Node3D.new()
	kit.add(details,"HallDoorFrames")
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/factory_plan/plan.json"))
	for door in plan.door_frames:
		var at := Vector3(door.at[0],door.at[1],door.at[2])
		if not inside(at): continue
		var along := Vector3.RIGHT if door.along_x else Vector3.BACK
		var width: float = door.width
		var height: float = door.height
		var post_size := Vector3(0.44,height,0.58) if door.along_x else Vector3(0.58,height,0.44)
		var beam_size := Vector3(width+0.44,0.22,0.58) if door.along_x else Vector3(0.58,0.22,width+0.44)
		for side in [-1.0,1.0]:
			block(String(door.name).to_pascal_case()+"Jamb"+str(side),at+along*side*(width/2.0)+Vector3(0,height/2.0,0),post_size,"rim",0.018)
		block(String(door.name).to_pascal_case()+"Lintel",at+Vector3(0,height+0.09,0),beam_size,"rim",0.018)
	details = parent

func make_palette() -> void:
	surface("plaster", "plastered_wall_04", 3.2, Color(0.88,0.86,0.77))
	surface("brick", "Bricks005", 2.8, Color(0.84,0.83,0.77), true)
	surface("concrete", "Concrete034", 3.2, Color(0.48,0.51,0.51))
	surface("ceiling", "plastered_wall_04", 3.2, Color(0.46,0.49,0.47))
	surface("teal", "Metal038", 0.8, Color(0.23,0.43,0.39), true, true)
	surface("rim", "Metal038", 0.7, Color(0.32,0.47,0.43), true, true)
	surface("dark", "Metal038", 0.7, Color(0.15,0.18,0.19), true, true)
	surface("cream", "Metal038", 0.8, Color(0.63,0.59,0.47), true, true)
	surface("light", "Concrete034", 0.5, Color(0.95,0.98,1.0))
	materials.light.set_shader_parameter("emission_strength",1.0)
	materials.light.set_shader_parameter("diffuser_ribs",true)
	for material in materials.values():
		material.set_shader_parameter("ceiling_height",13.0)
	materials["pit"] = materials.concrete.duplicate()
	materials.pit.set_shader_parameter("floor_height",-4.0)
