extends VBoxContainer
signal closed
var _focus: Control
var _status: Label

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var inputs := get_node("/root/InputBootstrap")
	var title := Label.new()
	title.text = "CONTROLLER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)
	_focus = _slider("Aim speed", 60.0, 360.0, 10.0, inputs.look_sensitivity, func(value: float) -> void: inputs.look_sensitivity = value)
	_slider("Stick deadzone", 0.05, 0.4, 0.01, inputs.look_deadzone, func(value: float) -> void: inputs.look_deadzone = value)
	var invert := CheckButton.new()
	invert.text = "Invert vertical aim"
	invert.button_pressed = inputs.invert_y
	invert.toggled.connect(func(value: bool) -> void: inputs.invert_y = value)
	add_child(invert)
	var back := Button.new()
	back.text = "BACK"
	back.pressed.connect(close)
	add_child(back)
	_status = Label.new()
	_status.text = "Left / right to adjust   ·   Back saves your settings"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status)

func open() -> void:
	visible = true
	_focus.grab_focus()

func close() -> void:
	var error: Error = get_node("/root/InputBootstrap").save_settings()
	if error != OK:
		_status.text = "Could not save settings. Try Back again."
		return
	visible = false
	closed.emit()

func _slider(title: String, minimum: float, maximum: float, step: float, initial: float, update: Callable) -> HSlider:
	var label := Label.new()
	label.text = "%s: %.2f" % [title, initial]
	add_child(label)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(460, 28)
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = initial
	slider.value_changed.connect(func(value: float) -> void:
		label.text = "%s: %.2f" % [title, value]
		update.call(value))
	add_child(slider)
	return slider
