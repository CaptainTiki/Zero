extends StaticBody3D
## A cardboard cutout of John: the aliens' idea of a human employee. Human
## shaped, goofy eyes, fixed smile, t-shirt and jeans, one hand waving forever.
## Anything flattens it. Kicking is the most satisfying way and costs no ammo.

const FX := preload("res://scripts/fx/impact_fx.gd")

@export var shirt: Color = Color("c8443a")
@export var card: Color = Color("cfa972")
@export var denim: Color = Color("3d5a80")

var _down := false
var _vel := Vector3.ZERO
var _spin := Vector3.ZERO
var _age := 0.0

func _ready() -> void:
	add_to_group("johns")
	_build()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.72, 1.9, 0.14)
	shape.shape = box
	shape.position = Vector3(0, 0.95, 0)
	add_child(shape)
	set_physics_process(false)

func _flat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	return m

func _card(label: String, size: Vector3, at: Vector3, color: Color, roll := 0.0) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _flat(color)
	mesh.mesh = box
	mesh.position = at
	mesh.rotation.z = roll
	mesh.name = label
	add_child(mesh)

## Flat panels only: this is a cutout, so everything is 0.05 thick.
func _build() -> void:
	_card("Foot", Vector3(0.34, 0.06, 0.26), Vector3(0, 0.03, 0.06), card)
	_card("Legs", Vector3(0.56, 0.74, 0.05), Vector3(0, 0.42, 0), denim)
	_card("LegGap", Vector3(0.06, 0.52, 0.06), Vector3(0, 0.32, 0), Color(0.12, 0.14, 0.2))
	_card("Shirt", Vector3(0.62, 0.68, 0.05), Vector3(0, 1.12, 0), shirt)
	_card("ArmDown", Vector3(0.14, 0.62, 0.05), Vector3(-0.37, 1.08, 0), card)
	# The waving hand, stuck mid-wave forever.
	_card("ArmUp", Vector3(0.14, 0.62, 0.05), Vector3(0.40, 1.40, 0), card, -0.85)
	_card("Hand", Vector3(0.17, 0.17, 0.05), Vector3(0.62, 1.66, 0), card)
	_card("Head", Vector3(0.44, 0.48, 0.05), Vector3(0, 1.64, 0), card)
	# Goofy eyes: different sizes, not quite level, pupils looking two ways.
	_card("EyeL", Vector3(0.15, 0.15, 0.06), Vector3(-0.10, 1.73, 0.01), Color("f4f1e6"))
	_card("EyeR", Vector3(0.12, 0.12, 0.06), Vector3(0.11, 1.70, 0.01), Color("f4f1e6"))
	_card("PupL", Vector3(0.05, 0.05, 0.07), Vector3(-0.07, 1.72, 0.02), Color("15161a"))
	_card("PupR", Vector3(0.05, 0.05, 0.07), Vector3(0.13, 1.71, 0.02), Color("15161a"))
	# Fixed smile, far too wide.
	_card("Smile", Vector3(0.26, 0.04, 0.06), Vector3(0, 1.53, 0.01), Color("15161a"))
	_card("SmileL", Vector3(0.09, 0.04, 0.06), Vector3(-0.15, 1.56, 0.01), Color("15161a"), 0.7)
	_card("SmileR", Vector3(0.09, 0.04, 0.06), Vector3(0.15, 1.56, 0.01), Color("15161a"), -0.7)
	# Name badge. Always John.
	_card("Badge", Vector3(0.17, 0.09, 0.06), Vector3(-0.17, 1.30, 0.01), Color("f4f1e6"))

func apply_kick(_damage: float, from: Vector3, force: float) -> void:
	_flatten(global_position - from, maxf(force, 6.0))

func take_damage(_amount: float, _weak := false) -> void:
	var away := global_basis.z
	_flatten(away, 4.0)

## Send it tumbling, burst some paper, count it, then clean up.
func _flatten(direction: Vector3, force: float) -> void:
	if _down:
		return
	_down = true
	var away := Vector3(direction.x, 0.0, direction.z)
	if away.length() < 0.01:
		away = Vector3.FORWARD
	away = away.normalized()
	_vel = away * (force * 0.45) + Vector3.UP * 3.2
	_spin = Vector3(away.z, randf_range(-6.0, 6.0), -away.x) * 7.0
	collision_layer = 0
	collision_mask = 0
	# Parent the burst to the level, not to this node, so it outlives the cutout.
	var world: Node = get_parent()
	if world == null:
		world = get_tree().current_scene
	if world:
		FX.puff(world, global_position + Vector3(0, 1.2, 0), Vector3.UP)
		FX.puff(world, global_position + Vector3(0, 0.7, 0), away)
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.play_at("john_flat", global_position, 0.0)
	get_tree().call_group("run_stats", "record_john")
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_age += delta
	_vel.y -= 16.0 * delta
	global_position += _vel * delta
	rotation += _spin * delta
	if _age > 1.4 or global_position.y < -8.0:
		queue_free()
