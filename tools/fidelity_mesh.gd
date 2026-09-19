extends RefCounted
## Shared modest bevel geometry for the approved room and factory prop pass.
static func chamfer_face(st: SurfaceTool, points: Array) -> void:
	var center := Vector3.ZERO
	for p in points: center += p
	center /= float(points.size())
	var normal: Vector3 = (points[1]-points[0]).cross(points[2]-points[0]).normalized()
	if normal.dot(center)<0.0: normal = -normal
	# Procedural Godot mesh front faces use clockwise winding.
	if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0.0:
		points.reverse()
	for i in range(1,points.size()-1):
		for j in [0,i,i+1]:
			st.set_normal(normal)
			st.add_vertex(points[j])

static func beveled_mesh(size: Vector3, amount: float, material: Material) -> ArrayMesh:
	var h := size*0.5
	var r := minf(amount, minf(h.x,minf(h.y,h.z))*0.45)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	for axis in 3:
		var a := (axis+1)%3
		var b := (axis+2)%3
		for sign_value in [-1.0,1.0]:
			var corners: Array = []
			for pair in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var p := Vector3.ZERO
				p[axis] = h[axis]*sign_value
				p[a] = (h[a]-r)*pair.x
				p[b] = (h[b]-r)*pair.y
				corners.append(p)
			chamfer_face(st,corners)
	# Twelve bevel strips.
	for axis in 3:
		var a := (axis+1)%3
		var b := (axis+2)%3
		for sa in [-1.0,1.0]:
			for sb in [-1.0,1.0]:
				var corners: Array = []
				for pair in [Vector2(-1,0),Vector2(1,0),Vector2(1,1),Vector2(-1,1)]:
					var p := Vector3.ZERO
					p[axis] = (h[axis]-r)*pair.x
					p[a] = (h[a]-(r if pair.y>0 else 0.0))*sa
					p[b] = (h[b]-(0.0 if pair.y>0 else r))*sb
					corners.append(p)
				chamfer_face(st,corners)
	for sx in [-1.0,1.0]:
		for sy in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				chamfer_face(st,[Vector3(h.x*sx,(h.y-r)*sy,(h.z-r)*sz),Vector3((h.x-r)*sx,h.y*sy,(h.z-r)*sz),Vector3((h.x-r)*sx,(h.y-r)*sy,h.z*sz)])
	return st.commit()

