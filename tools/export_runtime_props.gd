extends SceneTree
## One-time migration. Run against the pre-conversion scripts; existing migration refuses.
const DIR := "res://scenes/props/factory/runtime/"
var material_copies := {}
var manifest := {"signs":[],"doors":[],"johns":[]}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if FileAccess.file_exists(DIR+"manifest.json"):
		push_error("Authored runtime props already extracted; refusing overwrite")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(DIR)
	DirAccess.make_dir_recursive_absolute("res://scenes/props/signs")
	var level: Node3D=load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(level)
	level.process_mode=Node.PROCESS_MODE_DISABLED
	# Label and board become children of a single source asset, with the root at the mount.
	for i in 31:
		var board: MeshInstance3D=level.get_node("Sign%d" % i)
		var text: Label3D=level.get_node("Sign%dLettering" % i)
		var sign := Node3D.new()
		sign.name="Sign"
		var placement := Transform3D(board.basis.orthonormalized(),board.position)
		var b: MeshInstance3D=board.duplicate()
		b.name="Board"
		b.transform=placement.affine_inverse()*board.transform
		sign.add_child(b)
		var label: Label3D=text.duplicate()
		label.name="Text"
		label.transform=placement.affine_inverse()*text.transform
		sign.add_child(label)
		var path := "res://scenes/props/signs/factory_sign_%02d.tscn" % i
		save(sign,path)
		manifest.signs.append({"index":i,"scene":path,"position":[board.position.x,board.position.y,board.position.z],"yaw":board.rotation.y})
		sign.free()
	# Default city door and the factory's smaller opening. Text stays a saved Label3D.
	var door: Node3D=load("res://scenes/props/kick_door.tscn").instantiate()
	root.add_child(door)
	door.process_mode=Node.PROCESS_MODE_DISABLED
	door_names(door)
	save(door,"res://scenes/props/kick_door.tscn")
	door.free()
	for child in level.get_children():
		if str(child.name).begins_with("KickDoor") and not child.prompt.is_empty():
			door_names(child)
			save(child,DIR+"kick_door_factory.tscn")
	# Falling physics is a saved asset, while the standing card hands its saved art over.
	var john: Node3D=load("res://scenes/props/john_cutout.tscn").instantiate()
	root.add_child(john)
	john.process_mode=Node.PROCESS_MODE_DISABLED
	john._topple(Vector3(0,1,0),Vector3.ZERO)
	var fallen: RigidBody3D=john._fallen
	var art: Node=fallen.get_node("Art")
	fallen.remove_child(art)
	art.free()
	fallen.get_child(0).name="Shape"
	save(fallen,DIR+"fallen_john_body.tscn")
	fallen.free()
	john.free()
	for i in 6:
		var card: Node3D=level.get_node("John%d" % i)
		card.get_node("KnockOver").get_child(0).name="Shape"
		var boxes := []
		for child in card.get_children():
			if child is CollisionShape3D: boxes.append(child)
		boxes[0].name="BodyHitbox"
		boxes[1].name="ArmHitbox"
		card.fallen_scene=load(DIR+"fallen_john_body.tscn")
		var path := "res://scenes/props/john_cutout.tscn" if i==0 else DIR+"john_%d.tscn" % i
		save(card,path)
		manifest.johns.append(path)
	var pump: Node3D=level.get_node("CompressorPump0")
	pump._ram.name="Ram"
	pump._steam.name="Steam"
	save(pump,DIR+"compressor_pump.tscn")
	var machine: Node3D=level.get_node("MachineSetPiece")
	var button: Node3D=machine.button
	button._cap.name="ButtonCap"
	button._lamp.name="Indicator"
	button.armed_on=button._glow(Color(0.2,1.0,0.35),3.0)
	button.armed_off=button._glow(Color(0.1,0.3,0.12),0.3)
	button.pressed_material=button._glow(Color(1.0,0.2,0.1),3.0)
	save(button,DIR+"kick_button.tscn")
	var first: Node3D=machine._arm_nodes[1]
	first.pipe._body.name="Body"
	first.pipe._gas.name="Gas"
	for child in first.pipe.get_children():
		if child is CollisionShape3D: child.name="Shape"
	save(first.pipe,DIR+"coolant_pipe.tscn")
	for n in range(1,7):
		var arm: Node3D=machine._arm_nodes[n]
		arm._upper.name="UpperArm"
		arm._hang.name="Hang"
		arm._beacon.name="Beacon"
		arm._beacon_lamp.name="Lamp"
		arm._beacon_light.name="Light"
		arm._socket_steam.name="SocketSteam"
		arm._solids[0].get_parent().name="Forearm"
		arm._solids[0].name="Shape"
		var pivot:=Marker3D.new()
		pivot.name="ShoulderPivot"
		pivot.position=arm.shoulder+Vector3(0,0.45,0)
		arm.add_child(pivot)
		var socket:=Marker3D.new()
		socket.name="Socket"
		socket.position=arm.socket
		arm.add_child(socket)
		# Capture the torn stub now, then restore the unbroken pipe with its source scene.
		arm._snap_off()
		var stub: Node3D=arm.stub
		for child in stub.get_children():
			if child is CPUParticles3D: child.emitting=false
		save(stub,DIR+"broken_pipe_%d.tscn" % n)
		arm.remove_child(stub)
		stub.free()
		arm.stub=null
		arm.stub_scene=load(DIR+"broken_pipe_%d.tscn" % n)
		var pipe_transform: Transform3D=arm.pipe.transform
		# snap() moves geometry within the pipe, not this transform.
		var old_pipe: Node3D=arm.pipe
		var new_pipe: Node3D=load(DIR+"coolant_pipe.tscn").instantiate()
		# Temporarily strip the old constructor so this saved instance isn't built twice.
		new_pipe.set_script(null)
		new_pipe.transform=pipe_transform
		new_pipe.name="CoolantPipe"
		old_pipe.get_parent().remove_child(old_pipe)
		old_pipe.free()
		arm._hang.add_child(new_pipe)
		new_pipe.set_script(load("res://scripts/props/coolant_pipe.gd"))
		arm.warning_on=arm._glow(Color(1.0,0.15,0.08),3.0)
		arm.warning_off=arm._beacon_lamp.material_override
		save(arm,DIR+"pressure_arm_%d.tscn" % n)
	# Stable names replace anonymous runtime nodes for binding.
	machine._exit.name="ExitShutter"
	machine._exit_lamp.name="ExitIndicator"
	machine._end_zone.name="EndZone"
	for child in machine.get_children():
		if child is Area3D:
			child.name="StartTrigger" if child.position==machine.start_at else "OutsideTrigger"
			child.get_child(0).name="Shape"
	var idx:=0
	for jet in machine._steam:
		jet.name="Vent%d" % idx
		jet.set_meta("pit_vent",machine._pit_steam.has(jet))
		idx+=1
	idx=0
	for lamp in machine._alarm_lights:
		lamp.name="Alarm%d" % idx
		idx+=1
	# Saved future-event assets; runtime instantiates them rather than constructing meshes.
	var jet: CPUParticles3D=machine._steam_jet(Vector3.ZERO)
	save(jet,DIR+"steam_jet.tscn")
	jet.free()
	var fire: CPUParticles3D=machine._burst_particles(Vector3.ZERO,28,1.3,1.0,[Color(1.0,0.95,0.6),Color(1.0,0.55,0.1),Color(0.35,0.08,0.02,0.0)])
	save(fire,DIR+"explosion.tscn")
	fire.free()
	var smoke: CPUParticles3D=machine._burst_particles(Vector3.ZERO,40,9.0,9.0,[Color(0.25,0.23,0.22,0.75),Color(0.2,0.2,0.2,0.5),Color(0.2,0.2,0.2,0.0)])
	save(smoke,DIR+"smoke.tscn")
	smoke.free()
	var flash:=OmniLight3D.new()
	flash.name="ExplosionFlash"
	flash.light_color=Color(1.0,0.6,0.25)
	flash.light_energy=10.0
	flash.omni_range=6.0
	save(flash,DIR+"explosion_flash.tscn")
	flash.free()
	var seal:=StaticBody3D.new()
	seal.name="SealPipe"
	var shape:=CollisionShape3D.new()
	shape.name="Shape"
	var cylinder:=CylinderShape3D.new()
	cylinder.radius=machine.seal_radius
	cylinder.height=machine.seal_length
	shape.shape=cylinder
	seal.add_child(shape)
	var visual:=MeshInstance3D.new()
	visual.name="Body"
	var tube:=CylinderMesh.new()
	tube.top_radius=machine.seal_radius
	tube.bottom_radius=machine.seal_radius
	tube.height=machine.seal_length
	tube.radial_segments=12
	visual.mesh=tube
	visual.material_override=load("res://materials/retro/rust.tres")
	seal.add_child(visual)
	save(seal,DIR+"seal_pipe.tscn")
	seal.free()
	machine.seal_scene=load(DIR+"seal_pipe.tscn")
	machine.steam_scene=load(DIR+"steam_jet.tscn")
	machine.explosion_scene=load(DIR+"explosion.tscn")
	machine.smoke_scene=load(DIR+"smoke.tscn")
	machine.flash_scene=load(DIR+"explosion_flash.tscn")
	machine.exit_open_material=machine._glow(Color(0.2,1.0,0.3))
	idx=0
	for ev in machine.escape_events:
		if ev.kind=="fall":
			var body:=StaticBody3D.new()
			body.name="FallingDebris"
			var box:=BoxShape3D.new()
			box.size=ev.size
			var hit:=CollisionShape3D.new()
			hit.name="Shape"
			hit.shape=box
			hit.disabled=true
			body.add_child(hit)
			var mesh:=MeshInstance3D.new()
			mesh.name="Body"
			var slab:=BoxMesh.new()
			slab.size=ev.size
			mesh.mesh=slab
			mesh.material_override=load("res://materials/retro/rust.tres")
			body.add_child(mesh)
			var path:=DIR+"falling_debris_%d.tscn" % idx
			save(body,path)
			body.free()
			machine.debris_scenes[str(ev.size)]=load(path)
		idx+=1
	# Replace the constructed roots with source instances without invoking old _ready again.
	level.remove_child(machine)
	for n in range(1,7): replace_source(machine.get_node("PressureArm%d" % n),DIR+"pressure_arm_%d.tscn" % n)
	replace_source(machine.get_node("ActivateButton"),DIR+"kick_button.tscn")
	save(machine,DIR+"plant_encounter.tscn")
	machine.free()
	FileAccess.open(DIR+"manifest.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"  "))
	print("RUNTIME PROP EXTRACTION COMPLETE")
	level.free()
	quit()
func door_names(door: Node) -> void:
	door._hinge.name="Hinge"
	door._panel_collision.name="PanelCollision"
	door._impact_audio.name="ImpactAudio"
	door._impact_audio.stream=load("res://audio/sfx/props/door_kick.wav")
	var names: Array[String]=["Panel","KickPlate","Handle","Prompt"]
	for i in door._hinge.get_child_count(): door._hinge.get_child(i).name=names[i]
func replace_source(old: Node3D,path: String) -> void:
	var parent:=old.get_parent()
	var copy: Node3D=load(path).instantiate()
	var script=copy.get_script()
	copy.set_script(null)
	# Children are already saved; temporarily disconnect the whole branch from the tree.
	parent.remove_child(old)
	copy.name=old.name
	copy.transform=old.transform
	old.free()
	parent.add_child(copy)
	copy.set_script(script)
func copy_material(m: Material) -> Material:
	if m==null: return null
	if not material_copies.has(m.get_instance_id()): material_copies[m.get_instance_id()]=m.duplicate()
	return material_copies[m.get_instance_id()]
func prepare(node: Node,owner_root: Node) -> void:
	if node!=owner_root:
		node.owner=owner_root
		if not node.scene_file_path.is_empty(): return
	if str(node.name).begins_with("@"):
		node.name=node.get_class()+str(node.get_index())
	if node is MeshInstance3D or node is CPUParticles3D:
		if node.mesh:
			node.mesh=node.mesh.duplicate()
			node.mesh.resource_local_to_scene=true
			for i in node.mesh.get_surface_count(): node.mesh.surface_set_material(i,copy_material(node.mesh.surface_get_material(i)))
		if node is MeshInstance3D:
			node.material_override=copy_material(node.material_override)
	if node is CollisionShape3D and node.shape:
		node.shape=node.shape.duplicate()
		node.shape.resource_local_to_scene=true
	for child in node.get_children(): prepare(child,owner_root)
func save(node: Node,path: String) -> void:
	var transform:=Transform3D.IDENTITY
	if node is Node3D:
		transform=node.transform
		node.transform=Transform3D.IDENTITY
	prepare(node,node)
	var packed:=PackedScene.new()
	assert(packed.pack(node)==OK)
	assert(ResourceSaver.save(packed,path)==OK)
	if node is Node3D: node.transform=transform
	print("SAVED ",path)
