extends SceneTree
## The brute: walks slowly at the player, winds up and slams when in reach, hurts a player who
## stays in the slam zone and not one who steps out during the wind-up, won't slam at a player
## on another level, takes far more than a Rammer to kill, has its head as the weak spot, and
## barely moves when kicked.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS  ", message)
	else:
		failures += 1
		push_error(message)
		print("FAIL  ", message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func wait_until(condition: Callable, limit: int) -> bool:
	for i in limit:
		if condition.call():
			return true
		await physics_frame
	return condition.call()

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

	# A stand-in player that only counts damage.
	var stand_in := GDScript.new()
	stand_in.source_code = "extends Node3D\nvar damage := 0.0\nfunc take_damage(amount: float) -> void:\n\tdamage += amount\n"
	stand_in.reload()
	var player := Node3D.new()
	player.set_script(stand_in)
	player.position = Vector3(0, 0, -12)
	world.add_child(player)
	player.add_to_group("player")

	var brute = load("res://scenes/enemies/brute.tscn").instantiate()
	world.add_child(brute)
	await frames(10)
	var rammer = load("res://scenes/enemies/rammer.tscn").instantiate()
	check(brute.max_hp > float(rammer.max_hp) * 2.0, "a brute has well over twice a Rammer's health (%d)" % brute.max_hp)
	check(ceili(brute.max_hp / 22.0) >= 20, "a brute takes at least 20 pistol body shots")
	rammer.free()

	# Walks at the player, slowly.
	var start: Vector3 = brute.global_position
	await frames(60)
	var walked: float = brute.global_position.distance_to(start)
	check(brute.global_position.z < start.z - 0.5, "the brute walks towards the player")
	check(walked < 3.4, "slowly, at half the player's walk: %.2f in a second" % walked)

	# Stays in the zone: gets slammed.
	check(await wait_until(func() -> bool: return brute._state == brute.State.WINDUP, 600), "in reach, the brute winds up")
	check(player.damage == 0.0, "no damage during the wind-up")
	check(await wait_until(func() -> bool: return brute._state == brute.State.RECOVER, 120), "the slam lands")
	check(is_equal_approx(player.damage, brute.slam_damage), "standing in the zone costs %d (took %d)" % [brute.slam_damage, player.damage])

	# Steps out during the wind-up: no damage.
	check(await wait_until(func() -> bool: return brute._state == brute.State.WINDUP, 300), "it winds up again")
	var before: float = player.damage
	player.position += brute.global_basis.x * 5.0
	check(await wait_until(func() -> bool: return brute._state == brute.State.RECOVER, 120), "the second slam lands")
	check(player.damage == before, "stepping aside during the wind-up dodges it")

	# A player on a walk above is out of reach: no slam.
	await wait_until(func() -> bool: return brute._state == brute.State.CHASE, 200)
	player.position = brute.global_position + Vector3(1.5, 4.0, 0)
	await frames(90)
	check(brute._state == brute.State.CHASE, "no slam at a player on another level")
	player.position = brute.global_position + Vector3(0, 0, -30)

	# Hits.
	var hp: float = brute._hp
	brute.apply_shot(22.0, player.global_position, 3.0, false)
	check(is_equal_approx(brute._hp, hp - 22.0), "a body shot does full damage")
	hp = brute._hp
	brute.apply_shot(22.0, player.global_position, 3.0, true)
	check(brute._hp < hp - 22.0, "a head shot does more")
	check(brute.is_weak_hit(brute.to_global(Vector3(0, 2.4, -0.5))), "the head is the weak spot")
	check(not brute.is_weak_hit(brute.to_global(Vector3(0, 1.0, -0.8))), "the chest isn't")
	var at: Vector3 = brute.global_position
	brute.apply_kick(10.0, at + brute.global_basis.z * 1.5, 11.0)
	await frames(10)
	var moved := Vector2(brute.global_position.x - at.x, brute.global_position.z - at.z).length()
	check(moved < 0.9, "a kick barely shifts it (%.2f, its own walk included)" % moved)

	brute.apply_shot(10000.0, player.global_position, 0.0, false)
	await frames(2)
	check(not is_instance_valid(brute), "enough damage kills it")
	world.queue_free()
	await process_frame
	print("brute failures: ", failures)
	quit(1 if failures else 0)
