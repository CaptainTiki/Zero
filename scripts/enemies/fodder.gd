extends CharacterBody3D
class_name AlienFodder

@export var max_hp := 40.0
@export var move_speed := 3.0
@export var aggro_range := 18.0
@export var attack_range := 1.6
@export var attack_damage := 8.0
@export var attack_cooldown := 1.0

var _hp := 0.0
var _attack_timer := 0.0
var _player: Node3D

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
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

func take_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0.0:
		queue_free()

func apply_melee_hit(amount: float, _from: Vector3) -> void:
	take_damage(amount)
