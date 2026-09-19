extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1
func run() -> void:
	var level: Node3D=load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(level)
	level.set_process(false)
	level.get_node("Player").process_mode=Node.PROCESS_MODE_DISABLED
	for node in get_nodes_in_group("enemies"):
		node.get_parent().remove_child(node)
		node.queue_free()
	for i in 4: await physics_frame
	var world:=level.get_world_3d().direct_space_state
	var count:=0
	for node in level.find_children("*","Label3D",true,false):
		if not node is Label3D or not node.get_meta("measured_board_fit",false): continue
		var board: MeshInstance3D=node.get_parent().get_node("Board")
		var size: Vector3=board.mesh.get_aabb().size*board.scale.abs()
		var font: Font=node.font if node.font else ThemeDB.fallback_font
		var width: float=font.get_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,node.font_size).x*node.pixel_size
		check(width<size.x*0.9,"Lettering fits "+node.text)
		count+=1
	check(count==31,"All factory placards use measured fitting")
	for id in [9,12,13,21,22,23,24]:
		var board: MeshInstance3D=level.get_node("Sign"+str(id)+"/Board")
		var normal:=board.global_basis.z
		var back:=board.global_position-normal*0.07
		var hit:=world.intersect_ray(PhysicsRayQueryParameters3D.create(back+normal*0.001,back-normal*0.04,1))
		check(not hit.is_empty(),"Sign%d is seated against its wall" % id)
	check(level.has_node("FactoryPolish/SiloSignBracket-2_0"),"Curved silo sign has physical supports")
	for label in ["Wall38","Wall46"]:
		var wall: MeshInstance3D=level.get_node(label)
		check(absf(wall.position.y+wall.mesh.size.y/2.0+0.025)<0.001,"Marked floor/cap seam separated: "+label)
	for spec in [["Wall155",0,-50.2,false],["Wall11",0,6.2,true],["Wall13",0,6.2,true],["Wall27",2,-129.8,true],["Wall28",2,-129.8,true]]:
		var wall: MeshInstance3D=level.get_node(spec[0])
		var edge: float=wall.position[spec[1]]+wall.mesh.size[spec[1]]*(-0.5 if spec[3] else 0.5)
		check(absf(edge-spec[2])<0.001,"Return stops at facade: "+spec[0])
	for path in ["HallDoorFrames/PitTunnelJamb-1_0","FactorySurfaces/ManagerJamb-1_0","FactorySurfaces/OfficeToYardJamb1_0"]:
		var jamb: MeshInstance3D=level.get_node(path)
		var size:=jamb.mesh.get_aabb().size
		check(minf(size.x,size.z)>0.435,"Door liner clears the wall return: "+path)
	# The Q-marked stair is already 4m up: its first metre of rise needs a rail too.
	var hit:=world.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-29.5,4.75,-50),Vector3(-29.5,4.75,-52),1))
	check(not hit.is_empty() and hit.collider.get_parent().name=="HallWalkways","Upper stair foot has real rail collision")
	level.queue_free()
	await process_frame
	print("FACTORY POLISH TEST: ","PASS" if failures==0 else "FAIL")
	quit(1 if failures else 0)
