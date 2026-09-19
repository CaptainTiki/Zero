extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1
func signature(node: Node3D,t: Transform3D) -> String:
	var data: Array=[str(t.basis.x.snapped(Vector3.ONE*0.0001),t.basis.y.snapped(Vector3.ONE*0.0001),t.basis.z.snapped(Vector3.ONE*0.0001),t.origin.snapped(Vector3.ONE*0.0001)),node.cast_shadow]
	for i in node.mesh.get_surface_count():
		data.append(hash(node.mesh.surface_get_arrays(i)))
		var material: Material=node.get_active_material(i)
		if material is ShaderMaterial:
			for p in material.shader.get_shader_uniform_list():
				var value=material.get_shader_parameter(p.name)
				data.append(value.resource_path if value is Resource else str(value))
	return JSON.stringify(data)
func collect(node: Node,path: String,t: Transform3D,output: Array) -> void:
	path+="/"+str(node.name)
	if node is Node3D: t*=node.transform
	var fixture: bool=("/AdminArt/Lamp" in path or "/HallArt/Lamp" in path or "/FactorySurfaces/Lamp" in path)
	var utility: bool="/AdminArt/" in path and ("/CorridorPipe" in path or "/PipeCollar" in path or "/PipeBracket" in path or "/Cabinet" in path or "/ElectricalCabinet" in path or "/WallPipe/" in path)
	if node is MeshInstance3D and (fixture or utility): output.append(signature(node,t))
	for child in node.get_children(): collect(child,path,t,output)
func run() -> void:
	var current: Node=load("res://scenes/levels/factory.tscn").instantiate()
	var old_path:="res://.godot/editable_scene_before/scenes/generated/factory.tscn"
	if FileAccess.file_exists(old_path):
		var old: Node=load(old_path).instantiate()
		var before:=[]
		var after:=[]
		collect(old,"",Transform3D.IDENTITY,before)
		collect(current,"",Transform3D.IDENTITY,after)
		before.sort()
		after.sort()
		check(before==after,"All extracted fittings retain world geometry, materials and shadow flags (%d meshes)" % after.size())
		if before!=after:
			print("Before: ",before.size()," after: ",after.size())
			for entry in after:
				if not before.has(entry): print("NEW FITTING ",entry); break
		var same_lights:=true
		for lamp in old.get_children():
			if not lamp is OmniLight3D: continue
			var now: OmniLight3D=current.get_node(NodePath(str(lamp.name)))
			for key in ["transform","light_color","light_energy","omni_range","shadow_enabled","distance_fade_enabled","distance_fade_begin","distance_fade_length"]:
				if lamp.get(key)!=now.get(key): same_lights=false
		check(same_lights,"Every original lamp retains position, intensity, range and shadows")
		old.free()
	for length in [1,5]:
		var rail: Node3D=load("res://scenes/props/factory/fittings/rail_straight_%dm.tscn" % length).instantiate()
		check(rail.get_node("RailCollision").get_child_count()==length*3,"Rail %dm has matching post and bar collision" % length)
		check(not rail.has_node("RailPost%d" % length),"Rail %dm omits its end post to avoid doubled joints" % length)
		rail.free()
	current.free()
	print("FACTORY FITTINGS: ","PASS" if failures==0 else "FAIL")
	quit(1 if failures else 0)
