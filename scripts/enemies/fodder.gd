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
var _flash_left := 0.0
var _mat: StandardMaterial3D
var _base_color := Color(0.35, 0.85, 0.25, 1)

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemies")
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = _base_color
		mesh.material_override = _mat

func _physics_process(delta: float) -> void:
	if _kick_stagger > 0.0:
		_kick_stagger = maxf(0.0, _kick_stagger - delta)
		velocity.x = _kick_velocity.x
		velocity.z = _kick_velocity.z
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
		move_and_slide()
		_kick_velocity = _kick_velocity.move_toward(Vector3.ZERO, 24.0 * delta)
		return
	if _flash_left > 0.0:
		_flash_left = maxf(0.0, _flash_left - delta)
		if _mat and _flash_left <= 0.0:
			_mat.albedo_color = _base_color
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
		velocity += push.normalized() * 6.0
	take_damage(amount)

func apply_kick(amount: float, from: Vector3, force: float) -> void:
	var direction := global_position - from
	direction.y = 0.0
	_kick_velocity = direction.normalized() * force
	_kick_stagger = 0.4
	take_damage(amount)
