@tool
extends StaticBody3D
## A console with a big red button on top, kicked to set something off: the smog machine's
## ACTIVATE button. Kicks only; shots don't press it. Until it's armed a kick just thunks,
## and once armed its lamp blinks until someone kicks it.

signal pressed

## The console's footprint and height. Its front, where the button sits, faces local +z.
@export var size := Vector3(1.4, 1.6, 0.8)

var armed := false
var is_pressed := false
var _cap: MeshInstance3D
var _lamp: MeshInstance3D
var _blink := 0.0

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y / 2.0
	add_child(shape)
	var body := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = size
	body.mesh = slab
	body.material_override = load("res://materials/retro/metal_blue.tres")
	body.position.y = size.y / 2.0
	add_child(body)
	var stripe := MeshInstance3D.new()
	var band := BoxMesh.new()
	band.size = Vector3(size.x + 0.04, 0.2, size.z + 0.04)
	stripe.mesh = band
	stripe.material_override = load("res://materials/retro/hazard.tres")
	stripe.position.y = size.y * 0.35
	add_child(stripe)
	_cap = MeshInstance3D.new()
	var dome := CylinderMesh.new()
	dome.top_radius = 0.34
	dome.bottom_radius = 0.4
	dome.height = 0.22
	_cap.mesh = dome
	_cap.material_override = _glow(Color(0.85, 0.08, 0.06), 0.6)
	_cap.position = Vector3(0, size.y + 0.11, size.z * 0.12)
	add_child(_cap)
	_lamp = MeshInstance3D.new()
	var bulb := BoxMesh.new()
	bulb.size = Vector3(0.3, 0.2, 0.2)
	_lamp.mesh = bulb
	_lamp.material_override = _glow(Color(0.15, 0.15, 0.12), 0.0)
	_lamp.position = Vector3(size.x * 0.32, size.y + 0.1, -size.z * 0.25)
	add_child(_lamp)

func _process(delta: float) -> void:
	if not armed or is_pressed or Engine.is_editor_hint():
		return
	_blink += delta
	var on := fmod(_blink, 0.8) < 0.4
	_lamp.material_override = _glow(Color(0.2, 1.0, 0.35), 3.0) if on else _glow(Color(0.1, 0.3, 0.12), 0.3)

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
	_lamp.material_override = _glow(Color(1.0, 0.2, 0.1), 3.0)
	var push := create_tween()
	push.tween_property(_cap, "position:y", size.y + 0.02, 0.08)
	if bank:
		bank.play_at("button_press", global_position)
	pressed.emit()

func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = energy > 0.0
	m.emission = color
	m.emission_energy_multiplier = energy
	return m
