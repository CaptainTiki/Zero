extends RefCounted
## Placement only. Authored prop scenes own their meshes, materials and collision.
## A level bake must never regenerate or save over these assets.
func build_machinery(hall: RefCounted) -> void:
	var kit: SceneTree = hall.kit
	var group := Node3D.new()
	kit.add(group,"HallMachinery")
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/factory_plan/plan.json"))
	var count := 0
	for i in plan.blockers.size():
		var b: Dictionary = plan.blockers[i]
		if b.shape != "box" or not b.has("prop_scene"): continue
		var p := Vector3(b.c[0],b.c[1],b.c[2])
		if not hall.inside(p): continue
		var label: String = "Blocker%d%s" % [i,String(b.name).to_pascal_case()]
		var asset: PackedScene = load(b.prop_scene)
		assert(asset != null,"Missing authored prop: "+str(b.prop_scene))
		var prop: Node3D = asset.instantiate()
		prop.position = p-Vector3(0,float(b.s[1])/2.0,0)
		kit.add(prop,label,group)
		prop.set_meta("blocker_size",Vector3(b.s[0],b.s[1],b.s[2]))
		prop.set_meta("collision_source",prop.scene_file_path)
		var old: MeshInstance3D = kit.art.get_node(label)
		old.hide()
		old.set_meta("machine_art_replaced",true)
		for shape in kit.art.get_node(label+"Solid").get_children():
			if shape is CollisionShape3D:
				shape.disabled = true
				shape.set_meta("replaced_by_prop_art",true)
				if prop.has_node("FootprintCollision"):
					shape.set_meta("prefab_collision_relocated",true)
		count += 1
	print("HALL MACHINERY: ",count," authored scene instances; no prop generation")
