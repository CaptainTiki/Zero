extends SceneTree
var failures := 0
var collision := {}
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1
func collect(node: Node, parent_path := "", parent_transform := Transform3D.IDENTITY) -> void:
	var path := parent_path + "/" + str(node.name)
	var transform := parent_transform
	if node is Node3D:
		transform *= node.transform
	var newly_saved := "/John" in path or "/KickDoor" in path or "/MachineSetPiece/" in path
	if node is CollisionShape3D and not newly_saved and not "/HallWalkways/" in path and not "/FactoryWalkways/" in path and not "/HallMachinery/" in path and not "/Blocker103LooseSupplyCaseSolid/" in path:
		var shape: Shape3D = node.shape
		var props := {}
		for key in ["size", "radius", "height", "points"]:
			if key in shape:
				props[key] = str(shape.get(key))
		collision[path] = [str(transform), props, false if node.get_meta("replaced_by_open_rail",false) or node.get_meta("replaced_by_prop_art",false) else node.disabled]
	for child in node.get_children():
		collect(child, path, transform)
func run() -> void:
	var scene: PackedScene = load("res://scenes/levels/factory.tscn")
	var level := scene.instantiate()
	collect(level)
	collision=preload("res://tests/factory_snapshot_utils.gd").surviving(collision,level)
	var baseline_path := "res://.godot/factory_admin_collision_baseline.json"
	if "--baseline" in OS.get_cmdline_user_args():
		var file := FileAccess.open(baseline_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(collision))
		file.close()
		print("ADMIN COLLISION BASELINE SAVED: ", collision.size())
	else:
		if FileAccess.file_exists(baseline_path):
			check(stable_shape_keys(collision) == stable_shape_keys(preload("res://tests/factory_snapshot_utils.gd").surviving(JSON.parse_string(FileAccess.get_file_as_string(baseline_path)),level)), "Original collision shapes and transforms match before art; explicit open-rail and prop replacements excluded")
		else:
			print("SKIP  Optional before-art collision snapshot is absent")
		check(level.has_node("ManualDressing") and level.has_node("AdminArt"), "Persistent user dressing and generated art are separate")
		check(level.get_node("Blocker28ReceptionDesk").mesh is ArrayMesh, "Reception desk has beveled geometry")
		var material: ShaderMaterial = level.get_node("Blocker28ReceptionDesk").material_override
		check(material.get_shader_parameter("surface_maps") == true and material.get_shader_parameter("bump_strength") == 0.1, "Painted metal has restrained normal and roughness maps")
		var count := 0
		for child in level.get_children():
			if child is MeshInstance3D and child.material_override is ShaderMaterial and child.material_override.shader.resource_path.ends_with("factory_surface.gdshader") and child.get_meta("art_zone", "") not in ["production_hall", "factory_shared"]:
				count += 1
				check(child.position.x >= -100.21 and child.position.x <= -49.79 and child.position.z >= -0.21 and child.position.z <= 48.31, "Material scope: " + str(child.name))
		check(count > 80, "Admin walls, floors, ceilings and fixtures receive the approved surfaces")
		var details := level.get_node("AdminArt")
		check(details.find_children("*", "CollisionObject3D", true, false).is_empty(), "Decorative detail adds no new collision blockers")
		for child in level.get_children():
			if child is OmniLight3D and child.position.x < -49 and child.position.z >= 0:
				check(child.shadow_enabled, "Admin lamp receives solid-wall shadows: " + str(child.name))
	level.free()
	print("FACTORY ADMIN ART: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func stable_shape_keys(source: Dictionary) -> Dictionary:
	# Godot renumbers anonymous shape nodes when a new blocker is added. The named
	# parent body is stable; reject collisions rather than silently merging keys.
	var pattern := RegEx.new()
	pattern.compile("@CollisionShape3D@[0-9]+")
	var result := {}
	for key in source:
		var stable := pattern.sub(key,"GeneratedShape",true)
		assert(not result.has(stable),"Ambiguous generated shape key: "+stable)
		result[stable] = source[key]
	return result
