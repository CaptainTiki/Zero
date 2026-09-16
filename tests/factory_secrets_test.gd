extends SceneTree
## Every secret in the factory can be reached with the player's own body along the path the
## plan gives it, and counts exactly once. Enemies and ambushes are cleared and kick doors
## opened first, so this tests the squeezes and hollow containers, not the fights.

const PLAN := "res://docs/factory_plan/plan.json"

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1

func walk(walker: CharacterBody3D, target: Vector3) -> bool:
	var frames := 0
	var stuck := 0
	var last: Vector3 = walker.position
	while frames < 900:
		await physics_frame
		frames += 1
		var flat: Vector3 = target - walker.position
		flat.y = 0.0
		if flat.length() < 0.5:
			return true
		var vy: float = -2.0 if walker.is_on_floor() else walker.velocity.y - 9.8 / 60.0
		var dir := flat.normalized()
		walker.velocity = Vector3(dir.x * 6.0, vy, dir.z * 6.0)
		walker.move_and_slide()
		var moved: Vector3 = walker.position - last
		moved.y = 0.0
		last = walker.position
		stuck = stuck + 1 if moved.length() < 0.01 else 0
		if stuck > 60:
			return false
	return false

func run() -> void:
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLAN))
	var level = load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(level)
	for actor in get_nodes_in_group("enemies"):
		actor.get_parent().remove_child(actor)
		actor.queue_free()
	for area in get_nodes_in_group("ambush"):
		area.get_parent().remove_child(area)
		area.queue_free()
	var original = level.get_node("Player")
	original.process_mode = Node.PROCESS_MODE_DISABLED
	original.global_position = Vector3(4000, -400, 4000)
	for door in level.get_children():
		if String(door.name).begins_with("KickDoor") and door.has_method("apply_kick"):
			door.apply_kick(10.0, door.global_position + Vector3(0, 1, 3), 11.0)
	var machine = level.get_node_or_null("MachineSetPiece")
	if machine:
		machine.skip()
	for i in 20:
		await physics_frame
	var secrets: Array = plan["secrets"]
	var placed := get_nodes_in_group("secrets").size()
	check(placed == secrets.size(), "%d secret triggers in the scene for %d in the plan" % [placed, secrets.size()])
	check(secrets.size() <= 12, "at most twelve secrets (%d)" % secrets.size())

	for s in secrets:
		var name := String(s["name"])
		var path: Array = s["path"]
		check(path.size() >= 2, "%s has a path to walk" % name)
		if path.size() < 2:
			continue
		var before: int = level._secrets_found
		var walker = load("res://scenes/player/player.tscn").instantiate()
		root.add_child(walker)
		walker.set_physics_process(false)
		var first: Array = path[0]
		walker.position = Vector3(float(first[0]), float(first[1]) + 0.3, float(first[2]))
		for f in 10:
			await physics_frame
		var reached := true
		for k in range(1, path.size()):
			var p: Array = path[k]
			if not await walk(walker, Vector3(float(p[0]), float(p[1]), float(p[2]))):
				reached = false
				check(false, "%s: stuck at %s on the way to %s" % [name, walker.position, p])
				break
		for f in 10:
			await physics_frame
		if reached:
			check(level._secrets_found == before + 1, "%s is reachable and counts once" % name)
		walker.queue_free()
		for f in 5:
			await physics_frame

	print("FACTORY secrets: %d/%d found, failures %d" % [level._secrets_found, secrets.size(), failures])
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)
