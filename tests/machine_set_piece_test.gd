extends SceneTree
## Plays the factory's pressure-arm climax without the walk, on fast timings:
## - stepping into the pit seals the way back; the button does nothing yet;
## - the first arm's beacon warns, it comes down, and only its pipe can be hurt;
## - breaking it lifts the arm and its wave climbs out on the pit floor;
## - the next arm waits for the wave to die, or for pressure to force it;
## - an arm won't land on a player standing on its socket;
## - arms come down in the plan's order; stranded melee climbs out again on the player's
##   level while a Rammer or brute waits below; up on the walks a Rammer comes as fodder;
## - brutes climb out with the third wave and the last;
## - after the last pipe no wave comes and the button arms; kicking it sends the machine
##   critical, opens the exit, lights the end zone and starts the countdown;
## - the place falls apart; dropping into the truck yard stops the countdown and the factory
##   blows up behind you, and walking onto the pad ends the level;
## - on a fresh level, running out of time ends the run.

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

## Waits up to `limit` frames for `ready` to return true, and says whether it did.
func wait_until(ready: Callable, limit := 600) -> bool:
	for i in limit:
		if ready.call():
			return true
		await physics_frame
	return ready.call()

func freeze_enemies() -> void:
	for e in get_nodes_in_group("enemies"):
		e.process_mode = Node.PROCESS_MODE_DISABLED

func count(kind := "") -> int:
	var n := 0
	for e in get_nodes_in_group("enemies"):
		if e.get_parent() and String(e.get_parent().name) == "MachineSetPiece" and (kind == "" or String(e.scene_file_path).ends_with(kind + ".tscn")):
			n += 1
	return n

func kill_wave() -> void:
	for e in get_nodes_in_group("enemies"):
		if e.get_parent() and String(e.get_parent().name) == "MachineSetPiece":
			e.queue_free()

func kick_break(arm: Node, player: Node3D) -> void:
	for i in 3:
		arm.pipe.apply_kick(10.0, player.global_position, 11.0)

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
	var arms := {}
	for child in piece.get_children():
		if String(child.name).begins_with("PressureArm"):
			arms[int(child.number)] = child
	check(arms.size() == 6, "six pressure arms built (%d)" % arms.size())
	check(piece.order == [1, 3, 5, 2, 4, 6], "arms come down 1, 3, 5, 2, 4, 6 (%s)" % [piece.order])
	var expected := 0
	for w in piece.waves:
		expected += int(w[0]) + int(w[1]) + int(w[2])
	check(piece.waves.size() == 5 and expected == 31, "five waves, thirty-one enemies (%d, %d)" % [piece.waves.size(), expected])
	check(level.extra_expected_kills >= expected, "wave enemies counted in the level's kill total")
	var all_up := true
	for arm in arms.values():
		all_up = all_up and arm.lowered == 0.0 and not arm.pipe.exposed
	check(all_up, "every arm starts up, its pipe out of reach")
	var exit_shape: CollisionShape3D = null
	for child in piece.get_children():
		if child is StaticBody3D and child != piece.button:
			for c in child.get_children():
				if c is CollisionShape3D and c.shape is BoxShape3D:
					exit_shape = c
	check(exit_shape != null and not exit_shape.disabled, "high exit shut before the fight")
	check(not level._lift_open, "level exit not open yet")
	check(not piece._end_zone.visible, "end zone hidden before the machine goes critical")
	piece.button.apply_kick(10.0, player.global_position, 11.0)
	check(not piece.button.is_pressed and piece.state == piece.State.WAITING, "kicking the button before the pipes does nothing")

	piece.first_arm_seconds = 0.3
	piece.warning_seconds = 0.4
	piece.move_seconds = 0.3
	piece.cleared_pause = 0.2
	piece.pressure_seconds = 60.0

	# Into the pit, clear of every socket.
	player.global_position = Vector3(38, -3.6, -110)
	await frames(20)
	check(piece.state == piece.State.FIGHT, "stepping into the pit starts the fight")
	check(player.respawn_point == piece.respawn_at, "death now respawns in the pit")
	check(count() == 0, "no enemies before the first pipe breaks (%d)" % count())

	check(await wait_until(func() -> bool: return piece.phase == piece.Phase.WARN, 120), "pressure builds, then the first arm warns")
	check(arms[1].warning, "arm 1's beacon spins while it warns")
	check(await wait_until(func() -> bool: return piece.phase == piece.Phase.EXPOSED, 180), "arm 1 comes down and plugs in")
	check(arms[1].lowered == 1.0 and arms[1].pipe.exposed and not arms[1].warning, "arm 1 is down, its pipe exposed, its beacon off")
	var sealed := false
	for child in piece.get_children():
		if child is StaticBody3D:
			for c in child.get_children():
				if c is CollisionShape3D and c.shape is CylinderShape3D:
					sealed = child.position.distance_to(piece.seal_at) < 0.2
	check(sealed, "the seal pipe has landed across the tunnel door")
	kick_break(arms[3], player)
	check(not arms[3].pipe.is_broken, "a pipe whose arm is up only clangs")

	kick_break(arms[1], player)
	check(arms[1].pipe.is_broken, "three kicks break arm 1's pipe")
	check(arms[1].stub != null and arms[1].stub.global_position.distance_to(arms[1].socket) < 0.05, "the pipe snaps off and its foot stays in the socket")
	check(await wait_until(func() -> bool: return count() == 6, 180), "arm 1 lifts and wave 1 climbs out: 6 enemies (%d)" % count())
	check(arms[1].lowered == 0.0, "arm 1 is back up")
	check(arms[1].pipe.global_position.y - arms[1].socket.y > 1.0, "and what's left of its pipe is out of reach")
	check(count("rammer") == 1, "wave 1 brings one Rammer (%d)" % count("rammer"))
	var low := true
	for e in get_nodes_in_group("enemies"):
		if e.get_parent() == piece and e.global_position.y > -2.0:
			low = false
	check(low, "the wave climbs out on the pit floor, the player's level")
	freeze_enemies()
	await frames(30)
	check(piece.current_arm() == arms[3] and piece.phase == piece.Phase.PRESSURE and arms[3].lowered == 0.0, "arm 3 waits while wave 1 is alive")
	kill_wave()
	check(await wait_until(func() -> bool: return piece.phase == piece.Phase.EXPOSED, 180), "with wave 1 dead, arm 3 comes down")

	# Pressure forces the next arm even with the wave alive.
	kick_break(arms[3], player)
	check(await wait_until(func() -> bool: return count() == 6, 180), "arm 3's pipe sends wave 2 (%d)" % count())
	freeze_enemies()
	piece.pressure_seconds = 0.5
	check(await wait_until(func() -> bool: return piece.phase == piece.Phase.EXPOSED, 240), "pressure forces arm 5 down with wave 2 alive")
	check(piece.current_arm() == arms[5] and count() == 6, "it's arm 5, and wave 2 is still up (%d)" % count())

	# An arm waits for a player standing on its socket. Arm 2 is next.
	kick_break(arms[5], player)
	check(await wait_until(func() -> bool: return count() == 13, 180), "arm 5's pipe sends wave 3 (%d)" % count())
	check(count("brute") == 1, "wave 3 brings a brute (%d)" % count("brute"))
	freeze_enemies()
	player.global_position = arms[2].socket + Vector3(0.3, 0.4, 0)
	check(await wait_until(func() -> bool: return piece.phase == piece.Phase.DROP, 240), "arm 2 warns and is ready to drop")
	await frames(45)
	check(arms[2].lowered == 0.0 and piece.phase == piece.Phase.DROP, "arm 2 waits while the player stands on its socket")
	player.global_position = Vector3(38, -3.6, -110)
	check(await wait_until(func() -> bool: return piece.phase == piece.Phase.EXPOSED, 180), "arm 2 comes down once the player steps off")

	# Up on the machine walk: stranded fodder climbs out up there, a Rammer waits below, and
	# a wave sent while the player is up brings its Rammer as fodder.
	player.global_position = Vector3(55, 4.2, -104)
	piece.regroup_after = 0.5
	kick_break(arms[2], player)
	check(await wait_until(func() -> bool: return count() == 19, 180), "arm 2's pipe sends wave 4 (%d)" % count())
	freeze_enemies()
	check(count("rammer") == 2, "up on the walk, wave 4's Rammer comes as fodder (%d Rammers)" % count("rammer"))
	var fodder_all_up := func() -> bool:
		for e in get_nodes_in_group("enemies"):
			if e.get_parent() == piece and String(e.scene_file_path).ends_with("fodder.tscn") and e.global_position.y < 2.0:
				return false
		return true
	check(await wait_until(fodder_all_up, 600), "stranded fodder climbs out again on the walk")
	var rammer_below := false
	for e in get_nodes_in_group("enemies"):
		if e.get_parent() == piece and String(e.scene_file_path).ends_with("rammer.tscn") and e.global_position.y < 2.0:
			rammer_below = true
	check(rammer_below, "a stranded Rammer waits below, too wide for the walks")
	var brute_below := false
	for e in get_nodes_in_group("enemies"):
		if e.get_parent() == piece and String(e.scene_file_path).ends_with("brute.tscn") and e.global_position.y < 2.0:
			brute_below = true
	check(brute_below, "a stranded brute waits below too")
	check(count() == 19, "regrouping moves enemies, never adds them (%d)" % count())

	# The last two arms, pressure-forced.
	player.global_position = Vector3(38, -3.6, -110)
	kill_wave()
	check(await wait_until(func() -> bool: return piece.phase == piece.Phase.EXPOSED and piece.current_arm() == arms[4], 240), "arm 4 comes down fifth")
	kick_break(arms[4], player)
	check(await wait_until(func() -> bool: return count() == 8, 180), "arm 4's pipe sends wave 5, two Rammers (%d, %d Rammers)" % [count(), count("rammer")])
	check(count("rammer") == 2, "wave 5 brings two Rammers (%d)" % count("rammer"))
	check(count("brute") == 1, "and a brute (%d)" % count("brute"))
	freeze_enemies()
	check(await wait_until(func() -> bool: return piece.phase == piece.Phase.EXPOSED and piece.current_arm() == arms[6], 240), "arm 6 comes down last")
	kick_break(arms[6], player)
	check(await wait_until(func() -> bool: return piece.state == piece.State.BUTTON, 180), "the last pipe arms the button")
	await frames(30)
	check(count() == 8, "no wave after the last pipe (%d)" % count())
	check(piece.button.armed and not piece.button.is_pressed, "the button is armed, waiting for a kick")
	check(exit_shape != null and not exit_shape.disabled, "the high exit stays shut until the button")

	piece.button.apply_kick(10.0, player.global_position, 11.0)
	await frames(10)
	check(piece.state == piece.State.CRITICAL, "kicking the button sends the machine critical")
	check(exit_shape.disabled, "the high exit opens")
	check(level._lift_open, "the level exit can now finish the run")
	check(piece._end_zone.visible, "the end zone lights up")
	check(piece.escape_left > 85.0 and piece.escape_left <= 90.0, "the escape countdown is running (%.1f)" % piece.escape_left)

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
		if child is StaticBody3D and child != piece.button and child != exit_shape.get_parent():
			for c in child.get_children():
				if c is CollisionShape3D and c.shape is BoxShape3D and not c.disabled:
					landed += 1
	check(landed >= 4, "fallen debris is solid once it lands (%d pieces)" % landed)

	# Out of the building, past the dock edge into the truck yard.
	player.global_position = Vector3(50, 0.3, 30)
	await frames(20)
	check(piece.state == piece.State.OUT, "dropping into the truck yard gets you out")
	var frozen: float = piece.escape_left
	await frames(60)
	check(piece.escape_left == frozen, "the countdown stops once you're out (%.1f)" % piece.escape_left)
	check(await wait_until(func() -> bool: return piece._finale_fired.size() >= 3, 300), "the factory blows up behind you (%d events)" % piece._finale_fired.size())
	check(not level._finished, "getting out doesn't end the level")
	player.global_position = Vector3(62, 0.3, 47)
	await frames(20)
	check(level._finished and piece.state == piece.State.DONE, "walking onto the pad ends the level")
	level.queue_free()
	await frames(5)

	# The countdown running out, on a fresh level.
	var again = load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(again)
	await frames(5)
	var piece2 = again.get_node("MachineSetPiece")
	piece2._critical()
	piece2.escape_left = 0.05
	await frames(10)
	check(piece2.state == piece2.State.DONE, "the countdown runs out")
	check(again._finished, "running out of time ends the run")

	print("machine set piece failures: ", failures)
	again.queue_free()
	await process_frame
	quit(1 if failures else 0)
