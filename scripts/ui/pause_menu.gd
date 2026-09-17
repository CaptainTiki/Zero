extends CanvasLayer
## Only this overlay keeps processing while the SceneTree is paused.
const MENU := "res://scenes/ui/main_menu.tscn"
const GOLD := Color(1.0, 0.85, 0.3)
var _resume_button: Button
var _exit_button: Button
var _unstuck_button: Button
var _hint: Label
var _leaving := false
var _settings: VBoxContainer
var _buttons: VBoxContainer
var _controls_button: Button

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var back := ColorRect.new()
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.color = Color(0.02, 0.025, 0.03, 0.88)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	centre.add_child(column)
	column.add_child(_label("PAUSED", 48, GOLD))
	_resume_button = _button("RESUME", resume)
	_unstuck_button = _button("UNSTUCK", _unstuck)
	_exit_button = _button("EXIT TO MENU", _exit_to_menu)
	_controls_button = _button("CONTROLS", _show_settings)
	_buttons = VBoxContainer.new()
	column.add_child(_buttons)
	var buttons: Array[Button] = [_resume_button, _unstuck_button, _controls_button, _exit_button]
	for button in buttons:
		_buttons.add_child(button)
	for i in buttons.size():
		buttons[i].focus_neighbor_top = buttons[(i - 1 + buttons.size()) % buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()
	_settings = preload("res://scripts/ui/controller_settings.gd").new()
	_settings.visible = false
	column.add_child(_settings)
	_settings.closed.connect(func() -> void:
		_buttons.visible = true
		_controls_button.grab_focus())
	_hint = _label("Esc to resume   ·   Arrows / Enter or mouse to choose", 15, Color(0.65, 0.68, 0.7))
	column.add_child(_hint)
	get_node("/root/InputBootstrap").device_changed.connect(_refresh_controls)
	_refresh_controls()

func _refresh_controls() -> void:
	var inputs := get_node("/root/InputBootstrap")
	_hint.text = inputs.menu_hint() if inputs.using_controller else "Esc to resume   ·   Arrows / Enter or mouse to choose"

func open() -> void:
	if visible or _leaving:
		return
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume_button.grab_focus()

func resume() -> void:
	if not visible or _leaving or _settings.visible:
		return
	# The click or F press used to resume must not also fire a shot or kick.
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("release_menu_input"):
		player.release_menu_input()
	visible = false
	_resume_button.release_focus()
	_unstuck_button.release_focus()
	_exit_button.release_focus()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	get_node("/root/InputBootstrap").note_input(event)
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		if _settings.visible:
			_settings.close.call_deferred()
		else:
			resume.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _leaving or _settings.visible:
		return
	if event.is_action_pressed("kick") or event.is_action_pressed("primary"):
		var focused := get_viewport().gui_get_focus_owner() as BaseButton
		if focused == _resume_button or focused == _unstuck_button or focused == _exit_button or focused == _controls_button:
			get_viewport().set_input_as_handled()
			focused.pressed.emit()

func _show_settings() -> void:
	_buttons.visible = false
	_settings.open()

func _unstuck() -> void:
	if _leaving:
		return
	var level := get_parent()
	if level.has_method("unstuck_player") and level.unstuck_player():
		resume()

func _exit_to_menu() -> void:
	if _leaving:
		return
	_leaving = true
	_load_menu.call_deferred()

func _load_menu() -> void:
	var level := get_parent()
	if level.has_method("save_quit_report") and not level.save_quit_report():
		_leaving = false
		_hint.text = "Report could not be saved. Resume or try Exit to Menu again."
		return
	# Keep the old world paused through teardown. The menu unpauses in _ready.
	var error := get_tree().change_scene_to_file(MENU)
	if error != OK:
		_leaving = false
		_hint.text = "Could not open the menu. You can resume or try again."
		push_error("Could not open the menu: %s" % error_string(error))

func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.custom_minimum_size = Vector2(460, 52)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_focus_color", GOLD)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.mouse_entered.connect(button.grab_focus)
	button.pressed.connect(callback)
	return button
