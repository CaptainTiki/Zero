extends "res://tools/factory_hall_art.gd"
## Q-marker polish: signs and visual seams, with world collision preserved.
func apply(builder: SceneTree) -> void:
	kit=builder
	make_palette()
	details=Node3D.new()
	kit.add(details,"FactoryPolish")
	silo_sign_brackets()
	# Interior returns must stop at the facade's inner surface, not pierce its face.
	trim_end("Wall155",0,-50.2,false)
	trim_end("Wall11",0,6.2,true)
	trim_end("Wall13",0,6.2,true)
	trim_end("Wall27",2,-129.8,true)
	trim_end("Wall28",2,-129.8,true)
	var caps := 0
	for node in kit.art.get_children():
		if not node is MeshInstance3D or not node.mesh is BoxMesh or not str(node.name).begins_with("Wall"): continue
		if node.position.y>=0 or absf(node.position.y+node.mesh.size.y/2.0)>0.001: continue
		node.mesh=node.mesh.duplicate()
		node.mesh.size.y-=0.025
		node.position.y-=0.0125
		node.set_meta("floor_cap_lowered",true)
		caps+=1
	print("FACTORY POLISH: authored signs retained, silo brackets, 5 flush wall ends, ",caps," additional basement caps separated")

func trim_end(label: String,axis: int,edge: float,lower: bool) -> void:
	var node: MeshInstance3D=kit.art.get_node(label)
	var old_size: Vector3=node.mesh.size
	var old_position: Vector3=node.position
	var start: float=edge if lower else old_position[axis]-old_size[axis]/2.0
	var end: float=old_position[axis]+old_size[axis]/2.0 if lower else edge
	var size:=old_size
	size[axis]=end-start
	node.mesh=node.mesh.duplicate()
	node.mesh.size=size
	node.position[axis]=(start+end)/2.0
	node.set_meta("polish_join_trimmed",true)
	# Keep admin skirting/dado attached to the shortened wall return.
	for suffix in ["Skirt","Dado","TopTrim"]:
		var trim:=kit.art.get_node_or_null("AdminArt/"+label+suffix) as MeshInstance3D
		if trim==null: continue
		trim.mesh=trim.mesh.duplicate()
		trim.mesh.size[axis]+=size[axis]-old_size[axis]
		trim.position[axis]=node.position[axis]

func silo_sign_brackets() -> void:
	# A flat placard on a round silo needs real supports at both ends.
	var sign: Node3D=kit.art.get_node("Sign14")
	for offset in [-2.0,2.0]:
		var wall_x:=2.0-sqrt(4.0*4.0-offset*offset)
		var back_x:=sign.position.x+0.07
		block("SiloSignBracket"+str(offset),Vector3((back_x+wall_x)/2.0,sign.position.y,23.0+offset),Vector3(wall_x-back_x+0.02,0.12,0.10),"dark",0.01)
