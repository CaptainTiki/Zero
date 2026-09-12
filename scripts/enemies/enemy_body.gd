extends Node3D
class_name EnemyBody
## Procedural chunky-PS1 enemy bodies with walk cycles, hit flash, weak-point
## glow and a gib burst on death. Built from boxes so silhouettes stay readable
## at ten metres. Faces point down -Z, matching CharacterBody3D.look_at.

@export_enum("fodder", "rammer", "hunter") var kind := "fodder"

var _mats: Array[StandardMaterial3D] = []
var _bases: Array[Color] = []
var _weak: Array[StandardMaterial3D] = []
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _torso: Node3D
var _head: Node3D
var _flash_left := 0.0
var _walk := 0.0
var _idle := 0.0
var _lean := 0.0
var _weak_open := false
var _gib_color := Color(0.3, 0.6, 0.2)
var _leg_amp := 0.6
var _stride := 4.0
var _weak_color := Color(0.95, 0.8, 0.2)

func _ready() -> void:
	match kind:
		"fodder":
			_build_fodder()
		"rammer":
			_build_rammer()
		"hunter":
			_build_hunter()

# --- construction -----------------------------------------------------------

func _material(color: Color, emissive := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.0
	_mats.append(m)
	_bases.append(color)
	return m

func _box(size: Vector3, at: Vector3, m: StandardMaterial3D, parent: Node3D = self, tilt := Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = m
	part.mesh = mesh
	part.position = at
	part.rotation = tilt
	parent.add_child(part)
	return part

func _cone(radius: float, height: float, at: Vector3, m: StandardMaterial3D, parent: Node3D = self, tilt := Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 6
	mesh.material = m
	part.mesh = mesh
	part.position = at
	part.rotation = tilt
	parent.add_child(part)
	return part

func _pivot(at: Vector3, parent: Node3D = self) -> Node3D:
	var node := Node3D.new()
	node.position = at
	parent.add_child(node)
	return node

func _eyes(parent: Node3D, spread: float, y: float, z: float, size: float, iris: Color) -> void:
	var white := _material(Color(0.95, 0.95, 0.85))
	var dark := _material(iris)
	for side in [-1.0, 1.0]:
		_box(Vector3(size, size, 0.06), Vector3(side * spread, y, z), white, parent)
		_box(Vector3(size * 0.45, size * 0.45, 0.06), Vector3(side * spread, y - size * 0.05, z - 0.03), dark, parent)

func _build_fodder() -> void:
	_gib_color = Color(0.32, 0.6, 0.2)
	_leg_amp = 0.7
	_stride = 6.0
	var skin := _material(Color(0.45, 0.72, 0.3))
	var dark := _material(Color(0.3, 0.5, 0.22))
	var belly := _material(Color(0.74, 0.82, 0.5))
	var mouth := _material(Color(0.12, 0.08, 0.1))
	var tooth := _material(Color(0.95, 0.93, 0.8))
	_torso = _pivot(Vector3(0, 0.75, 0))
	_box(Vector3(0.85, 0.6, 0.75), Vector3.ZERO, skin, _torso)
	_box(Vector3(0.62, 0.42, 0.1), Vector3(0, -0.06, -0.36), belly, _torso)
	for i in 3:
		_box(Vector3(0.12, 0.28, 0.12), Vector3(-0.25 + i * 0.25, 0.32, 0.25), dark, _torso, Vector3(0.5, 0, 0))
	_head = _pivot(Vector3(0, 0.62, -0.05), _torso)
	_box(Vector3(0.95, 0.75, 0.85), Vector3.ZERO, skin, _head)
	_eyes(_head, 0.24, 0.1, -0.43, 0.24, Color(0.08, 0.06, 0.08))
	_box(Vector3(0.62, 0.08, 0.1), Vector3(0, 0.27, -0.42), dark, _head, Vector3(0, 0, 0.0))
	_box(Vector3(0.56, 0.12, 0.06), Vector3(0, -0.22, -0.43), mouth, _head)
	for i in 3:
		_box(Vector3(0.08, 0.1, 0.05), Vector3(-0.16 + i * 0.16, -0.19, -0.44), tooth, _head)
	for side in [-1.0, 1.0]:
		var arm := _pivot(Vector3(side * 0.52, 0.12, 0), _torso)
		_box(Vector3(0.22, 0.46, 0.22), Vector3(0, -0.2, 0), dark, arm)
		_arms.append(arm)
		var leg := _pivot(Vector3(side * 0.24, 0.45, 0))
		_box(Vector3(0.3, 0.44, 0.32), Vector3(0, -0.22, 0), dark, leg)
		_legs.append(leg)

func _build_rammer() -> void:
	_gib_color = Color(0.45, 0.14, 0.12)
	_leg_amp = 0.45
	_stride = 3.0
	var hide := _material(Color(0.56, 0.17, 0.14))
	var dark := _material(Color(0.32, 0.1, 0.09))
	var bone := _material(Color(0.85, 0.8, 0.65))
	_torso = _pivot(Vector3(0, 1.05, 0))
	_box(Vector3(1.5, 1.0, 1.9), Vector3.ZERO, hide, _torso)
	_box(Vector3(1.2, 0.45, 1.0), Vector3(0, 0.65, 0.3), dark, _torso)
	_box(Vector3(1.0, 0.5, 0.3), Vector3(0, -0.1, 1.05), dark, _torso)
	_head = _pivot(Vector3(0, 0.1, -1.2), _torso)
	_box(Vector3(0.95, 0.75, 0.8), Vector3.ZERO, hide, _head)
	_box(Vector3(0.6, 0.42, 0.45), Vector3(0, -0.14, -0.55), dark, _head)
	_cone(0.14, 0.55, Vector3(0, 0.35, -0.3), bone, _head, Vector3(-0.9, 0, 0))
	_eyes(_head, 0.3, 0.2, -0.41, 0.14, Color(0.9, 0.5, 0.1))
	_box(Vector3(0.9, 0.1, 0.12), Vector3(0, 0.32, -0.4), dark, _head)
	_box(Vector3(0.62, 0.08, 0.06), Vector3(0, -0.34, -0.79), bone, _head)
	for i in 4:
		_box(Vector3(0.07, 0.12, 0.05), Vector3(-0.21 + i * 0.14, -0.4, -0.79), bone, _head)
	for side in [-1.0, 1.0]:
		var plate := _material(_weak_color, true)
		_weak.append(plate)
		_box(Vector3(0.55, 0.3, 0.7), Vector3(side * 0.78, 0.6, -0.35), plate, _torso, Vector3(0, 0, side * -0.4))
		_box(Vector3(0.4, 0.2, 0.7), Vector3(side * 0.8, 0.42, -0.35), dark, _torso, Vector3(0, 0, side * -0.4))
	var core := _material(_weak_color, true)
	_weak.append(core)
	_box(Vector3(0.5, 0.42, 0.14), Vector3(0, -0.3, -0.98), core, _torso)
	for corner in [Vector3(-0.6, 0.6, -0.6), Vector3(0.6, 0.6, -0.6), Vector3(-0.6, 0.6, 0.65), Vector3(0.6, 0.6, 0.65)]:
		var leg := _pivot(corner)
		_box(Vector3(0.42, 0.62, 0.46), Vector3(0, -0.3, 0), dark, leg)
		_box(Vector3(0.48, 0.14, 0.52), Vector3(0, -0.55, 0), hide, leg)
		_legs.append(leg)

func _build_hunter() -> void:
	_gib_color = Color(0.7, 0.32, 0.1)
	_leg_amp = 0.55
	_stride = 4.5
	var skin := _material(Color(0.9, 0.45, 0.15))
	var dark := _material(Color(0.5, 0.22, 0.08))
	var visor := _material(Color(0.1, 0.08, 0.12))
	for side in [-1.0, 1.0]:
		var leg := _pivot(Vector3(side * 0.22, 1.3, 0))
		_box(Vector3(0.2, 0.75, 0.24), Vector3(0, -0.37, 0.04), skin, leg, Vector3(-0.15, 0, 0))
		_box(Vector3(0.16, 0.62, 0.18), Vector3(0, -1.0, -0.06), dark, leg, Vector3(0.2, 0, 0))
		_box(Vector3(0.2, 0.08, 0.36), Vector3(0, -1.3, -0.12), dark, leg)
		_legs.append(leg)
	_torso = _pivot(Vector3(0, 1.4, 0))
	_box(Vector3(0.5, 0.25, 0.36), Vector3.ZERO, dark, _torso)
	_box(Vector3(0.56, 0.9, 0.42), Vector3(0, 0.55, 0), skin, _torso)
	_box(Vector3(0.44, 0.5, 0.08), Vector3(0, 0.6, -0.24), dark, _torso)
	var joint := _material(_weak_color, true)
	_weak.append(joint)
	_box(Vector3(0.3, 0.3, 0.2), Vector3(0, 0.7, 0.28), joint, _torso)
	for side in [-1.0, 1.0]:
		var arm := _pivot(Vector3(side * 0.38, 0.9, 0), _torso)
		_box(Vector3(0.16, 0.7, 0.16), Vector3(0, -0.35, 0), skin, arm)
		_box(Vector3(0.12, 0.3, 0.36), Vector3(0, -0.78, -0.1), dark, arm, Vector3(0.3, 0, 0))
		_arms.append(arm)
	_head = _pivot(Vector3(0, 1.1, 0), _torso)
	_box(Vector3(0.18, 0.25, 0.18), Vector3(0, 0, 0), dark, _head)
	_box(Vector3(0.4, 0.35, 0.5), Vector3(0, 0.28, -0.05), skin, _head)
	_box(Vector3(0.36, 0.08, 0.06), Vector3(0, 0.3, -0.31), visor, _head)
	var crest := _material(_weak_color, true)
	_weak.append(crest)
	_box(Vector3(0.06, 0.55, 0.45), Vector3(0, 0.6, 0.05), crest, _head, Vector3(-0.2, 0, 0))

# --- runtime ----------------------------------------------------------------

## Call every physics frame. `speed` is planar speed; `lean` pitches the torso
## forward (positive) for charges and bursts.
func animate(delta: float, speed: float, lean: float = 0.0) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(0.0, _flash_left - delta)
		if _flash_left <= 0.0:
			_restore_colors()
	_idle += delta
	var moving := clampf(speed / 2.5, 0.0, 1.0)
	_walk += delta * _stride * maxf(speed, 0.0)
	var swing := sin(_walk) * _leg_amp * moving
	for i in _legs.size():
		var phase := 1.0 if (i % 2 == 0) == (i < 2) else -1.0
		_legs[i].rotation.x = swing * phase
	for i in _arms.size():
		_arms[i].rotation.x = -swing * (1.0 if i == 0 else -1.0) * 0.8
	_lean = lerpf(_lean, lean, clampf(delta * 8.0, 0.0, 1.0))
	if _torso:
		var base_y: float = {"fodder": 0.75, "rammer": 1.05, "hunter": 1.4}[kind]
		_torso.position.y = base_y + absf(sin(_walk)) * 0.05 * moving + sin(_idle * 2.2) * 0.012
		_torso.rotation.x = -_lean * 0.35
		_torso.rotation.z = sin(_walk) * 0.04 * moving
	if _head:
		_head.rotation.x = _lean * 0.25 + sin(_idle * 1.7) * 0.03

func flash() -> void:
	_flash_left = 0.1
	for m in _mats:
		m.albedo_color = Color(1.0, 1.0, 1.0)

func _restore_colors() -> void:
	for i in _mats.size():
		_mats[i].albedo_color = _bases[i]
	set_weak_open(_weak_open)

func set_weak_open(open: bool) -> void:
	_weak_open = open
	for m in _weak:
		m.emission_energy_multiplier = 1.6 if open else 0.0
		if _flash_left <= 0.0:
			m.albedo_color = Color(1.0, 0.9, 0.35) if open else _weak_color

## Spawns gibs and a splat into `world`, then the caller frees the enemy.
func burst(world: Node, away: Vector3) -> void:
	if world == null:
		return
	var origin := global_position + Vector3(0, 0.8, 0)
	var gib_mat := StandardMaterial3D.new()
	gib_mat.albedo_color = _gib_color
	gib_mat.roughness = 1.0
	var count: int = {"fodder": 7, "rammer": 12, "hunter": 9}[kind]
	for i in count:
		var chunk := RigidBody3D.new()
		chunk.collision_layer = 0
		chunk.collision_mask = 1
		var size := randf_range(0.14, 0.34)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3.ONE * size
		shape.shape = box
		chunk.add_child(shape)
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3.ONE * size
		bm.material = gib_mat
		mesh.mesh = bm
		chunk.add_child(mesh)
		world.add_child(chunk)
		chunk.global_position = origin + Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.4), randf_range(-0.3, 0.3))
		chunk.linear_velocity = away * randf_range(2.0, 5.0) + Vector3(randf_range(-3, 3), randf_range(3, 7), randf_range(-3, 3))
		chunk.angular_velocity = Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))
		var tween := chunk.create_tween()
		tween.tween_interval(randf_range(1.2, 2.0))
		tween.tween_property(mesh, "scale", Vector3.ZERO, 0.3)
		tween.tween_callback(chunk.queue_free)
	var splat := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	var splat_radius: float = {"fodder": 0.8, "rammer": 1.4, "hunter": 1.0}[kind]
	disc.top_radius = splat_radius
	disc.bottom_radius = disc.top_radius
	disc.height = 0.02
	disc.radial_segments = 7
	var splat_mat := StandardMaterial3D.new()
	splat_mat.albedo_color = _gib_color.darkened(0.25)
	splat_mat.roughness = 1.0
	disc.material = splat_mat
	splat.mesh = disc
	world.add_child(splat)
	splat.global_position = Vector3(global_position.x, global_position.y + 0.015, global_position.z)
	splat.rotation.y = randf() * TAU
	var fade := splat.create_tween()
	fade.tween_interval(12.0)
	fade.tween_property(splat, "scale", Vector3(1, 1, 1) * 0.01, 0.8)
	fade.tween_callback(splat.queue_free)
