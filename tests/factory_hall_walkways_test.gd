extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok: failures += 1
func ray(level: Node3D, y: float, z: float) -> Dictionary:
	return level.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-60.8,y,z),Vector3(-59.2,y,z),1))
func run() -> void:
	var level: Node3D = load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(level)
	level.set_process(false)
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	for actor in get_nodes_in_group("enemies") + get_nodes_in_group("ambush"):
		actor.get_parent().remove_child(actor)
		actor.queue_free()
	for i in 3: await physics_frame
	check(ray(level,4.8,-55.3).is_empty(),"Ray passes through rail opening; no invisible solid panel")
	check(not ray(level,4.55,-55.3).is_empty(),"Mid rail has collision")
	check(not ray(level,5.055,-55.3).is_empty(),"Handrail has collision")
	check(not ray(level,4.8,-55.0).is_empty(),"Upright has collision")
	var rails := 0
	var decks := 0
	var caps := 0
	var retired: Dictionary=level.get_meta("retired_blockouts",{})
	for label: String in retired:
		var info: Dictionary=retired[label]
		if info.get("art_zone","")=="factory_shared" or label.begins_with("RoundDeck"): continue
		if info.kind=="rail_panel": rails+=1
		if info.kind=="opaque_deck": decks+=1
		check(not level.has_node(NodePath(label)),"Superseded blockout removed: "+label)
	for node in level.get_children():
		if node.get_meta("pit_cap_lowered",false):
			caps += 1
			check(absf(node.position.y+node.mesh.size.y/2.0+0.025)<0.001,"Pit/corridor cap separated: "+str(node.name))
	check(rails==23 and decks==21 and caps==25,"Expected hall rails, decks and pit/corridor caps updated")
	for label in ["Wall91","Wall92","Wall75","Wall76","Wall78","Wall79"]:
		check(level.get_node(label).get_meta("pit_cap_lowered",false),"Marked seams and connected corridor fixed: "+label)
	# The mouth must have one visible wall face at each corner, not overlapping boxes.
	for pair in [["Wall87","Wall91"],["Wall85","Wall90"],["Wall85","Wall86"],["Wall86","Wall87"],["Wall75","Wall91"]]:
		var a: MeshInstance3D = level.get_node(pair[0])
		var b: MeshInstance3D = level.get_node(pair[1])
		var overlap: Vector3 = (a.mesh.size+b.mesh.size)/2.0-(a.position-b.position).abs()
		check(minf(overlap.x,minf(overlap.y,overlap.z))<0.001,"Corridor wall faces meet without overlap: "+str(pair))
	for label in ["Floor177","Floor168"]:
		var node: StaticBody3D = level.get_node(label+"Solid")
		check(absf(node.position.y+node.get_child(0).shape.size.y/2.0)<0.001,"Marked walking floor remains at y=0: "+label)
	var walker: CharacterBody3D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(walker)
	walker.set_physics_process(false)
	for spec in [[Vector3(-60.8,4.2,-55.3),Vector3.RIGHT,4.0],[Vector3(-34.0,4.2,-62),Vector3.RIGHT,4.0],[Vector3(-18.5,8.2,-62),Vector3.RIGHT,8.0]]:
		walker.position = spec[0]
		for i in 15:
			await physics_frame
			walker.velocity = Vector3(0,-3,0)
			walker.move_and_slide()
		for i in 60:
			await physics_frame
			walker.velocity = spec[1]*6.0+Vector3(0,-3,0)
			walker.move_and_slide()
		check(walker.is_on_floor() and absf(walker.position.y-float(spec[2]))<0.05,"Grating supports walker; open rails prevent stepping off at "+str(spec[0]))
	walker.position = Vector3(-60.75,4.05,-42)
	for target in [Vector3(-61,4,-69),Vector3(-34,4,-69),Vector3(-34,4,-54)]:
		var stuck := 0
		for i in 450:
			await physics_frame
			var flat: Vector3 = target-walker.position
			flat.y = 0
			if flat.length() < 0.8: break
			var before := walker.position
			walker.velocity = flat.normalized()*6.0+Vector3(0,-2,0)
			walker.move_and_slide()
			stuck = stuck+1 if walker.position.distance_to(before)<0.01 else 0
			if stuck>40:
				for j in walker.get_slide_collision_count():
					var contact := walker.get_slide_collision(j)
					print("TURN CONTACT ",contact.get_collider().name," shape ",contact.get_collider_shape()," normal ",contact.get_normal())
				break
		check(walker.position.distance_to(target)<2.0,"North catwalk turn reaches "+str(target)+" from "+str(walker.position))
	walker.queue_free()
	level.queue_free()
	await process_frame
	print("HALL WALKWAYS TEST: ","PASS" if failures==0 else "FAIL")
	quit(1 if failures else 0)
