extends SceneTree
var failures := 0
var snapshot := {}
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures += 1
func collect(node: Node, path := "", parent_transform := Transform3D.IDENTITY) -> void:
	path += "/"+str(node.name)
	if node is Node3D: parent_transform *= node.transform
	# These branches formerly constructed their shapes only at runtime and were absent
	# from the saved-scene baseline. Dedicated parity and gameplay tests cover them.
	var newly_saved := "/John" in path or "/KickDoor" in path or "/MachineSetPiece/" in path
	if node is CollisionShape3D and not newly_saved and not "/FactoryWalkways/" in path and not "/FootprintCollision/" in path:
		var values := {}
		for key in ["size","radius","height","points"]:
			if key in node.shape: values[key]=str(node.shape.get(key))
		# All new rail panels are explicitly marked; old hall state stays as captured.
		snapshot[path]=[str(parent_transform),values,false if node.get_meta("factory_shared_replaced",false) or node.get_meta("prefab_collision_relocated",false) else node.disabled]
	if node is CSGShape3D and node.is_root_shape():
		snapshot[path]=[str(parent_transform),true if node.get_meta("factory_shared_replaced",false) else node.use_collision]
	for child in node.get_children(): collect(child,path,parent_transform)
func run() -> void:
	var level: Node3D = load("res://scenes/levels/factory.tscn").instantiate()
	collect(level)
	snapshot=preload("res://tests/factory_snapshot_utils.gd").surviving(snapshot,level)
	var file := "res://.godot/factory_shared_collision_before.json"
	if "--baseline" in OS.get_cmdline_user_args():
		FileAccess.open(file,FileAccess.WRITE).store_string(JSON.stringify(snapshot))
		print("SHARED BEFORE SNAPSHOT: ",snapshot.size())
		level.free()
		quit()
		return
	if FileAccess.file_exists(file):
		check(comparison_snapshot(snapshot)==comparison_snapshot(preload("res://tests/factory_snapshot_utils.gd").surviving(JSON.parse_string(FileAccess.get_file_as_string(file)),level)),"All pre-pass collision unchanged except explicitly replaced rails")
	else:
		print("SKIP optional local pre-pass snapshot unavailable")
	var count := 0
	var opaque_rails := 0
	var opaque_decks := 0
	for node in level.get_children():
		if not node is MeshInstance3D: continue
		var label := str(node.name)
		if node.get_meta("art_zone","")=="factory_shared": count+=1
		if label.begins_with("Rail") and node.visible: opaque_rails+=1
		if label.begins_with("Floor") and node.mesh is BoxMesh and node.mesh.material.resource_path.ends_with("/metal_blue.tres") and node.position.y>1 and node.visible: opaque_decks+=1
	check(count>500,"Shared finishes cover the remaining factory structure")
	check(opaque_rails==0,"Every straight rail panel replaced")
	check(opaque_decks==0,"Every raised metal walkway uses grating")
	check(not level.has_node("RoundDeck0Rail"),"Circular rail panel and opaque collision removed")
	check(level.has_node("FactoryWalkways/RoundDeck0Grating"),"Circular platform has a framed grating surface")
	var grate: MeshInstance3D = level.get_node("FactoryWalkways/RoundDeck0Grating")
	var vertices: PackedVector3Array = grate.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var overlap := false
	for i in range(0,vertices.size(),3):
		var center: Vector3 = (vertices[i]+vertices[i+1]+vertices[i+2])/3.0+grate.position
		if center.x>46.001 and center.x<48.499 and center.z> -90.499: overlap = true
	check(not overlap,"Round grate has no coplanar triangles inside the bridge footprint")
	check(level.get_node("FactorySurfaces").find_children("*","CollisionObject3D",true,false).is_empty(),"Shared finish details do not add movement blockers")
	root.add_child(level)
	level.set_process(false)
	level.get_node("Player").process_mode=Node.PROCESS_MODE_DISABLED
	for i in 4: await physics_frame
	var world := level.get_world_3d().direct_space_state
	# Plant roof entry must remain open through the circular guardrail.
	var hit := world.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(47.25,8.8,-91),Vector3(47.25,8.8,-88.5),1))
	check(hit.is_empty(),"Circular platform entrance remains open")
	level.queue_free()
	await process_frame
	print("FACTORY SHARED ART TEST: ","PASS" if failures==0 else "FAIL")
	quit(1 if failures else 0)

func comparison_snapshot(source: Dictionary) -> Dictionary:
	var result := source.duplicate()
	# Q-marked Stair3 rails are extended to the upper landing. Other hall collision
	# remains covered; route/stair/polish tests verify the changed rail geometry.
	for key in result.keys():
		if "/HallWalkways/" in key and "/Stair3Rail" in key: result.erase(key)
	return result
