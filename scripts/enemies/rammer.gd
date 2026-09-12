extends CharacterBody3D
class_name AlienRammer

@export var max_hp := 180.0
@export var move_speed := 4.5
@export var charge_speed := 12.0
@export var aggro_range := 24.0
@export var windup_time := 0.7
@export var charge_time := 0.55
@export var recover_time := 0.9
@export var body_gun_mult := 0.15
@export var weak_gun_mult := 1.35
@export var melee_mult := 1.0

enum State { IDLE, CHASE, WINDUP, CHARGE, RECOVER }
var _state: State = State.IDLE
var _kick_stagger := 0.0
var _kick_velocity := Vector3.ZERO
var _hp := 0.0
var _timer := 0.0
var _charge_dir := Vector3.ZERO
var _player: Node3D
var _weak_open := false
var _body: Node

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemies")
	add_to_group("elites")
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
	if _body:
		_body.set_weak_open(_weak_open)
	_animate(delta, 1.0 if _state == State.CHARGE else (-0.4 if _state == State.WINDUP else 0.0))
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	match _state:
		State.IDLE:
			_weak_open = false
			if dist <= aggro_range:
				_state = State.CHASE
		State.CHASE:
			_weak_open = false
			if dist < 8.0:
				_state = State.WINDUP
				_timer = windup_time
				_charge_dir = to_player.normalized()
			else:
				var dir := to_player.normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				look_at(global_position + dir, Vector3.UP)
		State.WINDUP:
			_weak_open = true
			velocity = Vector3.ZERO
			_timer -= delta
			if _timer <= 0.0:
				_state = State.CHARGE
				_timer = charge_time
		State.CHARGE:
			_weak_open = true
			velocity.x = _charge_dir.x * charge_speed
			velocity.z = _charge_dir.z * charge_speed
			_timer -= delta
			if _timer <= 0.0:
				_state = State.RECOVER
				_timer = recover_time
		State.RECOVER:
			_weak_open = true
			velocity = Vector3.ZERO
			_timer -= delta
			if _timer <= 0.0:
				_state = State.CHASE
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
	var mult := weak_gun_mult if _weak_open else body_gun_mult
	_hp -= amount * mult
	if _hp <= 0.0:
		_die()

func apply_melee_hit(amount: float, _from: Vector3) -> void:
	_hit_fx()
	_hp -= amount * melee_mult
	if _hp <= 0.0:
		_die()

func apply_kick(amount: float, from: Vector3, force: float) -> void:
	var direction := global_position - from
	direction.y = 0.0
	_kick_velocity = direction.normalized() * force
	_kick_stagger = 0.4
	_kick_velocity *= 0.45
	_state = State.RECOVER
	_timer = recover_time
	take_damage(amount)

func apply_shot(amount: float, _from: Vector3, _push: float) -> void:
	# Too heavy to shove; weak-point multipliers still apply.
	take_damage(amount)
