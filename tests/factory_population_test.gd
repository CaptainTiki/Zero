extends SceneTree
## Every placed enemy and cardboard John in the factory lets physics settle for two seconds
## with the player out of the way. Anything that falls more than a step, drops out of the
## world, or gets shoved sideways was placed inside or over geometry. Also counts what the
## plan says should be there.

const PLAN := "res://docs/factory_plan/plan.json"

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL  " + message)

func run() -> void:
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLAN))
	var level = load("res://scenes/levels/factory.tscn").instantiate()
	root.add_child(level)
	var player = level.get_node("Player")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = Vector3(4000, -400, 4000)
	await physics_frame
	var start := {}
	for e in get_nodes_in_group("enemies"):
		start[e] = e.global_position
	var johns := get_nodes_in_group("johns")
	check(start.size() == (plan["enemies"] as Array).size(), "placed enemies: %d in the scene, %d in the plan" % [start.size(), (plan["enemies"] as Array).size()])
	check(johns.size() == (plan["johns"] as Array).size(), "Johns: %d in the scene, %d in the plan" % [johns.size(), (plan["johns"] as Array).size()])
	check(get_nodes_in_group("ambush").size() == (plan["ambushes"] as Array).size(), "ambush triggers match the plan")
	for i in 120:
		await physics_frame
	for e in start:
		if not is_instance_valid(e):
			check(false, "%s at %s was freed while settling" % [e, start[e]])
			continue
		var from: Vector3 = start[e]
		var now: Vector3 = e.global_position
		var flat := Vector2(now.x - from.x, now.z - from.z).length()
		check(now.y > from.y - 1.0, "%s placed at %s fell to %s" % [e.name, from, now])
		check(flat < 1.0, "%s placed at %s was pushed %.1f sideways to %s" % [e.name, from, flat, now])
	print("FACTORY population: %d enemies, %d Johns, %d ambushes, failures %d" % [start.size(), johns.size(), get_nodes_in_group("ambush").size(), failures])
	level.queue_free()
	await process_frame
	quit(1 if failures else 0)
