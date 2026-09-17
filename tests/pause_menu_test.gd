extends SceneTree
## Real Escape/GUI input, physics and clocks across pause, resume and exit.
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
		await process_frame

func press(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await frames(5)

func click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion)
	await frames(1)
	Input.action_press("primary")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = at
	event.global_position = at
	event.pressed = true
	root.push_input(event)
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await frames(5)

func run() -> void:
	root.size = Vector2i(1152, 648)
	change_scene_to_file(FACTORY)
	await scene_changed
	await frames(5)
	var level: Node = current_scene
	var player: Node = get_first_node_in_group("player")
	var pause_menu: CanvasLayer = level._pause_menu
	var piece: Node = level.get_node("MachineSetPiece")
	piece._critical()
	var falling := RigidBody3D.new()
	falling.position = player.position + Vector3(0, 20, 0)
	level.add_child(falling)
	var moving := Node3D.new()
	level.add_child(moving)
	level.create_tween().tween_property(moving, "position:x", 10.0, 1.0)
	await frames(3)
	await press(KEY_ESCAPE)
	check(paused and pause_menu.visible, "Escape pauses and shows the menu")
	check(root.gui_get_focus_owner() == pause_menu._resume_button, "Resume has initial focus")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Pause releases the mouse")
	var clock_before: float = level.clock()
	var escape_before: float = piece.escape_left
	var player_before: Vector3 = player.position
	var rigid_before: Vector3 = falling.position
	var tween_before: Vector3 = moving.position
	var timer_state := {"fired": false}
	create_timer(0.1, false).timeout.connect(func() -> void: timer_state.fired = true)
	await create_timer(0.25, true).timeout
	check(level.clock() == clock_before, "Run timer excludes paused time")
	check(piece.escape_left == escape_before, "Factory escape countdown stops")
	check(player.position == player_before and falling.position == rigid_before, "Player and physics bodies stop")
	check(moving.position == tween_before and not timer_state.fired, "Animations and gameplay timers stop")
	var aim_before: float = player._yaw
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, 100)
	root.push_input(motion)
	check(player._yaw == aim_before, "Mouse movement cannot aim behind the menu")
	await press(KEY_ESCAPE)
	check(not paused and not pause_menu.visible, "Escape resumes without immediately reopening pause")
	if DisplayServer.get_name() != "headless":
		check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Resume recaptures the mouse")
	await create_timer(0.2, true).timeout
	check(level.clock() > clock_before and piece.escape_left < escape_before, "Both clocks continue after resume")
	check(falling.position != rigid_before and moving.position != tween_before and timer_state.fired, "Physics, animation and timers continue")

	await press(KEY_ESCAPE)
	await click(pause_menu._resume_button.get_global_rect().get_center())
	check(not paused and not pause_menu.visible, "Mouse Resume continues the game")
	check(not player._combat_input_ready, "Held resume click is blocked from attacking")
	Input.action_release("primary")
	await create_timer(0.05, true).timeout
	check(player._combat_input_ready, "Combat returns once the menu click is released")
	await press(KEY_ESCAPE)
	await press(KEY_DOWN)
	await press(KEY_DOWN)
	await press(KEY_DOWN)
	check(root.gui_get_focus_owner() == pause_menu._exit_button, "Arrow selects Exit to Menu")
	await press(KEY_ENTER)
	await frames(10)
	check(current_scene.scene_file_path == MENU and not paused, "Exit to Menu leaves the old level and clears pause")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Main menu retains the cursor")
	await press(KEY_ENTER)
	await frames(10)
	check(current_scene.scene_file_path == FACTORY and not paused, "A fresh level starts normally after exiting pause")
	change_scene_to_file(CITY)
	await scene_changed
	await frames(5)
	await press(KEY_ESCAPE)
	check(paused and current_scene._pause_menu.visible, "District 04 also has the pause menu")
	await click(current_scene._pause_menu._exit_button.get_global_rect().get_center())
	Input.action_release("primary")
	await frames(10)
	check(current_scene.scene_file_path == MENU and not paused, "Mouse Exit to Menu works too")
	print("Pause menu failures: ", failures)
	quit(1 if failures else 0)
