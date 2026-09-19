extends "res://tools/factory_admin_art.gd"
## Open rails use actual bar collision; grating keeps the existing walking slabs.
var posts := {}
var rail_body: StaticBody3D
var replaced_rails := 0
var replaced_decks := 0

func build_walkways(hall: RefCounted, plan: Dictionary, whole_factory := false) -> void:
	kit = hall.kit
	materials = hall.materials
	details = Node3D.new()
	kit.add(details,"FactoryWalkways" if whole_factory else "HallWalkways")
	rail_body = StaticBody3D.new()
	kit.add(rail_body,"RailCollision",details)
	var originals: Array = kit.art.get_children()
	if not whole_factory:
		fix_corridor_caps(originals)
		fix_corridor_joins(originals)
	for node in originals:
		if not node is MeshInstance3D or not node.mesh is BoxMesh or (not whole_factory and not hall.inside(node.position)) or node.get_meta("open_rail",false) or node.get_meta("grated_deck",false):
			continue
		var label := str(node.name)
		var size: Vector3 = node.mesh.size
		if label.begins_with("Rail") and node.position.y > 1.0:
			var along := Vector3.RIGHT if size.x > size.z else Vector3.BACK
			var length := maxf(size.x,size.z)-0.12 # bake extends each rail 6cm at its joins
			var center: Vector3 = node.position-Vector3(0,size.y/2.0,0)
			replace_rail(node,center-along*length/2.0,center+along*length/2.0)
		elif label.begins_with("Floor") and node.position.y > 1.0 and node.mesh.material.resource_path.ends_with("/metal_blue.tres"):
			deck(node)

	for i in plan.ramps.size():
		var r: Dictionary = plan.ramps[i]
		var low := Vector3(r.low[0],r.low[1],r.low[2])
		var high := Vector3(r.high[0],r.high[1],r.high[2])
		if (not whole_factory and (not hall.inside(low) or not hall.inside(high))) or low.y < 0.0 or high.y < 2.0:
			continue
		var ramp_node: MeshInstance3D = kit.art.get_node("Stair%d" % i)
		if ramp_node.get_meta("grated_deck",false): continue
		deck(ramp_node)
		for offset in r.get("rails",[]):
			var side := "A" if float(offset) < 0.0 else "B"
			var node: MeshInstance3D = kit.art.get_node("Stair%dRail%s" % [i,side])
			var lateral := Vector3(0,0,offset) if r.along_x else Vector3(offset,0,0)
			replace_rail(node,low.lerp(high,maxf(0.0,1.0-low.y)/(high.y-low.y))+lateral,high+lateral)
	if whole_factory:
		for i in plan.get("round_decks",[]).size():
			round_walkway(i,plan.round_decks[i],plan)
	print(("FACTORY" if whole_factory else "HALL")+" WALKWAYS: %d rails, %d posts, %d grated decks" % [replaced_rails,posts.size(),replaced_decks])

func solid(label: String, at: Vector3, size: Vector3, material: String, basis := Basis.IDENTITY) -> void:
	var node := block(label,at,size,material,0.006)
	node.basis = basis
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.transform = node.transform
	kit.add(shape,label+"Shape",rail_body)

func connection(label: String, a: Vector3, b: Vector3, width: float, height: float, material: String) -> void:
	var direction := (b-a).normalized()
	var x := direction
	var z := x.cross(Vector3.UP).normalized()
	var y := z.cross(x).normalized()
	solid(label,(a+b)/2.0,Vector3(a.distance_to(b),height,width),material,Basis(x,y,z))

func replace_rail(old: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	old.hide()
	old.set_meta("open_rail",true)
	var body: StaticBody3D = kit.art.get_node(str(old.name)+"Solid")
	for child in body.get_children():
		if child is CollisionShape3D:
			child.disabled = true
			child.set_meta("replaced_by_open_rail",true)
			if details.name=="FactoryWalkways": child.set_meta("factory_shared_replaced",true)
	emit_rail(str(old.name),a,b)
	replaced_rails += 1

func emit_rail(label: String, a: Vector3, b: Vector3) -> void:
	var horizontal := Vector2(b.x-a.x,b.z-a.z).length()
	var bays := maxi(1,ceili(horizontal/1.1))
	for i in bays+1:
		var p := junction_clearance(a.lerp(b,float(i)/bays))
		var key := str(p.snapped(Vector3(0.001,0.001,0.001)))
		if not posts.has(key):
			posts[key] = true
			solid(label+"Post"+str(i),p+Vector3(0,0.55,0),Vector3(0.075,1.1,0.075),"rim")
		if i < bays:
			var q := junction_clearance(a.lerp(b,float(i+1)/bays))
			var delta := (q-p).normalized()*0.039
			connection(label+"Handrail"+str(i),p+delta+Vector3(0,1.055,0),q-delta+Vector3(0,1.055,0),0.095,0.09,"rim")
			connection(label+"Midrail"+str(i),p+delta+Vector3(0,0.55,0),q-delta+Vector3(0,0.55,0),0.045,0.045,"teal")

func deck(old: MeshInstance3D) -> void:
	var size: Vector3 = old.mesh.size
	old.hide()
	old.set_meta("grated_deck",true)
	var start := details.get_child_count()
	var label := str(old.name)
	var edge := minf(0.08,minf(size.x,size.z)*0.2)
	# Frame tops exactly meet the original walking plane; inset sheet does not overlap them.
	for side in [-1.0,1.0]:
		block(label+"FrameX"+str(side),Vector3(side*(size.x-edge)/2.0,0,0),Vector3(edge,size.y,size.z-2*edge),"dark")
		block(label+"FrameZ"+str(side),Vector3(0,0,side*(size.z-edge)/2.0),Vector3(size.x,size.y,edge),"dark")
	var material := ShaderMaterial.new()
	material.shader = load("res://materials/fidelity/grating.gdshader")
	material.set_shader_parameter("metal_texture",load("res://art/material_studies/cc0_candidates/Metal038/albedo_128.png"))
	var panel_size := Vector2(size.x-2*edge,size.z-2*edge)
	material.set_shader_parameter("panel_size",panel_size)
	var plane := PlaneMesh.new()
	plane.size = panel_size
	plane.material = material
	var sheet := MeshInstance3D.new()
	sheet.mesh = plane
	sheet.position.y = size.y/2.0
	sheet.set_meta("grating_sheet",true)
	kit.add(sheet,label+"Grating",details)
	# Sparse bearers underneath support the flat alpha sheet, including on the ramps.
	var along_x := size.x > size.z
	var length := maxf(size.x,size.z)
	var bays := maxi(1,ceili(length/2.0))
	for i in range(1,bays):
		var offset := -length/2.0+length*float(i)/bays
		var at := Vector3(offset,size.y/2.0-0.07,0) if along_x else Vector3(0,size.y/2.0-0.07,offset)
		var span := Vector3(0.055,0.08,size.z-2*edge) if along_x else Vector3(size.x-2*edge,0.08,0.055)
		block(label+"Bearer"+str(i),at,span,"teal")
	for i in range(start,details.get_child_count()):
		var node := details.get_child(i) as Node3D
		node.transform = old.transform*node.transform
	replaced_decks += 1

func fix_corridor_caps(originals: Array) -> void:
	# Include the service corridor from the pit to the pump room, not just pit walls.
	var changed := 0
	for node in originals:
		if not node is MeshInstance3D or not node.mesh is BoxMesh or not str(node.name).begins_with("Wall"):
			continue
		var p: Vector3 = node.position
		var size: Vector3 = node.mesh.size
		if p.x < -62.21 or p.x > 14.21 or p.z < -84.21 or p.z > -25.79 or p.y >= 0.0:
			continue
		if absf(p.y+size.y/2.0) > 0.001:
			continue
		node.mesh = node.mesh.duplicate()
		node.mesh.size.y -= 0.025
		node.position.y -= 0.0125
		node.set_meta("pit_cap_lowered",true)
		changed += 1
	print("PIT / CORRIDOR CAP FIX: ",changed," wall tops lowered 25mm; floor and collision unchanged")

func junction_clearance(p: Vector3) -> Vector3:
	# Flare the two shared entrance posts; a glancing turn must not catch their square ends.
	if p.distance_to(Vector3(-35,4,-68)) < 0.01:
		return p+Vector3(-0.14,0,0)
	if p.distance_to(Vector3(-33,4,-68)) < 0.01:
		return p+Vector3(0.14,0,0)
	return p

func fix_corridor_joins(originals: Array) -> void:
	# The bake extends boxes at joins. Keep the corner in the Z-running wall and
	# butt the X-running wall against it, so their visible faces cannot fight.
	var changed := 0
	for node in originals:
		if not node is MeshInstance3D or not node.get_meta("pit_cap_lowered",false):
			continue
		var size: Vector3 = node.mesh.size
		var axis := 0 if size.x > size.z else 2
		var lower: float = node.position[axis]-size[axis]/2.0
		var upper: float = node.position[axis]+size[axis]/2.0
		var initial_lower := lower
		var initial_upper := upper
		for other in originals:
			if other == node or not other is MeshInstance3D or not other.get_meta("pit_cap_lowered",false):
				continue
			var os: Vector3 = other.mesh.size
			var oa := 0 if os.x > os.z else 2
			var perpendicular := axis == 0 and oa == 2
			var lintel := axis == oa and size.y < os.y-0.1
			if not perpendicular and not lintel:
				continue
			var cross_axis := 2-axis
			if absf(node.position[cross_axis]-other.position[cross_axis]) >= (size[cross_axis]+os[cross_axis])/2.0-0.001:
				continue
			if absf(node.position.y+size.y/2.0-other.position.y-os.y/2.0)>0.001:
				continue
			if perpendicular and absf(size.y-os.y)>0.001:
				continue
			var ol: float = other.position[axis]-os[axis]/2.0
			var ou: float = other.position[axis]+os[axis]/2.0
			if ol <= lower+0.001 and ou > lower and ou < upper:
				lower = ou
			if ou >= upper-0.001 and ol < upper and ol > lower:
				upper = ol
		if absf(lower-initial_lower)+absf(upper-initial_upper)<0.001:
			continue
		node.mesh = node.mesh.duplicate()
		size[axis] = upper-lower
		node.mesh.size = size
		var at: Vector3 = node.position
		at[axis] = (lower+upper)/2.0
		node.position = at
		node.set_meta("corridor_join_trimmed",true)
		changed += 1
	print("PIT / CORRIDOR JOIN FIX: ",changed," wall visuals meet flush; collision unchanged")

func round_walkway(index: int, spec: Dictionary, plan: Dictionary) -> void:
	var label := "RoundDeck%d" % index
	var center := Vector3(spec.centre[0],spec.centre[1],spec.centre[2])
	var radius: float = spec.r
	var old: MeshInstance3D = kit.art.get_node(label+"Floor")
	old.hide()
	old.set_meta("grated_deck",true)
	var ring: CSGShape3D = kit.art.get_node(label+"Rail")
	ring.hide()
	ring.use_collision = false
	ring.set_meta("replaced_by_open_rail",true)
	ring.set_meta("factory_shared_replaced",true)
	# Match the original 48-sided boundary, splitting explicitly at its door cut.
	var angles: Array[float] = [0.0,360.0]
	for n in range(1,48): angles.append(n*7.5)
	for gap in spec.gaps:
		angles.append(float(gap[0]))
		angles.append(float(gap[1]))
	angles.sort()
	for i in angles.size()-1:
		var mid := (angles[i]+angles[i+1])*0.5
		var in_gap := false
		for gap in spec.gaps:
			if mid>=gap[0] and mid<=gap[1]: in_gap = true
		if in_gap: continue
		var a := deg_to_rad(angles[i])
		var b := deg_to_rad(angles[i+1])
		emit_rail(label+"Arc"+str(i),center+Vector3(sin(a),0,-cos(a))*(radius-0.10),center+Vector3(sin(b),0,-cos(b))*(radius-0.10))
	# The exit bridge overlaps the original disc. Cut that footprint out of the
	# visible sheet/frame so two coplanar grates cannot flicker at the entrance.
	var cutouts: Array[Rect2] = []
	for piece in plan.boxes:
		if piece.kind!="floor" or piece.m!="metal_blue" or absf(piece.c[1]+piece.s[1]/2.0-center.y)>0.01: continue
		var rect := Rect2(Vector2(piece.c[0]-piece.s[0]/2.0-center.x,piece.c[2]-piece.s[2]/2.0-center.z),Vector2(piece.s[0],piece.s[2]))
		if rect.intersects(Rect2(Vector2(-radius,-radius),Vector2(radius*2,radius*2))): cutouts.append(rect)
	var grating := ShaderMaterial.new()
	grating.shader = load("res://materials/fidelity/grating.gdshader")
	grating.set_shader_parameter("metal_texture",load("res://art/material_studies/cc0_candidates/Metal038/albedo_128.png"))
	grating.set_shader_parameter("panel_size",Vector2(radius*2,radius*2))
	var sheet := SurfaceTool.new()
	sheet.begin(Mesh.PRIMITIVE_TRIANGLES)
	sheet.set_material(grating)
	var frame := SurfaceTool.new()
	frame.begin(Mesh.PRIMITIVE_TRIANGLES)
	frame.set_material(materials.dark)
	for i in 48:
		var a := TAU*i/48.0
		var b := TAU*(i+1)/48.0
		var va := Vector3(sin(a),0,-cos(a))
		var vb := Vector3(sin(b),0,-cos(b))
		clipped_top(sheet,[Vector3.ZERO,vb*(radius-0.08),va*(radius-0.08)],radius,cutouts)
		clipped_top(frame,[va*(radius-0.08),vb*(radius-0.08),va*radius],radius,cutouts)
		clipped_top(frame,[va*radius,vb*(radius-0.08),vb*radius],radius,cutouts)
		# Give the perimeter actual thickness, matching the rectangular deck frames.
		var normal := (va+vb).normalized()
		for p in [va*radius,vb*radius,va*radius-Vector3(0,0.3,0),vb*radius,vb*radius-Vector3(0,0.3,0),va*radius-Vector3(0,0.3,0)]:
			frame.set_normal(normal)
			frame.add_vertex(p)
	var mesh := MeshInstance3D.new()
	mesh.mesh = sheet.commit()
	mesh.position = center
	mesh.set_meta("grating_sheet",true)
	kit.add(mesh,label+"Grating",details)
	var edge := MeshInstance3D.new()
	edge.mesh = frame.commit()
	edge.position = center
	kit.add(edge,label+"Frame",details)
	replaced_decks += 1
	replaced_rails += 1

func clip_plane(poly: Array, axis: int, edge: float, keep_less: bool) -> Array:
	var result: Array = []
	if poly.is_empty(): return result
	var previous: Vector3 = poly.back()
	var was_inside := previous[axis]<=edge if keep_less else previous[axis]>=edge
	for current: Vector3 in poly:
		var is_inside := current[axis]<=edge if keep_less else current[axis]>=edge
		if is_inside!=was_inside:
			result.append(previous.lerp(current,(edge-previous[axis])/(current[axis]-previous[axis])))
		if is_inside: result.append(current)
		previous=current
		was_inside=is_inside
	return result

func clipped_top(tool: SurfaceTool, triangle: Array, radius: float, cutouts: Array[Rect2]) -> void:
	var polygons: Array = [triangle]
	for rect in cutouts:
		var remaining: Array = []
		for poly in polygons:
			remaining.append(clip_plane(poly,0,rect.position.x,true))
			remaining.append(clip_plane(poly,0,rect.end.x,false))
			var middle := clip_plane(clip_plane(poly,0,rect.position.x,false),0,rect.end.x,true)
			remaining.append(clip_plane(middle,2,rect.position.y,true))
			remaining.append(clip_plane(middle,2,rect.end.y,false))
		polygons=remaining.filter(func(poly: Array) -> bool: return poly.size()>=3)
	for poly in polygons:
		for j in range(1,poly.size()-1):
			for p: Vector3 in [poly[0],poly[j],poly[j+1]]:
				tool.set_normal(Vector3.UP)
				tool.set_uv(Vector2(p.x,p.z)/(radius*2)+Vector2(0.5,0.5))
				tool.add_vertex(p)
