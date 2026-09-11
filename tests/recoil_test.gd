extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	player.set("_pitch", 0.2)
	player.set("_yaw", 0.4)
	player.rotation.y = 0.4
	for i in 30:
		player.set("_fire_timer", 0.0)
		player._try_fire()
		assert(is_equal_approx(player.get("_pitch"), 0.2), "Shots must not change aim pitch")
		assert(is_equal_approx(player.get("_yaw"), 0.4), "Shots must not change aim yaw")
		assert(player.get("_recoil").length() <= deg_to_rad(1.81), "Visual kick is bounded")
		player._update_recoil(0.18)
	assert(player.get("_shot_bloom") > 3.0, "Rapid fire builds meaningful long-range spread")
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(20, -10)
	player._apply_mouse_look(motion.relative)
	var adjusted_pitch: float = player.get("_pitch")
	var adjusted_yaw: float = player.get("_yaw")
	assert(not is_equal_approx(adjusted_pitch, 0.2), "Mouse can adjust aim during fire")
	player._update_recoil(3.0)
	assert(player.get("_recoil") == Vector2.ZERO, "Visual kick fully recovers")
	assert(is_zero_approx(player.get("_shot_bloom")), "Spread recovers")
	assert(is_equal_approx(player.get("_pitch"), adjusted_pitch), "Recovery preserves mouse pitch")
	assert(is_equal_approx(player.get("_yaw"), adjusted_yaw), "Recovery preserves mouse yaw")
	assert(is_equal_approx(player.head.rotation.x, adjusted_pitch), "Camera returns to current aim")
	print("Recoil checks passed")
	quit()
