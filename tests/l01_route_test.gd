extends SceneTree
## Walks the Level 01 golden path with the player's collision body through a
## waypoint list, confirms every beat line and the lift trigger are reachable,
## and reports walking distance and time with no fights.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

const WAYPOINTS := [
	Vector3(0, 0, 6), Vector3(8, 0, 0), Vector3(16, 0, 0), Vector3(50, 0, 0),
	Vector3(62, 0, 0), Vector3(62, 0, -30), Vector3(71, 0, -30), Vector3(78, 0, -30),
	Vector3(96, 0, -21), Vector3(96, 4.2, -35), Vector3(86, 4.2, -44), Vector3(86, 4.2, -50.5),
	Vector3(82, 2.8, -50.5), Vector3(78.5, 1.5, -50.5), Vector3(78, 0, -56),
	# Act 2: west along Canal Street, through the scaffold gap, up Mill Road.
	Vector3(60, 0, -60), Vector3(40, 0, -60), Vector3(28, 0, -57), Vector3(14, 0, -60),
	Vector3(0, 0, -60), Vector3(-12, 0, -60), Vector3(-19, 0, -66), Vector3(-19, 0, -80),
	Vector3(-19, 0, -95), Vector3(-19, 0, -103), Vector3(-19, 3.6, -114), Vector3(-19, 3.6, -122),
	Vector3(-19, 0, -132), Vector3(-19, 0, -145), Vector3(-18, 0, -151),
	# Act 3: down the works slot, east along the drains, out in the cross street.
	Vector3(-18, -5.2, -178), Vector3(0, -5.2, -178), Vector3(24, -5.2, -178), Vector3(42, -5.2, -178),
	Vector3(42, -5.2, -158), Vector3(42, -5.2, -132), Vector3(40, -5.2, -124), Vector3(34, -5.2, -116),
	Vector3(48, -5.2, -114), Vector3(56, -5.2, -114), Vector3(76, -5.2, -114), Vector3(96, -5.2, -114),
	Vector3(94, -5.2, -104), Vector3(94, -5.2, -97), Vector3(104, -5.2, -100), Vector3(114, -5.2, -100),
	Vector3(121, -5.2, -97), Vector3(121, 0.7, -82), Vector3(121, 0, -78), Vector3(121, 0, -74), Vector3(110, 0, -58),
	Vector3(101, 0, -52.5), Vector3(101, 1.2, -50.6), Vector3(103, 2.1, -50.3),
	Vector3(105.5, 3.0, -50.0), Vector3(108.5, 3.9, -50.0), Vector3(111.5, 4.8, -50.0), Vector3(112, 5.2, -47),
	Vector3(126, 5.2, -45), Vector3(139, 0.2, -45), Vector3(139, 0, 4), Vector3(152, 0, 4), Vector3(166, 0, 4),
	Vector3(170, 0.2, 0), Vector3(170, 0.2, -60), Vector3(168, 0.2, -75), Vector3(150, 0, -100),
	Vector3(150, 0, -112), Vector3(144, 0, -118), Vector3(145, 0, -128), Vector3(151, 0, -133),
]

func run() -> void:
	var level = load("res://scenes/levels/l01_district04.tscn").instantiate()
	root.add_child(level)
	for actor in get_nodes_in_group("enemies") + [level.get_node("Player")]:
		actor.process_mode = Node.PROCESS_MODE_DISABLED
	# The yard door starts closed; open it the way the player would.
	for door_name in ["YardDoor", "DetourDoor"]:
		var door = level.get_node_or_null(door_name)
		if door and door.has_method("apply_kick"):
			door.apply_kick(10.0, door.global_position - Vector3(5, -1, 0), 11.0)
	for i in 60:
		await physics_frame
	var walker = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(walker)
	walker.set_physics_process(false)
	walker.position = WAYPOINTS[0] + Vector3(0, 0.3, 0)
	var reached := {}
	for area in get_nodes_in_group("beat_lines"):
		area.body_entered.connect(func(body: Node) -> void:
			if body == walker:
				reached[area.get_meta("beat")] = true)
	level.set("arena_enabled", false) # no seal or waves; the route test only checks reachability
	level.open_lift()
	var exit_hit := {} # dictionary so the lambda writes through by reference
	for area in get_nodes_in_group("level_exit"):
		area.body_entered.connect(func(body: Node) -> void:
			if body == walker:
				exit_hit["done"] = true)
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
			if flat.length() < 0.6:
				break
			var rise: float = target.y - walker.position.y
			var vy: float = -2.0
			if rise > 0.3 and walker.is_on_floor() and flat.length() < 2.2:
				vy = 4.5 # jump like the player
			elif not walker.is_on_floor():
				vy = walker.velocity.y - 9.8 / 60.0
			walker.velocity = Vector3(flat.normalized().x * 6.0, vy, flat.normalized().z * 6.0)
			walker.move_and_slide()
			var moved: Vector3 = walker.position - last
			moved.y = 0.0
			distance += moved.length()
			last = walker.position
			stuck = stuck + 1 if moved.length() < 0.01 else 0
			if stuck > 40 or frames > 24000:
				break
		check(walker.position.distance_to(target) < 1.5, "Reached waypoint %d at %s (stopped at %s)" % [index, target, walker.position])
	for beat in [2, 3, 4, 5, 6, 7, 8, 9]:
		check(reached.has(beat), "Beat %d line crossed" % beat)
	check(exit_hit.has("done"), "Freight lift trigger reached")
	print("L01 route: %.0f units walked in %.1f s at walk speed, no fights" % [distance, frames / 60.0])
	print("L01 route failures: ", failures)
	walker.queue_free()
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)
