extends CharacterBody3D
class_name AlienFodder

@export var max_hp := 40.0
@export var move_speed := 3.0
@export var aggro_range := 18.0
@export var attack_range := 1.6
@export var attack_damage := 8.0
@export var attack_cooldown := 1.0

var _kick_stagger := 0.0
var _kick_velocity := Vector3.ZERO
var _hp := 0.0
var _attack_timer := 0.0
var _player: Node3D
var _body: Node

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemies")
	_body = get_node_or_null("Body")

func _physics_process(delta: float) -> void:
	if _kick_stagger > 0.0:
		_kick_stagger = maxf(0.0, _kick_stagger - delta)
		velocity.x = _kick_velocity.x
		velocity.z = _kick_velocity.z
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
		move_and_slide()
		_kick_velocity = _kick_velocity.move_toward(Vector3.ZERO, 24.0 * delta)
		_animate(delta, -0.6)
		return
	_animate(delta)
	_attack_timer = maxf(0.0, _attack_timer - delta)
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist > aggro_range:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if dist > attack_range:
		var dir := to_player.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			if _player.has_method("take_damage"):
				_player.take_damage(attack_damage)
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _hit_fx() -> void:
	if _body:
		_body.flash()

func _die() -> void:
	if _body:
		_body.burst(get_parent(), global_basis.z)
	queue_free()

func _animate(delta: float, lean: float = 0.0) -> void:
	if _body:
		_body.animate(delta, Vector2(velocity.x, velocity.z).length(), lean)

func take_damage(amount: float) -> void:
	_hit_fx()
	_hp -= amount
	if _hp <= 0.0:
		_die()

func apply_melee_hit(amount: float, from: Vector3) -> void:
	var push := global_position - from
	push.y = 0.0
	if push.length() > 0.01:
		velocity += push.normalized() * 6.0
	take_damage(amount)

func apply_kick(amount: float, from: Vector3, force: float) -> void:
	var direction := global_position - from
	direction.y = 0.0
	_kick_velocity = direction.normalized() * force
	_kick_stagger = 0.4
	take_damage(amount)

func apply_shot(amount: float, from: Vector3, push: float) -> void:
	# Shotgun pellets shove light enemies without the full kick stagger.
	var direction := global_position - from
	direction.y = 0.0
	if direction.length() > 0.01 and push > 0.0:
		_kick_velocity = direction.normalized() * push
		_kick_stagger = maxf(_kick_stagger, 0.12)
	take_damage(amount)
