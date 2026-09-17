extends Control
## The front of the game: START, which has focus so fire or kick begins the run, and CHOOSE
## LEVEL, which opens a list of everything built. The arrow keys move between entries and the
## mouse works the same way round: hovering takes focus, so the pointer and the keys can never
## disagree about what fire would pick. Built in code, like the rest of the art.

const LEVELS := preload("res://scripts/levels/level_list.gd")
## Fire and kick pick whatever has focus. ui_accept (Enter) is handled by the button itself.
const PICK_ACTIONS := ["primary", "kick"]
const GOLD := Color(1.0, 0.85, 0.3)
const INK := Color(0.82, 0.84, 0.86)
const DIM := Color(0.55, 0.58, 0.6)

var _root_menu: VBoxContainer
var _level_menu: VBoxContainer
var _hint: Label
var _opening := false
var _settings: VBoxContainer

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var sound := get_node_or_null("/root/Sound")
	if sound:
		sound.stop_ambience()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.color = Color(0.05, 0.06, 0.07)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var centre := CenterContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	centre.add_child(column)
	column.add_child(_text("SUPER ZERO", 64, GOLD))
	var version := String(ProjectSettings.get_setting("application/config/version", ""))
	column.add_child(_text("DEFENDERS OF EARTH   ·   %s" % version, 16, DIM))
	column.add_child(_gap(28))

	_root_menu = VBoxContainer.new()
	_root_menu.add_theme_constant_override("separation", 4)
	column.add_child(_root_menu)
	_root_menu.add_child(_button("START", _on_start))
	_root_menu.add_child(_button("CHOOSE LEVEL", _show_levels))
	_root_menu.add_child(_button("CONTROLS", _show_settings))
	_root_menu.add_child(_button("QUIT", func() -> void: get_tree().quit()))

	_level_menu = VBoxContainer.new()
	_level_menu.add_theme_constant_override("separation", 4)
	_level_menu.visible = false
	column.add_child(_level_menu)
	for entry in LEVELS.LEVELS:
		var path := String(entry["path"])
		_level_menu.add_child(_button(String(entry["name"]), func() -> void: _open(path)))
		_level_menu.add_child(_text(String(entry["note"]), 14, DIM))
	_level_menu.add_child(_gap(10))
	_level_menu.add_child(_button("BACK", _show_root))

	_settings = preload("res://scripts/ui/controller_settings.gd").new()
	_settings.visible = false
	column.add_child(_settings)
	_settings.closed.connect(_show_root)
	column.add_child(_gap(28))
	_hint = _text("Arrows to move   ·   Enter or F to choose\nClick to choose   ·   Esc to go back", 15, DIM)
	column.add_child(_hint)
	var inputs := get_node("/root/InputBootstrap")
	inputs.device_changed.connect(_refresh_controls)
	_refresh_controls()
	_show_root.call_deferred()

## Fire or kick presses whatever has focus, wherever the pointer happens to be. Escape backs out
## of the level list.
func _unhandled_input(event: InputEvent) -> void:
	if _opening:
		return
	if _settings.visible:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_settings.close()
		return
	if _level_menu.visible and event.is_action_pressed("ui_cancel"):
		_show_root()
		get_viewport().set_input_as_handled()
		return
	for action in PICK_ACTIONS:
		if not InputMap.has_action(action) or not event.is_action_pressed(action):
			continue
		var focused := get_viewport().gui_get_focus_owner()
		if focused is BaseButton:
			(focused as BaseButton).pressed.emit()
			get_viewport().set_input_as_handled()
		return

func _refresh_controls() -> void:
	_hint.text = get_node("/root/InputBootstrap").menu_hint()

func _on_start() -> void:
	_open(LEVELS.first_path())

func _open(path: String) -> void:
	if _opening:
		return
	_opening = true
	# Leave the input callback before replacing the controls that received it.
	_open_level.call_deferred(path)

func _open_level(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		_opening = false
		_hint.text = "Could not open the level. Choose again."
		push_error("Could not open %s: %s" % [path, error_string(error)])

func _show_settings() -> void:
	_root_menu.visible = false
	_level_menu.visible = false
	_settings.open()

func _show_root() -> void:
	_root_menu.visible = true
	_level_menu.visible = false
	_focus_first(_root_menu)

func _show_levels() -> void:
	_root_menu.visible = false
	_level_menu.visible = true
	_focus_first(_level_menu)

func _focus_first(menu: VBoxContainer) -> void:
	var buttons: Array[BaseButton] = []
	for child in menu.get_children():
		if child is BaseButton:
			buttons.append(child)
	if buttons.is_empty():
		return
	# Wrap top to bottom, so holding an arrow key never dead-ends.
	for i in buttons.size():
		buttons[i].focus_neighbor_top = buttons[(i - 1 + buttons.size()) % buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()
	buttons[0].grab_focus()

# --- pieces -----------------------------------------------------------------

func _text(content: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = content
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label

func _gap(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

## A menu line. The focused one is marked with an arrowhead and turns gold, which reads on any
## background and needs no theme.
func _button(label: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(460, 0)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_focus_color", GOLD)
	button.add_theme_color_override("font_hover_color", GOLD)
	var face := func(focused: bool) -> void:
		button.text = ("▸  %s" % label) if focused else ("     %s" % label)
	face.call(false)
	button.focus_entered.connect(func() -> void: face.call(true))
	button.focus_exited.connect(func() -> void: face.call(false))
	button.mouse_entered.connect(button.grab_focus)
	button.pressed.connect(on_pressed)
	return button
