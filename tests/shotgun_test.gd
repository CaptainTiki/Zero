extends SceneTree
## Shotgun, shells and boost drink behaviour on the real player scene.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(60, 1, 60)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	var player = load("res://scenes/player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	var fodder = load("res://scenes/enemies/fodder.tscn").instantiate()
	fodder.position = Vector3(0, 0, -3.5)
	world.add_child(fodder)
	fodder.set_physics_process(false)
	var far = load("res://scenes/enemies/fodder.tscn").instantiate()
	far.position = Vector3(0, 0, -22)
	world.add_child(far)
	far.set_physics_process(false)
	await physics_frame
	await physics_frame
	check(player.has_node("Head/Camera3D/ViewShotgun"), "Shotgun rig built")
	check(player.get_node("Head/Camera3D/ViewFists").get_child_count() >= 1, "Fist rig built")
	player._try_shotgun()
	check(is_equal_approx(fodder.get("_hp"), 40.0), "No shotgun before pickup")
	player.grant_shotgun()
	check(player.get("_shells") == 8 and player.get("_weapon") == 2, "Pickup grants shells and equips")
	check(player.add_shells(8), "Shells top up")
	check(player.get("_shells") == 16, "Shell count")
	player.set("_pitch", -0.25) # aim from eye height (1.6) down at the fodder centre
	player.set("_shotgun_timer", 0.0) # the empty click above started a cooldown
	player._try_shotgun()
	check(player.get("_shells") == 15, "Shot spends one shell")
	var close_hp: float = fodder.get("_hp")
	check(close_hp < 40.0 - 8.0 * 3.0, "Close spread lands most pellets: hp %s" % close_hp)
	check(player.get("_recoil").length() > deg_to_rad(2.5), "Shotgun kicks harder than the pistol")
	player.set("_shotgun_timer", 0.0)
	player._try_shotgun()
	check(player.get("_shells") == 15, "Cannot fire while pumping")
	player._update_pump(0.7)
	player._try_shotgun()
	check(player.get("_shells") == 14, "Fires again after the pump")
	check(not is_instance_valid(fodder) or fodder.get("_hp") < close_hp, "Second shot damages or kills")
	player.set("_pitch", -0.04) # line up the distant fodder
	player.set("_shotgun_timer", 0.0)
	player._update_pump(0.7)
	player._try_shotgun()
	var far_hp: float = far.get("_hp")
	check(far_hp > 20.0, "Distant target takes reduced or no damage: hp %s" % far_hp)
	player.set("_shells", 0)
	player.set("_shotgun_timer", 0.0)
	player._try_shotgun()
	check(player.get("_shells") == 0, "Empty gun clicks")
	player.set("_shells", 32)
	check(not player.add_shells(8), "Full shells refuse pickup")
	check(player.apply_boost(8.0) and player.get("_boost_left") > 7.9, "Boost applies")
	world.queue_free()
	await process_frame
	print("Shotgun failures: ", failures)
	quit(1 if failures else 0)
