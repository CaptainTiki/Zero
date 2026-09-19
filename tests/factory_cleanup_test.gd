extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1
func collect(node: Node,path: String,t: Transform3D,visible_parent: bool,physics: Dictionary,visuals: Dictionary,lights: Dictionary) -> void:
	path+="/"+str(node.name)
	var visible:=visible_parent
	if node is Node3D:
		t*=node.transform
		visible=visible and node.visible
	if node is CollisionShape3D and not node.disabled:
		var body: CollisionObject3D=node.get_parent()
		var properties: Array=[str(t),body.collision_layer,body.collision_mask,node.shape.get_class()]
		for key in ["size","radius","height","points"]:
			if key in node.shape: properties.append(str(node.shape.get(key)))
		physics[path]=properties
	if node is MeshInstance3D and node.mesh and visible:
		var data: Array=[str(t),node.cast_shadow,node.layers]
		for i in node.mesh.get_surface_count():
			data.append(hash(node.mesh.surface_get_arrays(i)))
			var m: Material=node.get_active_material(i)
			if m is ShaderMaterial:
				data.append(m.shader.resource_path)
				for uniform in m.shader.get_shader_uniform_list():
					var value=m.get_shader_parameter(uniform.name)
					data.append(value.resource_path if value is Resource else str(value))
			elif m: data.append([m.albedo_color,m.roughness,m.metallic])
		visuals[path]=data
	if node is Light3D:
		lights[path]=[str(t),node.visible,node.light_color,node.light_energy,node.shadow_enabled,node.get("omni_range"),node.distance_fade_enabled,node.distance_fade_begin,node.distance_fade_length]
	for child in node.get_children(): collect(child,path,t,visible,physics,visuals,lights)
func snapshot(level: Node) -> Array:
	var p: Dictionary={}
	var v: Dictionary={}
	var l: Dictionary={}
	collect(level,"",Transform3D.IDENTITY,true,p,v,l)
	return [p,v,l]
func run() -> void:
	var level: Node=load("res://scenes/levels/factory.tscn").instantiate()
	var baseline:="res://.godot/factory_before_cleanup.tscn"
	if FileAccess.file_exists(baseline):
		var before: Node=load(baseline).instantiate()
		var a:=snapshot(before)
		var b:=snapshot(level)
		check(a[0]==b[0],"Every active saved collider retains path, world transform, shape and layers (%d)" % b[0].size())
		check(a[1]==b[1],"Every approved visible mesh retains geometry, world transform and material (%d)" % b[1].size())
		check(a[2]==b[2],"All light settings remain unchanged")
		print("Node count: ",before.find_children("*","",true,false).size()," -> ",level.find_children("*","",true,false).size())
		before.free()
	else: print("SKIP optional local pre-cleanup snapshot unavailable")
	var no_obsolete:=true
	for node in level.get_children():
		for marker in ["open_rail","grated_deck","machine_art_replaced","fixture_replaced"]:
			if node.get_meta(marker,false): no_obsolete=false
		if node is CSGShape3D and node.get_meta("replaced_by_open_rail",false): no_obsolete=false
	check(no_obsolete,"No replaced blockout markers remain on scene nodes")
	var retired: Dictionary=level.get_meta("retired_blockouts",{})
	var kinds: Dictionary={}
	var valid:=not retired.is_empty()
	for path: String in retired:
		var item: Dictionary=retired[path]
		valid=valid and not level.has_node(NodePath(path)) and level.has_node(NodePath(item.replacement))
		kinds[item.kind]=kinds.get(item.kind,0)+1
	check(valid,"Every retired root is absent and has a saved replacement")
	print("Retired roots: ",JSON.stringify(kinds))
	for group in ["HallWalkways","FactoryWalkways"]:
		var sources:=0
		var batches:=0
		for child in level.get_node(group).get_children():
			if child.get_meta("rail_batch_source",false): sources+=1
			if child.get_meta("rail_batch",false): batches+=1
		check(sources>0 and batches>0,"Detailed rail editing sources and baked output remain: "+group)
	for name in ["Floor168Solid","Floor177Solid","RoundDeck0FloorSolid"]:
		check(level.has_node(NodePath(name)) and not level.get_node(NodePath(name)).get_child(0).disabled,"Walking collision remains: "+name)
	check(not level.has_node("Rail4"),"Old Rail4 cannot reappear through a stale override")
	check(level.has_node("ManualDressing"),"Manual dressing preserved")
	level.free()
	print("FACTORY CLEANUP: ","PASS" if failures==0 else "FAIL")
	quit(1 if failures else 0)
