extends SceneTree
## Exercise real GUI input and load both playable scenes through the menu.
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

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await frames()

func click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion)
	await frames(1)
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
	await frames()

func menu() -> Node:
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await frames(5)
	return current_scene

func focus_is(label: String) -> bool:
	var focused := root.gui_get_focus_owner() as Button
	return focused != null and focused.text.contains(label)

func run() -> void:
	root.size = Vector2i(1152, 648)
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/main_menu.tscn", "F5 opens the menu")
	var screen: Node = await menu()
	check(focus_is("START"), "Start has initial keyboard focus")
	await key(KEY_UP)
	check(focus_is("QUIT"), "Up wraps to Quit")
	await key(KEY_DOWN)
	check(focus_is("START"), "Down wraps back to Start")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	check(screen._level_menu.visible and focus_is("THE FACTORY"), "Enter opens level selection")
	await key(KEY_UP)
	check(focus_is("BACK"), "Level selection wraps to Back")
	await key(KEY_ESCAPE)
	check(screen._root_menu.visible and focus_is("START"), "Escape returns to the main menu")
	await key(KEY_F)
	await frames(5)
	check(current_scene.scene_file_path == "res://scenes/levels/factory.tscn", "Kick starts the factory")
	check(get_first_node_in_group("player") != null, "Factory player loaded")
	screen = await menu()
	var choose: Button = screen._root_menu.get_child(1)
	await click(choose.get_global_rect().get_center())
	check(screen._level_menu.visible, "Mouse click opens level selection")
	var city: Button = screen._level_menu.get_child(2)
	await click(city.get_global_rect().get_center())
	await frames(5)
	check(current_scene.scene_file_path == "res://scenes/levels/l01_district04.tscn", "Mouse selects District 04")
	screen = await menu()
	var sound := root.get_node_or_null("Sound")
	check(sound == null or sound._ambience == null or not sound._ambience.playing, "Level ambience stops on returning to menu")
	await click(Vector2(10, 10))
	await frames(5)
	check(current_scene.scene_file_path == "res://scenes/levels/factory.tscn", "Fire outside buttons selects the focused Start entry")
	print("Main menu failures: ", failures)
	quit(1 if failures else 0)
