extends CharacterBody3D
class_name AlienBrute
## A big, slow fodder. It walks at the player, and once in reach it raises both arms over its
## head and slams the ground in front of it. Anyone standing in the slam zone when it lands is
## hurt, so the wind-up is the tell to back off or step aside. Too heavy to shove: kicks and
## pellets barely move it, and it takes a lot more than a Rammer to put down. The head is the
## weak spot, as on fodder. Placed in the way, in corridors and doorways, and in the machine's
## waves: area denial, not a duel.

@export var max_hp := 480.0
## Half the player's walk speed (6.0), so backing off works but not for ever (user, playtest 6).
@export var move_speed := 3.0
@export var aggro_range := 16.0
@export var sight_range := 40.0
## Starts a slam when the player is this close.
@export var slam_range := 3.4
## The slam zone: a circle this far ahead, this wide.
@export var slam_reach := 2.0
@export var slam_radius := 2.3
@export var slam_damage := 30.0
@export var windup_time := 0.85
@export var slam_time := 0.14
@export var recover_time := 1.1
@export var head_mult := 1.6
## Arm angles about the shoulder: overhead for the wind-up, down at the ground for the slam.
const ARMS_UP := 2.9
const ARMS_DOWN := 0.55

enum State { IDLE, CHASE, WINDUP, SLAM, RECOVER }
var _state: State = State.IDLE
var _hp := 0.0
var _timer := 0.0
var _slam_dir := Vector3.FORWARD
var _push := Vector3.ZERO
var _player: Node3D
var _body: Node
var _alerted := false
var _voice_timer := randf_range(2.0, 6.0)
var _sound: Node

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemies")
	add_to_group("elites")
	_body = get_node_or_null("Body")

func _voice(event: String, offset := 0.0) -> void:
	if _sound == null:
		_sound = get_tree().root.get_node_or_null("Sound")
	if _sound:
		_sound.play_at(event, global_position + Vector3(0, 1.6, 0), offset)

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	_voice_timer -= delta
	if _voice_timer <= 0.0:
		_voice_timer = randf_range(4.0, 8.0)
		if dist < 26.0:
			_voice("brute_idle")
	var lean := 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	match _state:
		State.IDLE:
			if _update_alert(dist):
				_state = State.CHASE
		State.CHASE:
			if dist < slam_range and _same_level():
				_state = State.WINDUP
				_timer = windup_time
				_slam_dir = to_player.normalized() if dist > 0.01 else -global_basis.z
				look_at(global_position + _slam_dir, Vector3.UP)
				_voice("brute_windup")
			elif dist > 0.01:
				var dir := to_player.normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				look_at(global_position + dir, Vector3.UP)
			_pose_arms(0.0, 0.0)
		State.WINDUP:
			_timer -= delta
			var u := 1.0 - _timer / windup_time
			_pose_arms(ARMS_UP * (1.0 - pow(1.0 - clampf(u, 0.0, 1.0), 2.0)), 1.0)
			lean = -0.4
			if _timer <= 0.0:
				_state = State.SLAM
				_timer = slam_time
		State.SLAM:
			_timer -= delta
			_pose_arms(lerpf(ARMS_DOWN, ARMS_UP, clampf(_timer / slam_time, 0.0, 1.0)), 1.0)
			lean = 1.4
			if _timer <= 0.0:
				_land_slam()
				_state = State.RECOVER
				_timer = recover_time
		State.RECOVER:
			_timer -= delta
			# Fists stay on the ground, then the arms swing back to hanging.
			var back := clampf(_timer / (recover_time * 0.5), 0.0, 1.0)
			_pose_arms(ARMS_DOWN, back)
			lean = 1.4 * back
			if _timer <= 0.0:
				_state = State.CHASE
	# Kicks and shotgun blasts nudge it a little.
	velocity.x += _push.x
	velocity.z += _push.z
	_push = _push.move_toward(Vector3.ZERO, 12.0 * delta)
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if _body:
		_body.animate(delta, Vector2(velocity.x, velocity.z).length(), lean)

func _pose_arms(angle: float, weight: float) -> void:
	if _body and _body.has_method("pose_arms"):
		_body.pose_arms(angle, weight)

## The slam lands: hurt the player if they're in the zone, shake them if they're near, and
## throw up dust.
func _land_slam() -> void:
	var centre := global_position + _slam_dir * slam_reach
	_voice("brute_slam")
	_dust(centre)
	if _player == null:
		return
	var offset := _player.global_position - centre
	var height := absf(_player.global_position.y - global_position.y)
	if Vector2(offset.x, offset.z).length() <= slam_radius and height < 1.4:
		if _player.has_method("take_damage"):
			_player.take_damage(slam_damage)
		_shake(1.0)
	elif _player.global_position.distance_to(centre) < 9.0:
		_shake(0.45)

func _shake(strength: float) -> void:
	var camera = _player.get("camera")
	if camera == null:
		return
	# Tween from the camera's rest spot, so two slams at once don't leave it knocked off.
	var rest: Vector3 = camera.get_meta("rest_position", camera.position)
	camera.set_meta("rest_position", rest)
	var tw := create_tween()
	tw.tween_property(camera, "position", rest + Vector3(0.0, -0.16, 0.0) * strength, 0.04)
	tw.tween_property(camera, "position", rest + Vector3(0.06, 0.06, 0.0) * strength, 0.07)
	tw.tween_property(camera, "position", rest, 0.12)

func _dust(at: Vector3) -> void:
	var world := get_parent()
	if world == null:
		return
	var dust := CPUParticles3D.new()
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.amount = 26
	dust.lifetime = 0.8
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 0.9
	dust.direction = Vector3(0, 1, 0)
	dust.spread = 85.0
	dust.initial_velocity_min = 2.5
	dust.initial_velocity_max = 5.5
	dust.gravity = Vector3(0, -5, 0)
	dust.damping_min = 3.0
	dust.damping_max = 5.0
	dust.scale_amount_min = 0.8
	dust.scale_amount_max = 1.7
	var puff := QuadMesh.new()
	puff.size = Vector2(0.8, 0.8)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = Color(0.62, 0.6, 0.52, 0.55)
	puff.material = m
	dust.mesh = puff
	world.add_child(dust)
	dust.global_position = at + Vector3(0, 0.2, 0)
	dust.emitting = true
	var tw := dust.create_tween()
	tw.tween_interval(1.5)
	tw.tween_callback(dust.queue_free)

func _same_level() -> bool:
	return absf(_player.global_position.y - global_position.y) < 1.4

func _update_alert(dist: float) -> bool:
	if _alerted:
		if dist > sight_range * 1.3:
			_alerted = false
		return _alerted
	if dist <= aggro_range or (dist <= sight_range and _can_see_player()):
		_alerted = true
		_voice("brute_alert")
	return _alerted

func _can_see_player() -> bool:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 2.2, 0), _player.global_position + Vector3(0, 1.0, 0), 1, [get_rid()])
	return space.intersect_ray(query).is_empty()

func take_damage(amount: float, weak := false) -> void:
	if _body:
		_body.flash()
		_body.flinch(0.5 if weak else 0.2)
	if randf() < 0.4:
		_voice("brute_hurt")
	# Hurting it wakes it up.
	_alerted = true
	if _state == State.IDLE:
		_state = State.CHASE
	_hp -= amount * (head_mult if weak else 1.0)
	if _hp <= 0.0:
		_die()

## The head, sunk forward between the shoulders.
func is_weak_hit(point: Vector3) -> bool:
	var local := to_local(point)
	return local.y > 2.0 and local.z < -0.05 and absf(local.x) < 0.6

func apply_melee_hit(amount: float, _from: Vector3) -> void:
	take_damage(amount)

func apply_kick(amount: float, from: Vector3, force: float) -> void:
	var direction := global_position - from
	direction.y = 0.0
	if direction.length() > 0.01:
		_push = direction.normalized() * force * 0.12
	take_damage(amount)

func apply_shot(amount: float, _from: Vector3, _push_force: float, weak := false) -> void:
	take_damage(amount, weak)

func _die() -> void:
	get_tree().call_group("run_stats", "record_kill")
	_voice("brute_death")
	_voice("gib")
	if _body:
		_body.burst(get_parent(), global_basis.z)
	queue_free()
