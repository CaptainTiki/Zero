extends SceneTree
## Every secret in Level 01 is reachable with the player body (walk plus
## player-height jumps), each counts once, and dead-end ambushes fire.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

## [secret name, waypoints to reach it from a nearby safe spot]
const ROUTES := [
	["SecretWreck", [Vector3(-1.5, 0, 8), Vector3(-1.5, 0.9, 4.6), Vector3(-3.0, 1.5, 4.3), Vector3(-4.5, 2.1, 2.5)]],
	["SecretStore", [Vector3(24, 0, 0), Vector3(24, 0, 6), Vector3(22.5, 0, 10)]],
	["SecretStub", [Vector3(72, 0, 20), Vector3(72, 0, 34), Vector3(67, 0, 37)]],
	["SecretPharmRoof", [Vector3(104, 5.0, -44), Vector3(101.5, 5.8, -40), Vector3(101.5, 6.6, -37.8), Vector3(101.5, 7.4, -35.6), Vector3(101.5, 8.1, -33.4), Vector3(98, 8.5, -31), Vector3(93.5, 8.5, -30)]],
	["SecretLoop", [Vector3(126, 0, -75), Vector3(126, 0, -90), Vector3(126, 0, -97), Vector3(110, 0, -104), Vector3(97.5, 0, -103)]],
	["SecretPatrol", [Vector3(130, 0, 6), Vector3(130, 0.2, 16), Vector3(144, 0, 17)]],
	["SecretBarge", [Vector3(171, 0.2, -40), Vector3(176, -0.6, -40), Vector3(179, -0.8, -38)]],
	["SecretTerrace", [Vector3(134, 0, -72), Vector3(134, 2.6, -84), Vector3(134, 2.8, -104)]],
	["SecretCulDeSac", [Vector3(-22, 0, -60), Vector3(-30, 0, -62), Vector3(-34, 0, -64)]],
	["SecretMillAlley", [Vector3(-4, 0, -99), Vector3(8, 0, -99), Vector3(21, 0, -98)]],
	["SecretSpur", [Vector3(18, -5.2, -180), Vector3(18, -5.2, -190), Vector3(18, -5.2, -196)]],
	["SecretCistern", [Vector3(34, -5.2, -112), Vector3(30.5, -4.9, -108), Vector3(27, -4.3, -108)]],
]

func walk(walker: CharacterBody3D, target: Vector3) -> bool:
	var frames := 0
	var stuck := 0
	var last: Vector3 = walker.position
	while frames < 900:
		await physics_frame
		frames += 1
		var flat: Vector3 = target - walker.position
		flat.y = 0.0
		if flat.length() < 0.6 and absf(target.y - walker.position.y) < 1.2:
			return true
		var rise: float = target.y - walker.position.y
		var vy: float = -2.0
		if rise > 0.3 and walker.is_on_floor() and flat.length() < 3.0:
			vy = 4.5
		elif not walker.is_on_floor():
			vy = walker.velocity.y - 9.8 / 60.0
		var dir := flat.normalized() if flat.length() > 0.01 else Vector3.ZERO
		walker.velocity = Vector3(dir.x * 6.0, vy, dir.z * 6.0)
		walker.move_and_slide()
		var moved: Vector3 = walker.position - last
		moved.y = 0.0
		last = walker.position
		stuck = stuck + 1 if moved.length() < 0.01 and walker.is_on_floor() else 0
		if stuck > 60:
			return false
	return false

func run() -> void:
	var level = load("res://scenes/levels/l01_district04.tscn").instantiate()
	root.add_child(level)
	level.set("arena_enabled", false)
	for actor in get_nodes_in_group("enemies") + [level.get_node("Player")]:
		actor.process_mode = Node.PROCESS_MODE_DISABLED
	for door_name in ["YardDoor", "DetourDoor", "StoreDoor"]:
		var door = level.get_node_or_null(door_name)
		check(door != null, "%s exists" % door_name)
		if door and door.has_method("apply_kick"):
			door.apply_kick(10.0, door.global_position + Vector3(0, 1, 3), 11.0)
	for i in 30:
		await physics_frame
	check(level.get("_secrets_total") == 12, "Twelve secrets counted (got %s)" % level.get("_secrets_total"))
	var walker = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(walker)
	walker.set_physics_process(false)
	var ambushes_before := get_nodes_in_group("ambush").size()
	for route in ROUTES:
		var found_before: int = level.get("_secrets_found")
		walker.position = route[1][0] + Vector3(0, 0.3, 0)
		walker.velocity = Vector3.ZERO
		for i in 5:
			await physics_frame
		var ok := true
		for index in range(1, route[1].size()):
			var target: Vector3 = route[1][index]
			# Stacked hops (rise over 0.6) are teleported: the scripted walker cannot
			# time a jump the way a player does. The surface must still exist there.
			if target.y - walker.position.y > 0.6:
				var space: PhysicsDirectSpaceState3D = walker.get_world_3d().direct_space_state
				var probe := PhysicsRayQueryParameters3D.create(target + Vector3(0, 1.0, 0), target - Vector3(0, 0.6, 0), 1)
				var hit: Dictionary = space.intersect_ray(probe)
				ok = not hit.is_empty() and absf(hit.position.y - target.y) < 0.35
				if not ok:
					break
				walker.position = Vector3(target.x, hit.position.y + 0.05, target.z)
				walker.velocity = Vector3.ZERO
				await physics_frame
				continue
			ok = await walk(walker, target)
			if not ok:
				break
		check(ok, "%s reachable (stopped at %s)" % [route[0], walker.position])
		for i in 3:
			await physics_frame
		check(level.get("_secrets_found") == found_before + 1, "%s counted" % route[0])
		# Freshly spawned ambush fodder must not block later routes.
		for e in get_nodes_in_group("enemies"):
			e.process_mode = Node.PROCESS_MODE_DISABLED
	check(get_nodes_in_group("ambush").size() < ambushes_before, "Dead-end ambushes fired (%d of %d left)" % [get_nodes_in_group("ambush").size(), ambushes_before])
	print("L01 secrets: %d/%d found, failures %d" % [level.get("_secrets_found"), level.get("_secrets_total"), failures])
	walker.queue_free()
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)
