extends Node

func _ready() -> void:
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("move_forward", KEY_W)
	_bind_key("move_back", KEY_S)
	_bind_key("jump", KEY_SPACE)
	_bind_key("sprint", KEY_SHIFT)
	_bind_key("interact", KEY_E)
	_bind_key("weapon_fists", KEY_1)
	_bind_key("weapon_pistol", KEY_2)
	_bind_mouse("primary", MOUSE_BUTTON_LEFT)
	_bind_mouse("ads", MOUSE_BUTTON_RIGHT)

func _bind_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	# clear old events so we don't stack on reload
	for e in InputMap.action_get_events(action):
		InputMap.action_erase_event(action, e)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

func _bind_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		InputMap.action_erase_event(action, e)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
