extends "res://tools/art_kit.gd"
## One-time extraction of approved fittings and creation of editable rail source modules.
const DIR := "res://scenes/props/factory/fittings/"
func _initialize() -> void: call_deferred("run")
func save_asset(node: Node,path: String) -> void:
	if FileAccess.file_exists(path):
		push_error("Refusing to overwrite authored fitting "+path)
		quit(1)
		return
	own(node,node)
	var packed:=PackedScene.new()
	assert(packed.pack(node)==OK)
	assert(ResourceSaver.save(packed,path)==OK)
func own(node: Node,top: Node) -> void:
	if node!=top:
		node.owner=top
		if not node.scene_file_path.is_empty(): return
	if node is MeshInstance3D:
		node.mesh=node.mesh.duplicate()
		for i in node.mesh.get_surface_count():
			var mat: Material=node.mesh.surface_get_material(i)
			if mat: node.mesh.surface_set_material(i,mat.duplicate())
		if node.material_override: node.material_override=node.material_override.duplicate()
	for child in node.get_children(): own(child,top)
func grouped(source: Node,labels: Array,origin: Vector3,label: String) -> Node3D:
	var assembly:=Node3D.new()
	assembly.name=label
	for name in labels:
		var mesh: Node3D=source.get_node(name).duplicate()
		mesh.position-=origin
		assembly.add_child(mesh)
	return assembly
func run() -> void:
	if FileAccess.file_exists(DIR+"fixture_warm.tscn"):
		push_error("Fittings already extracted")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(DIR)
	var level: Node3D=load("res://scenes/levels/factory.tscn").instantiate()
	for spec in [["AdminArt","warm"],["HallArt","high"],["FactorySurfaces","neutral"]]:
		var source:=level.get_node(spec[0])
		var prefix: String=""
		for node in source.get_children():
			if str(node.name).begins_with("Lamp") and str(node.name).ends_with("Housing"):
				prefix=str(node.name).trim_suffix("Housing")
				break
		assert(not prefix.is_empty())
		var labels:=[]
		for node in source.get_children():
			if str(node.name).begins_with(prefix) and not str(node.name).trim_prefix(prefix).left(1).is_valid_int(): labels.append(str(node.name))
		var lamp: OmniLight3D=level.get_node(prefix)
		var fixture:=grouped(source,labels,lamp.position,"Fixture")
		save_asset(fixture,DIR+"fixture_"+spec[1]+".tscn")
		fixture.free()
		# Convenient complete light asset for manual placement; level keeps its original lamps.
		var complete: OmniLight3D=lamp.duplicate()
		complete.name="CeilingLight"
		complete.position=Vector3.ZERO
		complete.add_child(load(DIR+"fixture_"+spec[1]+".tscn").instantiate())
		save_asset(complete,DIR+"ceiling_light_"+spec[1]+".tscn")
		complete.free()
	var admin:=level.get_node("AdminArt")
	var pipe_parts:=[]
	var cabinet_parts:=[]
	for node in admin.get_children():
		var label:=str(node.name)
		if label=="CorridorPipe" or label.begins_with("PipeCollar") or label.begins_with("PipeBracket"): pipe_parts.append(label)
		if label=="ElectricalCabinet" or label.begins_with("Cabinet"): cabinet_parts.append(label)
	var pipe:=grouped(admin,pipe_parts,Vector3(-83.91,0,35.5),"WallPipe")
	save_asset(pipe,DIR+"wall_pipe.tscn")
	pipe.free()
	var cabinet:=grouped(admin,cabinet_parts,Vector3(-83.89,1.55,31.2),"ElectricalCabinet")
	save_asset(cabinet,DIR+"electrical_cabinet.tscn")
	cabinet.free()
	level.free()
	# Module ends deliberately omit the final post, so adjoining sections do not overlap.
	var hall:=preload("res://tools/factory_hall_art.gd").new()
	hall.kit=self
	hall.make_palette()
	for length in [1,5]:
		var recipe:=preload("res://tools/factory_hall_walkways.gd").new()
		recipe.kit=self
		recipe.materials=hall.materials
		recipe.details=Node3D.new()
		add(recipe.details,"Rail%dMetre" % length)
		recipe.rail_body=StaticBody3D.new()
		add(recipe.rail_body,"RailCollision",recipe.details)
		recipe.emit_rail("Rail",Vector3.ZERO,Vector3(length,0,0))
		var end_post:=recipe.details.get_node("RailPost%d" % length)
		var end_shape:=recipe.rail_body.get_node("RailPost%dShape" % length)
		if length==1:
			var cap:=Node3D.new()
			cap.name="RailEndPost"
			var mesh: Node3D=end_post.duplicate()
			mesh.position.x=0
			cap.add_child(mesh)
			var body:=StaticBody3D.new()
			body.name="Collision"
			cap.add_child(body)
			var shape: CollisionShape3D=end_shape.duplicate()
			shape.position.x=0
			body.add_child(shape)
			save_asset(cap,DIR+"rail_end_post.tscn")
			cap.free()
		end_post.free()
		end_shape.free()
		save_asset(recipe.details,DIR+"rail_straight_%dm.tscn" % length)
		recipe.details.free()
	print("FITTINGS: 11 reusable source scenes saved")
	art.free()
	quit()
