extends SceneTree
## Plays the factory's machine set piece without the walk: step into the pit, check the
## seal and the first wave, break the six coolant pipes (kicks, pistol hits, a shotgun
## blast), check a wave per pipe from hatches on the player's level, that Rammers come as
## fodder up on the walks, then the critical state, the open exit, the lit end zone and
## the countdown, and that the countdown running out ends the run.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func freeze_enemies() -> void:
	for e in get_nodes_in_group("enemies"):
		e.process_mode = Node.PROCESS_MODE_DISABLED

func count(kind := "") -> int:
	var n := 0
	for e in get_nodes_in_group("enemies"):
		if e.get_parent() and String(e.get_parent().name) == "MachineSetPiece" and (kind == "" or String(e.scene_file_path).ends_with(kind + ".tscn")):
			n += 1
	return n

func kick_break(pipe: Node, player: Node3D) -> void:
	for i in 3:
		pipe.apply_kick(10.0, player.global_position, 11.0)

func run() -> void:
	var level = load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(level)
	await frames(5)
	# Only the set piece's own enemies count here.
	for actor in get_nodes_in_group("enemies"):
		actor.queue_free()
	await frames(2)
	var piece = level.get_node("MachineSetPiece")
	var player = level.get_node("Player")
	player.set_physics_process(false)
	var pipes := []
	for child in piece.get_children():
		if String(child.name).begins_with("CoolantPipe"):
			pipes.append(child)
	check(pipes.size() == 6, "six coolant pipes built (%d)" % pipes.size())
	var expected := 0
	for w in piece.waves:
		expected += int(w[0]) + int(w[1]) + int(w[2])
	check(expected == 31, "thirty-one enemies across the waves (%d)" % expected)
	check(level.extra_expected_kills >= expected, "wave enemies counted in the level's kill total")
	var exit_shape: CollisionShape3D = null
	for child in piece.get_children():
		if child is StaticBody3D and not String(child.name).begins_with("CoolantPipe"):
			for c in child.get_children():
				if c is CollisionShape3D and c.shape is BoxShape3D:
					exit_shape = c
	check(exit_shape != null and not exit_shape.disabled, "high exit shut before the fight")
	check(not level._lift_open, "level exit not open yet")
	check(not piece._end_zone.visible, "end zone hidden before the machine goes critical")

	# Into the pit.
	player.global_position = Vector3(46, -3.6, -110)
	await frames(60)
	check(piece.state == piece.State.FIGHT, "stepping into the pit starts the fight")
	check(count() == 4, "first wave: 4 enemies (%d)" % count())
	var low := true
	for e in get_nodes_in_group("enemies"):
		if e.get_parent() == piece and e.global_position.y > -2.0:
			low = false
	check(low, "first-wave fodder climbs out on the pit floor, the player's level")
	check(player.respawn_point == piece.respawn_at, "death now respawns in the pit")
	freeze_enemies()
	var sealed := false
	for child in piece.get_children():
		if child is StaticBody3D:
			for c in child.get_children():
				if c is CollisionShape3D and c.shape is CylinderShape3D:
					sealed = child.position.distance_to(piece.seal_at) < 0.2
	check(sealed, "the seal pipe has landed across the tunnel door")

	# Base pipes on the pit floor: kicks, pistol hits, a shotgun blast and kicks.
	for i in 3:
		check(not pipes[0].is_broken, "pipe 1 holds before kick %d" % (i + 1))
		pipes[0].apply_kick(10.0, player.global_position, 11.0)
	check(pipes[0].is_broken, "three kicks break pipe 1")
	await frames(60)
	check(count() == 9, "pipe 1 sends wave 2 (%d enemies)" % count())
	check(count("rammer") == 1, "wave 2 brings a Rammer on the pit floor")
	freeze_enemies()
	var shots := 0
	while not pipes[1].is_broken and shots < 20:
		pipes[1].take_damage(22.0)
		shots += 1
	check(shots == 10, "ten pistol hits break pipe 2 (%d)" % shots)
	await frames(60)
	check(count() == 15, "pipe 2 sends wave 3 (%d)" % count())
	freeze_enemies()
	pipes[2].apply_shot(96.0, player.global_position, 7.0)
	check(not pipes[2].is_broken, "one shotgun blast doesn't break a pipe on its own")
	pipes[2].apply_kick(10.0, player.global_position, 11.0)
	pipes[2].apply_kick(10.0, player.global_position, 11.0)
	check(pipes[2].is_broken, "a blast and two kicks break pipe 3")
	await frames(60)
	check(count() == 20, "pipe 3 sends wave 4 (%d)" % count())
	freeze_enemies()

	# Up on the roof walkway round the stack. A Rammer in this wave has to come as fodder.
	player.global_position = Vector3(41.25, 8.2, -91.5)
	piece.waves[4] = [3, 2, 1]
	var rammers_before := count("rammer")
	kick_break(pipes[3], player)
	await frames(60)
	check(count() == 26, "pipe 4 sends wave 5 (%d)" % count())
	check(count("rammer") == rammers_before, "up on the walks the Rammer comes as fodder")
	var high := 0
	for e in get_nodes_in_group("enemies"):
		if e.get_parent() == piece and e.process_mode != Node.PROCESS_MODE_DISABLED and not String(e.scene_file_path).ends_with("hunter.tscn") and e.global_position.y > 6.0:
			high += 1
	check(high == 4, "wave 5's melee climbs out on the roof level (%d)" % high)
	freeze_enemies()
	kick_break(pipes[4], player)
	await frames(60)
	check(count() == 32, "pipe 5 sends wave 6 (%d)" % count())
	freeze_enemies()

	kick_break(pipes[5], player)
	await frames(10)
	check(piece.state == piece.State.CRITICAL, "the last pipe sends the machine critical")
	check(count() == 32, "no wave after the last pipe")
	check(exit_shape.disabled, "the high exit opens")
	check(level._lift_open, "the level exit can now finish the run")
	check(piece._end_zone.visible, "the end zone lights up")
	check(piece.escape_left > 60.0 and piece.escape_left <= 65.0, "the escape countdown is running (%.1f)" % piece.escape_left)

	# The place falls apart: alarms, the plant room's own debris on a delay, then debris as
	# the player reaches each trigger on the way out.
	await frames(5)
	check(piece._alarm_lights.size() > 0 and piece._alarm_lights[0].visible, "alarm lights come on")
	await frames(240)
	check(piece._fired.size() >= 3, "the plant room falls apart on its own (%d events)" % piece._fired.size())
	var fired_before: int = piece._fired.size()
	player.global_position = Vector3(83, 0.2, -30)
	await frames(90)
	check(piece._fired.size() > fired_before, "reaching the warehouse stair foot brings a beam down ahead")
	var landed := 0
	for child in piece.get_children():
		if child is StaticBody3D and not String(child.name).begins_with("CoolantPipe"):
			for c in child.get_children():
				if c is CollisionShape3D and c.shape is BoxShape3D and not c.disabled and child.position.distance_to(exit_shape.get_parent().position) > 1.0:
					landed += 1
	check(landed >= 4, "fallen debris is solid once it lands (%d pieces)" % landed)

	piece.escape_left = 0.05
	await frames(10)
	check(piece.state == piece.State.DONE, "the countdown runs out")
	check(level._finished, "running out of time ends the run")

	print("machine set piece failures: ", failures)
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)
