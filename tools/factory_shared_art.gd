extends "res://tools/factory_hall_art.gd"
## Shared building finishes only. Room-specific prop art stays in its own pass.
var regions: Array = []
var variants := {}

func apply(builder: SceneTree) -> void:
	kit = builder
	make_palette()
	surface("paving", "Concrete034", 4.0, Color(0.25,0.28,0.28))
	materials.paving.set_shader_parameter("contact_strength",0.0)
	details = Node3D.new()
	kit.add(details,"FactorySurfaces")
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/factory_plan/plan.json"))
	regions = plan.art_regions
	var painted := 0
	var fixtures := 0
	for node in kit.art.get_children():
		if not node is MeshInstance3D or not node.mesh is BoxMesh:
			continue
		# Existing room art wins; shared work never overwrites approved local finishes.
		if node.material_override is ShaderMaterial: continue
		var label := str(node.name)
		var key := ""
		if label.begins_with("Wall"):
			key = "brick" if exterior_wall(node) else "plaster"
		elif label.begins_with("Roof"):
			key = "ceiling"
		elif label.begins_with("Floor") or label.begins_with("Ground"):
			key = "paving" if source_name(node) == "asphalt" else "concrete"
			if source_name(node) == "metal_blue": key = "dark"
		elif label.begins_with("Rail") or label.begins_with("Stair") or label.begins_with("Panel") or label.begins_with("Fence"):
			key = "teal"
		if key.is_empty(): continue
		node.material_override = region_material(key,node.position)
		node.set_meta("art_zone","factory_shared")
		painted += 1
	# Replace the fixture geometry, keeping the existing light count, strength and fade.
	for node in kit.art.get_children():
		if not node is OmniLight3D: continue
		var old := kit.art.get_node_or_null(str(node.name)+"Fix") as MeshInstance3D
		if old == null or not old.visible: continue
		fixture(str(node.name),node.position)
		node.shadow_enabled = true
		fixtures += 1
	shared_doorways(plan)
	preload("res://tools/factory_hall_walkways.gd").new().build_walkways(self,plan,true)
	print("FACTORY SHARED ART: %d surfaces, %d light fixtures; props retained for room passes" % [painted,fixtures])

func source_name(node: MeshInstance3D) -> String:
	return node.mesh.material.resource_path.get_file().get_basename() if node.mesh.material else ""

func exterior_wall(node: MeshInstance3D) -> bool:
	if node.position.y < 0.0: return false
	var p := node.position
	for region in regions:
		var r: Array = region.rect
		if p.x<r[0]-0.21 or p.x>r[2]+0.21 or p.z<r[1]-0.21 or p.z>r[3]+0.21: continue
		if absf(p.x-r[0])<0.05 or absf(p.x-r[2])<0.05 or absf(p.z-r[1])<0.05 or absf(p.z-r[3])<0.05: return true
	return source_name(node)=="brick_dark"

func region_material(key: String,p: Vector3) -> ShaderMaterial:
	var floor_y := -4.0 if p.y < -0.4 else 0.0
	var ceiling_y := 0.0 if floor_y<0 else 4.5
	for region in regions:
		var r: Array = region.rect
		if p.x>=r[0]-0.21 and p.x<=r[2]+0.21 and p.z>=r[1]-0.21 and p.z<=r[3]+0.21:
			ceiling_y = region.ceiling
			if region.name in ["Mixing station","Compressor hall"]: floor_y = -4.0
			break
	# The enclosed skybridge's walls have their own floor and ceiling.
	if p.x>=-20.21 and p.x<=-16.79 and p.z< -70.21 and p.z> -85.79 and p.y>7:
		floor_y = 8.0
		ceiling_y = 11.5
	var cache_key := "%s:%s:%s" % [key,floor_y,ceiling_y]
	if not variants.has(cache_key):
		var m: ShaderMaterial = materials[key].duplicate()
		m.set_shader_parameter("floor_height",floor_y)
		m.set_shader_parameter("ceiling_height",ceiling_y)
		variants[cache_key] = m
	return variants[cache_key]

func shared_doorways(plan: Dictionary) -> void:
	for door in plan.door_frames:
		var at := Vector3(door.at[0],door.at[1],door.at[2])
		if inside(at): continue # HallDoorFrames already owns these five.
		if String(door.name)=="Admin doors": continue # Existing facade frame.
		var along := Vector3.RIGHT if door.along_x else Vector3.BACK
		var width: float = door.width
		var height: float = door.height
		var post := Vector3(0.44,height,0.58) if door.along_x else Vector3(0.58,height,0.44)
		var beam := Vector3(width+0.44,0.22,0.58) if door.along_x else Vector3(0.58,0.22,width+0.44)
		for side in [-1.0,1.0]:
			block(String(door.name).to_pascal_case()+"Jamb"+str(side),at+along*side*width/2.0+Vector3(0,height/2.0,0),post,"rim",0.018)
		block(String(door.name).to_pascal_case()+"Lintel",at+Vector3(0,height+0.09,0),beam,"rim",0.018)
