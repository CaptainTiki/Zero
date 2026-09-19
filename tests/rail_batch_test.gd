extends SceneTree
const Baker=preload("res://scripts/editor/rail_batches.gd")
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1
func expanded(mesh: Mesh) -> Array:
	var a:=mesh.surface_get_arrays(0)
	var out: Array=[]
	var indices: PackedInt32Array=a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
	if indices.is_empty():
		for i in a[Mesh.ARRAY_VERTEX].size(): indices.append(i)
	for i in indices: out.append([a[Mesh.ARRAY_VERTEX][i],a[Mesh.ARRAY_NORMAL][i],a[Mesh.ARRAY_TEX_UV][i] if a[Mesh.ARRAY_TEX_UV]!=null else Vector2.ZERO])
	return out
func physical(node: Node,path: String="",out: Dictionary={}) -> Dictionary:
	if node is CollisionShape3D: out[path]=str(node.transform,node.disabled,node.shape.get_class(),node.shape.get("size"),node.shape.get("radius"),node.shape.get("height"))
	if node is CollisionObject3D: out[path]=str(node.transform,node.collision_layer,node.collision_mask)
	if node is Light3D: out[path]=str(node.transform,node.light_color,node.light_energy,node.shadow_enabled,node.get("omni_range"))
	for child in node.get_children(): physical(child,path+"/"+str(child.name),out)
	return out
func run() -> void:
	var level: Node=load("res://scenes/levels/factory.tscn").instantiate()
	var sources:=0
	var batches:=0
	var vertices:=0
	for label in ["HallWalkways","FactoryWalkways"]:
		var group: Node3D=level.get_node(label)
		var seen: Dictionary={}
		var correct:=true
		var max_position:=0.0
		var max_normal:=0.0
		var max_uv:=0.0
		for batch in group.get_children():
			if not batch.get_meta("rail_batch",false): continue
			batches+=1
			correct=correct and batch.visible and batch.owner!=null
			var actual:=expanded(batch.mesh)
			var cursor:=0
			for source_name in batch.get_meta("rail_sources"):
				var source: MeshInstance3D=group.get_node(NodePath(source_name))
				seen[source_name]=true
				correct=correct and not source.visible and source.get_active_material(0)==batch.get_active_material(0)
				for flag in Baker.FLAGS: correct=correct and source.get(flag)==batch.get(flag)
				for vertex in expanded(source.mesh):
					if cursor>=actual.size(): correct=false; break
					max_position=maxf(max_position,(source.transform*vertex[0]).distance_to(batch.transform*actual[cursor][0]))
					max_normal=maxf(max_normal,(source.basis*vertex[1]).distance_to(batch.basis*actual[cursor][1]))
					max_uv=maxf(max_uv,vertex[2].distance_to(actual[cursor][2]))
					cursor+=1
					vertices+=1
			correct=correct and cursor==actual.size()
		for source in group.get_children():
			if source.get_meta("rail_batch_source",false):
				sources+=1
				correct=correct and seen.has(str(source.name))
		print(label," maximum errors: position=",max_position," normal=",max_normal," uv=",max_uv)
		check(correct and max_position<0.0001 and max_normal<0.001 and max_uv<0.0001,label+" preserves every triangle, normal, UV, material and render setting")
	check(vertices>250000,"Geometry comparison visited actual triangle vertices")
	check(sources==2259 and batches<300,"2259 original meshes retained; fewer than 300 saved draw meshes (%d)" % batches)
	var before_path:="res://.godot/rail_pass_before.tscn"
	if FileAccess.file_exists(before_path):
		var before: Node=load(before_path).instantiate()
		check(preload("res://tests/factory_snapshot_utils.gd").surviving(physical(before,"",{}),level)==physical(level,"",{}),"All collision and light settings match pre-batch scene")
		before.free()
	var count:=level.get_node("HallWalkways").get_child_count()+level.get_node("FactoryWalkways").get_child_count()
	level.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(level)
	check(count==level.get_node("HallWalkways").get_child_count()+level.get_node("FactoryWalkways").get_child_count(),"Entering runtime adds no rail nodes")
	# Explicit offline re-bake reads an authored source edit and leaves collision untouched.
	var group: Node3D=level.get_node("HallWalkways")
	var source: MeshInstance3D
	for child in group.get_children():
		if child.get_meta("rail_batch_source",false): source=child; break
	var original_physics:=physical(group,"",{})
	source.position.x+=0.25
	Baker.bake(group,level)
	check(physical(group,"",{})==original_physics,"Explicit re-bake preserves independent collision")
	var found:=false
	for batch in group.get_children():
		if batch.get_meta("rail_batch",false) and str(source.name) in batch.get_meta("rail_sources"):
			found=true
	check(found and not source.visible,"Authored source edits can be explicitly re-baked")
	var edited_position:=source.position
	var source_path:=level.get_path_to(source)
	var packed:=PackedScene.new()
	check(packed.pack(level)==OK and ResourceSaver.save(packed,"res://.godot/rail_edited.tscn")==OK,"Edited rail sources and batches save together")
	var saved: PackedScene=ResourceLoader.load("res://.godot/rail_edited.tscn","PackedScene",ResourceLoader.CACHE_MODE_IGNORE)
	var reloaded: Node=saved.instantiate()
	check(reloaded.get_node(source_path).position==edited_position,"Edited source placement survives reload")
	var matching:=true
	for batch in group.get_children():
		if batch.get_meta("rail_batch",false):
			var other: MeshInstance3D=reloaded.get_node(level.get_path_to(batch))
			matching=matching and batch.visible==other.visible and batch.transform==other.transform
			if batch.mesh: matching=matching and expanded(batch.mesh)==expanded(other.mesh)
	check(matching,"Explicitly rebuilt output survives saved level reload")
	reloaded.free()
	level.queue_free()
	await process_frame
	print("RAIL BATCH TEST: ","PASS" if failures==0 else "FAIL","; verified ",vertices," triangle vertices")
	quit(1 if failures else 0)
