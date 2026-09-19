extends RefCounted
## Final bake pass: retire only explicitly replaced blockouts, never arbitrary hidden art.
static func detach(node: Node) -> int:
	var count:=1
	for child in node.find_children("*","",true,false): count+=1
	node.get_parent().remove_child(node)
	node.free()
	return count

static func apply(level: Node3D) -> bool:
	var retired: Dictionary={}
	var removed:=0
	for node in level.get_children():
		if not is_instance_valid(node): continue
		var label:=str(node.name)
		var kind:=""
		var replacement:=""
		var remove_body:=false
		if node.get_meta("open_rail",false):
			kind="rail_panel"
			var group:="HallWalkways" if level.has_node("HallWalkways/"+label+"Post0") else "FactoryWalkways"
			replacement=group+"/RailCollision"
			remove_body=true
		elif node.get_meta("grated_deck",false):
			kind="opaque_deck"
			var mesh_name:=label.trim_suffix("Floor") if label.begins_with("RoundDeck") else label
			replacement=("HallWalkways/" if level.has_node("HallWalkways/"+mesh_name+"Grating") else "FactoryWalkways/")+mesh_name+"Grating"
		elif node.get_meta("machine_art_replaced",false):
			kind="machinery_blockout"
			replacement="HallMachinery/"+label
			remove_body=true
		elif node.get_meta("fixture_replaced",false):
			kind="lamp_blockout"
			for group in ["AdminArt","HallArt","FactorySurfaces"]:
				var candidate: String=group+"/"+label.trim_suffix("Fix")+"Fixture"
				if level.has_node(candidate): replacement=candidate; break
		elif node is CSGShape3D and node.get_meta("replaced_by_open_rail",false):
			kind="circular_rail_panel"
			replacement="FactoryWalkways/RailCollision"
			assert(not node.use_collision,"Replacement CSG still owns collision: "+label)
		if kind.is_empty(): continue
		assert(not node.visible,"Refusing to remove visible generated geometry: "+label)
		assert(not replacement.is_empty() and level.has_node(replacement),"Missing replacement for "+label)
		retired[label]={"kind":kind,"replacement":replacement,"art_zone":node.get_meta("art_zone","")}
		if remove_body:
			var body: Node=level.get_node(NodePath(label+"Solid"))
			assert(body.get_child_count()>0)
			for shape in body.get_children():
				assert(shape is CollisionShape3D and shape.disabled,"Refusing to remove live collision: "+label)
			retired[str(body.name)]={"kind":"disabled_blockout_collision","replacement":replacement}
			removed+=detach(body)
		# Deck/ramp floor bodies remain: they are the intentional walking collision.
		removed+=detach(node)
	level.set_meta("retired_blockouts",retired)
	print("FACTORY CLEANUP: removed ",removed," obsolete nodes (",retired.size()," roots); active collision retained")
	return true
