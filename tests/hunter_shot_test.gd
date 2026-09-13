extends SceneTree
## The Hunter fires a visible projectile during its shooting window when it can
## see the player, the projectile travels and damages the player, and a wall
## between them stops both the shot and the decision to fire.

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

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(120, 1, 120)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	var player = load("res://scenes/player/player.tscn").instantiate()
	player.position = Vector3(0, 0.3, 0)
	world.add_child(player)
	player.set_physics_process(false)
	var hunter = load("res://scenes/enemies/hunter.tscn").instantiate()
	hunter.position = Vector3(0, 0.3, -18)
	world.add_child(hunter)
	var hp_before: float = player.get("_hp")
	await frames(240)
	check(hunter.get("_shots_fired") >= 1, "Hunter fires in its shooting window (fired %s)" % hunter.get("_shots_fired"))
	check(player.get("_hp") < hp_before, "A projectile reached the player (hp %s)" % player.get("_hp"))
	# Wall between them: no line of sight, no shot.
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(30, 8, 1)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(0, 4, -9)
	world.add_child(wall)
	hunter.position = Vector3(0, 0.3, -18)
	hunter.set("_alerted", true)
	var fired_before: int = hunter.get("_shots_fired")
	var hp_mid: float = player.get("_hp")
	await frames(180)
	check(hunter.get("_shots_fired") == fired_before, "No shot without line of sight")
	check(is_equal_approx(player.get("_hp"), hp_mid), "No damage through the wall")
	print("Hunter shot failures: ", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
