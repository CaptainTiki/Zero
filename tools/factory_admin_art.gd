extends RefCounted
## First factory material/detail pass, bounded to the existing admin block.
## Works on the generated base only. ManualDressing belongs to the public scene.
const MeshKit = preload("res://tools/fidelity_mesh.gd")
var kit: SceneTree
var details: Node3D
var materials := {}

func surface(key: String, asset: String, repeat_size: float, tint: Color, maps := false, painted := false) -> void:
	var material := ShaderMaterial.new()
	material.shader = load("res://materials/fidelity/factory_surface.gdshader")
	var folder := "res://art/material_studies/cc0_candidates/" + asset + "/"
	material.set_shader_parameter("soft_texture", load(folder + "albedo_128.png"))
	material.set_shader_parameter("softness", 0.5)
	material.set_shader_parameter("repeat_metres", repeat_size)
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("painted_finish", painted)
	material.set_shader_parameter("rectangular_texture", asset == "Concrete034")
	if maps:
		material.set_shader_parameter("normal_texture", load(folder + "normal_128.png"))
		material.set_shader_parameter("roughness_texture", load(folder + "roughness_128.png"))
		material.set_shader_parameter("surface_maps", true)
		material.set_shader_parameter("bump_strength", 0.1)
		material.set_shader_parameter("roughness_range", Vector2(0.5, 0.85) if painted else Vector2(0.88, 1.0))
	materials[key] = material

func block(label: String, at: Vector3, size: Vector3, material: String, bevel := 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	if bevel > 0:
		node.mesh = MeshKit.beveled_mesh(size, bevel, materials[material])
	else:
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = materials[material]
		node.mesh = mesh
	node.position = at
	kit.add(node, label, details)
	return node

func tube(label: String, at: Vector3, height: float, radius: float, material: String) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1
	mesh.material = materials[material]
	node.mesh = mesh
	node.position = at
	kit.add(node, label, details)

func apply(builder: SceneTree) -> void:
	kit = builder
	details = Node3D.new()
	kit.add(details, "AdminArt")
	surface("plaster", "plastered_wall_04", 3.2, Color(1.0, 0.95, 0.84))
	surface("ceiling", "plastered_wall_04", 3.2, Color(0.78, 0.8, 0.76))
	surface("concrete", "Concrete034", 3.2, Color(0.48, 0.51, 0.51))
	surface("tiles", "floor_tiles_06", 3.0, Color(0.82, 0.84, 0.8))
	surface("brick", "Bricks005", 2.8, Color(0.87, 0.87, 0.83), true)
	surface("teal", "Metal038", 0.8, Color(0.23, 0.43, 0.39), true, true)
	surface("rim", "Metal038", 0.7, Color(0.32, 0.47, 0.43), true, true)
	surface("dark", "Metal038", 0.7, Color(0.15, 0.18, 0.19), true, true)
	surface("cream", "Metal038", 0.8, Color(0.7, 0.66, 0.52), true, true)
	surface("light", "Concrete034", 0.5, Color(1.0, 0.92, 0.77))
	materials.light.set_shader_parameter("emission_strength", 0.8)
	materials.light.set_shader_parameter("diffuser_ribs", true)
	materials.plaster.set_shader_parameter("lower_paint", true)
	var originals: Array = kit.art.get_children()
	for child in originals:
		if not child is MeshInstance3D or not child.mesh is BoxMesh:
			continue
		var p: Vector3 = child.position
		if p.x < -100.21 or p.x > -49.79 or p.z < -0.21 or p.z > 48.31:
			continue
		var name_text := str(child.name)
		var size: Vector3 = child.mesh.size
		if name_text.begins_with("Wall"):
			var exterior := is_equal_approx(p.x, -100.0) or is_equal_approx(p.x, -50.0) or is_equal_approx(p.z, 0.0) or is_equal_approx(p.z, 48.0)
			child.material_override = materials.brick if exterior else materials.plaster
			if p.y < 3.0 and not exterior:
				wall_trim(name_text, p, size)
		elif name_text.begins_with("Floor"):
			child.material_override = materials.tiles if p.z >= 34.0 else materials.concrete
		elif name_text.begins_with("Roof"):
			child.material_override = materials.ceiling
		elif name_text.begins_with("Sign"):
			# Preserve sign text, ink and the existing jokes; give the backing a physical edge.
			var backing := "teal" if child.mesh.material.resource_path.ends_with("/teal.tres") else "cream"
			child.material_override = materials[backing]
			child.mesh = MeshKit.beveled_mesh(size, 0.025, materials[backing])
		elif name_text.begins_with("Blocker"):
			child.material_override = materials.teal
			child.mesh = MeshKit.beveled_mesh(size, 0.045, materials.teal)
			furniture(child, name_text, p, size)
	# Add shade on the existing lamps, not more lights to the Compatibility budget.
	for child in originals:
		if child is OmniLight3D and child.position.x < -49.0 and child.position.z >= 0.0 and child.position.z <= 48.0:
			child.shadow_enabled = true
			child.light_energy = 1.65
			child.omni_range = 11.0
			fixture(str(child.name), child.position)
	facade()
	utilities()
	cracks()
	print("FACTORY ADMIN ART: ", details.get_child_count(), " saved detail meshes; original collision untouched")

func wall_trim(label: String, p: Vector3, size: Vector3) -> void:
	# Wrap existing wall segments: openings stay openings, with no new collision.
	block(label+"Skirt", Vector3(p.x,0.11,p.z), Vector3(size.x+0.025,0.22,size.z+0.025), "dark")
	block(label+"Dado", Vector3(p.x,1.1,p.z), Vector3(size.x+0.035,0.055,size.z+0.035), "rim")
	block(label+"TopTrim", Vector3(p.x,4.3,p.z), Vector3(size.x+0.025,0.09,size.z+0.025), "dark")

func furniture(node: MeshInstance3D, label: String, p: Vector3, size: Vector3) -> void:
	if "ReceptionDesk" in label or "ManagerSDesk" in label:
		node.mesh = MeshKit.beveled_mesh(size-Vector3(0,0.11,0),0.045,materials.teal)
		node.position.y -= 0.055
		block(label+"Top", p+Vector3(0,size.y/2.0-0.055,0), Vector3(size.x,0.11,size.z), "cream", 0.025)
		block(label+"Plinth", Vector3(p.x,0.09,p.z), Vector3(size.x-0.1,0.18,size.z-0.08), "dark")
		for i in int(size.x/1.25):
			var x := p.x-size.x/2.0+0.68+i*1.25
			block(label+"Frame"+str(i),Vector3(x,p.y,p.z+size.z/2.0+0.013),Vector3(1.12,size.y-0.25,0.025),"rim",0.01)
			block(label+"Inset"+str(i),Vector3(x,p.y,p.z+size.z/2.0+0.029),Vector3(1.0,size.y-0.37,0.02),"teal")
	elif "Cubicles" in label:
		# Keep the low blocker silhouette readable as a bank of enclosed workstations.
		node.material_override = materials.cream
		node.mesh = MeshKit.beveled_mesh(size-Vector3(0,0.08,0),0.045,materials.cream)
		node.position.y -= 0.04
		block(label+"Cap", p+Vector3(0,size.y/2.0-0.04,0), Vector3(size.x,0.08,size.z), "rim",0.018)
		for side in [-1.0,1.0]:
			for i in 4:
				var x := p.x-size.x/2.0+0.75+i*1.5
				block(label+"Panel"+str(side)+str(i),Vector3(x,p.y,p.z+side*(size.z/2.0+0.012)),Vector3(1.36,1.25,0.024),"teal")
			for i in 4:
				var z := p.z-size.z/2.0+0.75+i*1.5
				block(label+"EndPanel"+str(side)+str(i),Vector3(p.x+side*(size.x/2.0+0.012),p.y,z),Vector3(0.024,1.25,1.36),"teal")
	elif "FilingCabinets" in label:
		for i in 8:
			for row in 3:
				var at := Vector3(p.x+size.x/2.0+0.02,0.42+row*0.65,p.z-size.z/2.0+0.65+i*1.24)
				block(label+"Drawer"+str(i)+str(row),at,Vector3(0.035,0.58,1.1),"rim",0.012)
				block(label+"Handle"+str(i)+str(row),at+Vector3(0.03,0.1,0),Vector3(0.04,0.045,0.24),"dark")
	elif "Shelving" in label:
		node.material_override = materials.dark
		for row in 4:
			block(label+"Shelf"+str(row),p+Vector3(0,-size.y/2.0+0.15+row*0.58,size.z/2.0+0.018),Vector3(size.x,0.08,0.035),"rim")
	elif "WaitingChairs" in label:
		node.material_override = materials.dark
		node.mesh = MeshKit.beveled_mesh(Vector3(size.x,0.48,size.z),0.035,materials.dark)
		node.position.y = 0.24
		for i in 5:
			var x := p.x-size.x/2.0+0.65+i*1.16
			block(label+"Seat"+str(i),Vector3(x,0.57,p.z+0.1),Vector3(1.02,0.17,1.72),"teal",0.055)
			block(label+"Back"+str(i),Vector3(x,0.85,p.z-0.86),Vector3(1.02,0.28,0.14),"rim",0.035)
	elif "LunchTable" in label:
		node.mesh = MeshKit.beveled_mesh(size-Vector3(0,0.1,0),0.045,materials.teal)
		node.position.y -= 0.05
		block(label+"Tabletop",p+Vector3(0,0.45,0),Vector3(size.x,0.1,size.z),"cream",0.03)
	elif "VendingMachines" in label:
		for i in 2:
			var z := p.z-1.0+i*2.0
			block(label+"Front"+str(i),Vector3(p.x+1.015,1.12,z),Vector3(0.03,1.5,1.7),"dark",0.012)
			for row in 3:
				block(label+"Shelf"+str(i)+str(row),Vector3(p.x+1.04,0.75+row*0.35,z),Vector3(0.024,0.15,1.2),"cream")

func fixture(label: String, at: Vector3) -> void:
	kit.art.get_node(label+"Fix").hide()
	kit.art.get_node(label+"Fix").set_meta("fixture_replaced",true)
	var variant := "neutral" if str(details.name)=="FactorySurfaces" else "warm"
	var node: Node3D=load("res://scenes/props/factory/fittings/fixture_%s.tscn" % variant).instantiate()
	node.position=at
	kit.add(node,label+"Fixture",details)

func facade() -> void:
	for x in [-99.75,-80.0,-60.0,-50.25]:
		block("FacadePier"+str(x),Vector3(x,2.25,48.25),Vector3(0.35,4.5,0.25),"concrete",0.03)
	block("FacadeCornice",Vector3(-75,4.38,48.26),Vector3(50.0,0.22,0.3),"cream",0.04)
	for x in [-72.13,-67.87]:
		block("EntryJamb"+str(x),Vector3(x,1.6,48.22),Vector3(0.22,3.2,0.22),"teal",0.02)
	block("EntryHeader",Vector3(-70,3.23,48.22),Vector3(4.48,0.16,0.22),"rim",0.02)
	block("EntryCanopy",Vector3(-70,3.55,48.95),Vector3(6.0,0.18,1.9),"teal",0.035)
	block("CanopyFascia",Vector3(-70,3.49,49.86),Vector3(6.0,0.2,0.1),"rim",0.018)
	for x in [-90.0,-58.0]:
		for dx in [-3.0,0.0,3.0]:
			block("WindowMullion"+str(x)+str(dx),Vector3(x+dx,1.8,48.34),Vector3(0.085,1.12,0.08),"rim")
		for y in [1.23,2.37]:
			block("WindowRail"+str(x)+str(y),Vector3(x,y,48.34),Vector3(6.08,0.085,0.08),"rim")

func utilities() -> void:
	var pipe: Node3D=load("res://scenes/props/factory/fittings/wall_pipe.tscn").instantiate()
	pipe.position=Vector3(-83.91,0,35.5)
	kit.add(pipe,"WallPipe",details)
	var cabinet: Node3D=load("res://scenes/props/factory/fittings/electrical_cabinet.tscn").instantiate()
	cabinet.position=Vector3(-83.89,1.55,31.2)
	kit.add(cabinet,"ElectricalCabinet",details)

func cracks() -> void:
	# A few opaque material variants; no bright damage overlays or regular repeated cracks.
	for spec in [["Wall173",Vector3(-76.5,2.0,34),1],["Wall167",Vector3(-83.5,2.05,33.1),2],["Wall170",Vector3(-64.0,2.1,30),1]]:
		var wall: MeshInstance3D = kit.art.get_node(spec[0])
		var material: ShaderMaterial = materials.plaster.duplicate()
		material.set_shader_parameter("crack_variant",spec[2])
		material.set_shader_parameter("crack_origin",spec[1])
		wall.material_override = material
