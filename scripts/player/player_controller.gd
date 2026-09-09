extends CharacterBody3D
class_name PlayerController

@export var walk_speed := 6.0
@export var sprint_speed := 9.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.0025
@export var melee_damage := 25.0
@export var melee_cooldown := 0.45

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _yaw := 0.0
var _pitch := 0.0
var _melee_timer := 0.0
var _has_gun := false
var _held_prop: Node3D

@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head
@onready var melee_ray: RayCast3D = $Head/Camera3D/MeleeRay
@onready var gun_ray: RayCast3D = $Head/Camera3D/GunRay
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	melee_ray.enabled = true
	gun_ray.enabled = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-85.0), deg_to_rad(85.0))
		rotation.y = _yaw
		head.rotation.x = _pitch
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	_melee_timer = maxf(0.0, _melee_timer - delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	if Input.is_action_just_pressed("melee"):
		_try_melee()
	if _has_gun and Input.is_action_just_pressed("fire"):
		_try_fire()

func grant_gun() -> void:
	_has_gun = true
	if hud and hud.has_method("set_has_gun"):
		hud.set_has_gun(true)

func _try_melee() -> void:
	if _melee_timer > 0.0:
		return
	_melee_timer = melee_cooldown
	melee_ray.force_raycast_update()
	if not melee_ray.is_colliding():
		return
	var col := melee_ray.get_collider()
	if col and col.has_method("apply_melee_hit"):
		col.apply_melee_hit(melee_damage, global_position)
	elif col and col.has_method("take_damage"):
		col.take_damage(melee_damage)

func _try_fire() -> void:
	gun_ray.force_raycast_update()
	if not gun_ray.is_colliding():
		return
	var col := gun_ray.get_collider()
	if col and col.has_method("take_damage"):
		col.take_damage(20.0)

func _try_interact() -> void:
	if _held_prop and is_instance_valid(_held_prop) and _held_prop.has_method("throw_forward"):
		_held_prop.throw_forward(camera)
		_held_prop = null
		return
	melee_ray.force_raycast_update()
	if not melee_ray.is_colliding():
		return
	var col := melee_ray.get_collider()
	if col and col.has_method("interact"):
		col.interact(self)
		_held_prop = col