extends Node3D
## Level 01 greybox runtime: run timer, beat-line timestamps, run stats, and the
## plaza arena. Entering the plaza seals the walkway behind the player; a saucer
## then beams enemies down in clumps at spots around the plaza, in view, every few
## seconds. The lift opens shortly after the last wave is sent.

const FODDER := preload("res://scenes/enemies/fodder.tscn")
const HUNTER := preload("res://scenes/enemies/hunter.tscn")
const RAMMER := preload("res://scenes/enemies/rammer.tscn")

## [fodder, hunters, rammers] per wave; spacing in seconds between waves.
const WAVES := [[3, 0, 0], [4, 0, 0], [4, 1, 0], [5, 0, 0], [3, 0, 1], [4, 2, 0], [6, 1, 0]]
const WAVE_SPACING := 7.0
const FIRST_WAVE_DELAY := 2.5
## The seal waits until the player is properly inside the plaza, not on the line.
const SEAL_POINT := Vector3(150, 0, -88)
const SEAL_RADIUS := 14.0
const LIFT_DELAY_AFTER_LAST := 12.0
const BEAM_SPOTS := [Vector3(140, 0.15, -80), Vector3(162, 0.15, -78), Vector3(165, 0.15, -100), Vector3(138, 0.15, -104), Vector3(150, 0.15, -90), Vector3(158, 0.15, -106)]
const SAUCER_HEIGHT := 38.0
## Par for Mission 01 with acts 2 and 3 (west district, storm drains) in place.
## Retune against playtest times; 12:00 is the middle of the ten-to-fifteen band.
const PAR_TIME := 720.0 # 12:00. Full time credit at or under par, fading to none at double par.
const WEIGHT_KILLS := 0.4
const WEIGHT_SECRETS := 0.4
const WEIGHT_TIME := 0.2

var arena_enabled := true
var _elapsed := 0.0
var _label: Label
var _hint: Label
var _stats_label: Label
var _reached := {}
var _finished := false
var _arena_started := false
var _arena_armed := false
var _player: Node3D
var _wave_index := 0
var _wave_timer := 0.0
var _lift_open := false
var _lift_timer := -1.0
var _saucer: Node3D
var _saucer_target := Vector3.ZERO
var _beam: MeshInstance3D
var _beam_left := 0.0
var _kills := 0
var _shots := {"pistol": 0, "shotgun": 0}
var _damage_taken := 0.0
var _secrets_found := 0
var _secrets_total := 0
var _kills_total := 0
var _debug_visible := true
var _kills_at_beat := {}
var _beacons: Array[Node3D] = []
var _debug: CanvasLayer
var _tally: Label

func _ready() -> void:
	add_to_group("run_stats")
	var overlay := CanvasLayer.new()
	overlay.layer = 6
	add_child(overlay)
	# Debug readout: top-right, toggled with the backquote key.
	_debug = CanvasLayer.new()
	_debug.layer = 7
	add_child(_debug)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.offset_left = -520.0
	_label.offset_right = -16.0
	_label.offset_top = 16.0
	_label.offset_bottom = 44.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.add_theme_font_size_override("font_size", 18)
	_debug.add_child(_label)
	_stats_label = Label.new()
	_stats_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_stats_label.offset_left = -820.0
	_stats_label.offset_right = -16.0
	_stats_label.offset_top = 44.0
	_stats_label.offset_bottom = 120.0
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stats_label.add_theme_font_size_override("font_size", 14)
	_stats_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	_debug.add_child(_stats_label)
	_tally = Label.new()
	_tally.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_tally.offset_left = -300.0
	_tally.offset_right = 300.0
	_tally.offset_top = -120.0
	_tally.offset_bottom = 120.0
	_tally.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tally.add_theme_font_size_override("font_size", 28)
	_tally.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_tally.visible = false
	overlay.add_child(_tally)
	_hint = Label.new()
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_hint.offset_top = 40
	_hint.add_theme_font_size_override("font_size", 26)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(_hint)
	for area in get_tree().get_nodes_in_group("beat_lines"):
		area.body_entered.connect(_on_beat_line.bind(area))
	for area in get_tree().get_nodes_in_group("level_exit"):
		area.body_entered.connect(_on_exit)
	for area in get_tree().get_nodes_in_group("secrets"):
		area.body_entered.connect(_on_secret.bind(area))
	for area in get_tree().get_nodes_in_group("ambush"):
		area.body_entered.connect(_on_ambush.bind(area))
	_secrets_total = get_tree().get_nodes_in_group("secrets").size()
	var wave_total := 0
	for w in WAVES:
		wave_total += w[0] + w[1] + w[2]
	var ambush_total := 0
	for area in get_tree().get_nodes_in_group("ambush"):
		ambush_total += int(area.get_meta("count"))
	_kills_total = get_tree().get_nodes_in_group("enemies").size() + wave_total + ambush_total
	_push_progress()
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.start_ambience("ambience_wind")
	_build_saucer()
	print("L01 greybox: timer started")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle", false, true):
		_debug_visible = not _debug_visible
		_debug.visible = _debug_visible
	if event.is_action_pressed("hud_toggle", false, true):
		_hint.visible = not _hint.visible
	if _finished and _tally.visible and event.is_action_pressed("ui_cancel"):
		# Esc drops the end screen and hands the mouse back to the game.
		_tally.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	_label.text = "L01  %s" % _stamp(_elapsed)
	_update_stats_label()
	_update_saucer(delta)
	if _arena_armed and not _arena_started and _player and Vector2(_player.global_position.x - SEAL_POINT.x, _player.global_position.z - SEAL_POINT.z).length() < SEAL_RADIUS:
		_start_arena()
	if _arena_started and _wave_index < WAVES.size():
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_send_wave(WAVES[_wave_index])
			_wave_index += 1
			_wave_timer = WAVE_SPACING
			if _wave_index == WAVES.size():
				_lift_timer = LIFT_DELAY_AFTER_LAST
				_hint.text = "LAST WAVE DOWN. LIFT ON ITS WAY."
			else:
				_hint.text = "WAVE %d / %d" % [_wave_index, WAVES.size()]
	if _lift_timer > 0.0:
		_lift_timer -= delta
		if _lift_timer <= 0.0:
			open_lift()

# --- stats ---------------------------------------------------------------------

func record_shot(kind: String) -> void:
	_shots[kind] = _shots.get(kind, 0) + 1

func record_kill() -> void:
	_kills += 1
	_push_progress()

func _push_progress() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.get("hud") and player.hud.has_method("set_progress"):
		player.hud.set_progress(_secrets_found, _secrets_total, _kills, _kills_total)

func _on_secret(body: Node, area: Area3D) -> void:
	if not body.is_in_group("player"):
		return
	_secrets_found += 1
	print("L01 secret %d/%d at %s (%s)" % [_secrets_found, _secrets_total, _stamp(_elapsed), area.name])
	_hint.text = "SECRET FOUND  %d / %d" % [_secrets_found, _secrets_total]
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.play("boost")
	area.queue_free()
	_push_progress()

## Dead ends bite on the way out: enemies pour in behind the player.
func _on_ambush(body: Node, area: Area3D) -> void:
	if not body.is_in_group("player"):
		return
	var spawn: Vector3 = area.get_meta("spawn")
	var count: int = int(area.get_meta("count"))
	for i in count:
		var e := FODDER.instantiate()
		add_child(e)
		e.global_position = spawn + Vector3(randf_range(-1.5, 1.5), 0.5, randf_range(-1.5, 1.5))
		e.set("_alerted", true)
	print("L01 ambush %s: %d at %s" % [area.name, count, _stamp(_elapsed)])
	area.queue_free()

func record_damage(amount: float) -> void:
	_damage_taken += amount

func _update_stats_label() -> void:
	var minutes := maxf(_elapsed / 60.0, 1.0 / 60.0)
	_stats_label.text = "shots  pistol %d  shotgun %d   |   kills %d  (%.1f/min)   |   damage taken %d" % [_shots["pistol"], _shots["shotgun"], _kills, _kills / minutes, int(_damage_taken)]

func _stats_summary() -> String:
	var minutes := maxf(_elapsed / 60.0, 1.0 / 60.0)
	return "pistol %d, shotgun %d, kills %d (%.1f/min), damage taken %d" % [_shots["pistol"], _shots["shotgun"], _kills, _kills / minutes, int(_damage_taken)]

func _stamp(t: float) -> String:
	return "%d:%02d" % [int(t / 60.0), int(t) % 60]

# --- beats and arena -------------------------------------------------------------

func _on_beat_line(body: Node, area: Area3D) -> void:
	if not body.is_in_group("player"):
		return
	var beat: int = area.get_meta("beat")
	if _reached.has(beat):
		return
	_reached[beat] = _elapsed
	_kills_at_beat[beat] = _kills
	print("L01 beat %d reached at %s  (kills so far %d)" % [beat, _stamp(_elapsed), _kills])
	if beat == 8 and arena_enabled:
		_arena_armed = true
		_player = body as Node3D

func _start_arena() -> void:
	if _arena_started:
		return
	_arena_started = true
	_wave_timer = FIRST_WAVE_DELAY
	# Seal the walkway behind the player. Greybox: a brick falls in. Later: a bus.
	var seal := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(9, 4.5, 3)
	shape.shape = box
	seal.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	bm.material = load("res://materials/retro/brick_dark.tres")
	mesh.mesh = bm
	seal.add_child(mesh)
	add_child(seal)
	seal.global_position = Vector3(170, 14.0, -67.5)
	var drop := create_tween()
	drop.tween_property(seal, "global_position:y", 2.25, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_callback(func() -> void:
		var bank := get_tree().root.get_node_or_null("Sound")
		if bank:
			bank.play_at("gib", seal.global_position, 6.0))
	_hint.text = "THEY'VE SEALED THE PLAZA"
	print("L01 arena sealed at %s" % _stamp(_elapsed))

func _send_wave(spec: Array) -> void:
	var spot: Vector3 = BEAM_SPOTS[_wave_index % BEAM_SPOTS.size()]
	_saucer_target = Vector3(spot.x, SAUCER_HEIGHT, spot.z)
	_beam.global_position = Vector3(spot.x, SAUCER_HEIGHT / 2.0, spot.z)
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
	print("L01 wave %d beamed down at %s: %s" % [_wave_index + 1, _stamp(_elapsed), spec])

# --- saucer and beam (greybox placeholders) ---------------------------------------

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
	_saucer.global_position = Vector3(190, SAUCER_HEIGHT + 6.0, -140)
	_saucer_target = _saucer.global_position
	_beam = MeshInstance3D.new()
	var beam := CylinderMesh.new()
	beam.top_radius = 3.0
	beam.bottom_radius = 4.0
	beam.height = SAUCER_HEIGHT
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
		_beam.scale.x = 1.0 + sin(_elapsed * 30.0) * 0.06
		_beam.scale.z = _beam.scale.x
		if _beam_left <= 0.0:
			_beam.visible = false

# --- lift and finish --------------------------------------------------------------

func open_lift() -> void:
	if _lift_open:
		return
	_lift_open = true
	_hint.text = "LIFT HERE"
	print("L01 lift arrived at %s" % _stamp(_elapsed))
	var solid := get_node_or_null("LiftDoorSolid")
	if solid:
		solid.queue_free()
	var visual := get_node_or_null("LiftDoor") as Node3D
	if visual:
		var tween := create_tween()
		tween.tween_property(visual, "position:y", visual.position.y + 5.0, 0.9)
		tween.tween_callback(visual.queue_free)

func _on_exit(body: Node) -> void:
	if _finished or not _lift_open or not body.is_in_group("player"):
		return
	_finished = true
	print("L01 finished at %s  [%s]  secrets %d/%d kills %d/%d" % [_stamp(_elapsed), _stats_summary(), _secrets_found, _secrets_total, _kills, _kills_total])
	_print_kills_per_beat()
	_hint.text = ""
	_label.text = "PLAYTEST COMPLETE  %s" % _stamp(_elapsed)
	var kill_part := WEIGHT_KILLS * float(_kills) / maxf(float(_kills_total), 1.0)
	var secret_part := WEIGHT_SECRETS * float(_secrets_found) / maxf(float(_secrets_total), 1.0)
	var time_part := WEIGHT_TIME * clampf(1.0 - maxf(_elapsed - PAR_TIME, 0.0) / PAR_TIME, 0.0, 1.0)
	var complete := 100.0 * (kill_part + secret_part + time_part)
	var par_note := "UNDER PAR" if _elapsed <= PAR_TIME else "OVER PAR"
	_tally.text = "LEVEL 01 PLAYTEST  (one section of Mission 01)\n\nTIME  %s   (par %s, %s)\nKILLS  %d / %d\nSECRETS  %d / %d\n\nMAP COMPLETE  %d%%\n\nEsc to continue and look around" % [_stamp(_elapsed), _stamp(PAR_TIME), par_note, _kills, _kills_total, _secrets_found, _secrets_total, int(round(complete))]
	_tally.visible = true
	_mark_survivors()

## Kills between consecutive beat lines: shows where the player was exploring, not fighting.
func _print_kills_per_beat() -> void:
	var beats := _kills_at_beat.keys()
	beats.sort()
	var last_time := 0.0
	var last_kills := 0
	var lines := []
	for beat in beats:
		var t: float = _reached[beat]
		var k: int = _kills_at_beat[beat]
		lines.append("  to beat %d: %s, %d kills" % [beat, _stamp(t - last_time), k - last_kills])
		last_time = t
		last_kills = k
	lines.append("  to finish: %s, %d kills" % [_stamp(_elapsed - last_time), _kills - last_kills])
	print("L01 kills per segment:\n" + "\n".join(lines))

## Tall beacons over any enemy still alive so a missed kill can be found.
func _mark_survivors() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 1.0, 1.0, 0.55)
	m.emission_enabled = true
	m.emission = Color(0.2, 0.9, 1.0)
	m.emission_energy_multiplier = 2.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D):
			continue
		var beacon := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.25
		mesh.bottom_radius = 0.6
		mesh.height = 60.0
		mesh.radial_segments = 6
		mesh.material = m
		beacon.mesh = mesh
		add_child(beacon)
		beacon.global_position = e.global_position + Vector3(0, 30.0, 0)
		_beacons.append(beacon)
		print("L01 survivor: %s at %s" % [e.name, e.global_position])
