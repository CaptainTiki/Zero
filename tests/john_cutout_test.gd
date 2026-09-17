extends SceneTree
## A cardboard John blocks nobody, knocks over when something walks into it,
## falls the way it was hit, counts itself exactly once, comes to rest on the
## floor and clears itself away.

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
	john.set("debris_seconds", 3.0)
	world.add_child(john)
	return john

func make_walker(world: Node, at: Vector3) -> CharacterBody3D:
	var walker := CharacterBody3D.new()
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	walker.add_child(collision)
	world.add_child(walker)
	walker.global_position = at
	return walker

## World position of the fallen John's head, or null once it has gone.
func head_of(john: Node) -> Variant:
	var fallen = john.get("_fallen") if is_instance_valid(john) else null
	if fallen == null or not is_instance_valid(fallen):
		return null
	return fallen.to_global(Vector3(0, 1.64, 0))

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var stats := Node.new()
	stats.set_script(STUB)
	stats.add_to_group("run_stats")
	world.add_child(stats)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(80, 1, 80)
	floor_shape.shape = slab
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	await frames(2)

	# Kicked from in front: it falls away from the kicker and counts once.
	var kicked := make_john(world, Vector3(0, 0, 0))
	check(kicked.is_in_group("johns"), "A cutout joins the johns group")
	await frames(2)
	kicked.apply_kick(10.0, Vector3(0, 0, 4), 11.0)
	await frames(6)
	check(stats.get("johns") == 1, "A kick counts one John (got %s)" % stats.get("johns"))
	kicked.apply_kick(10.0, Vector3(0, 0, 4), 11.0)
	await frames(2)
	check(stats.get("johns") == 1, "A falling John does not count twice")

	# Shot in the back of the head: it falls away from the shooter, not towards them.
	var shot := make_john(world, Vector3(6, 0, 0))
	await frames(2)
	shot.apply_bullet(22.0, Vector3(6, 1.65, -0.2), Vector3(0, 0, 1))
	await frames(6)
	check(stats.get("johns") == 2, "A bullet counts one John (got %s)" % stats.get("johns"))

	# Edge-on, the hitbox is deeper than the card.
	var edge := make_john(world, Vector3(12, 0, 0))
	await frames(2)
	var side := PhysicsRayQueryParameters3D.create(Vector3(12.18, 1.2, 5), Vector3(12.18, 1.2, -5), 4)
	var side_hit := world.get_world_3d().direct_space_state.intersect_ray(side)
	check(side_hit.get("collider") == edge, "A shot 0.18 beside the card still hits it")
	var world_only := PhysicsRayQueryParameters3D.create(Vector3(12, 1.2, 5), Vector3(12, 1.2, -5), 1)
	check(world.get_world_3d().direct_space_state.intersect_ray(world_only).get("collider") != edge, "A standing John isn't on the world layer")

	# Standing still beside a John leaves it up; walking into it knocks it over,
	# and the walker carries on through without stopping.
	var bumped := make_john(world, Vector3(20, 0, 0))
	var walker := make_walker(world, Vector3(20, 0.02, 0.5))
	await frames(20)
	check(not bumped.get("_down"), "Something standing still beside a John doesn't topple it")
	for i in 70:
		walker.velocity = Vector3(0, -1, -5)
		walker.move_and_slide()
		await physics_frame
	check(bumped.get("_down"), "Walking into a John knocks it over")
	check(walker.global_position.z < -4.0, "A John doesn't stop the walker (z %.2f)" % walker.global_position.z)
	check(stats.get("johns") == 3, "A bumped John counts (got %s)" % stats.get("johns"))

	# Everything comes to rest lying on the floor, freezes, and ends up past its side.
	await frames(60)
	var kicked_head = head_of(kicked)
	var shot_head = head_of(shot)
	check(kicked_head != null and kicked_head.z < -0.8 and kicked_head.y < 0.3, "A kicked John lies flat, away from the kicker: head %s" % [kicked_head])
	check(shot_head != null and shot_head.z > 0.8 and shot_head.y < 0.3, "A shot John lies flat, away from the shooter: head %s" % [shot_head])
	check(kicked.get("_fallen").freeze, "A John at rest stops simulating")
	var bumped_head = head_of(bumped)
	check(bumped_head != null and bumped_head.y < 0.3 and bumped_head.y > -0.1, "A bumped John lies on the floor: head %s" % [bumped_head])

	# Fallen Johns clear themselves away rather than littering the level.
	await frames(160)
	check(not is_instance_valid(kicked), "A flattened John frees itself")
	check(not is_instance_valid(shot), "A shot John frees itself")
	check(get_nodes_in_group("johns").size() == 1, "Only the untouched John is left (%d)" % get_nodes_in_group("johns").size())
	var leftovers := 0
	for child in world.get_children():
		if child is RigidBody3D:
			leftovers += 1
	check(leftovers == 0, "No fallen bodies are left behind (%d)" % leftovers)

	print("John cutout failures: ", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
