extends SceneTree
var failures := 0
const FACTORY := "res://scenes/levels/factory.tscn"
const CITY := "res://scenes/levels/l01_district04.tscn"

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1

func frames(n := 5) -> void:
	for i in n:
		await process_frame

func beat(number: int) -> Area3D:
	for area in get_nodes_in_group("beat_lines"):
		if int(area.get_meta("beat")) == number:
			return area
	return null

func action(name: String) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	root.push_input(event)
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await frames()

func run() -> void:
	root.size = Vector2i(1152, 648)
	change_scene_to_file(FACTORY)
	await scene_changed
	await frames()
	var level: Node = current_scene
	var player: Node = get_first_node_in_group("player")
	var start: Vector3 = level._unstuck_at
	await action("pause")
	player.position += Vector3(5, -3, 5)
	player.velocity = Vector3(10, -20, 10)
	check(level.unstuck_player() and player.position == start, "Before any beat, Unstuck returns to the level start")
	check(player.velocity == Vector3.ZERO, "Unstuck clears falling and sideways velocity")

	var crossing: Vector3 = beat(2).global_position - Vector3(0, 1.0, 0)
	player.position = crossing
	level._on_beat_line(player, beat(2))
	var destination: Vector3 = level._unstuck_at
	check(level._unstuck_beat == 2 and destination.distance_to(crossing) < 0.11, "Checkpoint records where the player crossed the latest beat")
	player.position = beat(1).global_position - Vector3(0, 1.0, 0)
	level._on_beat_line(player, beat(1))
	check(level._unstuck_at == destination, "An earlier beat cannot roll back the checkpoint")
	player._hp = 63.0
	player._shells = 9
	level._kills = 7
	level._secrets_found = 2
	var walked: float = level._walked
	var elapsed: float = level.clock()
	player.position = Vector3(200, -10, 200)
	var trapped: Vector3 = player.position
	player.velocity = Vector3(8, -30, 6)
	check(level.unstuck_player(), "Unstuck succeeds while paused")
	check(player.position == destination and player.velocity == Vector3.ZERO, "Player returns to the latest beat without momentum")
	check(player._hp == 63.0 and player._shells == 9 and level._kills == 7 and level._secrets_found == 2, "Unstuck preserves health, ammo and completion")
	check(level._walked == walked and level.clock() == elapsed and level._last_pos == destination, "Teleport adds no walk distance and rewinds no time")
	check(level._safe_pos == destination, "Fall recovery no longer points at the trapped position")
	check(level._report[-1].contains("UNSTUCK") and level._report[-1].contains(str(trapped)) and level._report[-1].contains("beat 2"), "Log records the trapped position, destination and beat")
	player.position += Vector3(3, 0, 3)
	await action("ui_down")
	check(root.gui_get_focus_owner() == level._pause_menu._unstuck_button, "Unstuck is selectable in the pause menu")
	await action("ui_accept")
	check(not paused and not level._pause_menu.visible and player.position.distance_to(destination) < 0.8, "Selecting Unstuck teleports and resumes gameplay")
	if DisplayServer.get_name() != "headless":
		check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Unstuck recaptures the mouse")

	await action("pause")
	var piece: Node = level.get_node("MachineSetPiece")
	piece._start(player)
	check(level._unstuck_at == piece.respawn_at, "Machine seal moves the checkpoint into the pit")
	player.position = Vector3(47, -3.5, -125)
	level.unstuck_player()
	check(player.position == piece.respawn_at, "Unstuck stays inside the closed machine room")
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await scene_changed
	await frames()
	change_scene_to_file(CITY)
	await scene_changed
	await frames()
	level = current_scene
	player = get_first_node_in_group("player")
	await action("pause")
	player.position = Vector3(-18, 0.25, -150)
	level._on_beat_line(player, beat(6))
	destination = level._unstuck_at
	check(destination.y > 0.0, "City ramp checkpoint uses player height instead of trigger-centre height")
	player.position = Vector3(100.4, 5.0, -36.645)
	level.unstuck_player()
	check(player.position == destination and level._unstuck_beat == 6, "City Unstuck works even with old checkpoint-respawn disabled")
	paused = false
	print("Unstuck failures: ", failures)
	quit(1 if failures else 0)
