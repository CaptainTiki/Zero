extends SceneTree
## Walks the factory's golden path with the player's own collision body, confirms
## every beat line and the exit are reachable, and reports the distance and the
## walk time with no fights. Par comes from that walk time times 2.5.

const WAYPOINTS := preload("res://tests/factory_waypoints.gd").ROUTE

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
	for actor in get_nodes_in_group("enemies"):
		actor.process_mode = Node.PROCESS_MODE_DISABLED
	var original = level.get_node_or_null("Player")
	if original:
		original.process_mode = Node.PROCESS_MODE_DISABLED
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
	for beat in [1, 2, 3, 4, 5, 6, 7]:
		check(reached.has(beat), "Beat %d line crossed" % beat)
	check(exit_hit.has("done"), "Level exit reached")
	print("FACTORY route: %.0f units walked in %.1f s at walk speed, no fights" % [distance, frames / 60.0])
	print("FACTORY suggested par: %s" % _stamp(frames / 60.0 * 2.5))
	print("FACTORY route failures: ", failures)
	walker.queue_free()
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)

func _stamp(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]
