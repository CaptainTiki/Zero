extends RigidBody3D
class_name ThrowableProp

@export var throw_speed := 16.0
@export var damage := 55.0

var _held := false
var _thrown := false
var _arm_time := 0.0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _thrown:
		_arm_time = maxf(0.0, _arm_time - delta)

func interact(player: Node3D) -> void:
	if _held:
		return
	_held = true
	_thrown = false
	freeze = true
	collision_layer = 0
	collision_mask = 0
	reparent(player)
	position = Vector3(0.7, 1.1, -1.3)
	rotation = Vector3.ZERO

func throw_forward(origin: Node3D) -> void:
	if not _held:
		return
	_held = false
	_thrown = true
	_arm_time = 2.0
	var scene := origin.get_tree().current_scene
	reparent(scene)
	global_position = origin.global_position - origin.global_transform.basis.z * 1.2 + Vector3.UP * 0.4
	freeze = false
	collision_layer = 1
	collision_mask = 1
	linear_velocity = -origin.global_transform.basis.z * throw_speed + Vector3.UP * 2.5
	angular_velocity = Vector3(randf() * 4.0, randf() * 2.0, randf() * 4.0)

func _on_body_entered(body: Node) -> void:
	if _held or not _thrown or _arm_time <= 0.0:
		return
	if linear_velocity.length() < 3.0:
		return
	if body.is_in_group("player"):
		return
	if body.has_method("apply_melee_hit"):
		body.apply_melee_hit(damage, global_position)
	elif body.has_method("take_damage"):
		body.take_damage(damage)
	# visual stop
	linear_velocity *= 0.2
	_thrown = false
