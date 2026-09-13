extends CharacterBody3D
class_name AlienHunter

## Committed movement bursts separated by readable shooting windows.
@export var max_hp := 45.0
@export var move_speed := 6.5
@export var strafe_speed := 6.0
@export var aggro_range := 30.0
@export var attack_range := 1.8
@export var attack_damage := 12.0
@export var attack_cooldown := 0.7
@export var burst_duration := 0.45
@export var pause_duration := 0.65
@export var shot_range := 32.0
@export var shot_cooldown := 1.4
@export var shot_speed := 13.0
const SHOT := preload("res://scripts/enemies/hunter_shot.gd")
var _shot_timer := 0.0
var _shots_fired := 0

var _kick_stagger := 0.0
var _kick_velocity := Vector3.ZERO
var _hp := 0.0
var _attack_timer := 0.0
var _phase_timer := 0.45
var _bursting := false
var _burst_velocity := Vector3.ZERO
var _strafe_sign := 1.0
var _player: Node3D
var _body: Node

var _voice_timer := randf_range(2.0, 6.0)
var _sound: Node

func _voice(event: String, offset := 0.0) -> void:
	if _sound == null:
		_sound = get_tree().root.get_node_or_null("Sound")
	if _sound:
		_sound.play_at(event, global_position + Vector3(0, 1.0, 0), offset)

func _idle_voice(delta: float, event: String, near_player: bool) -> void:
	_voice_timer -= delta
	if _voice_timer <= 0.0:
		_voice_timer = randf_range(3.0, 7.0)
		if near_player:
			_voice(event)
var _stun := 0.0

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemies")
	add_to_group("elites")
	_body = get_node_or_null("Body")
	_strafe_sign = 1.0 if randf() > 0.5 else -1.0

func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_shot_timer = maxf(0.0, _shot_timer - delta)
	if _stun > 0.0:
		_stun = maxf(0.0, _stun - delta)
		_end_burst()
		_move_with_gravity(delta)
		_animate(delta, -0.9)
		return
	_animate(delta, 0.8 if _bursting else (-0.5 if _kick_stagger > 0.0 else 0.0))
	if _kick_stagger > 0.0:
		_kick_stagger = maxf(0.0, _kick_stagger - delta)
		velocity.x = _kick_velocity.x
		velocity.z = _kick_velocity.z
		_move_with_gravity(delta)
		_kick_velocity = _kick_velocity.move_toward(Vector3.ZERO, 24.0 * delta)
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	velocity.x = 0.0
	velocity.z = 0.0
	if _player == null:
		_move_with_gravity(delta)
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	_idle_voice(delta, "hunter_idle", dist < 30.0)
	if not _update_alert(dist):
		_end_burst()
		_move_with_gravity(delta)
		return
	var forward := to_player.normalized() if dist > 0.01 else Vector3.FORWARD
	look_at(global_position + forward, Vector3.UP)
	_phase_timer = maxf(0.0, _phase_timer - delta)
	if dist <= attack_range:
		if _bursting:
			_end_burst()
		if _attack_timer <= 0.0 and _player.has_method("take_damage") and _can_reach_player():
			_attack_timer = attack_cooldown
			_player.take_damage(attack_damage)
	elif _phase_timer <= 0.0:
		if _bursting:
			_end_burst()
		else:
			_start_burst(forward, dist)
	# Standing in the shooting window: one shot per pause, if the player is in view.
	if not _bursting and dist > attack_range and dist <= shot_range and _shot_timer <= 0.0 and _can_see_player():
		_fire(forward)
	if _bursting:
		velocity.x = _burst_velocity.x
		velocity.z = _burst_velocity.z
	_move_with_gravity(delta)
	if _bursting and is_on_wall():
		_end_burst()

func _fire(forward: Vector3) -> void:
	_shot_timer = shot_cooldown
	_shots_fired += 1
	var shot := Area3D.new()
	shot.set_script(SHOT)
	shot.set("speed", shot_speed)
	get_parent().add_child(shot)
	var muzzle := global_position + Vector3(0, 2.3, 0) + forward * 0.6
	var aim := (_player.global_position + Vector3(0, 0.9, 0)) - muzzle
	shot.launch(muzzle, aim)
	if _body:
		_body.flinch(0.35)
	_voice("hunter_burst", -2.0)

func _start_burst(forward: Vector3, distance: float) -> void:
	var side := Vector3(-forward.z, 0.0, forward.x) * _strafe_sign
	var lateral_weight := 0.35 if distance > 5.0 else 0.65
	var speed := move_speed if distance > 5.0 else strafe_speed
	_burst_velocity = (forward + side * lateral_weight).normalized() * speed
	_strafe_sign *= -1.0
	_bursting = true
	if randf() < 0.5:
		_voice("hunter_burst")
	_phase_timer = burst_duration

func _end_burst() -> void:
	_bursting = false
	_burst_velocity = Vector3.ZERO
	_phase_timer = pause_duration
	velocity.x = 0.0
	velocity.z = 0.0

func _move_with_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _hit_fx() -> void:
	if _body:
		_body.flash()
	if randf() < 0.6:
		_voice("hunter_hurt")

func _die() -> void:
	get_tree().call_group("run_stats", "record_kill")
	_voice("hunter_death")
	_voice("gib")
	if _body:
		_body.burst(get_parent(), global_basis.z)
	queue_free()

func _animate(delta: float, lean: float = 0.0) -> void:
	if _body:
		_body.animate(delta, Vector2(velocity.x, velocity.z).length(), lean)

func take_damage(amount: float, weak := false) -> void:
	_hit_fx()
	if _body:
		_body.flinch(1.0 if weak else 0.4)
	if weak:
		amount *= 1.6
		_stun = maxf(_stun, 0.45)
		_end_burst()
	_hp -= amount
	if _hp <= 0.0:
		_die()

## Head crest from any side, or the exposed back joint from behind.
func is_weak_hit(point: Vector3) -> bool:
	var local := to_local(point)
	if local.y > 2.45:
		return true
	return local.z > 0.12 and local.y > 1.9 and local.y < 2.4

func apply_melee_hit(amount: float, from: Vector3) -> void:
	var push := global_position - from
	push.y = 0.0
	if push.length() > 0.01:
		velocity += push.normalized() * 8.0
	take_damage(amount)

func apply_kick(amount: float, from: Vector3, force: float) -> void:
	var direction := global_position - from
	direction.y = 0.0
	_kick_velocity = direction.normalized() * force
	_kick_stagger = 0.4
	_end_burst()
	take_damage(amount)

func apply_shot(amount: float, from: Vector3, push: float, weak := false) -> void:
	# Shotgun pellets shove light enemies without the full kick stagger.
	var direction := global_position - from
	direction.y = 0.0
	if direction.length() > 0.01 and push > 0.0:
		_kick_velocity = direction.normalized() * push
		_kick_stagger = maxf(_kick_stagger, 0.12)
	take_damage(amount, weak)

## Line-of-sight activation: near range always alerts; up to `sight_range` alerts
## only with a clear view. Once alerted the enemy stays on the player until the
## player is well beyond sight range.
@export var sight_range := 60.0
var _alerted := false

func _update_alert(dist: float) -> bool:
	if _alerted:
		if dist > sight_range * 1.3:
			_alerted = false
		return _alerted
	if dist <= aggro_range or (dist <= sight_range and _can_see_player()):
		_alerted = true
		_voice("hunter_burst")
	return _alerted

func _can_see_player() -> bool:
	if _player == null:
		return false
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.2, 0), _player.global_position + Vector3(0, 1.0, 0), 1, [get_rid()])
	return space.intersect_ray(query).is_empty()

## Melee only lands on the same level with nothing in between: no biting
## through floors, ceilings, or fire-escape decks.
func _can_reach_player() -> bool:
	if _player == null:
		return false
	if absf(_player.global_position.y - global_position.y) > 1.4:
		return false
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.9, 0), _player.global_position + Vector3(0, 0.9, 0), 1, [get_rid()])
	return space.intersect_ray(query).is_empty()
