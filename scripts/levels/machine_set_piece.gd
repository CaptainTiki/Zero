extends Node3D
## The plant room climax. A set piece like arena_set_piece.gd: drop it into a level.
##
## Walk into the pit and a pipe crashes across the tunnel door behind you. Break the
## coolant pipes on the machine with kicks or shots; the fight starts with a wave and
## every broken pipe but the last sends the next one. The last pipe sends the machine
## critical: clanging, steam, the Commander says get out, the high exit opens, the end
## zone lights up and the escape countdown starts. If it runs out, that is logged and
## the run ends, so playtests stay focused. Losing will restart the level once that exists.
##
## Melee enemies climb out of a hatch on the player's own level, so they have a straight
## line to them; Hunters come out of ranged hatches wherever they can see. Up on the
## walks a Rammer can't follow, so it comes as fodder instead.
##
## The level it sits in is its parent, running scripts/levels/level_base.gd.

const PIPE := preload("res://scripts/props/coolant_pipe.gd")
const FODDER := preload("res://scenes/enemies/fodder.tscn")
const HUNTER := preload("res://scenes/enemies/hunter.tscn")
const RAMMER := preload("res://scenes/enemies/rammer.tscn")
## Enemies sharing a hatch climb out this far apart.
const HATCH_GAP := 0.7

## Box the player walks into to start the fight: centre and size.
@export var start_at := Vector3.ZERO
@export var start_size := Vector3(8, 4, 8)
## The pipe that falls across the way back: where it lands, radius, length along z.
@export var seal_at := Vector3.ZERO
@export var seal_radius := 1.6
@export var seal_length := 6.0
## Where a death respawns the player once the seal is down.
@export var respawn_at := Vector3.ZERO
## Coolant pipes: [centre, size] each.
@export var pipes: Array = []
## One wave for the fight starting, then one per broken pipe except the last:
## [fodder, hunters, rammers], the same order as the arena set piece.
@export var waves: Array = []
## Floor points enemies climb out at. Melee hatches are used by level; ranged ones anywhere.
@export var melee_hatches: Array = []
@export var ranged_hatches: Array = []
## The shut high exit: centre and size of the shutter.
@export var exit_at := Vector3.ZERO
@export var exit_size := Vector3(2.5, 3.2, 0.5)
## The lit pad at the level exit, shown once the machine goes critical.
@export var end_zone_at := Vector3.ZERO
@export var end_zone_size := Vector3(8, 4, 12)
## Where steam jets out when the machine goes critical.
@export var vents: Array = []
@export var escape_seconds := 65.0
## The place falling apart once the machine is critical. Each is a Dictionary: kind "fall"
## (a pipe, beam or crate dropping to rest at "at" with "size") or "steam" (a jet at "at" for
## "duration"). With a "trigger" it fires when the player comes within "radius" of it,
## otherwise "delay" seconds after critical.
@export var escape_events: Array = []
## Red lights that pulse once the machine is critical.
@export var alarms: Array = []
@export var line_start := "COMMANDER: Those are coolant pipes. Break them."
@export var line_critical := "COMMANDER: That's done it. Now get out of there."

enum State { WAITING, FIGHT, CRITICAL, DONE }

var state := State.WAITING
var escape_left := 0.0
var _level: Node
var _player: Node3D
var _broken := 0
var _pipe_nodes: Array = []
var _exit: StaticBody3D
var _exit_lamp: MeshInstance3D
var _end_zone: Node3D
var _steam: Array = []
var _clang_in := 0.0
var _line_left := 0.0
## [seconds until it climbs out, scene, position]
var _queue: Array = []
var _melee_turn := 0
var _since_critical := -1.0
var _fired := {}
var _alarm_lights: Array = []
var _ranged_turn := 0

func _ready() -> void:
	_level = get_parent()
	# Children are ready before their parent, so the level's kill total picks these up.
	var total := 0
	for wave in waves:
		total += int(wave[0]) + int(wave[1]) + int(wave[2])
	if _level and "extra_expected_kills" in _level:
		_level.extra_expected_kills += total
	for i in pipes.size():
		var pipe := StaticBody3D.new()
		pipe.set_script(PIPE)
		pipe.name = "CoolantPipe%d" % (i + 1)
		pipe.set("size", pipes[i][1])
		pipe.position = pipes[i][0]
		add_child(pipe)
		pipe.connect("broken", _on_pipe_broken)
		_pipe_nodes.append(pipe)
	_build_exit()
	_build_start()
	_build_end_zone()
	for at in vents:
		_steam.append(_steam_jet(at))
	var lids := {}
	for at in melee_hatches + ranged_hatches:
		lids[at] = true
	for at in lids:
		_hatch(at)
	for at in alarms:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.12, 0.08)
		lamp.light_energy = 0.0
		lamp.omni_range = 22.0
		lamp.distance_fade_enabled = true
		lamp.distance_fade_begin = 45.0
		lamp.distance_fade_length = 10.0
		lamp.position = at
		lamp.visible = false
		add_child(lamp)
		_alarm_lights.append(lamp)
	for area in get_tree().get_nodes_in_group("level_exit"):
		area.body_entered.connect(_on_exit)

## For the route test: the machine is already broken and the way out is open. With
## escape_events true the place still falls apart round the walker, but no clock runs.
func skip(with_escape_events := false) -> void:
	state = State.CRITICAL if with_escape_events else State.DONE
	escape_left = INF
	for pipe in _pipe_nodes:
		pipe.is_broken = true
	_open_exit()
	if with_escape_events:
		_since_critical = 0.0

func _process(delta: float) -> void:
	_release_queue(delta)
	if _since_critical >= 0.0:
		_since_critical += delta
		_run_escape_events()
	if state != State.CRITICAL:
		return
	for lamp in _alarm_lights:
		lamp.visible = true
		lamp.light_energy = 2.5 + sin(Time.get_ticks_msec() * 0.008) * 2.5
	if escape_left == INF:
		return
	escape_left -= delta
	_line_left -= delta
	if _line_left <= 0.0:
		_hint("GET OUT  %d" % int(ceil(maxf(escape_left, 0.0))))
	_clang_in -= delta
	if _clang_in <= 0.0:
		_clang_in = randf_range(0.5, 1.3)
		var bank := get_tree().root.get_node_or_null("Sound")
		if bank and not vents.is_empty():
			bank.play_at("kick_prop", vents[randi() % vents.size()], 2.0)
	if _end_zone:
		_end_zone.scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.08
	if escape_left <= 0.0:
		state = State.DONE
		_log("escape timer ran out")
		if _level and _level.has_method("finish"):
			_level.finish()

func _on_enter(body: Node) -> void:
	if state == State.WAITING and body.is_in_group("player"):
		_start(body)

func _start(body: Node) -> void:
	state = State.FIGHT
	_player = body as Node3D
	if body and "respawn_point" in body:
		body.set("respawn_point", respawn_at)
	_drop_seal()
	_hint(line_start)
	_log("machine fight started, way back sealed")
	_send_wave(0)

func _on_pipe_broken(_pipe: Node) -> void:
	if state == State.DONE:
		return
	if state == State.WAITING:
		_start(get_tree().get_first_node_in_group("player"))
	_broken += 1
	_log("coolant pipe %d / %d broken" % [_broken, _pipe_nodes.size()])
	if _broken < _pipe_nodes.size():
		_hint("COOLANT PIPES  %d / %d" % [_broken, _pipe_nodes.size()])
		_send_wave(_broken)
	else:
		_critical()

func _critical() -> void:
	state = State.CRITICAL
	escape_left = escape_seconds
	_line_left = 4.0
	_hint(line_critical)
	for jet in _steam:
		jet.emitting = true
	_open_exit()
	if _end_zone:
		_end_zone.visible = true
	_since_critical = 0.0
	_log("machine critical, escape countdown %d s" % int(escape_seconds))

func _on_exit(body: Node) -> void:
	if state == State.CRITICAL and body.is_in_group("player"):
		state = State.DONE
		_log("escaped with %.1f s left" % escape_left)
		_hint("")

func _send_wave(index: int) -> void:
	if index >= waves.size():
		return
	var spec: Array = waves[index]
	var fodder := int(spec[0])
	var hunters := int(spec[1])
	var rammers := int(spec[2])
	var floor_y := _player.global_position.y if _player else start_at.y
	# A Rammer is too wide for the walks, so up there it comes as fodder.
	if floor_y > 2.0:
		fodder += rammers
		rammers = 0
	var melee := _hatches_on_level(floor_y)
	var used := {}
	for i in fodder + rammers:
		var at: Vector3 = melee[_melee_turn % melee.size()]
		_melee_turn += 1
		_enqueue(FODDER if i < fodder else RAMMER, at, used)
	for i in hunters:
		var at: Vector3 = ranged_hatches[_ranged_turn % ranged_hatches.size()]
		_ranged_turn += 1
		_enqueue(HUNTER, at, used)
	_log("wave %d / %d: %d fodder, %d hunters, %d rammers" % [index + 1, waves.size(), fodder, hunters, rammers])

## Melee hatches on the level the player stands on; failing that, the nearest level.
func _hatches_on_level(floor_y: float) -> Array:
	var best := INF
	for at in melee_hatches:
		best = minf(best, absf((at as Vector3).y - floor_y))
	var picked := []
	for at in melee_hatches:
		if absf((at as Vector3).y - floor_y) <= best + 1.0:
			picked.append(at)
	return picked

func _enqueue(scene: PackedScene, at: Vector3, used: Dictionary) -> void:
	var n: int = used.get(at, 0)
	used[at] = n + 1
	_queue.append([n * HATCH_GAP, scene, at])

func _release_queue(delta: float) -> void:
	var i := 0
	while i < _queue.size():
		_queue[i][0] -= delta
		if _queue[i][0] <= 0.0:
			var enemy: Node3D = (_queue[i][1] as PackedScene).instantiate()
			add_child(enemy)
			enemy.global_position = (_queue[i][2] as Vector3) + Vector3(0, 0.4, 0)
			enemy.set("_alerted", true)
			_queue.remove_at(i)
		else:
			i += 1

# --- the place falling apart ---------------------------------------------------

func _run_escape_events() -> void:
	for i in escape_events.size():
		if _fired.has(i):
			continue
		var ev: Dictionary = escape_events[i]
		if ev["trigger"] == null:
			if _since_critical >= float(ev["delay"]):
				_fire(i, ev)
			continue
		var point: Vector3 = ev["trigger"]
		for body in get_tree().get_nodes_in_group("player"):
			var p: Vector3 = (body as Node3D).global_position
			if Vector2(p.x - point.x, p.z - point.z).length() <= float(ev["radius"]) and absf(p.y - point.y) < 3.0:
				_fire(i, ev)
				break

func _fire(index: int, ev: Dictionary) -> void:
	_fired[index] = true
	_log("escape %s at %s" % [String(ev["kind"]), ev["at"]])
	if String(ev["kind"]) == "fall":
		_fall(ev["at"], ev["size"])
	else:
		_steam_burst(ev["at"], float(ev["duration"]))

## Drops a pipe, beam or crate from above. It only becomes solid once it has landed, so it
## can't fall through, or onto, anything standing in the way.
func _fall(at: Vector3, size: Vector3) -> void:
	var piece := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.disabled = true
	piece.add_child(shape)
	var mesh := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = size
	mesh.mesh = slab
	mesh.material_override = load("res://materials/retro/rust.tres")
	piece.add_child(mesh)
	add_child(piece)
	piece.position = at + Vector3(0, 11.0, 0)
	piece.rotation.y = randf_range(-0.05, 0.05)
	var drop := create_tween()
	drop.tween_property(piece, "position:y", at.y, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_callback(func() -> void:
		shape.disabled = false
		var bank := get_tree().root.get_node_or_null("Sound")
		if bank:
			bank.play_at("kick_prop", at, 6.0)
		var burst := _steam_jet(at + Vector3(0, size.y / 2.0, 0))
		burst.one_shot = true
		burst.amount = 24
		burst.initial_velocity_max = 4.0
		burst.emitting = true
		_shake_near(at))

func _steam_burst(at: Vector3, duration: float) -> void:
	var jet := _steam_jet(at)
	jet.emitting = true
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.play_at("weak_hit", at, 4.0)
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		if is_instance_valid(jet):
			jet.emitting = false)

func _shake_near(at: Vector3) -> void:
	for body in get_tree().get_nodes_in_group("player"):
		var camera = body.get("camera")
		if camera == null or (body as Node3D).global_position.distance_to(at) > 14.0:
			continue
		var start: Vector3 = camera.position
		var tw := create_tween()
		tw.tween_property(camera, "position", start + Vector3(0.12, -0.08, 0.0), 0.05)
		tw.tween_property(camera, "position", start + Vector3(-0.08, 0.05, 0.0), 0.06)
		tw.tween_property(camera, "position", start, 0.1)

# --- greybox pieces ------------------------------------------------------------

func _build_start() -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = start_size
	shape.shape = box
	area.add_child(shape)
	area.position = start_at
	add_child(area)
	area.body_entered.connect(_on_enter)

func _build_exit() -> void:
	_exit = StaticBody3D.new()
	_exit.position = exit_at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = exit_size
	shape.shape = box
	_exit.add_child(shape)
	var mesh := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = exit_size
	mesh.mesh = slab
	mesh.material_override = load("res://materials/retro/metal_blue.tres")
	_exit.add_child(mesh)
	add_child(_exit)
	_exit_lamp = MeshInstance3D.new()
	var bulb := BoxMesh.new()
	bulb.size = Vector3(0.5, 0.3, 0.3)
	_exit_lamp.mesh = bulb
	_exit_lamp.material_override = _glow(Color(1.0, 0.15, 0.1))
	_exit_lamp.position = exit_at + Vector3(0, exit_size.y / 2.0 + 0.35, 0)
	add_child(_exit_lamp)

func _open_exit() -> void:
	if _exit and is_instance_valid(_exit):
		for child in _exit.get_children():
			if child is CollisionShape3D:
				child.set_deferred("disabled", true)
		var lift := create_tween()
		lift.tween_property(_exit, "position:y", exit_at.y + exit_size.y + 0.2, 1.2)
	if _exit_lamp:
		_exit_lamp.material_override = _glow(Color(0.2, 1.0, 0.3))
	if _level and _level.has_method("open_exit"):
		_level.open_exit()

## A glowing pad and a tall light column over the level exit, so the way out can be
## seen from across the truck yard. Hidden until the machine goes critical.
func _build_end_zone() -> void:
	_end_zone = Node3D.new()
	_end_zone.visible = false
	add_child(_end_zone)
	var floor_y := end_zone_at.y - end_zone_size.y / 2.0
	_end_zone.position = Vector3(end_zone_at.x, floor_y, end_zone_at.z)
	var pad := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(end_zone_size.x, 0.06, end_zone_size.z)
	pad.mesh = plate
	pad.material_override = _glow(Color(0.25, 1.0, 0.4))
	pad.position.y = 0.04
	_end_zone.add_child(pad)
	var column := MeshInstance3D.new()
	var beam := BoxMesh.new()
	beam.size = Vector3(end_zone_size.x * 0.8, 24.0, end_zone_size.z * 0.8)
	column.mesh = beam
	var haze := StandardMaterial3D.new()
	haze.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	haze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	haze.cull_mode = BaseMaterial3D.CULL_DISABLED
	haze.albedo_color = Color(0.3, 1.0, 0.45, 0.18)
	column.material_override = haze
	column.position.y = 12.0
	_end_zone.add_child(column)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(0.4, 1.0, 0.5)
	lamp.light_energy = 3.0
	lamp.omni_range = 14.0
	lamp.position.y = 2.5
	_end_zone.add_child(lamp)

func _drop_seal() -> void:
	var seal := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = seal_radius
	cylinder.height = seal_length
	shape.shape = cylinder
	seal.add_child(shape)
	var mesh := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = seal_radius
	tube.bottom_radius = seal_radius
	tube.height = seal_length
	tube.radial_segments = 12
	mesh.mesh = tube
	mesh.material_override = load("res://materials/retro/rust.tres")
	seal.add_child(mesh)
	# Lying along z, across the doorway.
	seal.rotation.x = PI / 2.0
	add_child(seal)
	seal.position = seal_at + Vector3(0, 12.0, 0)
	var drop := create_tween()
	drop.tween_property(seal, "position:y", seal_at.y, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_callback(func() -> void:
		var bank := get_tree().root.get_node_or_null("Sound")
		if bank:
			bank.play_at("kick_prop", seal.global_position, 6.0))

func _steam_jet(at: Vector3) -> CPUParticles3D:
	var jet := CPUParticles3D.new()
	jet.emitting = false
	jet.amount = 40
	jet.lifetime = 1.2
	jet.direction = Vector3(0, 1, 0)
	jet.spread = 15.0
	jet.initial_velocity_min = 6.0
	jet.initial_velocity_max = 9.0
	jet.damping_min = 2.0
	jet.damping_max = 4.0
	jet.scale_amount_min = 0.8
	jet.scale_amount_max = 2.0
	var puff := QuadMesh.new()
	puff.size = Vector2(0.8, 0.8)
	var steam := StandardMaterial3D.new()
	steam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	steam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	steam.albedo_color = Color(0.95, 0.95, 0.95, 0.5)
	puff.material = steam
	jet.mesh = puff
	jet.position = at
	add_child(jet)
	return jet

func _hatch(at: Vector3) -> void:
	var lid := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(1.6, 0.06, 1.6)
	lid.mesh = plate
	lid.material_override = load("res://materials/retro/dark.tres")
	lid.position = at + Vector3(0, 0.03, 0)
	add_child(lid)

func _glow(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.0
	return m

func _hint(text: String) -> void:
	if _level and _level.has_method("set_hint"):
		_level.set_hint(text)

func _log(text: String) -> void:
	var tag: String = _level.level_tag if _level and "level_tag" in _level else "LEVEL"
	var at: String = _level.stamp(_level.clock()) if _level and _level.has_method("stamp") else "?"
	print("%s %s at %s" % [tag, text, at])
