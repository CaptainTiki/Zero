extends CharacterBody3D
class_name PlayerController

enum Weapon { FISTS, PISTOL }

@export var walk_speed := 6.0
@export var sprint_speed := 9.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.0025
@export var melee_damage := 25.0
@export var melee_cooldown := 0.45
@export var pistol_damage := 22.0
@export var pistol_cooldown := 0.18
@export var pistol_spread_degrees := 0.35
@export var pistol_max_bloom_degrees := 4.0
@export var pistol_bloom_per_shot := 1.1
@export var pistol_bloom_recovery := 1.8
@export var pistol_camera_kick_scale := 1.7
@export var max_hp := 100.0
@export var kick_range := 2.2
@export var kick_damage := 10.0
@export var kick_force := 11.0
@export var kick_cooldown := 0.55

var _kick_timer := 0.0
var _kick_elapsed := -1.0
var _kick_connected := false
var _boot: Node3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _yaw := 0.0
var _pitch := 0.0
var _recoil := Vector2.ZERO
var _shot_bloom := 0.0
var _melee_timer := 0.0
var _fire_timer := 0.0
var _has_gun := false
var _weapon: Weapon = Weapon.FISTS
var _held_prop: Node3D
var _hp := 100.0
var _hurt_cd := 0.0
var _ads := false

@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head
@onready var melee_ray: RayCast3D = $Head/Camera3D/MeleeRay
@onready var gun_ray: RayCast3D = $Head/Camera3D/GunRay
@onready var hud: CanvasLayer = $HUD
@onready var view_fists: Node3D = $Head/Camera3D/ViewFists
@onready var view_pistol: Node3D = $Head/Camera3D/ViewPistol
@onready var muzzle: OmniLight3D = $Head/Camera3D/ViewPistol/MuzzleFlash
@onready var sfx: AudioStreamPlayer = $SFX

var _sfx_melee: AudioStream
var _sfx_impact: AudioStream
var _sfx_gun: AudioStream
var _sfx_hurt: AudioStream

func _ready() -> void:
	_hp = max_hp
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	melee_ray.enabled = true
	gun_ray.enabled = true
	_sfx_melee = _load_sfx("res://audio/sfx/player/melee_punch_01.wav")
	_sfx_impact = _load_sfx("res://audio/sfx/player/melee_impact_01.wav")
	_sfx_gun = _load_sfx("res://audio/sfx/weapons/gunfire_pistol_01.wav")
	_sfx_hurt = _load_sfx("res://audio/sfx/alien/hit_01.wav")
	_refresh_weapon_visuals()
	_update_hud()
	_build_boot()

func _load_sfx(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _play(stream: AudioStream) -> void:
	if stream == null or sfx == null:
		return
	sfx.stream = stream
	sfx.pitch_scale = randf_range(0.92, 1.08)
	sfx.play()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_look(event.relative)
		get_viewport().set_input_as_handled()

func _apply_mouse_look(relative: Vector2) -> void:
	var sens := mouse_sensitivity * (0.65 if _ads else 1.0)
	_yaw -= relative.x * sens
	_pitch = clampf(_pitch - relative.y * sens, deg_to_rad(-85.0), deg_to_rad(85.0))
	rotation.y = _yaw
	_apply_aim()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("weapon_fists"):
		_set_weapon(Weapon.FISTS)
	if event.is_action_pressed("weapon_pistol") and _has_gun:
		_set_weapon(Weapon.PISTOL)

func _physics_process(delta: float) -> void:
	_update_recoil(delta)
	_kick_timer = maxf(0.0, _kick_timer - delta)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_just_pressed("kick") and _kick_timer <= 0.0:
		_kick_timer = kick_cooldown
		_kick_elapsed = 0.0
		_kick_connected = false
		_play(_sfx_melee)
	_update_kick(delta)
	_melee_timer = maxf(0.0, _melee_timer - delta)
	_fire_timer = maxf(0.0, _fire_timer - delta)
	_hurt_cd = maxf(0.0, _hurt_cd - delta)
	_ads = _weapon == Weapon.PISTOL and Input.is_action_pressed("ads")
	if muzzle and muzzle.light_energy > 0.0:
		muzzle.light_energy = maxf(0.0, muzzle.light_energy - delta * 30.0)

	if not is_on_floor():
		velocity.y -= _gravity * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	if _ads:
		speed *= 0.7
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	if Input.is_action_just_pressed("primary"):
		if _weapon == Weapon.FISTS:
			_try_melee()
		elif _weapon == Weapon.PISTOL:
			_try_fire()

	_update_viewmodel_pose(delta)

func _build_boot() -> void:
	_boot = Node3D.new()
	_boot.name = "ViewBoot"
	camera.add_child(_boot)
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color(0.19, 0.12, 0.07)
	var sole := StandardMaterial3D.new()
	sole.albedo_color = Color(0.045, 0.04, 0.035)
	var trousers := StandardMaterial3D.new()
	trousers.albedo_color = Color(0.25, 0.29, 0.16)
	_boot_piece(Vector3(0.23, 0.23, 0.55), Vector3.ZERO, leather)
	_boot_piece(Vector3(0.25, 0.065, 0.58), Vector3(0, -0.14, 0), sole)
	_boot_piece(Vector3(0.18, 0.2, 0.65), Vector3(0, 0.1, 0.48), trousers)
	_boot.visible = false

func _boot_piece(size: Vector3, offset: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.material_override = material
	part.position = offset
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_boot.add_child(part)

func _update_kick(delta: float) -> void:
	if _kick_elapsed < 0.0:
		return
	_kick_elapsed += delta
	_boot.visible = true
	var extension: float
	if _kick_elapsed < 0.12:
		extension = ease(clampf(_kick_elapsed / 0.12, 0.0, 1.0), 0.5)
	elif _kick_elapsed < 0.19:
		extension = 1.0
	else:
		extension = 1.0 - smoothstep(0.19, 0.40, _kick_elapsed)
	# The toe reaches the same distance as the contact ray at full extension.
	_boot.position = Vector3(0.3, -0.85, -0.35).lerp(Vector3(0.0, -0.25, -kick_range + 0.275), extension)
	_boot.rotation.x = lerpf(-0.45, 0.0, extension)
	if _kick_elapsed >= 0.12 and not _kick_connected:
		_kick_connected = true
		var origin := camera.global_position - camera.global_basis.y * 0.25
		var query := PhysicsRayQueryParameters3D.create(origin, origin - camera.global_basis.z * kick_range, 1, [get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			_play(_sfx_impact)
			var target: Object = hit.collider
			if target.has_method("apply_kick"):
				target.apply_kick(kick_damage, global_position, kick_force)
	if _kick_elapsed >= 0.40:
		_kick_elapsed = -1.0
		_boot.visible = false

func grant_gun() -> void:
	_has_gun = true
	_set_weapon(Weapon.PISTOL)
	_play(_sfx_gun)

func _set_weapon(w: Weapon) -> void:
	_weapon = w
	_ads = false
	_refresh_weapon_visuals()
	_update_hud()

func _refresh_weapon_visuals() -> void:
	if view_fists:
		view_fists.visible = (_weapon == Weapon.FISTS)
	if view_pistol:
		view_pistol.visible = (_weapon == Weapon.PISTOL)

func _update_viewmodel_pose(delta: float) -> void:
	# simple bob / ads push
	var t := Time.get_ticks_msec() * 0.01
	var bob := sin(t) * 0.004
	if _weapon == Weapon.PISTOL and view_pistol:
		var target := Vector3(0.18, -0.16, -0.35) if _ads else Vector3(0.28, -0.22, -0.45)
		var recoil_amount := _recoil.length() / deg_to_rad(1.8)
		view_pistol.position = view_pistol.position.lerp(target + Vector3(0, bob + recoil_amount * 0.05, recoil_amount * 0.15), clampf(delta * 32.0, 0.0, 1.0))
	if _weapon == Weapon.FISTS and view_fists:
		view_fists.position = Vector3(0.2, -0.25, -0.4) + Vector3(0, bob, 0)

func restore_health(amount: float) -> bool:
	if amount <= 0.0 or _hp >= max_hp:
		return false
	_hp = minf(max_hp, _hp + amount)
	_update_hud()
	return true

func take_damage(amount: float) -> void:
	if _hurt_cd > 0.0:
		return
	_hurt_cd = 0.35
	_hp = maxf(0.0, _hp - amount)
	_update_hud()
	_play(_sfx_hurt)
	if hud and hud.has_method("flash_hurt"):
		hud.flash_hurt()
	var start := camera.position
	var tw := create_tween()
	tw.tween_property(camera, "position", start + Vector3(0.05, -0.04, 0.05), 0.04)
	tw.tween_property(camera, "position", start, 0.1)
	if _hp <= 0.0:
		_hp = max_hp
		global_position = Vector3(0, 0.5, 4)
		_update_hud()

func _update_hud() -> void:
	if hud and hud.has_method("set_status"):
		var wname := "FISTS" if _weapon == Weapon.FISTS else "PISTOL"
		hud.set_status(wname, _hp, max_hp, _has_gun, _ads)

func _try_melee() -> void:
	if _melee_timer > 0.0:
		return
	_melee_timer = melee_cooldown
	_play(_sfx_melee)
	# punch anim nudge
	if view_fists:
		var tw := create_tween()
		var start := view_fists.position
		tw.tween_property(view_fists, "position", start + Vector3(0.05, 0.02, -0.15), 0.05)
		tw.tween_property(view_fists, "position", start, 0.12)
	melee_ray.force_raycast_update()
	if not melee_ray.is_colliding():
		return
	var col := melee_ray.get_collider()
	var hit := false
	if col and col.has_method("apply_melee_hit"):
		col.apply_melee_hit(melee_damage, global_position)
		hit = true
	elif col and col.has_method("take_damage"):
		col.take_damage(melee_damage)
		hit = true
	if hit:
		_play(_sfx_impact)
		var start := camera.position
		var tw2 := create_tween()
		tw2.tween_property(camera, "position", start + Vector3(0, 0, 0.07), 0.04)
		tw2.tween_property(camera, "position", start, 0.08)

func _try_fire() -> void:
	if _fire_timer > 0.0:
		return
	_fire_timer = pistol_cooldown
	_play(_sfx_gun)
	if muzzle:
		muzzle.light_energy = 4.5
	# Accuracy follows the player's aim, independently of temporary visual kick.
	var spread := deg_to_rad(pistol_spread_degrees + _shot_bloom) * (0.5 if _ads else 1.0)
	var radius := sqrt(randf()) * tan(spread)
	var angle := randf() * TAU
	var direction := Vector3(cos(angle) * radius, sin(angle) * radius, -1.0).normalized()
	var aim_basis := global_transform.basis * Basis(Vector3.RIGHT, _pitch)
	direction = aim_basis * direction
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + direction * gun_ray.target_position.length(), gun_ray.collision_mask, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	_shot_bloom = minf(pistol_max_bloom_degrees, _shot_bloom + pistol_bloom_per_shot)
	_recoil += Vector2(deg_to_rad(randf_range(-0.45, 0.45)), deg_to_rad(randf_range(0.9, 1.4))) * (0.65 if _ads else 1.0)
	_recoil = _recoil.limit_length(deg_to_rad(1.8))
	_apply_aim()
	var col = hit.get("collider")
	if col and col.has_method("take_damage"):
		col.take_damage(pistol_damage)

func _apply_aim() -> void:
	# Camera punch is tuned separately from the approved weapon animation.
	head.rotation.x = clampf(_pitch + _recoil.y * pistol_camera_kick_scale, deg_to_rad(-85.0), deg_to_rad(85.0))
	head.rotation.y = _recoil.x * pistol_camera_kick_scale

func _update_recoil(delta: float) -> void:
	_recoil = _recoil.move_toward(Vector2.ZERO, deg_to_rad(8.0) * delta)
	_shot_bloom = move_toward(_shot_bloom, 0.0, pistol_bloom_recovery * delta)
	_apply_aim()

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
