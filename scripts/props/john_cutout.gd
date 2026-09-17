@tool
extends StaticBody3D
## A cardboard cutout of John: the aliens' idea of a human employee. Human
## shaped, goofy eyes, fixed smile, t-shirt and jeans, one hand waving forever.
##
## Standing, it blocks nobody. It sits on the props layer, where only shots and
## kicks look for it, and its hitbox is deeper than the card so it's easy to hit
## edge-on. Anything that walks into it knocks it over. Going down hands the art
## to a real physics body, pushed from where it was hit, which comes to rest,
## lies around for a few seconds and then shrinks away. A John counts once it's
## down.

const FX := preload("res://scripts/fx/impact_fx.gd")
## Physics layer 3: shots and kicks look for it, nothing walks into it.
const PROP_LAYER := 4
## A falling John lands on the world (layer 1) and never blocks anyone. It leaves the
## player (layer 2) out, because a walking capsule doesn't scuff flat cardboard, it
## bulldozes it along the floor. Enemies share layer 1, so they can still shove one
## until it comes to rest and freezes.
const FALLEN_MASK := 1
const CARD_MASS := 1.5

## Shared by every John, so each colour is one material rather than one per card.
static var _materials := {}
static var _cardboard: PhysicsMaterial

@export var shirt: Color = Color("c8443a")
@export var card: Color = Color("cfa972")
@export var denim: Color = Color("3d5a80")
## Seconds a fallen John lies around before it shrinks away.
@export var debris_seconds := 8.0

var _art: Node3D
var _zone: Area3D
var _fallen: RigidBody3D
var _down := false
var _age := 0.0
## Bodies inside the knock-over zone, waiting to see if they're moving.
var _bumpers: Array[Node3D] = []

func _ready() -> void:
	_build()
	# A tool script so the editor shows the cutout; it does nothing else there.
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	add_to_group("johns")
	collision_layer = PROP_LAYER
	collision_mask = 0
	_hitbox(Vector3(0.9, 1.92, 0.45), Vector3(0, 0.96, 0))
	# The waving arm and hand stick out past the body.
	_hitbox(Vector3(0.42, 0.58, 0.45), Vector3(0.51, 1.47, 0))
	_zone = Area3D.new()
	_zone.name = "KnockOver"
	_zone.collision_layer = 0
	_zone.collision_mask = 3
	_zone.monitorable = false
	var reach := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.5, 0.3)
	reach.shape = box
	reach.position = Vector3(0, 0.75, 0)
	_zone.add_child(reach)
	add_child(_zone)
	_zone.body_entered.connect(_on_bump_entered)
	_zone.body_exited.connect(_on_bump_exited)
	set_physics_process(false)

func _hitbox(size: Vector3, at: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	add_child(shape)

static func _flat(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 1.0
		_materials[color] = m
	return _materials[color]

func _card(label: String, size: Vector3, at: Vector3, color: Color, roll := 0.0) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _flat(color)
	mesh.mesh = box
	mesh.position = at
	mesh.rotation.z = roll
	mesh.name = label
	_art.add_child(mesh)

## Flat panels only: this is a cutout, so everything is 0.05 thick.
func _build() -> void:
	_art = Node3D.new()
	_art.name = "Art"
	add_child(_art)
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
	# The boot lands a little below the player's eye line.
	var height := clampf(from.y + 1.35 - global_position.y, 0.3, 1.8)
	_topple(global_position + Vector3.UP * height, _away_from(from) * maxf(force, 6.0) * 0.5 + Vector3.UP * 1.5)

func apply_melee_hit(_amount: float, from: Vector3) -> void:
	var height := clampf(from.y + 1.4 - global_position.y, 0.3, 1.8)
	_topple(global_position + Vector3.UP * height, _away_from(from) * 3.0 + Vector3.UP * 0.8)

## A shot that says where it landed and which way it was going, so a John shot
## from behind falls away from the shooter and a shot on the arm spins it.
func apply_bullet(amount: float, point: Vector3, direction: Vector3) -> void:
	_topple(point, direction.normalized() * _shot_speed(amount) + Vector3.UP * 0.6)

## Damage that doesn't say where it came from pushes the John away from the player.
func take_damage(amount: float, _weak := false) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var from: Vector3 = player.global_position if player else global_position + global_basis.z
	_topple(global_position + Vector3.UP * 1.2, _away_from(from) * _shot_speed(amount))

func _shot_speed(amount: float) -> float:
	return clampf(amount * 0.12, 2.5, 6.0)

func _away_from(from: Vector3) -> Vector3:
	var away := global_position - from
	away.y = 0.0
	if away.length() < 0.01:
		return -global_basis.z
	return away.normalized()

func _on_bump_entered(body: Node) -> void:
	if body is Node3D and not _bumpers.has(body):
		_bumpers.append(body)
		set_physics_process(true)

func _on_bump_exited(body: Node) -> void:
	_bumpers.erase(body)

func _physics_process(delta: float) -> void:
	if not _down:
		_check_bumps()
		return
	_age += delta
	if is_instance_valid(_fallen) and not _fallen.freeze and _age > 0.5 and _fallen.sleeping:
		# At rest: stop simulating it, so nothing pushes it round the floor.
		_fallen.freeze = true
		_fallen.collision_mask = 0
	if _age >= debris_seconds:
		_clear_away()

## Something walking into a standing John knocks it over the way it was going.
## Something just standing there, like an enemy placed beside it, doesn't.
func _check_bumps() -> void:
	for body in _bumpers.duplicate():
		if not is_instance_valid(body):
			_bumpers.erase(body)
			continue
		var moving := Vector3.ZERO
		if body is CharacterBody3D:
			moving = body.get("velocity")
		elif body is RigidBody3D:
			moving = body.get("linear_velocity")
		moving.y = 0.0
		if moving.length() < 1.0:
			continue
		var push := (moving.normalized() * 0.6 + _away_from(body.global_position) * 0.4).normalized()
		_topple(global_position + Vector3.UP * 1.1, push * clampf(moving.length() * 0.6, 2.5, 6.0) + Vector3.UP * 1.0)
		return
	if _bumpers.is_empty():
		set_physics_process(false)

## Hand the art to a physics body, push it from the hit point, count it once.
func _topple(point: Vector3, push: Vector3) -> void:
	if _down:
		return
	_down = true
	_bumpers.clear()
	collision_layer = 0
	_zone.set_deferred("monitoring", false)
	# Parent the fallen John and the burst to the level, not to this node.
	var world: Node = get_parent()
	if world == null:
		world = get_tree().current_scene
	_fallen = RigidBody3D.new()
	_fallen.name = name + "Fallen"
	_fallen.collision_layer = 0
	_fallen.collision_mask = FALLEN_MASK
	_fallen.mass = CARD_MASS
	_fallen.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	_fallen.center_of_mass = Vector3(0, 0.95, 0)
	_fallen.continuous_cd = true
	_fallen.linear_damp = 0.4
	_fallen.angular_damp = 1.5
	if _cardboard == null:
		_cardboard = PhysicsMaterial.new()
		_cardboard.friction = 0.9
		_cardboard.bounce = 0.05
	_fallen.physics_material_override = _cardboard
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.62, 1.9, 0.08)
	shape.shape = box
	shape.position = Vector3(0, 0.95, 0)
	_fallen.add_child(shape)
	world.add_child(_fallen)
	_fallen.global_transform = global_transform
	_art.reparent(_fallen)
	_fallen.apply_impulse(push * CARD_MASS, point - _fallen.global_position)
	FX.puff(world, point, -push.normalized())
	FX.puff(world, global_position + Vector3(0, 0.7, 0), Vector3.UP)
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.play_at("john_flat", point, 0.0)
	get_tree().call_group("run_stats", "record_john")
	set_physics_process(true)

func _clear_away() -> void:
	set_physics_process(false)
	if is_instance_valid(_fallen):
		_fallen.freeze = true
		_fallen.collision_mask = 0
		var shrink := _fallen.create_tween()
		shrink.tween_property(_art, "scale", Vector3.ONE * 0.01, 0.35)
		shrink.tween_callback(_fallen.queue_free)
	queue_free()
