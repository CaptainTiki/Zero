extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func solid(parent: Node, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	body.position = at

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func scenario(label: String, enemy_kind: String, distance: float, wall: bool = false, multiple: bool = false, moving: bool = false) -> void:
	var world := Node3D.new()
	root.add_child(world)
	solid(world, Vector3(0, -0.5, 0), Vector3(60, 1, 20))
	if wall:
		solid(world, Vector3(2.4, 2, 0), Vector3(0.4, 4, 10))
	var box = load("res://scenes/props/kick_box.tscn").instantiate()
	box.position = Vector3.ZERO
	world.add_child(box)
	var enemy = null
	var second = null
	if not enemy_kind.is_empty():
		enemy = load("res://scenes/enemies/" + enemy_kind + ".tscn").instantiate()
		enemy.position = Vector3(distance, 0, 0)
		world.add_child(enemy)
		if moving:
			var player := Node3D.new()
			world.add_child(player)
			player.position = Vector3(-5, 0, 0)
			enemy.set("_player", player)
	if multiple:
		second = load("res://scenes/enemies/fodder.tscn").instantiate()
		second.position = Vector3(distance + 1.1, 0, 0)
		world.add_child(second)
	await frames(2)
	box.apply_kick(10, Vector3(-1, 0, 0), 11)
	await frames(18)
	var early_x: float = box.position.x
	if enemy_kind == "fodder" and not wall and not multiple:
		check(early_x > 0.8, label + ": box must visibly advance")
		if distance < 2.0:
			check(enemy.position.x > distance + 1.0, label + ": enemy must recoil")
	await frames(130)
	check(box.get("_slide").length() < 0.01, label + ": must stop")
	if enemy != null:
		var expected: float = 176.25 if enemy_kind == "rammer" else (65.0 if enemy_kind == "hunter" else 15.0)
		check(is_equal_approx(enemy.get("_hp"), expected), label + ": one damage event")
	if wall:
		check(box.position.x <= 1.56, label + ": box must not cross wall")
		if enemy != null:
			check(enemy.position.x < 2.2, label + ": enemy must not cross wall")
	if multiple:
		check(is_equal_approx(second.get("_hp"), 40.0), label + ": no second armed impact")
	print(label, ": early box x=", early_x, " final x=", box.position.x)
	if enemy_kind == "fodder" and not wall and not multiple and not moving:
		box.position = enemy.position - Vector3(1.12, 0, 0)
		box.apply_kick(10, box.position - Vector3.RIGHT, 11)
		await frames(10)
		check(not is_instance_valid(enemy), label + ": fresh kick rearms damage")
	world.queue_free()
	await frames(2)

func run() -> void:
	await scenario("empty", "", 0)
	await scenario("close", "fodder", 1.12)
	await scenario("distant", "fodder", 3.0)
	await scenario("moving", "fodder", 1.5, false, false, true)
	await scenario("trapped", "fodder", 1.12, true)
	await scenario("wall", "", 0, true)
	await scenario("multiple", "fodder", 1.12, false, true)
	await scenario("rammer", "rammer", 1.4)
	await scenario("hunter", "hunter", 1.4)
	print("Kick box failures: ", failures)
	quit(1 if failures else 0)
