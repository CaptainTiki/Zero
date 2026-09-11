extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var level = load("res://scenes/levels/m01_beats_1_5.tscn").instantiate()
	root.add_child(level)
	level.process_mode = Node.PROCESS_MODE_DISABLED
	check(level.has_node("OpeningArt"), "Saved art scene loaded")
	for name_text in ["CrashPad", "CheckFloor", "AlleyFloor"]:
		var floor_node = level.get_node(name_text)
		check(is_zero_approx(floor_node.position.y + floor_node.size.y / 2), name_text + " top is flush")
	for enemy in get_nodes_in_group("enemies"):
		enemy.collision_layer = 0
		enemy.collision_mask = 0
	var rammer = load("res://scenes/enemies/rammer.tscn").instantiate()
	root.add_child(rammer)
	rammer.set_physics_process(false)
	# Isolate terrain traversal with the real Rammer shape and move_and_slide.
	for direction in [1.0, -1.0]:
		rammer.position = Vector3(35 if direction > 0 else 58, 0.2, 1.8)
		for i in 260:
			await physics_frame
			rammer.velocity = Vector3(direction * 6.0, -2, 0)
			rammer.move_and_slide()
		print("Traversal direction ", direction, " ends at ", rammer.position); check(rammer.position.x > 57 if direction > 0 else rammer.position.x < 34, "Rammer crosses checkpoint transition in both directions")
	check(level.get_node("CrashExitDoor").position.is_equal_approx(Vector3(11, 0.025, 0)), "Door placement preserved")
	check(level.get_node("ServiceRoadKickBox").position.is_equal_approx(Vector3(15, 0.1, 0)), "Metal box placement preserved")
	print("Opening art failures: ", failures)
	rammer.queue_free()
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)



