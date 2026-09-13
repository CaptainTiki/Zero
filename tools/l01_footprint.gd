extends SceneTree
## Reports the occupied surface footprint of Level 01 so new sections can be
## planned into genuinely empty space. Prints per-node x/z extents.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var level = load("res://scenes/levels/l01_district04.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var min_x := 1e9
	var max_x := -1e9
	var min_z := 1e9
	var max_z := -1e9
	var rows := []
	for child in level.get_children():
		if not (child is Node3D):
			continue
		var aabb := AABB()
		var have := false
		for m in _meshes(child):
			var box: AABB = m.global_transform * m.get_aabb()
			aabb = box if not have else aabb.merge(box)
			have = true
		if not have:
			continue
		# Ground slabs, the far bank and the skyline backdrop are not playable
		# occupancy; they would fill every cell.
		var span_x: float = aabb.end.x - aabb.position.x
		var span_z: float = aabb.end.z - aabb.position.z
		var nm := String(child.name)
		if span_x * span_z > 4000.0 or nm.begins_with("Ground") or nm.contains("Beyond") or nm.contains("Skyline") or nm.contains("FarBank") or nm.contains("Backdrop"):
			print("  (excluded as backdrop) %-20s x %7.1f..%7.1f  z %7.1f..%7.1f" % [nm, aabb.position.x, aabb.end.x, aabb.position.z, aabb.end.z])
			continue
		min_x = minf(min_x, aabb.position.x)
		max_x = maxf(max_x, aabb.end.x)
		min_z = minf(min_z, aabb.position.z)
		max_z = maxf(max_z, aabb.end.z)
		rows.append([child.name, aabb.position.x, aabb.end.x, aabb.position.z, aabb.end.z])
	print("LEVEL FOOTPRINT  x %.1f .. %.1f    z %.1f .. %.1f" % [min_x, max_x, min_z, max_z])
	print("--- nodes reaching north of z -70 ---")
	for r in rows:
		if r[3] < -70.0:
			print("  %-22s x %7.1f..%7.1f   z %7.1f..%7.1f" % [r[0], r[1], r[2], r[3], r[4]])
	print("--- occupancy grid, 20-unit cells (x across, z down), # = geometry ---")
	var x0 := int(floor(min_x / 20.0))
	var x1 := int(ceil(max_x / 20.0))
	var z0 := int(floor(min_z / 20.0))
	var z1 := int(ceil(max_z / 20.0))
	var header := "        "
	for cx in range(x0, x1):
		header += "%-3d" % (cx * 20)
	print(header)
	for cz in range(z0, z1):
		var line := "z%5d  " % (cz * 20)
		for cx in range(x0, x1):
			var cell := Rect2(cx * 20, cz * 20, 20, 20)
			var filled := false
			for r in rows:
				if cell.intersects(Rect2(r[1], r[3], maxf(r[2] - r[1], 0.1), maxf(r[4] - r[3], 0.1))):
					filled = true
					break
			line += " # " if filled else " . "
		print(line)
	level.queue_free()
	await process_frame
	quit(0)

func _meshes(node: Node) -> Array:
	var out := []
	if node is MeshInstance3D and node.mesh != null:
		out.append(node)
	for c in node.get_children():
		out += _meshes(c)
	return out
