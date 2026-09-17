extends SceneTree
## Real scene transitions: completion, inspection, death, escape failure and restart.
const FACTORY := "res://scenes/levels/factory.tscn"
const CITY := "res://scenes/levels/l01_district04.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1

func frames(n := 3) -> void:
	for i in n:
		await physics_frame
	await process_frame

func open(path: String) -> Node:
	change_scene_to_file(path)
	await frames(5)
	return current_scene

func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	root.push_input(event)
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await frames(5)

func quiet_enemies() -> void:
	for actor in get_nodes_in_group("enemies"):
		actor.process_mode = Node.PROCESS_MODE_DISABLED

func run() -> void:
	root.size = Vector2i(1152, 648)
	Input.action_press("primary")
	var level: Node = await open(FACTORY)
	quiet_enemies()
	var player: Node = get_first_node_in_group("player")
	check(not player._combat_input_ready and level._shots.pistol == 0, "Held menu input cannot attack on level entry")
	Input.action_release("primary")
	await frames()
	check(player._combat_input_ready, "Releasing menu input enables combat")

	level._lift_open = true
	level.finish()
	var finished_time: float = level.clock()
	var old_id: int = level.get_instance_id()
	await frames()
	check(level._finished and level._tally.visible, "Factory completion shows the tally")
	check(not player.can_process() and level.clock() == finished_time, "Tally freezes the player and run timer")
	var ground := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, player.global_position + Vector3.DOWN * 3.0, 1)
	check(not player.get_world_3d().direct_space_state.intersect_ray(ground).is_empty(), "Frozen world retains its floor collisions")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Tally releases the mouse")
	await press("ui_cancel")
	check(not level._tally.visible and player.can_process(), "Escape enables inspection after completion")
	if DisplayServer.get_name() != "headless":
		check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Inspection captures the mouse exactly once")
	player.take_damage(10000.0)
	check(not player.dead, "Inspecting a completed run cannot cause a new death")
	await press("ui_cancel")
	check(level._tally.visible and not player.can_process(), "Escape reopens the tally and stops inspection")
	await press("ui_accept")
	check(current_scene.scene_file_path == CITY and current_scene.get_instance_id() != old_id, "Continue loads District 04 after the factory")
	level = current_scene
	quiet_enemies()
	level._lift_open = true
	level.finish()
	await frames()
	await press("kick")
	check(current_scene.scene_file_path == MENU, "Completing the last level returns to the menu")

	level = await open(FACTORY)
	quiet_enemies()
	player = get_first_node_in_group("player")
	old_id = level.get_instance_id()
	player.take_damage(10000.0)
	var death_time: float = level.clock()
	var dead_at: Vector3 = player.global_position
	await frames(8)
	check(level._dead and not level._finished and player.dead, "Lethal damage fails the run")
	check(player._hp == 0.0 and level._deaths == 1, "Death keeps zero health and records one death")
	check(level.clock() == death_time and player.global_position == dead_at, "Death freezes time and position")
	player.take_damage(10000.0)
	level.finish()
	check(level._deaths == 1 and not level._finished, "Repeated damage and exit cannot turn death into completion")
	await press("primary")
	check(current_scene.scene_file_path == FACTORY and current_scene.get_instance_id() != old_id, "Fire restarts the same level with a fresh scene")
	level = current_scene
	player = get_first_node_in_group("player")
	check(not player.dead and player._hp == player.max_hp and level._deaths == 0, "Restart resets health, death state and run stats")
	quiet_enemies()
	player.take_damage(10000.0)
	await frames()
	await press("ui_cancel")
	check(current_scene.scene_file_path == MENU, "Escape from death returns to the menu")

	level = await open(FACTORY)
	quiet_enemies()
	var piece: Node = level.get_node("MachineSetPiece")
	piece._critical()
	piece.escape_left = 0.01
	await frames(5)
	check(level._dead and not level._finished and level._tally.text.contains("ESCAPE FAILED"), "Escape timeout offers failure instead of the next level")
	old_id = level.get_instance_id()
	await frames(5)
	await press("ui_accept")
	await frames(10)
	check(current_scene.scene_file_path == FACTORY and current_scene.get_instance_id() != old_id, "Enter restarts after escape failure")
	print("Game flow failures: ", failures)
	quit(1 if failures else 0)
