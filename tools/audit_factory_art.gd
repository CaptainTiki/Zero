extends SceneTree
func _initialize() -> void:
	var level: Node = load("res://scenes/levels/factory.tscn").instantiate()
	var counts := {}
	var collision := {}
	inspect(level,"",Transform3D.IDENTITY,counts,collision)
	collision=preload("res://tests/factory_snapshot_utils.gd").surviving(collision,level)
	print("ART COUNTS ",JSON.stringify(counts))
	var path := "res://.godot/hall_prop_collision_before.json"
	if "--baseline" in OS.get_cmdline_user_args():
		var f := FileAccess.open(path,FileAccess.WRITE)
		f.store_string(JSON.stringify(collision))
	elif FileAccess.file_exists(path):
		var same: bool = stable_shape_keys(collision) == stable_shape_keys(preload("res://tests/factory_snapshot_utils.gd").surviving(JSON.parse_string(FileAccess.get_file_as_string(path)),level))
		print("ORIGINAL COLLISION UNCHANGED EXCEPT MARKED PROP / RAIL REPLACEMENTS: ",same," (",collision.size()," shapes)")
		if not same:
			var baseline := stable_shape_keys(preload("res://tests/factory_snapshot_utils.gd").surviving(JSON.parse_string(FileAccess.get_file_as_string(path)),level))
			var current := stable_shape_keys(collision)
			for key in current:
				if not baseline.has(key) or baseline[key] != current[key]: print("COLLISION DIFF ",key)
			level.free()
			quit(1)
			return
	level.free()
	quit()
func inspect(node: Node,path: String,t: Transform3D,counts: Dictionary,collision: Dictionary) -> void:
	path += "/"+str(node.name)
	if node is Node3D: t *= node.transform
	var newly_saved := "/John" in path or "/KickDoor" in path or "/MachineSetPiece/" in path
	if node is CollisionShape3D and not newly_saved and not "/FactoryWalkways/" in path and not "/HallMachinery/" in path and not "/Blocker103LooseSupplyCaseSolid/" in path:
		var props := {}
		for key in ["size","radius","height","points"]:
			if key in node.shape: props[key] = str(node.shape.get(key))
		collision[path] = [str(t),props,false if node.get_meta("replaced_by_prop_art",false) or node.get_meta("factory_shared_replaced",false) else node.disabled]
	if node is MeshInstance3D and node.visible and node.mesh:
		var key := "other"
		if "/HallWalkways/" in path or "/FactoryWalkways/" in path:
			key = "grating_frames"
			if "Post" in str(node.name): key = "posts"
			elif "Handrail" in str(node.name): key = "handrails"
			elif "Midrail" in str(node.name): key = "midrails"
		elif "/HallMachinery/" in path: key = "machinery"
		if not counts.has(key): counts[key] = {"meshes":0,"triangles":0}
		counts[key].meshes += 1
		for i in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(i)
			var indices = arrays[Mesh.ARRAY_INDEX]
			counts[key].triangles += (indices.size() if indices != null and indices.size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3
	for child in node.get_children(): inspect(child,path,t,counts,collision)

func stable_shape_keys(source: Dictionary) -> Dictionary:
	# Godot renumbers anonymous shape nodes when a new blocker is added. The named
	# parent body is stable; reject collisions rather than silently merging keys.
	var pattern := RegEx.new()
	pattern.compile("@CollisionShape3D@[0-9]+")
	var result := {}
	for key in source:
		# The marked upper hall stair now has rails down to its landing.
		if "/HallWalkways/" in key and "/Stair3Rail" in key: continue
		var stable := pattern.sub(key,"GeneratedShape",true)
		assert(not result.has(stable),"Ambiguous generated shape key: "+stable)
		result[stable] = source[key]
	return result
