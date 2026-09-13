extends SceneTree
## Drives the Level 01 plaza arena with synthetic time: the seal drops, waves
## beam down on schedule, and the lift opens after the last wave.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var level = load("res://scenes/levels/l01_district04.tscn").instantiate()
	root.add_child(level)
	var player = level.get_node("Player")
	player.set_physics_process(false)
	for e in get_nodes_in_group("enemies"):
		e.process_mode = Node.PROCESS_MODE_DISABLED
	var placed := get_nodes_in_group("enemies").size()
	player.global_position = Vector3(170, 0.4, -75)
	await physics_frame
	await physics_frame
	player.global_position = Vector3(170, 0.4, -71)
	for i in 4:
		await physics_frame
	check(level.get("_arena_armed") and not level.get("_arena_started"), "Crossing the line arms the arena but does not seal it yet")
	player.global_position = Vector3(152, 0.4, -90)
	level._process(0.1)
	check(level.get("_arena_started"), "Walking into the plaza seals it")
	# Synthetic time: step the level's process by hand.
	var elapsed := 0.0
	var waves_seen := 0
	var beam_seen := false
	while elapsed < 70.0:
		level._process(0.25)
		elapsed += 0.25
		await physics_frame
		if level.get("_beam").visible:
			beam_seen = true
		if level.get("_wave_index") > waves_seen:
			waves_seen = level.get("_wave_index")
			print("arena: wave %d at %.2fs, enemies now %d" % [waves_seen, elapsed, get_nodes_in_group("enemies").size()])
			for e in get_nodes_in_group("enemies"):
				e.process_mode = Node.PROCESS_MODE_DISABLED
		if elapsed > 2.6 and waves_seen == 0:
			check(false, "First wave should have beamed down by 2.6 s")
			break
	check(waves_seen == 7, "All seven waves sent (saw %d)" % waves_seen)
	check(beam_seen, "Beam was shown")
	check(get_nodes_in_group("enemies").size() > placed + 25, "Waves added enemies (placed %d, now %d)" % [placed, get_nodes_in_group("enemies").size()])
	check(level.get("_lift_open"), "Lift opened after the last wave")
	check(level.get_node_or_null("LiftDoorSolid") == null, "Lift door collision removed")
	var seal_found := false
	for child in level.get_children():
		if child is StaticBody3D and child.global_position.distance_to(Vector3(170, 2.25, -67.5)) < 1.0:
			seal_found = true
	check(seal_found, "Walkway sealed behind the player")
	print("L01 arena failures: ", failures)
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)
