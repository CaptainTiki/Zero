extends SceneTree
## A cardboard John goes down to a kick or to a bullet, counts itself exactly
## once, and cleans itself up afterwards.

const STUB := preload("res://tests/support_stats_stub.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func make_john(world: Node, at: Vector3) -> Node:
	var john = load("res://scenes/props/john_cutout.tscn").instantiate()
	john.position = at
	world.add_child(john)
	return john

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var stats := Node.new()
	stats.set_script(STUB)
	stats.add_to_group("run_stats")
	world.add_child(stats)
	await frames(2)

	# Kicked from in front: it should topple away and count once.
	var kicked := make_john(world, Vector3(0, 0, 0))
	check(kicked.is_in_group("johns"), "A cutout joins the johns group")
	var standing: Vector3 = kicked.global_position
	kicked.apply_kick(10.0, Vector3(0, 0, 4), 11.0)
	await frames(6)
	check(stats.get("johns") == 1, "A kick counts one John (got %s)" % stats.get("johns"))
	check(kicked.global_position != standing, "A kicked John moves")
	# A second hit on the way down must not count again.
	if is_instance_valid(kicked):
		kicked.apply_kick(10.0, Vector3(0, 0, 4), 11.0)
	await frames(2)
	check(stats.get("johns") == 1, "A falling John does not count twice")

	# Shot instead of kicked.
	var shot := make_john(world, Vector3(6, 0, 0))
	shot.take_damage(12.0)
	await frames(6)
	check(stats.get("johns") == 2, "A bullet counts one John (got %s)" % stats.get("johns"))

	# Both should clean themselves up rather than littering the level.
	await frames(110)
	check(not is_instance_valid(kicked), "A flattened John frees itself")
	check(not is_instance_valid(shot), "A shot John frees itself")

	print("John cutout failures: ", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
