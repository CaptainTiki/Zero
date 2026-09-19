extends SceneTree
## Saved geometry parity, nested reuse, collision relocation and runtime non-rebuilding.
var failures := 0
const SNAPSHOT := "res://.godot/factory_props_before.json"
const FOLDER := "res://scenes/props/factory/"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures += 1
func rounded(t: Transform3D) -> String:
	return str(t.basis.x.snapped(Vector3.ONE*0.0001),t.basis.y.snapped(Vector3.ONE*0.0001),t.basis.z.snapped(Vector3.ONE*0.0001),t.origin.snapped(Vector3.ONE*0.0001))
func material_signature(m: Material) -> String:
	if m == null: return "none"
	var values := {}
	if m is ShaderMaterial:
		values.shader=m.shader.resource_path
		for param in m.shader.get_shader_uniform_list():
			var v = m.get_shader_parameter(param.name)
			values[param.name] = v.resource_path if v is Resource else str(v)
	else:
		for key in ["albedo_color","roughness","metallic","emission_enabled","emission","emission_energy_multiplier","transparency","billboard_mode"]:
			values[key]=str(m.get(key))
	return JSON.stringify(values)
func collect(node: Node, transform: Transform3D, shapes: Array, visuals: Dictionary, path: String) -> void:
	if node is Node3D: transform *= node.transform
	# The historical capture predates serialized doors/Johns/encounter. Those 172 shapes
	# are validated by editable_runtime_scenes_test and their gameplay/route tests.
	var newly_saved := path.begins_with("/John") or path.begins_with("/KickDoor") or path.begins_with("/MachineSetPiece/")
	if node is CollisionShape3D and not node.disabled and not newly_saved:
		var body := node.get_parent() as CollisionObject3D
		var value := {"world":rounded(transform),"type":node.shape.get_class(),"layer":body.collision_layer,"mask":body.collision_mask}
		for key in ["size","radius","height","points"]:
			if key in node.shape: value[key]=str(node.shape.get(key))
		shapes.append(JSON.stringify(value))
	if node is MeshInstance3D and "/HallMachinery/" in path:
		var mats := []
		var arrays := []
		for i in node.mesh.get_surface_count():
			mats.append(material_signature(node.get_active_material(i)))
			arrays.append(hash(node.mesh.surface_get_arrays(i)))
		visuals[path] = [rounded(transform),mats,arrays,node.visible]
	for child in node.get_children(): collect(child,transform,shapes,visuals,path+"/"+str(child.name))
func snapshot(level: Node) -> Dictionary:
	var shapes := []
	var visuals := {}
	collect(level,Transform3D.IDENTITY,shapes,visuals,"")
	shapes.sort()
	return {"shapes":shapes,"visuals":visuals}
func run() -> void:
	var level: Node3D = load("res://scenes/levels/factory.tscn").instantiate()
	var current := snapshot(level)
	FileAccess.open("res://.godot/factory_props_after.json",FileAccess.WRITE).store_string(JSON.stringify(current))
	if "--baseline" in OS.get_cmdline_user_args():
		FileAccess.open(SNAPSHOT,FileAccess.WRITE).store_string(JSON.stringify(current))
		print("PREFAB BASELINE: ",current.visuals.size()," hall meshes; ",current.shapes.size()," world collision shapes")
		level.free()
		quit()
		return
	if FileAccess.file_exists(SNAPSHOT):
		var before: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOT))
		check(JSON.stringify(current.shapes)==JSON.stringify(before.shapes),"Every saved active collision shape retains world dimensions, transform and layers")
		check(JSON.parse_string(JSON.stringify(current.visuals))==before.visuals,"All 343 hall meshes retain geometry, transforms and material values")
		if JSON.parse_string(JSON.stringify(current.visuals))!=before.visuals:
			for key in current.visuals:
				if not before.visuals.has(key) or JSON.parse_string(JSON.stringify(current.visuals[key]))!=before.visuals[key]: print("VISUAL DIFF ",key)
	for prop in level.get_node("HallMachinery").get_children():
		check(prop.scene_file_path.begins_with(FOLDER),"Level references authored scene: "+str(prop.name))
		var source: PackedScene = load(prop.scene_file_path)
		var isolated := source.instantiate()
		check(not isolated.find_children("*","CollisionShape3D",true,false).is_empty(),"Standalone prop carries its collision: "+str(prop.name))
		isolated.process_mode=Node.PROCESS_MODE_DISABLED
		var count := isolated.find_children("*","MeshInstance3D",true,false).size()
		var saved_visuals := {}
		collect(isolated,Transform3D.IDENTITY,[],saved_visuals,"/HallMachinery/Asset")
		root.add_child(isolated)
		var runtime_visuals := {}
		collect(isolated,Transform3D.IDENTITY,[],runtime_visuals,"/HallMachinery/Asset")
		check(saved_visuals==runtime_visuals,"Saved appearance matches initial runtime pose: "+str(prop.name))
		check(count==isolated.find_children("*","MeshInstance3D",true,false).size(),"Entering runtime adds no prop meshes: "+str(prop.name))
		isolated.free()
	# A genuine artist edit survives save/reload and runtime, rather than being rebuilt.
	var edited: Node3D=load(FOLDER+"shipping_case.tscn").instantiate()
	edited.get_node("Shell").position.x=0.125
	var override_material:=StandardMaterial3D.new()
	override_material.albedo_color=Color(0.2,0.8,0.3)
	edited.get_node("Shell").material_override=override_material
	var packed:=PackedScene.new()
	check(packed.pack(edited)==OK,"Edited case packs successfully")
	check(ResourceSaver.save(packed,"res://.godot/edited_case_test.tscn")==OK,"Edited case saves successfully")
	edited.free()
	var reloaded: Node3D=load("res://.godot/edited_case_test.tscn").instantiate()
	root.add_child(reloaded)
	check(is_equal_approx(reloaded.get_node("Shell").position.x,0.125) and reloaded.get_node("Shell").material_override.albedo_color.is_equal_approx(Color(0.2,0.8,0.3)),"Artist geometry/material overrides survive reload and runtime")
	reloaded.free()
	var loose:=level.get_node("HallMachinery/Blocker103LooseSupplyCase/LooseCase")
	var stack:=level.get_node("HallMachinery/Blocker50Crates/Case000")
	check(loose.scene_file_path==FOLDER+"shipping_case.tscn" and stack.scene_file_path==loose.scene_file_path,"Loose and stacked cases share the same source scene")
	for label in ["Blocker53Hoppers","Blocker54Conveyor","Blocker58HopperTower"]:
		check(not level.has_node(label+"Solid") and level.has_node("HallMachinery/"+label+"/FootprintCollision"),"Obsolete footprint removed; scene-owned collision retained: "+label)
	level.free()
	print("FACTORY PROP SCENES TEST: ","PASS" if failures==0 else "FAIL")
	quit(1 if failures else 0)
