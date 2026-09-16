extends SceneTree
## Two questions a level plan can't answer by eye:
##
## 1. Can the player cut the corner? For every pair of waypoints it compares the
##    straight line against the route between them, and if the straight line is
##    much shorter it checks whether you could actually walk it. Anything it finds
##    is a skip: real distance the player never has to cover.
##
## 2. Can the player be shot from too many places at once? It samples the route
##    and counts how many standing positions on the level have line of sight to
##    each sample within a Hunter's range. High numbers are crossfire.
##
## Reports only; nothing passes or fails.
##   godot --headless --path . -s tools/route_analysis.gd

const SCENE := "res://scenes/levels/factory.tscn"
const ROUTE := preload("res://tests/factory_waypoints.gd").ROUTE

## A skip is only interesting if the straight line saves a decent share of the walk.
const SKIP_RATIO := 0.6
const SKIP_MIN_UNITS := 25.0
const SKIP_MAX_STRAIGHT := 90.0
## Below this the two waypoints are the same place revisited, not a shortcut.
const SKIP_MIN_STRAIGHT := 12.0
## Hunter shot range, from scripts/enemies/hunter.gd.
const THREAT_RANGE := 32.0
const EYE := 1.5
## How closely the route and the threat grid are sampled.
const ROUTE_STEP := 4.0
const GRID_STEP := 6.0
## Above this many threats with a clear shot, a spot is worth looking at.
const CROSSFIRE := 12

var _space: PhysicsDirectSpaceState3D

func _initialize() -> void:
	call_deferred("run")

func _floor_at(x: float, z: float, from_y := 30.0) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, from_y, z), Vector3(x, -30.0, z), 1)
	var hit: Dictionary = _space.intersect_ray(query)
	return hit.position.y if not hit.is_empty() else -999.0

func _fits(at: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	q.shape = cap
	q.transform = Transform3D(Basis(), at + Vector3(0, 0.95, 0))
	q.collision_mask = 1
	return _space.intersect_shape(q, 1).is_empty()

func _clear_line(a: Vector3, b: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(a, b, 1)
	return _space.intersect_ray(query).is_empty()

## Could a player walk straight from a to b: continuous floor, no steps over 0.6,
## and room to stand the whole way.
func _walkable_between(a: Vector3, b: Vector3) -> bool:
	var flat := Vector3(b.x - a.x, 0, b.z - a.z)
	var length := flat.length()
	if length < 0.5:
		return true
	var steps := int(length)
	var previous := _floor_at(a.x, a.z, a.y + 3.0)
	if previous < -900.0:
		return false
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var at := a.lerp(b, t)
		var ground := _floor_at(at.x, at.z, maxf(a.y, b.y) + 3.0)
		if ground < -900.0:
			return false
		if absf(ground - previous) > 0.6:
			return false
		if not _fits(Vector3(at.x, ground, at.z)):
			return false
		previous = ground
	return true

func run() -> void:
	var level = load(SCENE).instantiate()
	root.add_child(level)
	var player = level.get_node_or_null("Player")
	if player:
		player.queue_free()
	for actor in get_nodes_in_group("enemies"):
		actor.queue_free()
	for i in 10:
		await physics_frame
	_space = level.get_world_3d().direct_space_state

	# --- 1. shortcuts ---------------------------------------------------------
	var legs: Array[float] = []
	var total := 0.0
	for i in range(ROUTE.size() - 1):
		var leg: float = (ROUTE[i + 1] - ROUTE[i]).length()
		legs.append(leg)
		total += leg
	print("ROUTE: %d waypoints, %.0f units along the golden path" % [ROUTE.size(), total])
	print("--- shortcuts ---")
	var found := 0
	for i in range(ROUTE.size()):
		for j in range(i + 2, ROUTE.size()):
			var along := 0.0
			for k in range(i, j):
				along += legs[k]
			var straight: float = (ROUTE[j] - ROUTE[i]).length()
			if straight > SKIP_MAX_STRAIGHT or straight < SKIP_MIN_STRAIGHT:
				continue
			if straight > along * SKIP_RATIO:
				continue
			if along - straight < SKIP_MIN_UNITS:
				continue
			if not _walkable_between(ROUTE[i], ROUTE[j]):
				continue
			found += 1
			print("  waypoint %d -> %d skips %.0f units (route %.0f, straight %.0f)  %s -> %s"
				% [i, j, along - straight, along, straight, ROUTE[i], ROUTE[j]])
	if found == 0:
		print("  none: every pair of waypoints is either blocked or barely shorter")

	# --- 2. crossfire ---------------------------------------------------------
	print("--- exposure: standing positions with a clear shot, within %.0f units ---" % THREAT_RANGE)
	var threats: Array[Vector3] = []
	var x := -40.0
	while x <= 95.0:
		var z := -75.0
		while z <= 60.0:
			var ground := _floor_at(x, z)
			if ground > -900.0 and _fits(Vector3(x, ground, z)):
				threats.append(Vector3(x, ground, z))
			z += GRID_STEP
		x += GRID_STEP
	var samples: Array[Vector3] = []
	for i in range(ROUTE.size() - 1):
		var leg: float = legs[i]
		var steps := maxi(1, int(leg / ROUTE_STEP))
		for s in steps:
			samples.append(ROUTE[i].lerp(ROUTE[i + 1], float(s) / float(steps)))
	var worst := []
	var sum := 0
	for sample in samples:
		var eye := sample + Vector3(0, EYE, 0)
		var count := 0
		for threat in threats:
			if threat.distance_to(sample) > THREAT_RANGE:
				continue
			if _clear_line(eye, threat + Vector3(0, EYE, 0)):
				count += 1
		sum += count
		worst.append([count, sample])
	worst.sort_custom(func(a, b): return int(a[0]) > int(b[0]))
	print("  %d route samples, %d standing positions on the level" % [samples.size(), threats.size()])
	print("  average exposed positions per sample: %.1f" % (float(sum) / maxf(float(samples.size()), 1.0)))
	var shown := 0
	for entry in worst:
		if shown >= 8 or int(entry[0]) < CROSSFIRE:
			break
		print("  %3d positions can see %s" % [int(entry[0]), entry[1]])
		shown += 1
	if shown == 0:
		print("  nowhere on the route is exposed to %d or more positions" % CROSSFIRE)
	level.queue_free()
	await process_frame
	quit(0)
