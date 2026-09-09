extends RigidBody3D
class_name ThrowableProp

@export var throw_speed := 14.0
@export var damage := 40.0

var _held := false
var _holder: Node3D

func interact(player: Node3D) -> void:
	if _held:
		return
	_held = true
	_holder = player
	freeze = true
	collision_layer = 0
	reparent(player)
	position = Vector3(0.6, 1.0, -1.2)

func throw_forward(origin: Node3D) -> void:
	if not _held:
		return
	_held = false
	reparent(origin.get_tree().current_scene)
	global_transform = origin.global_transform
	freeze = false
	collision_layer = 1
	linear_velocity = -origin.global_transform.basis.z * throw_speed + Vector3.UP * 2.0
	_holder = null

func _on_body_entered(body: Node) -> void:
	if _held:
		return
	if linear_velocity.length() < 4.0:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	if body.has_method("apply_melee_hit"):
		body.apply_melee_hit(damage, global_position)
