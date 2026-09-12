extends CharacterBody3D
class_name PlayerController

enum Weapon { FISTS, PISTOL, SHOTGUN }
const ViewKitScript = preload("res://scripts/player/view_kit.gd")

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
@export var shotgun_damage := 9.0
@export var shotgun_pellets := 8
@export var shotgun_spread_degrees := 6.0
@export var shotgun_cooldown := 0.85
@export var shotgun_range := 26.0
@export var shotgun_push := 7.0
@export var shell_capacity := 32
@export var boost_speed_scale := 1.5
@export var boost_jump_scale := 1.35
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
var _has_shotgun := false
var _shells := 0
var _shotgun_timer := 0.0
var _pump_elapsed := -1.0
var _boost_left := 0.0
var view_shotgun: Node3D
var _pump: Node3D
var _pump_hand: Node3D
var _pistol_slide: Node3D
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
	_build_view_rigs()
	_refresh_weapon_visuals()
	_update_hud()

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
	if event.is_action_pressed("weapon_shotgun") and _has_shotgun:
		_set_weapon(Weapon.SHOTGUN)

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
	_shotgun_timer = maxf(0.0, _shotgun_timer - delta)
	if _boost_left > 0.0:
		_boost_left = maxf(0.0, _boost_left - delta)
		if _boost_left <= 0.0:
			_update_hud()
	_update_pump(delta)
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
	if _boost_left > 0.0:
		speed *= boost_speed_scale
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity * (boost_jump_scale if _boost_left > 0.0 else 1.0)

	move_and_slide()

	if Input.is_action_just_pressed("primary"):
		if _weapon == Weapon.FISTS:
			_try_melee()
		elif _weapon == Weapon.PISTOL:
			_try_fire()
		elif _weapon == Weapon.SHOTGUN:
			_try_shotgun()

	_update_viewmodel_pose(delta)

func _build_view_rigs() -> void:
	# Replace the placeholder blocks in the scene with procedural rigs.
	for holder in [view_fists, view_pistol]:
		for child in holder.get_children():
			if child is MeshInstance3D:
				child.queue_free()
	view_fists.add_child(ViewKitScript.fists())
	var pistol_rig: Node3D = ViewKitScript.pistol()
	view_pistol.add_child(pistol_rig)
	_pistol_slide = pistol_rig.get_node("Slide")
	view_shotgun = Node3D.new()
	view_shotgun.name = "ViewShotgun"
	view_shotgun.position = Vector3(0.24, -0.24, -0.42)
	view_shotgun.rotation = Vector3(0.0, 0.06, 0.0)
	camera.add_child(view_shotgun)
	var shotgun_rig: Node3D = ViewKitScript.shotgun()
	view_shotgun.add_child(shotgun_rig)
	_pump = shotgun_rig.get_node("Pump")
	_pump_hand = shotgun_rig.get_node("PumpHand")
	for i in 4:
		var groove: Node3D = shotgun_rig.get_node("PumpGroove%d" % i)
		var world_pos := groove.position
		shotgun_rig.remove_child(groove)
		_pump.add_child(groove)
		groove.position = world_pos - _pump.position
	_boot = ViewKitScript.boot()
	camera.add_child(_boot)
	_boot.visible = false

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

func grant_shotgun() -> void:
	_has_shotgun = true
	_shells = mini(shell_capacity, _shells + 8)
	_set_weapon(Weapon.SHOTGUN)
	_play_pitched(_sfx_gun, 0.6)

func add_shells(amount: int) -> bool:
	if _shells >= shell_capacity:
		return false
	_shells = mini(shell_capacity, _shells + amount)
	_update_hud()
	return true

func apply_boost(duration: float) -> bool:
	_boost_left = maxf(_boost_left, duration)
	_update_hud()
	if hud and hud.has_method("flash_boost"):
		hud.flash_boost()
	return true

func _play_pitched(stream: AudioStream, pitch: float) -> void:
	if stream == null or sfx == null:
		return
	sfx.stream = stream
	sfx.pitch_scale = pitch * randf_range(0.96, 1.04)
	sfx.play()

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
	if view_shotgun:
		view_shotgun.visible = (_weapon == Weapon.SHOTGUN)

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
	if _weapon == Weapon.SHOTGUN and view_shotgun:
		var kick := _recoil.length() / deg_to_rad(4.5)
		var pump_lift := 0.0
		if _pump_elapsed >= 0.0:
			pump_lift = sin(clampf(_pump_elapsed / 0.55, 0.0, 1.0) * PI) * 0.06
		var target := Vector3(0.24, -0.24 + bob + pump_lift, -0.42 + kick * 0.14)
		view_shotgun.position = view_shotgun.position.lerp(target, clampf(delta * 24.0, 0.0, 1.0))
		view_shotgun.rotation.x = lerpf(view_shotgun.rotation.x, kick * 0.35 + pump_lift * 2.0, clampf(delta * 20.0, 0.0, 1.0))
	if _pistol_slide:
		_pistol_slide.position.z = -0.02 + _recoil.length() / deg_to_rad(1.8) * 0.05

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
		var names := {Weapon.FISTS: "FISTS", Weapon.PISTOL: "PISTOL", Weapon.SHOTGUN: "SHOTGUN"}
		var wname: String = names[_weapon]
		var ammo := ""
		if _weapon == Weapon.SHOTGUN:
			ammo = "SHELLS %d" % _shells
		hud.set_status(wname, _hp, max_hp, _has_gun, _ads, ammo, _boost_left)

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

func _try_shotgun() -> void:
	if _shotgun_timer > 0.0 or _pump_elapsed >= 0.0:
		return
	if _shells <= 0:
		_shotgun_timer = 0.3
		_play_pitched(_sfx_melee, 1.6)
		_update_hud()
		return
	_shells -= 1
	_shotgun_timer = shotgun_cooldown
	_pump_elapsed = 0.0
	_play_pitched(_sfx_gun, 0.55)
	if muzzle:
		muzzle.light_energy = 7.0
	var aim_basis := global_transform.basis * Basis(Vector3.RIGHT, _pitch)
	var origin := camera.global_position
	var hits := {}
	for i in shotgun_pellets:
		var spread := deg_to_rad(shotgun_spread_degrees)
		var radius := sqrt(randf()) * tan(spread)
		var angle := randf() * TAU
		var direction := aim_basis * Vector3(cos(angle) * radius, sin(angle) * radius, -1.0).normalized()
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * shotgun_range, gun_ray.collision_mask, [get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var col: Object = hit.collider
		if col == null or not col.has_method("take_damage"):
			continue
		var distance: float = origin.distance_to(hit.position)
		var falloff := 1.0 if distance < 10.0 else clampf(1.0 - (distance - 10.0) / (shotgun_range - 10.0), 0.15, 1.0)
		hits[col] = hits.get(col, 0.0) + shotgun_damage * falloff
	for col in hits:
		var amount: float = hits[col]
		if col.has_method("apply_shot"):
			col.apply_shot(amount, global_position, shotgun_push * clampf(amount / (shotgun_damage * shotgun_pellets), 0.3, 1.0))
		else:
			col.take_damage(amount)
	_recoil += Vector2(deg_to_rad(randf_range(-0.8, 0.8)), deg_to_rad(randf_range(3.0, 3.8)))
	_recoil = _recoil.limit_length(deg_to_rad(4.5))
	_apply_aim()
	_update_hud()

func _update_pump(delta: float) -> void:
	if _pump_elapsed < 0.0:
		return
	_pump_elapsed += delta
	# Pump racks back between 0.2 and 0.4 s, returns by 0.6 s.
	var travel := 0.0
	if _pump_elapsed > 0.2:
		travel = sin(clampf((_pump_elapsed - 0.2) / 0.4, 0.0, 1.0) * PI)
	if _pump:
		_pump.position.z = -0.26 + travel * 0.09
	if _pump_hand:
		_pump_hand.position.z = -0.26 + travel * 0.09
	if _pump_elapsed >= 0.6:
		_pump_elapsed = -1.0

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
