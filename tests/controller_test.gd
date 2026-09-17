extends SceneTree
var failures := 0
var inputs: Node
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1
func frames(n := 5) -> void:
	for i in n:
		await process_frame
func button(code: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frames()
func axis(code: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = code
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func run() -> void:
	root.size = Vector2i(1152, 648)
	inputs = root.get_node("InputBootstrap")
	print("Connected controllers: ", Input.get_connected_joypads())
	var old_speed: float = inputs.look_sensitivity
	var old_deadzone: float = inputs.look_deadzone
	var old_invert: bool = inputs.invert_y
	inputs.look_sensitivity = 180.0
	inputs.look_deadzone = 0.18
	inputs.invert_y = false
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await scene_changed
	await frames()
	axis(JOY_AXIS_LEFT_Y, 0.1)
	check(not inputs.using_controller, "Stick noise does not switch prompts")
	axis(JOY_AXIS_LEFT_Y, 0.0)
	await button(JOY_BUTTON_DPAD_DOWN)
	check(root.gui_get_focus_owner().text.contains("CHOOSE LEVEL"), "D-pad moves menu focus")
	check(inputs.using_controller and current_scene._hint.text.contains("D-pad"), "Controller events switch menu prompts")
	await button(JOY_BUTTON_A)
	check(current_scene._level_menu.visible, "South button opens level selection")
	await button(JOY_BUTTON_B)
	check(current_scene._root_menu.visible, "East button goes back")
	await button(JOY_BUTTON_A)
	await frames(10)
	check(current_scene.scene_file_path.ends_with("factory.tscn"), "Controller starts the factory")
	var level: Node = current_scene
	var player: Node = get_first_node_in_group("player")
	player.set_physics_process(false)
	axis(JOY_AXIS_LEFT_X, 0.6)
	var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	check(movement.x > 0.1 and movement.x < 0.9, "Left stick preserves partial movement strength")
	axis(JOY_AXIS_LEFT_X, 0.0)
	axis(JOY_AXIS_RIGHT_X, 0.1)
	var yaw: float = player._yaw
	player._update_controller_look(1.0)
	check(player._yaw == yaw, "Aim deadzone rejects stick drift")
	axis(JOY_AXIS_RIGHT_X, 1.0)
	if DisplayServer.get_name() != "headless":
		player._update_controller_look(0.5)
		var half: float = player._yaw - yaw
		player._yaw = yaw
		player._update_controller_look(0.25)
		player._update_controller_look(0.25)
		check(is_equal_approx(player._yaw - yaw, half) and half < 0.0, "Right-stick turning is frame-rate independent")
	axis(JOY_AXIS_RIGHT_X, 0.0)
	axis(JOY_AXIS_RIGHT_Y, 1.0)
	if DisplayServer.get_name() != "headless":
		player._pitch = 0.0
		player._update_controller_look(0.1)
		check(player._pitch < 0.0, "Normal vertical aim looks down on stick down")
		inputs.invert_y = true
		player._pitch = 0.0
		player._update_controller_look(0.1)
		check(player._pitch > 0.0, "Invert Y reverses vertical aim")
	axis(JOY_AXIS_RIGHT_Y, 0.0)
	axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	check(Input.is_action_pressed("primary"), "Right trigger uses shared fire action")
	axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	check(Input.is_action_pressed("ads"), "Left trigger uses shared aim action")
	axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await button(JOY_BUTTON_RIGHT_SHOULDER)
	check(player._weapon == player.Weapon.FISTS, "Weapon cycling cannot select locked weapons")
	player._has_gun = true
	player._has_shotgun = true
	await button(JOY_BUTTON_RIGHT_SHOULDER)
	check(player._weapon == player.Weapon.PISTOL, "Right shoulder selects the next owned weapon")
	await button(JOY_BUTTON_LEFT_SHOULDER)
	check(player._weapon == player.Weapon.FISTS, "Left shoulder selects the previous weapon")
	if DisplayServer.get_name() != "headless":
		player._set_weapon(player.Weapon.PISTOL)
		player.set_physics_process(true)
		await frames()
		var shots: int = level._shots.pistol
		axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
		await frames(10)
		check(level._shots.pistol == shots + 1, "Trigger fires exactly one pistol shot per press")
		axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
		await button(JOY_BUTTON_RIGHT_STICK)
		check(player._kick_timer > 0.0, "Right-stick click performs a gameplay kick")
		await button(JOY_BUTTON_A)
		check(player.velocity.y > 0.0, "South button jumps during gameplay")
	await button(JOY_BUTTON_B)
	check(not paused, "Menu Back does not pause live gameplay")
	await button(JOY_BUTTON_START)
	check(paused and level._pause_menu.visible, "Start pauses gameplay")
	await button(JOY_BUTTON_DPAD_DOWN)
	check(root.gui_get_focus_owner() == level._pause_menu._unstuck_button, "Controller can select Unstuck")
	await button(JOY_BUTTON_DPAD_DOWN)
	await button(JOY_BUTTON_A)
	check(level._pause_menu._settings.visible and paused, "Controller opens aim settings while paused")
	var slider := root.gui_get_focus_owner() as HSlider
	var before: float = slider.value
	await button(JOY_BUTTON_DPAD_RIGHT)
	check(slider.value > before, "D-pad adjusts controller settings")
	# Restore the user's values before Back persists settings.
	inputs.look_sensitivity = old_speed
	inputs.look_deadzone = old_deadzone
	inputs.invert_y = old_invert
	await button(JOY_BUTTON_B)
	check(not level._pause_menu._settings.visible and paused, "Back saves settings without resuming the game")
	await button(JOY_BUTTON_START)
	check(not paused, "Start resumes gameplay")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check(not inputs.using_controller and Input.is_action_pressed("move_forward"), "Keyboard works and switches prompts back")
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await button(JOY_BUTTON_RIGHT_STICK)
	inputs._connection_changed(0, false)
	check(paused and level._pause_menu.visible, "Losing the active controller pauses the run")
	level._pause_menu.resume()
	level._lift_open = true
	level.finish()
	await frames(10)
	await button(JOY_BUTTON_A)
	await frames(20)
	check(current_scene.scene_file_path.ends_with("l01_district04.tscn"), "South button continues from completion to District")
	current_scene.fail_run("YOU DIED")
	await frames()
	await button(JOY_BUTTON_B)
	await frames(20)
	check(current_scene.scene_file_path.ends_with("main_menu.tscn"), "East button returns to menu from a failed run")
	print("Controller failures: ", failures)
	quit(1 if failures else 0)
