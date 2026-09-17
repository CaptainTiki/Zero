extends SceneTree
## The player's kick sweeps a boot-sized box: it connects with a John edge-on and
## just off the aim line, stops at a wall, still kicks enemies, and whiffs at air.
## The pistol finds a John edge-on through its deeper hitbox.

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

func make_john(world: Node, at: Vector3, yaw := 0.0) -> Node:
	var john = load("res://scenes/props/john_cutout.tscn").instantiate()
	john.position = at
	john.rotation.y = yaw
	world.add_child(john)
	return john

func box(world: Node, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	body.position = at
	world.add_child(body)

func kick(player: Node) -> void:
	player.set("_kick_elapsed", 0.0)
	player.set("_kick_connected", false)
	player._update_kick(0.13)

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var stats := Node.new()
	stats.set_script(STUB)
	stats.add_to_group("run_stats")
	world.add_child(stats)
	box(world, Vector3(0, -0.5, 0), Vector3(80, 1, 80))
	var player = load("res://scenes/player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	# Each case gets its own lane along x, with the player looking down -z.
	var at := func(x: float) -> void:
		player.global_position = Vector3(x, 0, 0)

	# Edge-on and 0.3 off the aim line: a ray misses even the deeper hitbox, the boot doesn't.
	var edge := make_john(world, Vector3(0.3, 0, -1.7), PI / 2)
	await frames(3)
	at.call(0.0)
	await frames(1)
	kick(player)
	check(edge.get("_down"), "The boot connects with an edge-on John just off the aim line")

	# A wall between the boot and a John stops the kick.
	var walled := make_john(world, Vector3(10, 0, -1.9))
	box(world, Vector3(10, 1.5, -1.0), Vector3(3, 3, 0.2))
	await frames(3)
	at.call(10.0)
	await frames(1)
	kick(player)
	check(not walled.get("_down"), "A wall stops the kick before the John behind it")

	# Enemies still take the kick.
	var fodder = load("res://scenes/enemies/fodder.tscn").instantiate()
	fodder.position = Vector3(20, 0, -1.4)
	world.add_child(fodder)
	fodder.set_physics_process(false)
	await frames(3)
	at.call(20.0)
	await frames(1)
	var hp: float = fodder.get("_hp")
	kick(player)
	check(fodder.get("_hp") < hp, "The kick still lands on an enemy (hp %s)" % fodder.get("_hp"))

	# Nothing in reach, nothing kicked.
	at.call(30.0)
	await frames(1)
	var origin: Vector3 = player.camera.global_position - player.camera.global_basis.y * 0.25
	check(player._kick_target(origin) == null, "Kicking at air finds nothing")

	# The pistol hits an edge-on John 0.15 off the aim line through its deeper hitbox.
	var shot := make_john(world, Vector3(40.15, 0, -4), PI / 2)
	await frames(3)
	at.call(40.0)
	await frames(1)
	player.grant_gun()
	player.set("_fire_timer", 0.0)
	player._try_fire()
	check(shot.get("_down"), "A pistol shot knocks over an edge-on John")
	check(stats.get("johns") == 2, "Two Johns counted (got %s)" % stats.get("johns"))

	print("Kick reach failures: ", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
