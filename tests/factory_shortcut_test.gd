extends SceneTree
## Walks every short way in the plan (P.alt) with the player's own collision body. The golden
## path is walked by factory_route_test, which cannot catch a way that has been walled off since
## it stopped using it: trimming a corridor left a wall baked across the pump room tunnel and
## only a playtest found it (September 17, 2026).

const PLAN_ROUTE := preload("res://tests/factory_waypoints.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS  ", message)
	else:
		failures += 1
		push_error(message)
		print("FAIL  ", message)

func run() -> void:
	var level = load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(level)
	# No fights on the walk, the same as the route test.
	for actor in get_nodes_in_group("enemies"):
		actor.get_parent().remove_child(actor)
		actor.queue_free()
	for area in get_nodes_in_group("ambush"):
		area.get_parent().remove_child(area)
		area.queue_free()
	var original = level.get_node_or_null("Player")
	if original:
		original.process_mode = Node.PROCESS_MODE_DISABLED
	for door in level.get_children():
		if String(door.name).begins_with("KickDoor") and door.has_method("apply_kick"):
			door.apply_kick(10.0, door.global_position + Vector3(0, 1, 3), 11.0)
	var walker = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(walker)
	walker.set_physics_process(false)
	var ways: Array = PLAN_ROUTE.alts()
	check(not ways.is_empty(), "the plan has short ways to walk")
	for way in ways:
		var points: Array = way["pts"]
		walker.position = points[0] + Vector3(0, 0.3, 0)
		for i in 30:
			await physics_frame
		var walked := 0.0
		var stopped := false
		for index in range(1, points.size()):
			var target: Vector3 = points[index]
			var reached := await _walk_to(walker, target)
			walked += reached["distance"]
			if not reached["arrived"]:
				check(false, "%s: stopped at %s on the way to waypoint %d %s" % [way["name"], walker.position, index, target])
				stopped = true
				break
		if not stopped:
			check(true, "%s: walked %.0f units end to end" % [way["name"], walked])
	print("FACTORY shortcut failures: ", failures)
	walker.queue_free()
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)

## Walks to one point the way the route test does, and says whether it got there.
func _walk_to(walker: Node3D, target: Vector3) -> Dictionary:
	var distance := 0.0
	var stuck := 0
	var frames := 0
	var last: Vector3 = walker.position
	while true:
		await physics_frame
		frames += 1
		var flat: Vector3 = target - walker.position
		flat.y = 0.0
		if flat.length() < 0.8:
			break
		var rise: float = target.y - walker.position.y
		var vy := -2.0
		if rise > 0.3 and walker.is_on_floor() and flat.length() < 2.2:
			vy = 4.5
		elif not walker.is_on_floor():
			vy = walker.velocity.y - 9.8 / 60.0
		walker.velocity = Vector3(flat.normalized().x * 6.0, vy, flat.normalized().z * 6.0)
		walker.move_and_slide()
		var moved: Vector3 = walker.position - last
		moved.y = 0.0
		distance += moved.length()
		last = walker.position
		stuck = stuck + 1 if moved.length() < 0.01 else 0
		if stuck > 40 or frames > 3000:
			break
	return {"arrived": walker.position.distance_to(target) < 2.0, "distance": distance}
