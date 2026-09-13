extends SceneTree
## Guards two bug classes that are invisible until someone walks the level:
##   1. A block laid over an interior, filling a room with solid geometry.
##   2. wall() used for a lintel, which builds from the ground up and seals the door.
## Also checks every placed enemy has floor under it and is not embedded in the
## world, which is how a sealed room announces itself: the enemy inside gets
## pushed through the floor and shows up as an unkillable survivor.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

## Player-sized standing space, named so a failure says where.
const ROOMS := [
	["busted shop", Vector3(34, 0.95, -8)],
	["busted shop doorway", Vector3(34, 0.95, -4.3)],
	["storeroom", Vector3(24, 0.95, 8)],
	["storeroom doorway", Vector3(24, 0.95, 4.3)],
	["pharmacy ground floor", Vector3(86, 0.95, -35)],
	["pharmacy doorway", Vector3(74.3, 0.95, -30)],
	["pharmacy first floor", Vector3(88, 4.95, -40)],
	["museum lobby", Vector3(144, 1.1, -118)],
	["museum doorway", Vector3(150, 1.1, -110.3)],
	["freight lift", Vector3(151, 1.1, -133)],
	["cistern", Vector3(34, -4.55, -112)],
	["pump station yard", Vector3(-36, 0.95, -155)],
]

func overlaps(space: PhysicsDirectSpaceState3D, at: Vector3, radius: float, skip_breakables := false) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius
	cap.height = 1.8
	q.shape = cap
	q.transform = Transform3D(Basis(), at)
	q.collision_mask = 1
	var names := []
	for hit in space.intersect_shape(q, 8):
		var collider := hit["collider"] as Node
		# Enemies share the world layer; one standing near another is not "buried".
		if collider.is_in_group("enemies"):
			continue
		# A pickup inside a supply crate is released by breaking the crate, so the
		# crate itself is not what makes it unreachable.
		if skip_breakables and collider.has_method("take_damage"):
			continue
		names.append(String(collider.name))
	return names

func run() -> void:
	var level = load("res://scenes/levels/l01_district04.tscn").instantiate()
	root.add_child(level)
	for actor in get_nodes_in_group("enemies") + [level.get_node("Player")]:
		actor.process_mode = Node.PROCESS_MODE_DISABLED
	# Doors start shut; open them the way the player would before testing doorways.
	for door_name in ["YardDoor", "DetourDoor", "StoreDoor"]:
		var door = level.get_node_or_null(door_name)
		if door and door.has_method("apply_kick"):
			door.apply_kick(10.0, door.global_position + Vector3(0, 1, 3), 11.0)
	for i in 20:
		await physics_frame
	var space: PhysicsDirectSpaceState3D = level.get_node("Player").get_world_3d().direct_space_state
	for room in ROOMS:
		var names: Array = overlaps(space, room[1], 0.4)
		check(names.is_empty(), "%s is blocked at %s by %s" % [room[0], room[1], names])
	# Every placed enemy: floor underneath, and not buried in the world.
	var buried := 0
	var floating := 0
	for enemy in get_nodes_in_group("enemies"):
		if not (enemy is Node3D):
			continue
		var at: Vector3 = (enemy as Node3D).global_position
		var down := PhysicsRayQueryParameters3D.create(at + Vector3(0, 0.5, 0), at - Vector3(0, 2.0, 0), 1)
		var hit: Dictionary = space.intersect_ray(down)
		if hit.is_empty():
			floating += 1
			push_error("%s at %s has no floor under it" % [enemy.name, at])
		var names: Array = overlaps(space, at + Vector3(0, 0.9, 0), 0.3)
		if not names.is_empty():
			buried += 1
			push_error("%s at %s is inside %s" % [enemy.name, at, names])
	# Every pickup must have standing room on the surface it sits on, or it cannot
	# be collected. The cistern is only 3.5 tall, which is how this first bit.
	var unreachable := 0
	for group in ["ammo_pickups", "health_pickups", "boost_pickups"]:
		for pickup in get_nodes_in_group(group):
			if not (pickup is Node3D):
				continue
			var at: Vector3 = (pickup as Node3D).global_position
			var down := PhysicsRayQueryParameters3D.create(at, at - Vector3(0, 3.0, 0), 1)
			var hit: Dictionary = space.intersect_ray(down)
			if hit.is_empty():
				continue # floating pickups are caught by eye, not here
			var names: Array = overlaps(space, Vector3(at.x, hit.position.y + 0.92, at.z), 0.35, true)
			if not names.is_empty():
				unreachable += 1
				push_error("%s at %s has no standing room on %.2f: %s" % [pickup.name, at, hit.position.y, names])
	failures += buried + floating + unreachable
	print("L01 interiors: %d rooms checked, %d enemies buried, %d without floor, %d pickups with no standing room" % [ROOMS.size(), buried, floating, unreachable])
	print("L01 interiors failures: ", failures)
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)
