extends SceneTree
## Every factory stair that climbs above the ground can't be stepped off the side once it is
## a jump high. Stands the player's own body on each stair 40, 65 and 90 percent of the way up,
## next to each side, and walks it straight at that side for a second: it must still be on the
## stair. The bottom stays open on purpose, so routes can step onto a stair's foot from the side.
## Rails or walls, either will do. A pit ramp's open side is the control, to show the probe
## does step off where nothing stops it. Found in factory playtest 2: the player dropped off
## the warehouse stair and skipped half the escape.

const PLAN := "res://docs/factory_plan/plan.json"

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1

func v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

## Stands the walker on the stair at fraction t of the way up, inset from one side, and walks
## it at that side. Returns how far it ended from the centre line and how far it dropped.
func probe(walker: CharacterBody3D, r: Dictionary, t: float, side: float) -> Vector2:
	var low := v3(r["low"])
	var high := v3(r["high"])
	var along_x := bool(r["along_x"])
	var half := float(r["w"]) / 2.0
	var surface := low.lerp(high, t)
	var across := Vector3(0, 0, 1) if along_x else Vector3(1, 0, 0)
	walker.global_position = surface + across * side * (half - 0.6) + Vector3(0, 0.5, 0)
	walker.velocity = Vector3.ZERO
	for i in 10:
		await physics_frame
		walker.velocity = Vector3(0, -2.0, 0)
		walker.move_and_slide()
	for i in 60:
		await physics_frame
		var vy := -2.0 if walker.is_on_floor() else walker.velocity.y - 9.8 / 60.0
		var push := across * side * 6.0
		walker.velocity = Vector3(push.x, vy, push.z)
		walker.move_and_slide()
	var off := (walker.global_position - surface).dot(across)
	return Vector2(absf(off), surface.y + 0.5 - walker.global_position.y)

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
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	var walker: CharacterBody3D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(walker)
	walker.set_physics_process(false)
	for i in 10:
		await physics_frame

	var probed := 0
	for r in plan["ramps"]:
		var low := v3(r["low"])
		var high := v3(r["high"])
		if low.y < -0.5 or high.y < 2.0:
			continue
		var half := float(r["w"]) / 2.0
		for side in [-1.0, 1.0]:
			for t in [0.4, 0.65, 0.9]:
				var result: Vector2 = await probe(walker, r, t, side)
				probed += 1
				check(result.x <= half + 0.1 and result.y < 1.0,
					"%s from %s: side %+d at %d%% holds (%.2f from centre, dropped %.2f)" % [r["name"], r["low"], int(side), int(t * 100), result.x, result.y])

	# Control: the pit ramps are left open, and the probe walks off one into the pit.
	for r in plan["ramps"]:
		if String(r["name"]) == "Pit ramp north":
			var result: Vector2 = await probe(walker, r, 0.5, 1.0)
			check(result.x > float(r["w"]) / 2.0 + 0.3, "control: the probe steps off the pit ramp's open side (%.2f from centre)" % result.x)

	print("FACTORY stairs: %d probes, failures %d" % [probed, failures])
	walker.queue_free()
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)
