extends CharacterBody3D
class_name AlienHunter

## Fast pursue / flank elite. Repositions laterally when player aims or gets close.

@export var max_hp := 90.0
@export var move_speed := 7.5
@export var strafe_speed := 8.5
@export var aggro_range := 30.0
@export var attack_range := 1.8
@export var attack_damage := 12.0
@export var attack_cooldown := 0.7
@export var reposition_every := 1.1

var _hp := 0.0
var _attack_timer := 0.0
var _reposition_timer := 0.0
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
	_reposition_timer = maxf(0.0, _reposition_timer - delta)
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

	var forward := to_player.normalized() if dist > 0.01 else Vector3.FORWARD
	var side := Vector3(-forward.z, 0.0, forward.x) * _strafe_sign

	if _reposition_timer <= 0.0:
		_strafe_sign *= -1.0
		_reposition_timer = reposition_every

	if dist > attack_range * 1.6:
		# Close distance with a strafe bias (flank feel)
		var desire := (forward * 0.65 + side * 0.55).normalized()
		velocity.x = desire.x * move_speed
		velocity.z = desire.z * move_speed
	elif dist > attack_range:
		var desire := (forward * 0.25 + side).normalized()
		velocity.x = desire.x * strafe_speed
		velocity.z = desire.z * strafe_speed
	else:
		velocity.x = side.x * strafe_speed * 0.4
		velocity.z = side.z * strafe_speed * 0.4
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			if _player.has_method("take_damage"):
				_player.take_damage(attack_damage)

	if forward.length() > 0.01:
		look_at(global_position + forward, Vector3.UP)

	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
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
	# Getting shot triggers an immediate strafe flip
	_strafe_sign *= -1.0
	_reposition_timer = reposition_every * 0.5
	if _hp <= 0.0:
		queue_free()

func apply_melee_hit(amount: float, from: Vector3) -> void:
	var push := global_position - from
	push.y = 0.0
	if push.length() > 0.01:
		velocity += push.normalized() * 8.0
	take_damage(amount)
