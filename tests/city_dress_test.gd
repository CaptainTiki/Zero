extends SceneTree
## Checks the baked city dressing keeps the route open and closes the end plaza.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var level = load("res://scenes/levels/m01_beats_1_5.tscn").instantiate()
	root.add_child(level)
	check(level.has_node("CityDress"), "City dress scene loaded")
	# Disabling a node's processing also pulls its StaticBody3D collisions out of
	# the physics space, so only the actors are disabled, never the level itself.
	for actor in get_nodes_in_group("enemies") + [level.get_node("Player")]:
		actor.process_mode = Node.PROCESS_MODE_DISABLED
	# Walk the player's own collision body down the spine from the checkpoint exit
	# to the tunnel closure. The exit gap is 4 units wide and the wrecked car
	# blocks z >= -0.4, so the open lanes sit just left of centre.
	var walker = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(walker)
	walker.set_physics_process(false)
	walker.set_process_input(false)
	walker.set_process_unhandled_input(false)
	for lane in [-1.5, -1.0]:
		walker.position = Vector3(56, 0.3, lane)
		for i in 720:
			await physics_frame
			walker.velocity = Vector3(6.0, -2.0, 0.0)
			walker.move_and_slide()
		print("Lane ", lane, " ends at ", walker.position)
		check(walker.position.x > 112.0, "Spine lane %s stays walkable to the end plaza" % lane)
		check(walker.position.x < 117.0, "Tunnel closure stops the walker on lane %s" % lane)
	# The end plaza is enclosed on the sides.
	var space: PhysicsDirectSpaceState3D = walker.get_world_3d().direct_space_state
	for side in [1.0, -1.0]:
		var query := PhysicsRayQueryParameters3D.create(Vector3(109, 1.2, 0), Vector3(109, 1.2, side * 12.0))
		var hit: Dictionary = space.intersect_ray(query)
		check(not hit.is_empty() and absf(hit.position.z) < 9.0, "End plaza wall on side %s" % side)
	# The boulevard platform and ledge are still reachable up the ramp.
	walker.position = Vector3(69, 0.3, -5.6)
	for i in 300:
		await physics_frame
		walker.velocity = Vector3(5.0, -2.0, 0.0)
		walker.move_and_slide()
	print("Ramp walk ends at ", walker.position)
	check(walker.position.y > 2.4 and walker.position.x > 81.0, "Ramp to the tram platform is climbable")
	walker.queue_free()
	level.queue_free()
	await process_frame
	print("City dress failures: ", failures)
	quit(1 if failures else 0)
