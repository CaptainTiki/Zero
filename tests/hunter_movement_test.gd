extends SceneTree

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
		await process_frame

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(100, 1, 100)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	var player := Node3D.new()
	player.position = Vector3(15, 0, 0)
	world.add_child(player)
	var hunter = load("res://scenes/enemies/hunter.tscn").instantiate()
	world.add_child(hunter)
	hunter.set("_player", player)
	await frames(12)
	check(hunter.position.x < 0.05, "Initial readable pause")
	await frames(20)
	check(hunter.get("_bursting"), "Hunter starts burst")
	var committed: Vector3 = hunter.get("_burst_velocity")
	player.position.z = 4
	hunter.take_damage(1)
	await frames(5)
	check(hunter.get("_burst_velocity").is_equal_approx(committed), "Movement and bullet hits do not redirect committed burst")
	await frames(20)
	check(not hunter.get("_bursting"), "Burst ends in shooting window")
	var resting: Vector3 = hunter.position
	await frames(20)
	check(hunter.position.distance_to(resting) < 0.03, "Hunter holds still through pause")
	await frames(22)
	check(hunter.get("_bursting"), "Hunter resumes pursuit")
	var before: Vector3 = hunter.position
	hunter.apply_kick(10, hunter.position - Vector3.RIGHT, 11)
	await frames(12)
	check(not hunter.get("_bursting"), "Kick cancels burst")
	check(hunter.position.x > before.x + 0.8, "Kick knockback remains visible")
	await frames(18)
	check(not hunter.get("_bursting"), "Recovery pause after stagger")
	player.position = Vector3(90, 0, 0)
	await frames(50)
	check(not hunter.get("_bursting"), "No pursuit outside aggro range")
	check(is_equal_approx(hunter.get("_hp"), 79.0), "Damage preserved")
	world.queue_free()
	await process_frame
	print("Hunter movement failures: ", failures)
	quit(1 if failures else 0)
