extends SceneTree
## Walks the factory's golden path with the player's own collision body, confirms
## every beat line and the exit are reachable, and reports the distance and the
## walk time with no fights. Par comes from that walk time times 3.

const PLAN_ROUTE := preload("res://tests/factory_waypoints.gd")
var WAYPOINTS: Array = PLAN_ROUTE.route()

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var level = load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(level)
	# No fights on the walk: enemies and ambushes go, so nothing stands in the walker's way
	# or spawns behind it.
	for actor in get_nodes_in_group("enemies"):
		actor.get_parent().remove_child(actor)
		actor.queue_free()
	for area in get_nodes_in_group("ambush"):
		area.get_parent().remove_child(area)
		area.queue_free()
	var original = level.get_node_or_null("Player")
	if original:
		original.process_mode = Node.PROCESS_MODE_DISABLED
	# The machine fight is tested on its own; here the machine is already broken, and the
	# escape still falls apart round the walker so the gaps it leaves get walked.
	var machine = level.get_node_or_null("MachineSetPiece")
	if machine:
		machine.skip(true)
	# Kick doors start shut; open them the way the player would.
	for door in level.get_children():
		if String(door.name).begins_with("KickDoor") and door.has_method("apply_kick"):
			door.apply_kick(10.0, door.global_position + Vector3(0, 1, 3), 11.0)
	var reached := {}
	for area in get_nodes_in_group("beat_lines"):
		area.body_entered.connect(func(body: Node) -> void:
			reached[area.get_meta("beat")] = true)
	var exit_hit := {}
	for area in get_nodes_in_group("level_exit"):
		area.body_entered.connect(func(body: Node) -> void:
			exit_hit["done"] = true)
	var walker = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(walker)
	walker.set_physics_process(false)
	walker.position = WAYPOINTS[0] + Vector3(0, 0.3, 0)
	for i in 30:
		await physics_frame

	var distance := 0.0
	var frames := 0
	for index in range(1, WAYPOINTS.size()):
		var target: Vector3 = WAYPOINTS[index]
		var stuck := 0
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
			if stuck > 40 or frames > 30000:
				break
		check(walker.position.distance_to(target) < 2.0, "Reached waypoint %d at %s (stopped at %s)" % [index, target, walker.position])
	for beat in range(1, PLAN_ROUTE.beat_count() + 1):
		check(reached.has(beat), "Beat %d line crossed" % beat)
	# Deaths respawn at the furthest beat line crossed, standing on its floor.
	for area in get_nodes_in_group("beat_lines"):
		if int(area.get_meta("beat")) == PLAN_ROUTE.beat_count():
			var expected: Vector3 = area.global_position - Vector3(0, 1.0, 0)
			check(walker.respawn_point.distance_to(expected) < 0.01, "Respawn moved to the last beat line: %s, expected %s" % [walker.respawn_point, expected])
	check(exit_hit.has("done"), "Level exit reached")
	print("FACTORY route: %.0f units walked in %.1f s at walk speed, no fights" % [distance, frames / 60.0])
	print("FACTORY suggested par: %s" % _stamp(frames / 60.0 * 3.0))
	print("FACTORY route failures: ", failures)
	walker.queue_free()
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)

func _stamp(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]
