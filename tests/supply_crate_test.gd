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
	var crate_scene := load("res://scenes/props/supply_crate.tscn") as PackedScene
	var crate = crate_scene.instantiate()
	world.add_child(crate)
	crate.take_damage(22.0)
	check(not crate.get("_broken"), "One pistol shot should leave crate intact")
	crate.take_damage(22.0)
	crate.apply_kick(10.0, Vector3.ZERO, 11.0)
	await frames(3)
	check(not is_instance_valid(crate), "Broken crate removed")
	check(get_nodes_in_group("health_pickups").size() == 1, "Repeated hits produce exactly one reward")
	var player = load("res://scenes/player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	player.position = Vector3.ZERO
	await frames(5)
	check(get_nodes_in_group("health_pickups").size() == 1, "Full health leaves pickup available")
	player.set("_hp", 90.0)
	await frames(5)
	check(is_equal_approx(player.get("_hp"), 100.0), "Healing caps at max HP")
	check(get_nodes_in_group("health_pickups").is_empty(), "Pickup consumed after healing")
	crate = crate_scene.instantiate()
	world.add_child(crate)
	player.set("_hp", 40.0)
	crate.apply_kick(10.0, Vector3(-1, 0, 0), 11.0)
	await frames(8)
	check(not is_instance_valid(crate), "Single kick breaks crate")
	check(is_equal_approx(player.get("_hp"), 65.0), "Pickup restores exactly 25 HP")
	await frames(80)
	check(world.get_child_count() == 1, "Debris and collected rewards cleaned up")
	player.position = Vector3(0, 0, 8)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(40, 1, 20)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	crate = crate_scene.instantiate()
	crate.position = Vector3(1.3, 0, 0)
	world.add_child(crate)
	var metal = load("res://scenes/props/kick_box.tscn").instantiate()
	world.add_child(metal)
	await frames(4)
	check(not crate.get("_broken"), "Resting metal box does not break crate")
	metal.apply_kick(10.0, Vector3(-1, 0, 0), 11.0)
	await frames(20)
	check(not is_instance_valid(crate), "Sliding metal box breaks supply crate")
	check(metal.position.x > 1.5, "Metal box carries through broken crate")
	check(get_nodes_in_group("health_pickups").size() == 1, "Metal impact releases exactly one reward")
	print("Supply crate failures: ", failures)
	quit(1 if failures else 0)
