extends CharacterBody3D
class_name AlienHunter

## Committed movement bursts separated by readable shooting windows.
@export var max_hp := 90.0
@export var move_speed := 6.5
@export var strafe_speed := 6.0
@export var aggro_range := 30.0
@export var attack_range := 1.8
@export var attack_damage := 12.0
@export var attack_cooldown := 0.7
@export var burst_duration := 0.45
@export var pause_duration := 0.65

var _kick_stagger := 0.0
var _kick_velocity := Vector3.ZERO
var _hp := 0.0
var _attack_timer := 0.0
var _phase_timer := 0.45
var _bursting := false
var _burst_velocity := Vector3.ZERO
var _strafe_sign := 1.0
var _player: Node3D
var _flash_left := 0.0
var _mat: StandardMaterial3D
var _base_color := Color(0.95, 0.45, 0.15, 1)

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemies")
	add_to_group("elites")
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = _base_color
		mesh.material_override = _mat
	_strafe_sign = 1.0 if randf() > 0.5 else -1.0

func _physics_process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(0.0, _flash_left - delta)
		if _mat and _flash_left <= 0.0:
			_mat.albedo_color = _base_color
	_attack_timer = maxf(0.0, _attack_timer - delta)
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
	if dist > aggro_range:
		_end_burst()
		_move_with_gravity(delta)
		return
	var forward := to_player.normalized() if dist > 0.01 else Vector3.FORWARD
	look_at(global_position + forward, Vector3.UP)
	_phase_timer = maxf(0.0, _phase_timer - delta)
	if dist <= attack_range:
		if _bursting:
			_end_burst()
		if _attack_timer <= 0.0 and _player.has_method("take_damage"):
			_attack_timer = attack_cooldown
			_player.take_damage(attack_damage)
	elif _phase_timer <= 0.0:
		if _bursting:
			_end_burst()
		else:
			_start_burst(forward, dist)
	if _bursting:
		velocity.x = _burst_velocity.x
		velocity.z = _burst_velocity.z
	_move_with_gravity(delta)
	if _bursting and is_on_wall():
		_end_burst()

func _start_burst(forward: Vector3, distance: float) -> void:
	var side := Vector3(-forward.z, 0.0, forward.x) * _strafe_sign
	var lateral_weight := 0.35 if distance > 5.0 else 0.65
	var speed := move_speed if distance > 5.0 else strafe_speed
	_burst_velocity = (forward + side * lateral_weight).normalized() * speed
	_strafe_sign *= -1.0
	_bursting = true
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
	_flash_left = 0.12
	if _mat:
		_mat.albedo_color = Color(1, 1, 1, 1)

func take_damage(amount: float) -> void:
	_hit_fx()
	_hp -= amount
	if _hp <= 0.0:
		queue_free()

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
