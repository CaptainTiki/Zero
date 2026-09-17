extends "res://tools/art_kit.gd"
## Level-scale building blocks shared by every level builder: floors, walls,
## buildings, prop instances, triggers, secrets, ambushes, beat lines, lit
## corridors, ramps, catwalks and hollow containers.
##
## Primitives live one layer down in art_kit.gd. Content lives one layer up, in
## each level's own builder, and is not shared.

## Storm-drain style corridors: floor top, mid height and interior height.
const DRAIN_FLOOR := -5.5
const DRAIN_MID := -3.75
const DRAIN_H := 3.5

## Solid slab with its top at `top`.
func slab(label: String, x0: float, z0: float, x1: float, z1: float, top: float, thickness: float, material: String) -> void:
	box(label, Vector3((x0 + x1) / 2.0, top - thickness / 2.0, (z0 + z1) / 2.0), Vector3(absf(x1 - x0), thickness, absf(z1 - z0)), material, 0, true)

## Kerb wedge so a 0.15 kerb is walkable: CharacterBody3D has no step-up.
## `rise_dir` is the world direction the wedge climbs toward (+X, -X, +Z or -Z).

## Splits [lo, hi] by gap ranges; returns the kept segments.
func _segments(lo: float, hi: float, gaps: Array) -> Array:
	var kept := [[lo, hi]]
	for gap in gaps:
		var next := []
		for seg in kept:
			if gap[1] <= seg[0] or gap[0] >= seg[1]:
				next.append(seg)
				continue
			if gap[0] > seg[0]:
				next.append([seg[0], gap[0]])
			if gap[1] < seg[1]:
				next.append([gap[1], seg[1]])
		kept = next
	return kept

## Road along X or Z with pavements either side, kerb wedges, and a centre line.
## `gaps_a` drops pavement on the north/west side, `gaps_b` on the south/east side,
## for junction mouths where the kerb is dropped.

## Building shell: solid block from ground to `height`.
func building(label: String, x0: float, z0: float, x1: float, z1: float, height: float, material := "plaster_grey") -> void:
	box(label, Vector3((x0 + x1) / 2.0, height / 2.0, (z0 + z1) / 2.0), Vector3(absf(x1 - x0), height, absf(z1 - z0)), material, 0, true)

func wall(label: String, x0: float, z0: float, x1: float, z1: float, height: float, material := "concrete_dark") -> void:
	var w := maxf(absf(x1 - x0), 0.6)
	var d := maxf(absf(z1 - z0), 0.6)
	box(label, Vector3((x0 + x1) / 2.0, height / 2.0, (z0 + z1) / 2.0), Vector3(w, height, d), material, 0, true)

## Vehicle-scale blocker that still shows the street beyond: a bus across the road.

func scene(label: String, path: String, at: Vector3, yaw := 0.0) -> Node:
	var node: Node = load(path).instantiate()
	node.name = label
	art.add_child(node)
	node.owner = art
	if node is Node3D:
		node.position = at
		node.rotation.y = yaw
	return node

func trigger(label: String, at: Vector3, size: Vector3, group: String, meta: Dictionary = {}) -> Area3D:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = at
	for key in meta:
		area.set_meta(key, meta[key])
	add(area, label)
	area.add_to_group(group, true)
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	shape.shape = b
	area.add_child(shape)
	shape.owner = art
	return area

## A secret: reward pickups plus a trigger that counts once.

## A secret: reward pickups plus a trigger that counts once.
func secret(label: String, at: Vector3, reward: String) -> void:
	scene(label + "Reward", reward, at)
	trigger(label, at + Vector3(0, 1.0, 0), Vector3(4.5, 3.0, 4.5), "secrets")

## Dead-end ambush: trigger at the end, enemies spawn at the mouth.

## Dead-end ambush: trigger at the end, enemies spawn at the mouth. `kind` is fodder,
## rammer or hunter.
func ambush(label: String, at: Vector3, size: Vector3, spawn: Vector3, count: int, kind := "fodder") -> void:
	trigger(label, at, size, "ambush", {"spawn": spawn, "count": count, "kind": kind})

func beat_line(label: String, at: Vector3, size: Vector3, beat: int) -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = at
	area.set_meta("beat", beat)
	add(area, label)
	area.add_to_group("beat_lines", true)
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	shape.shape = b
	area.add_child(shape)
	shape.owner = art

# --- world -------------------------------------------------------------------

## A length of drain. `gaps_a`/`gaps_b` open the side walls at junctions, given
## along the run axis (x when along_x, z otherwise).
func drain(label: String, x0: float, z0: float, x1: float, z1: float, along_x: bool, gaps_a: Array = [], gaps_b: Array = []) -> void:
	slab(label + "Floor", x0, z0, x1, z1, DRAIN_FLOOR, 0.8, "concrete")
	slab(label + "Ceil", x0, z0, x1, z1, -1.4, 0.6, "concrete_dark")
	var cx := (x0 + x1) / 2.0
	var cz := (z0 + z1) / 2.0
	var w := absf(x1 - x0)
	var d := absf(z1 - z0)
	var index := 0
	if along_x:
		for seg in _segments(x0, x1, gaps_a):
			box("%sWallA%d" % [label, index], Vector3((seg[0] + seg[1]) / 2.0, DRAIN_MID, z0 - 0.4), Vector3(seg[1] - seg[0], DRAIN_H, 0.8), "concrete_dark", 0, true)
			index += 1
		for seg in _segments(x0, x1, gaps_b):
			box("%sWallB%d" % [label, index], Vector3((seg[0] + seg[1]) / 2.0, DRAIN_MID, z1 + 0.4), Vector3(seg[1] - seg[0], DRAIN_H, 0.8), "concrete_dark", 0, true)
			index += 1
	else:
		for seg in _segments(z0, z1, gaps_a):
			box("%sWallA%d" % [label, index], Vector3(x0 - 0.4, DRAIN_MID, (seg[0] + seg[1]) / 2.0), Vector3(0.8, DRAIN_H, seg[1] - seg[0]), "concrete_dark", 0, true)
			index += 1
		for seg in _segments(z0, z1, gaps_b):
			box("%sWallB%d" % [label, index], Vector3(x1 + 0.4, DRAIN_MID, (seg[0] + seg[1]) / 2.0), Vector3(0.8, DRAIN_H, seg[1] - seg[0]), "concrete_dark", 0, true)
			index += 1
	box(label + "Water", Vector3(cx, DRAIN_FLOOR + 0.06, cz), Vector3(w - 1.0, 0.12, d - 1.0), "glass")
	var run := w if along_x else d
	var count := maxi(1, int(run / 15.0))
	for i in count:
		var t := (float(i) + 0.5) / float(count)
		var at := Vector3(x0 + w * t, -2.4, cz) if along_x else Vector3(cx, -2.4, z0 + d * t)
		drain_light(label + "Light%d" % i, at)

## Nothing down here is lit by the sun, so every run carries its own fixtures.

## Nothing down here is lit by the sun, so every run carries its own fixtures.
func drain_light(label: String, at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(0.82, 1.0, 0.88)
	light.light_energy = 3.2
	light.omni_range = 18.0
	light.position = at
	add(light, label)
	box(label + "Fix", at + Vector3(0, 0.42, 0), Vector3(1.4, 0.14, 0.5), "hazard")

func drain_cap(label: String, at: Vector3, size: Vector3) -> void:
	box(label, at, size, "concrete_dark", 0, true)

## A walkable slope whose feet land flush at both ends, because CharacterBody3D
## has no step-up and a lip of 0.3 stops the player dead. Give it the two ends
## and a width; the tilt, length and centre are worked out here.
## `along_x` runs the slope east-west, otherwise north-south.
func ramp(label: String, low: Vector3, high: Vector3, width: float, along_x: bool, material := "concrete", thickness := 0.4) -> void:
	var run := absf(high.x - low.x) if along_x else absf(high.z - low.z)
	var rise := high.y - low.y
	if run <= 0.01:
		push_warning("ramp %s has no run" % label)
		return
	var tilt := atan(rise / run)
	var length := sqrt(run * run + rise * rise)
	var centre := Vector3((low.x + high.x) / 2.0, (low.y + high.y) / 2.0 - (thickness / 2.0) / cos(tilt), (low.z + high.z) / 2.0)
	if along_x:
		# tilt about Z: positive lifts the +X end, as RoofRamp in the city proves.
		var sign_x := 1.0 if high.x > low.x else -1.0
		box(label, centre, Vector3(length, thickness, width), material, 0, true, sign_x * tilt)
	else:
		# tilt about X: positive lifts the -Z end, matching the rest of the level.
		var node := box(label, centre, Vector3(width, thickness, length), material, 0, true)
		var sign_z := 1.0 if high.z < low.z else -1.0
		node.rotation.x = sign_z * tilt
		var solid := art.get_node_or_null(label + "Solid") as Node3D
		if solid:
			solid.rotation.x = sign_z * tilt

## A rail down one side of a ramp, sloped with it. `offset` is across the ramp from its
## centre line, so half the ramp's width either way. The rail stands 1.1 clear of the
## slope and dips into the ramp's thickness below, leaving no gap to slip under. It starts
## where the ramp is `open_rise` up: stepping off lower than a jump skips nothing, and a
## route can still step onto the ramp's foot from the side.
func ramp_rail(label: String, low: Vector3, high: Vector3, offset: float, along_x: bool, open_rise := 1.0) -> void:
	var run := absf(high.x - low.x) if along_x else absf(high.z - low.z)
	var rise := high.y - low.y
	if run <= 0.01 or rise <= open_rise:
		push_warning("ramp rail %s has no run or no rise above %.1f" % [label, open_rise])
		return
	var side := Vector3(0, 0, offset) if along_x else Vector3(offset, 0, 0)
	var start := low.lerp(high, open_rise / rise)
	# ramp() hangs a box below the line through its ends, so lift the ends until the box's
	# top is the rail's top, measured square to the slope.
	var lift := Vector3(0, 1.1 / cos(atan(rise / run)), 0)
	ramp(label, start + side + lift, high + side + lift, 0.12, along_x, "dark", 1.35)

## A raised walkway with rails down both long sides.
func catwalk(label: String, x0: float, z0: float, x1: float, z1: float, top: float, along_x: bool, material := "metal_blue") -> void:
	slab(label, x0, z0, x1, z1, top, 0.3, material)
	var cx := (x0 + x1) / 2.0
	var cz := (z0 + z1) / 2.0
	var rail_y := top + 0.55
	if along_x:
		var w := absf(x1 - x0)
		box(label + "RailA", Vector3(cx, rail_y, z0 + 0.1), Vector3(w, 1.1, 0.12), "dark", 0, true)
		box(label + "RailB", Vector3(cx, rail_y, z1 - 0.1), Vector3(w, 1.1, 0.12), "dark", 0, true)
	else:
		var d := absf(z1 - z0)
		box(label + "RailA", Vector3(x0 + 0.1, rail_y, cz), Vector3(0.12, 1.1, d), "dark", 0, true)
		box(label + "RailB", Vector3(x1 - 0.1, rail_y, cz), Vector3(0.12, 1.1, d), "dark", 0, true)

## A crate, bin or locker that is hollow, with one face left open. Put the reward
## inside and turn the opening away from the route. `facing` is the world
## direction the opening points.
func container(label: String, at: Vector3, size: Vector3, facing: Vector3, material := "teal") -> void:
	var half := size / 2.0
	var t := 0.12
	var open_x := absf(facing.x) > absf(facing.z)
	box(label + "Floor", at + Vector3(0, -half.y + t / 2.0, 0), Vector3(size.x, t, size.z), material, 0, true)
	box(label + "Lid", at + Vector3(0, half.y - t / 2.0, 0), Vector3(size.x, t, size.z), material, 0, true)
	if open_x:
		var sx: float = -1.0 if facing.x > 0.0 else 1.0
		box(label + "Back", at + Vector3(sx * (half.x - t / 2.0), 0, 0), Vector3(t, size.y, size.z), material, 0, true)
		box(label + "SideA", at + Vector3(0, 0, half.z - t / 2.0), Vector3(size.x, size.y, t), material, 0, true)
		box(label + "SideB", at + Vector3(0, 0, -half.z + t / 2.0), Vector3(size.x, size.y, t), material, 0, true)
	else:
		var sz: float = -1.0 if facing.z > 0.0 else 1.0
		box(label + "Back", at + Vector3(0, 0, sz * (half.z - t / 2.0)), Vector3(size.x, size.y, t), material, 0, true)
		box(label + "SideA", at + Vector3(half.x - t / 2.0, 0, 0), Vector3(t, size.y, size.z), material, 0, true)
		box(label + "SideB", at + Vector3(-half.x + t / 2.0, 0, 0), Vector3(t, size.y, size.z), material, 0, true)

## Any interior needs its own light; there is no sun indoors.
func light(label: String, at: Vector3, tint := Color(1.0, 0.95, 0.85), energy := 3.0, range_units := 18.0, fixture := true) -> void:
	var lamp := OmniLight3D.new()
	lamp.light_color = tint
	lamp.light_energy = energy
	lamp.omni_range = range_units
	lamp.position = at
	add(lamp, label)
	if fixture:
		box(label + "Fix", at + Vector3(0, 0.42, 0), Vector3(1.4, 0.14, 0.5), "hazard")

## Four walls with openings cut in them, which is most of what an interior is.
## `openings` entries are [side, from, to] for a doorway, or [side, from, to,
## y0, y1] for an opening at height, which is how a catwalk crosses a wall.
## Sides are "n", "s", "e", "w"; from/to are world coordinates along that wall.
## Solid wall is built either side of every opening, below it and above it.
func enclosure(label: String, x0: float, z0: float, x1: float, z1: float, height: float, material: String, openings: Array = [], door_height := 3.2) -> void:
	var sides := {
		"n": [z0, true, x0, x1],
		"s": [z1, true, x0, x1],
		"w": [x0, false, z0, z1],
		"e": [x1, false, z0, z1],
	}
	for side in sides:
		var info: Array = sides[side]
		var at: float = info[0]
		var along_x: bool = info[1]
		var lo: float = info[2]
		var hi: float = info[3]
		var here := []
		for opening in openings:
			if String(opening[0]) == side:
				here.append(opening)
		var gaps := []
		for opening in here:
			gaps.append([float(opening[1]), float(opening[2])])
		var index := 0
		for seg in _segments(lo, hi, gaps):
			if along_x:
				wall("%s%s%d" % [label, side.to_upper(), index], seg[0], at - 0.3, seg[1], at + 0.3, height, material)
			else:
				wall("%s%s%d" % [label, side.to_upper(), index], at - 0.3, seg[0], at + 0.3, seg[1], height, material)
			index += 1
		# Fill under and over each opening.
		var piece := 0
		for opening in here:
			var from_at := float(opening[1])
			var to_at := float(opening[2])
			var y0 := 0.0 if opening.size() < 5 else float(opening[3])
			var y1 := door_height if opening.size() < 5 else float(opening[4])
			var span := to_at - from_at
			var mid := (from_at + to_at) / 2.0
			for band in [[0.0, y0], [y1, height]]:
				var lowy: float = band[0]
				var highy: float = band[1]
				if highy - lowy <= 0.05:
					continue
				var cy := (lowy + highy) / 2.0
				var thick := highy - lowy
				var name_text := "%s%sFill%d" % [label, side.to_upper(), piece]
				if along_x:
					box(name_text, Vector3(mid, cy, at), Vector3(span, thick, 0.6), material, 0, true)
				else:
					box(name_text, Vector3(at, cy, mid), Vector3(0.6, thick, span), material, 0, true)
				piece += 1

## A single wall between two points, at any angle. Frees a plan from the grid:
## rooms can be offset, L-shaped or cut across a corner. Build a room as a list
## of runs and simply leave the doorways undrawn.
func wall_run(label: String, from_at: Vector2, to_at: Vector2, height: float, material := "concrete_dark", thickness := 0.6) -> void:
	var delta := to_at - from_at
	var length := delta.length()
	if length <= 0.01:
		return
	var mid := (from_at + to_at) / 2.0
	var yaw := atan2(delta.x, delta.y) - PI / 2.0
	box(label, Vector3(mid.x, height / 2.0, mid.y), Vector3(length, height, thickness), material, yaw, true)

## Wall along a polyline, one run per pair of points. `gaps` names the segment
## indices to skip, which is where the doors go.
func wall_path(label: String, points: Array, height: float, material := "concrete_dark", gaps: Array = [], thickness := 0.6) -> void:
	for i in range(points.size() - 1):
		if gaps.has(i):
			continue
		wall_run("%s%d" % [label, i], points[i], points[i + 1], height, material, thickness)
