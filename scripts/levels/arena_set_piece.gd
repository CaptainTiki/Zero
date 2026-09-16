extends Node3D
## A set piece, not a kind of level: drop this node into a level and the plaza
## arena happens there. It listens for a beat line, seals the way back, and has a
## saucer beam enemies down in clumps until the waves run out, then opens the lift.
##
## The level it sits in is its parent, running scripts/levels/level_base.gd.

const FODDER := preload("res://scenes/enemies/fodder.tscn")
const HUNTER := preload("res://scenes/enemies/hunter.tscn")
const RAMMER := preload("res://scenes/enemies/rammer.tscn")

## [fodder, hunters, rammers] per wave.
@export var waves: Array = [[3, 0, 0], [4, 0, 0], [4, 1, 0], [5, 0, 0], [3, 0, 1], [4, 2, 0], [6, 1, 0]]
@export var wave_spacing := 7.0
@export var first_wave_delay := 2.5
## Armed when this beat line is crossed, sealed when the player is properly inside.
@export var arm_on_beat := 8
@export var seal_point := Vector3(150, 0, -88)
@export var seal_radius := 14.0
## Where the greybox seal brick lands, and how big it is.
@export var seal_at := Vector3(170, 2.25, -67.5)
@export var seal_size := Vector3(9, 4.5, 3)
@export var lift_delay_after_last := 12.0
@export var saucer_height := 38.0
@export var saucer_park := Vector3(190, 44.0, -140)
@export var beam_spots: Array[Vector3] = [
	Vector3(140, 0.15, -80), Vector3(162, 0.15, -78), Vector3(165, 0.15, -100),
	Vector3(138, 0.15, -104), Vector3(150, 0.15, -90), Vector3(158, 0.15, -106),
]

var _level: Node
var _armed := false
var _started := false
var _wave_index := 0
var _wave_timer := 0.0
var _lift_timer := -1.0
var _saucer: Node3D
var _saucer_target := Vector3.ZERO
var _beam: MeshInstance3D
var _beam_left := 0.0
var _player: Node3D

func _ready() -> void:
	_level = get_parent()
	# Children are ready before their parent, so the level's kill total picks this up.
	var total := 0
	for w in waves:
		total += int(w[0]) + int(w[1]) + int(w[2])
	if _level and "extra_expected_kills" in _level:
		_level.extra_expected_kills += total
	if _level and _level.has_signal("beat_reached"):
		_level.beat_reached.connect(_on_beat)
	_build_saucer()

func _on_beat(beat: int, _elapsed: float) -> void:
	if beat != arm_on_beat:
		return
	if _level and "arena_enabled" in _level and not _level.arena_enabled:
		return
	_armed = true
	_player = get_tree().get_first_node_in_group("player") as Node3D

func _process(delta: float) -> void:
	_update_saucer(delta)
	if _armed and not _started and _player:
		var flat := Vector2(_player.global_position.x - seal_point.x, _player.global_position.z - seal_point.z)
		if flat.length() < seal_radius:
			_start()
	if _started and _wave_index < waves.size():
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_send_wave(waves[_wave_index])
			_wave_index += 1
			_wave_timer = wave_spacing
			if _wave_index == waves.size():
				_lift_timer = lift_delay_after_last
				_say_hint("LAST WAVE DOWN. LIFT ON ITS WAY.")
			else:
				_say_hint("WAVE %d / %d" % [_wave_index, waves.size()])
	if _lift_timer > 0.0:
		_lift_timer -= delta
		if _lift_timer <= 0.0 and _level and _level.has_method("open_lift"):
			_level.open_lift()

func _say_hint(text: String) -> void:
	if _level and _level.has_method("set_hint"):
		_level.set_hint(text)

func _stamp() -> String:
	if _level and _level.has_method("stamp"):
		return _level.stamp(_level.clock())
	return "?"

func _start() -> void:
	if _started:
		return
	_started = true
	_wave_timer = first_wave_delay
	# Seal the way back behind the player. Greybox: a brick falls in. Later: a bus.
	var seal := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = seal_size
	shape.shape = box
	seal.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	bm.material = load("res://materials/retro/brick_dark.tres")
	mesh.mesh = bm
	seal.add_child(mesh)
	add_child(seal)
	seal.global_position = Vector3(seal_at.x, seal_at.y + 11.75, seal_at.z)
	var drop := create_tween()
	drop.tween_property(seal, "global_position:y", seal_at.y, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_callback(func() -> void:
		var bank := get_tree().root.get_node_or_null("Sound")
		if bank:
			bank.play_at("gib", seal.global_position, 6.0))
	_say_hint("THEY'VE SEALED THE PLAZA")
	print("arena sealed at %s" % _stamp())

func _send_wave(spec: Array) -> void:
	var spot: Vector3 = beam_spots[_wave_index % beam_spots.size()]
	_saucer_target = Vector3(spot.x, saucer_height, spot.z)
	_beam.global_position = Vector3(spot.x, saucer_height / 2.0, spot.z)
	_beam.visible = true
	_beam_left = 1.6
	var count := 0
	for kind in [[FODDER, spec[0]], [HUNTER, spec[1]], [RAMMER, spec[2]]]:
		for i in kind[1]:
			var e: Node3D = kind[0].instantiate()
			add_child(e)
			var angle := TAU * float(count) / maxf(float(spec[0] + spec[1] + spec[2]), 1.0)
			e.global_position = spot + Vector3(cos(angle) * 1.8, 6.0, sin(angle) * 1.8)
			e.set("_alerted", true)
			count += 1
	print("arena wave %d beamed down at %s: %s" % [_wave_index + 1, _stamp(), spec])

# --- saucer and beam (greybox placeholders) -----------------------------------

func _build_saucer() -> void:
	_saucer = Node3D.new()
	var hull := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 4.0
	disc.bottom_radius = 7.0
	disc.height = 1.6
	disc.radial_segments = 12
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.37, 0.4)
	m.metallic = 0.6
	m.roughness = 0.4
	disc.material = m
	hull.mesh = disc
	_saucer.add_child(hull)
	var dome := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 2.5
	dm.height = 3.0
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.5, 0.9, 1.0)
	dmat.emission_enabled = true
	dmat.emission = Color(0.3, 0.8, 1.0)
	dmat.emission_energy_multiplier = 1.5
	dm.material = dmat
	dome.mesh = dm
	dome.position.y = 1.4
	_saucer.add_child(dome)
	add_child(_saucer)
	_saucer.global_position = saucer_park
	_saucer_target = _saucer.global_position
	_beam = MeshInstance3D.new()
	var beam := CylinderMesh.new()
	beam.top_radius = 3.0
	beam.bottom_radius = 4.0
	beam.height = saucer_height
	beam.radial_segments = 12
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.4, 0.9, 1.0, 0.35)
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material = bmat
	_beam.mesh = beam
	_beam.visible = false
	add_child(_beam)

func _update_saucer(delta: float) -> void:
	if _saucer == null:
		return
	_saucer.global_position = _saucer.global_position.lerp(_saucer_target, clampf(delta * 2.5, 0.0, 1.0))
	_saucer.rotation.y += delta * 0.8
	if _beam_left > 0.0:
		_beam_left -= delta
		_beam.scale.x = 1.0 + sin(Time.get_ticks_msec() * 0.03) * 0.06
		_beam.scale.z = _beam.scale.x
		if _beam_left <= 0.0:
			_beam.visible = false
