extends SceneTree
## Saved appearance must survive startup, edits, packing and reload without construction.
const DIR := "res://scenes/props/factory/runtime/"
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1
func state(node: Node,path: String="",out: Dictionary={}) -> Dictionary:
	if node.get_meta("editor_preview",false): return out
	var record: Array=[node.get_class()]
	if node is Node3D: record.append(str(node.transform))
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			record.append(hash(node.mesh.surface_get_arrays(i)))
			var m: Material=node.get_active_material(i)
			if m is StandardMaterial3D: record.append([m.albedo_color,m.roughness,m.metallic])
			elif m is ShaderMaterial:
				for uniform in m.shader.get_shader_uniform_list():
					var value=m.get_shader_parameter(uniform.name)
					record.append(value.resource_path if value is Resource else str(value))
	if node is Label3D:
		record.append([node.text,node.pixel_size,node.font_size,node.modulate])
	if node is CollisionShape3D:
		record.append(node.disabled)
		for property in ["size","radius","height"]:
			if property in node.shape: record.append(str(node.shape.get(property)))
	out[path]=record
	for child in node.get_children(): state(child,path+"/"+str(child.name),out)
	return out
func run() -> void:
	var paths: Array[String]=["res://scenes/props/kick_door.tscn","res://scenes/props/john_cutout.tscn"]
	for folder in [DIR,"res://scenes/props/signs/","res://scenes/props/factory/fittings/"]:
		for filename in DirAccess.get_files_at(folder):
			if filename.ends_with(".tscn"): paths.append(folder+filename)
	for path in paths:
		var instance: Node=load(path).instantiate()
		instance.process_mode=Node.PROCESS_MODE_DISABLED
		var before:=state(instance,"",{})
		root.add_child(instance)
		var after:=state(instance,"",{})
		check(before==after,"Saved/runtime parity: "+path.get_file())
		if before!=after:
			for key in after:
				if not before.has(key) or before[key]!=after[key]: print("DIFF ",key," ",before.get(key)," -> ",after[key])
		instance.free()
	# A text edit and deliberately chosen scale are retained, not auto-fitted on load.
	var sign: Node3D=load("res://scenes/props/signs/editable_sign.tscn").instantiate()
	sign.get_node("Text").text="THIS IS MY EDITED SIGN\nSECOND LINE"
	sign.get_node("Text").pixel_size=0.013
	sign.get_node("Board").position.x=0.125
	var paint:=StandardMaterial3D.new()
	paint.albedo_color=Color(0.2,0.7,0.3)
	sign.get_node("Board").material_override=paint
	var fitted: float=sign.fitted_pixel_size()
	check(fitted>0 and fitted<0.013,"Explicit fitting handles long multiline text")
	var packed:=PackedScene.new()
	check(packed.pack(sign)==OK and ResourceSaver.save(packed,"res://.godot/edited_sign.tscn")==OK,"Edited sign saves")
	sign.free()
	var edited: Node3D=load("res://.godot/edited_sign.tscn").instantiate()
	root.add_child(edited)
	check(edited.get_node("Text").text=="THIS IS MY EDITED SIGN\nSECOND LINE" and is_equal_approx(edited.get_node("Text").pixel_size,0.013),"Artist text and text scale survive reload and runtime")
	check(is_equal_approx(edited.get_node("Board").position.x,0.125) and edited.get_node("Board").material_override.albedo_color.is_equal_approx(Color(0.2,0.7,0.3)),"Artist board geometry/material edits survive reload and runtime")
	edited.free()
	# A damaged instance must never shorten the other pipes that share its source scene.
	var pipe_a: Node3D=load(DIR+"coolant_pipe.tscn").instantiate()
	var pipe_b: Node3D=load(DIR+"coolant_pipe.tscn").instantiate()
	root.add_child(pipe_a)
	root.add_child(pipe_b)
	pipe_a.call("snap",0.75)
	check(is_equal_approx(pipe_a.get_node("Shape").shape.size.y,2.25) and is_equal_approx(pipe_b.get_node("Shape").shape.size.y,3.0),"Pipe break collision is local to its instance")
	var a: CylinderMesh=pipe_a.get_node("Body/MeshInstance3D0").mesh
	var b: CylinderMesh=pipe_b.get_node("Body/MeshInstance3D0").mesh
	check(is_equal_approx(a.height,2.25) and is_equal_approx(b.height,3.0),"Pipe break visual mesh is local to its instance")
	pipe_a.free()
	pipe_b.free()
	var level: Node=load("res://scenes/levels/factory.tscn").instantiate()
	var taught:=0
	for child in level.get_children():
		if str(child.name).begins_with("KickDoor"):
			if not child.get_node("Hinge/Prompt").text.is_empty(): taught+=1
	check(taught==1,"Only the taught factory door has a saved prompt")
	check(level.get_node("MachineSetPiece").scene_file_path==DIR+"plant_encounter.tscn","Factory instances the authored encounter")
	check(level.get_node("CompressorPump0").has_node("Ram"),"Compressor geometry exists before entering the tree")
	for i in 31:
		var mounted:=level.get_node("Sign%d" % i)
		check(mounted.has_node("Board") and mounted.has_node("Text") and not mounted.scene_file_path.is_empty(),"Reusable saved placard %d" % i)
	level.free()
	print("EDITABLE RUNTIME SCENES: ","PASS" if failures==0 else "FAIL", " (",failures,")")
	quit(1 if failures else 0)
