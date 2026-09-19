extends SceneTree
## Completes this migration's saved editor previews and reusable encounter subassemblies.
const DIR := "res://scenes/props/factory/runtime/"
func _initialize() -> void: call_deferred("run")
func own(node: Node, top: Node) -> void:
	if node!=top:
		node.owner=top
		if not node.scene_file_path.is_empty(): return
	for child in node.get_children(): own(child,top)
func save(node: Node,path: String) -> void:
	own(node,node)
	var packed:=PackedScene.new()
	assert(packed.pack(node)==OK)
	assert(ResourceSaver.save(packed,path)==OK)
func preview_root() -> Node3D:
	var root_node:=Node3D.new()
	root_node.name="EditorPreview"
	root_node.set_script(load("res://scripts/props/editor_preview.gd"))
	root_node.set_meta("editor_preview",true)
	return root_node
func ghost_copy(mesh: MeshInstance3D,parent: Node,label: String,at: Transform3D) -> void:
	var copy:=MeshInstance3D.new()
	copy.name=label
	copy.mesh=mesh.mesh
	copy.transform=at
	copy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m:=StandardMaterial3D.new()
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color=Color(1,0.45,0.1,0.35)
	copy.material_override=m
	parent.add_child(copy)
func source_child(child: Node3D,path: String) -> void:
	var parent:=child.get_parent()
	var placement:=child.transform
	var label:=child.name
	parent.remove_child(child)
	child.transform=Transform3D.IDENTITY
	save(child,path)
	child.free()
	var replacement: Node3D=load(path).instantiate()
	replacement.name=label
	replacement.transform=placement
	parent.add_child(replacement)
func run() -> void:
	for n in range(1,7):
		var path:=DIR+"pressure_arm_%d.tscn" % n
		var arm: Node3D=load(path).instantiate()
		if arm.has_node("EditorPreview"):
			push_error("Migration already finalized; refusing overwrite")
			quit(1)
			return
		var preview:=preview_root()
		arm.add_child(preview)
		var stub: Node3D=arm.stub_scene.instantiate()
		for child in stub.get_children():
			if child is MeshInstance3D:
				ghost_copy(child,preview,"Stub"+str(child.get_index()),Transform3D(Basis.IDENTITY,arm.get_node("Socket").position)*child.transform)
		stub.free()
		save(arm,path)
		arm.free()
	var machine: Node3D=load(DIR+"plant_encounter.tscn").instantiate()
	var preview:=preview_root()
	machine.add_child(preview)
	var seal: Node3D=machine.seal_scene.instantiate()
	ghost_copy(seal.get_node("Body"),preview,"SealLanding",Transform3D(machine._seal_basis(),machine.seal_at))
	seal.free()
	var i:=0
	for event in machine.escape_events:
		if event.kind=="fall":
			var piece: Node3D=machine.debris_scenes[str(event.size)].instantiate()
			ghost_copy(piece.get_node("Body"),preview,"DebrisLanding%d" % i,Transform3D(Basis.IDENTITY,event.at))
			piece.free()
		i+=1
	var marker:=Marker3D.new()
	marker.name="SealLanding"
	marker.position=machine.seal_at
	marker.rotation.y=machine.seal_yaw
	machine.add_child(marker)
	var checkpoint:=Marker3D.new()
	checkpoint.name="FightCheckpoint"
	checkpoint.position=machine.respawn_at
	machine.add_child(checkpoint)
	# Flags remain with a moved hatch; runtime derives spawn points from the saved nodes.
	i=0
	for child in machine.get_children():
		if not child is MeshInstance3D or not str(child.name).begins_with("MeshInstance3D"): continue
		var at: Vector3=child.position-Vector3(0,0.03,0)
		var melee:=false
		var ranged:=false
		for p in machine.melee_hatches: if at.distance_to(p)<0.001: melee=true
		for p in machine.ranged_hatches: if at.distance_to(p)<0.001: ranged=true
		if not melee and not ranged: continue
		child.name="Hatch%02d" % i
		child.set_meta("melee_hatch",melee)
		child.set_meta("ranged_hatch",ranged)
		if i==0:
			var mesh:=MeshInstance3D.new()
			mesh.name="Hatch"
			mesh.mesh=child.mesh
			mesh.material_override=child.material_override
			save(mesh,DIR+"hatch.tscn")
			mesh.free()
		var saved_transform: Transform3D=child.transform
		var label: String=child.name
		machine.remove_child(child)
		child.free()
		var instance: MeshInstance3D=load(DIR+"hatch.tscn").instantiate()
		instance.name=label
		instance.transform=saved_transform
		instance.set_meta("melee_hatch",melee)
		instance.set_meta("ranged_hatch",ranged)
		machine.add_child(instance)
		i+=1
	source_child(machine.get_node("ExitShutter"),DIR+"exit_shutter.tscn")
	source_child(machine.get_node("EndZone"),DIR+"exit_beacon.tscn")
	save(machine,DIR+"plant_encounter.tscn")
	machine.free()
	print("SAVED EVENT PREVIEWS AND ENCOUNTER SUBASSEMBLIES")
	quit()
