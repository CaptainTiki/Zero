extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures += 1
func ray(level: Node3D,a: Vector3,b: Vector3) -> Dictionary:
	return level.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1))
func run() -> void:
	var level: Node3D = load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(level)
	level.set_process(false)
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	for node in get_nodes_in_group("enemies")+get_nodes_in_group("ambush"):
		node.get_parent().remove_child(node)
		node.queue_free()
	var expected_replacements := ["Blocker50CratesSolid", "Blocker51PressASolid", "Blocker52PressBSolid", "Blocker55DrumWasherSolid", "Blocker56DrumWasherSolid", "Blocker57DrumWasherSolid", "Blocker103LooseSupplyCaseSolid", "Blocker53HoppersSolid", "Blocker54ConveyorSolid", "Blocker58HopperTowerSolid"]
	var replacements: Array[String] = []
	for label: String in level.get_meta("retired_blockouts",{}):
		if label in expected_replacements:
			replacements.append(label)
			check(not level.has_node(NodePath(label)),"Replaced blocker is removed: "+label)
	expected_replacements.sort()
	replacements.sort()
	check(replacements == expected_replacements, "Ten intended prop blockers use scene-owned collision (three footprints relocated unchanged)")
	var props := level.get_node("HallMachinery")
	var press: Node3D = props.get_node("Blocker51PressA")
	for name in ["Blocker51PressA","Blocker52PressB"]:
		var machine: Node3D = props.get_node(name)
		machine.set_physics_process(false)
		machine.set_pose(0.0)
	for i in 3: await physics_frame
	for name in ["Blocker51PressA","Blocker52PressB"]:
		var machine: Node3D = props.get_node(name)
		var p := machine.global_position
		check(ray(level,p+Vector3(0,2.8,3.1),p+Vector3(0,2.8,-3.1)).is_empty(),name+" working bay is genuinely open to rays")
		var raised := ray(level,p+Vector3(0,3.3,3.1),p+Vector3(0,3.3,-3.1))
		check(not raised.is_empty() and raised.collider==machine.get_node("MovingHead"),name+" raised head has matching collision")
		machine.set_pose(1.0)
		await physics_frame
		await physics_frame
		var lowered := ray(level,p+Vector3(0,2.22,3.1),p+Vector3(0,2.22,-3.1))
		check(not lowered.is_empty() and lowered.collider==machine.get_node("MovingHead"),name+" lowered head collision follows motion")
	var missing := ray(level,Vector3(-49,4,-31),Vector3(-49,0.5,-31))
	check(not missing.is_empty() and absf(missing.position.y-1.4)<0.02,"Removed top crate has no invisible collision")
	check(props.get_node("Blocker50Crates").get_child_count()==6,"Six cases in the main stack")
	check(props.has_node("Blocker103LooseSupplyCase/LooseCase"),"Seventh case is separately placed on floor")
	check(props.get_node("Blocker55DrumWasher").has_node("Supply000") and props.get_node("Blocker56DrumWasher").has_node("Supply000"),"Both pit stacks use matching supply cases")
	check(props.get_node("Blocker57DrumWasher").has_node("Chassis") and props.get_node("Blocker57DrumWasher").has_node("OverheadGuard") and props.get_node("Blocker57DrumWasher").has_node("LiftCarriage"),"Eastern pit bay has parked forklift")
	var low := 99.0
	var high := -99.0
	for i in 104:
		press._physics_process(0.05)
		var y: float = press.get_node("MovingHead").position.y
		low = minf(low,y)
		high = maxf(high,y)
	check(high-low>1.0 and press.steam_pulses>=1,"Press completes a stroke and triggers steam")
	press.set_physics_process(true)
	var before: float = press.clock
	paused = true
	for i in 12: await process_frame
	check(is_equal_approx(press.clock,before),"Press animation respects pause")
	paused = false
	for i in 4: await physics_frame
	check(press.clock>before,"Press resumes with the world")
	for node in level.find_children("*","Label3D",true,false):
		if not node is Label3D or not node.text in ["PRODUCTION LINE (PRODUCING)","DAYS WITHOUT A HOOMAN INCIDENT: 0"]: continue
		var board: MeshInstance3D = node.get_parent().get_node("Board")
		var font: Font = node.font if node.font else ThemeDB.fallback_font
		var text_width: float = font.get_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,node.font_size).x*node.pixel_size
		check(text_width<board.mesh.get_aabb().size.x*0.9,"Placard text fits with margins: "+node.text)
		if "PRODUCTION" in node.text:
			check(absf(board.global_position.z+69.72)<0.01 and board.global_position.y>5.5,"Production sign is mounted on wall above railing")
		else:
			check(board.mesh.get_aabb().size.x>=12.0 and node.modulate.r>0.9,"Incident sign is wider with contrasting lettering")
	check(level.get_node("HallDoorFrames").get_child_count()==15,"Five hall openings have jambs and lintels")
	for x in [-31.6,-30.0,-28.4]:
		check(ray(level,Vector3(x,1.6,-27),Vector3(x,1.6,-25)).is_empty(),"Hall entry clear at x="+str(x))
	level.queue_free()
	await process_frame
	print("HALL FEEDBACK TEST: ","PASS" if failures==0 else "FAIL")
	quit(1 if failures else 0)
