@tool
extends StaticBody3D
@export var fallen_scene: PackedScene
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
	_art = $Art
	_zone = $KnockOver
	set_physics_process(false)
	if Engine.is_editor_hint(): return
	add_to_group("johns")
	_zone.body_entered.connect(_on_bump_entered)
	_zone.body_exited.connect(_on_bump_exited)

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
	_fallen = fallen_scene.instantiate()
	_fallen.name = name + "Fallen"
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
