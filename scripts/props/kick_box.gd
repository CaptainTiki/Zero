extends CharacterBody3D
## Upright sliding prop. Only a deliberate kick arms its enemy impact.

@export var slide_speed := 13.0
@export var slide_deceleration := 7.0
@export var impact_damage := 25.0
@export var impact_push := 9.0
@export var minimum_hit_speed := 3.0

var _slide := Vector3.ZERO
var _armed := false

func apply_kick(_damage: float, from: Vector3, _force: float) -> void:
	var direction := global_position - from
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		return
	_slide = direction.normalized() * slide_speed
	_armed = true

func _physics_process(delta: float) -> void:
	var speed := _slide.length()
	if speed < minimum_hit_speed:
		_armed = false
	velocity.x = _slide.x
	velocity.z = _slide.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	move_and_slide()
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var body := collision.get_collider()
		if body is Node and body.is_in_group("enemies") and _armed:
			_armed = false
			if body.has_method("apply_kick"):
				body.apply_kick(impact_damage, global_position, impact_push)
			elif body.has_method("take_damage"):
				body.take_damage(impact_damage)
			_slide *= 0.2
		elif absf(collision.get_normal().y) < 0.5:
			# Walls and the player stop the box; resting floor contact does not.
			_slide = Vector3.ZERO
			_armed = false
	_slide = _slide.move_toward(Vector3.ZERO, slide_deceleration * delta)
