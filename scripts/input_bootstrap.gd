extends Node
## One shared action map for gameplay and menus. Register defaults without erasing bindings.
signal device_changed
signal controller_lost
var using_controller := false
var controller_device := -1
var look_sensitivity := 180.0
var look_deadzone := 0.18
var invert_y := false
const SETTINGS_PATH := "user://controls.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for pair in [["move_left", KEY_A], ["move_right", KEY_D], ["move_forward", KEY_W], ["move_back", KEY_S], ["jump", KEY_SPACE], ["sprint", KEY_SHIFT], ["interact", KEY_E], ["kick", KEY_F], ["weapon_fists", KEY_1], ["weapon_pistol", KEY_2], ["weapon_shotgun", KEY_3], ["debug_toggle", KEY_QUOTELEFT]]:
		_bind_key(pair[0], pair[1])
	_bind_key("pause", KEY_ESCAPE)
	_bind_button("pause", JOY_BUTTON_START)
	_bind_key("hud_toggle", KEY_QUOTELEFT, true)
	_bind_mouse("primary", MOUSE_BUTTON_LEFT)
	_bind_mouse("ads", MOUSE_BUTTON_RIGHT)
	_bind_mouse("weapon_next", MOUSE_BUTTON_WHEEL_UP)
	_bind_mouse("weapon_previous", MOUSE_BUTTON_WHEEL_DOWN)
	for pair in [["jump", JOY_BUTTON_A], ["sprint", JOY_BUTTON_LEFT_STICK], ["interact", JOY_BUTTON_X], ["kick", JOY_BUTTON_RIGHT_STICK], ["weapon_next", JOY_BUTTON_RIGHT_SHOULDER], ["weapon_previous", JOY_BUTTON_LEFT_SHOULDER], ["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B], ["ui_cancel", JOY_BUTTON_START], ["ui_up", JOY_BUTTON_DPAD_UP], ["ui_down", JOY_BUTTON_DPAD_DOWN], ["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT]]:
		_bind_button(pair[0], pair[1])
	for spec in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0], ["move_forward", JOY_AXIS_LEFT_Y, -1.0], ["move_back", JOY_AXIS_LEFT_Y, 1.0], ["look_left", JOY_AXIS_RIGHT_X, -1.0], ["look_right", JOY_AXIS_RIGHT_X, 1.0], ["look_up", JOY_AXIS_RIGHT_Y, -1.0], ["look_down", JOY_AXIS_RIGHT_Y, 1.0], ["primary", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["ads", JOY_AXIS_TRIGGER_LEFT, 1.0], ["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0], ["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0]]:
		_bind_axis(spec[0], spec[1], spec[2])
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		InputMap.action_set_deadzone(action, 0.2)
	for action in ["primary", "ads"]:
		InputMap.action_set_deadzone(action, 0.3)
	for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		InputMap.action_set_deadzone(action, 0.5)
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		look_sensitivity = clampf(float(config.get_value("controller", "sensitivity", 180.0)), 60.0, 360.0)
		look_deadzone = clampf(float(config.get_value("controller", "deadzone", 0.18)), 0.05, 0.4)
		invert_y = bool(config.get_value("controller", "invert_y", false))
	Input.joy_connection_changed.connect(_connection_changed)

func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("controller", "sensitivity", look_sensitivity)
	config.set_value("controller", "deadzone", look_deadzone)
	config.set_value("controller", "invert_y", invert_y)
	return config.save(SETTINGS_PATH)

func _input(event: InputEvent) -> void:
	note_input(event)

func note_input(event: InputEvent) -> void:
	var pad: bool = event is InputEventJoypadButton and event.pressed
	if event is InputEventJoypadMotion:
		pad = event.axis_value > 0.3 if event.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT] else absf(event.axis_value) > maxf(0.25, look_deadzone)
	var keyboard_mouse: bool = (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed()
	keyboard_mouse = keyboard_mouse or (event is InputEventMouseMotion and event.relative.length() > 2.0)
	if pad and (not using_controller or controller_device != event.device):
		using_controller = true
		controller_device = event.device
		device_changed.emit()
	elif keyboard_mouse and using_controller:
		using_controller = false
		device_changed.emit()

func _connection_changed(device: int, connected: bool) -> void:
	if not connected and using_controller and device == controller_device:
		using_controller = false
		controller_device = -1
		device_changed.emit()
		controller_lost.emit()

func button_label(action: String) -> String:
	if not using_controller:
		return {"ui_accept": "Enter", "ui_cancel": "Esc", "kick": "F"}.get(action, action)
	var playstation := Input.get_joy_name(controller_device).to_lower()
	var sony := "playstation" in playstation or "dual" in playstation or "ps4" in playstation or "ps5" in playstation
	return {"ui_accept": "Cross" if sony else "A", "ui_cancel": "Circle / Options" if sony else "B / Start", "kick": "R3" if sony else "RS"}.get(action, action)

func menu_hint() -> String:
	return "D-pad / left stick to move   ·   %s select   ·   %s back" % [button_label("ui_accept"), button_label("ui_cancel")] if using_controller else "Arrows to move   ·   Enter or F to choose\nClick to choose   ·   Esc to go back"

func gameplay_hint() -> String:
	if using_controller:
		return "LS move · RS aim · RT/R2 fire · LT/L2 aim · %s jump · %s click kick\nLB/RB (L1/R1) weapons · X/Square interact · LS/L3 hold sprint · Start/Options pause" % [button_label("ui_accept"), button_label("kick")]
	return "1 fists · 2 pistol · 3 shotgun · LMB use · RMB ADS · F kick · E throw · Esc pause · ` debug · ~ hud"

func _add(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _bind_key(action: String, keycode: Key, shift := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.shift_pressed = shift
	_add(action, event)

func _bind_mouse(action: String, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	_add(action, event)

func _bind_button(action: String, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	_add(action, event)

func _bind_axis(action: String, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = value
	_add(action, event)
