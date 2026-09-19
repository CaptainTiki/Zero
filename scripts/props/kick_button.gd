@tool
extends StaticBody3D
@export var armed_on: Material
@export var armed_off: Material
@export var pressed_material: Material
## A console with a big red button on top, kicked to set something off: the smog machine's
## ACTIVATE button. Kicks only; shots don't press it. Until it's armed a kick just thunks,
## and once armed its lamp blinks until someone kicks it.

signal pressed

## The console's footprint and height. Its front, where the button sits, faces local +z.
var _cap_rest_y := 0.0

var armed := false
var is_pressed := false
var _cap: MeshInstance3D
var _lamp: MeshInstance3D
var _blink := 0.0

func _ready() -> void:
	_cap = $ButtonCap
	_lamp = $Indicator
	_cap_rest_y = _cap.position.y

func _process(delta: float) -> void:
	if not armed or is_pressed or Engine.is_editor_hint():
		return
	_blink += delta
	var on := fmod(_blink, 0.8) < 0.4
	_lamp.material_override = armed_on if on else armed_off

func arm() -> void:
	armed = true

func apply_kick(_damage: float, _from: Vector3, _force: float) -> void:
	if is_pressed:
		return
	var bank := get_tree().root.get_node_or_null("Sound")
	if not armed:
		if bank:
			bank.play_at("kick_prop", global_position, -6.0)
		return
	is_pressed = true
	_lamp.material_override = pressed_material
	var push := create_tween()
	push.tween_property(_cap, "position:y", _cap_rest_y - 0.09, 0.08)
	if bank:
		bank.play_at("button_press", global_position)
	pressed.emit()
