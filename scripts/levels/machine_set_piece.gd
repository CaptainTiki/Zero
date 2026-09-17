extends Node3D
## The plant room climax: the smog machine's pressure arms. A set piece like
## arena_set_piece.gd: drop it into a level.
##
## Six arms reach from the machine's roof edge down into sockets in the pit floor, each with a
## coolant pipe at its foot. Walk into the pit and a pipe crashes across the tunnel door. Then,
## one arm at a time in `order`:
##   pressure builds: steam from the pit vents and a hiss, stronger the longer it goes;
##   the arm's beacon spins and the alarm sounds;
##   the arm comes down and plugs in, which releases the pressure;
##   you break its pipe, kicks or shots;
##   the arm lifts with steam from both broken ends, and its wave climbs out.
## The next arm starts once that wave is dead, or when `pressure_seconds` force it. After the
## last pipe the Commander sends you up to the button on the roof. Kicking it sends the machine
## critical: steam, shaking, the high exit opens, the end zone lights and the escape countdown
## starts. If the countdown runs out, that is logged and the run ends, so playtests stay
## focused. Losing will restart the level once that exists.
##
## Melee enemies climb out of a hatch on the player's own level, so they have a straight line
## to them; up on the walks a Rammer can't follow, so it comes as fodder. A melee enemy left
## on another level from the player climbs out again on theirs.
##
## The level it sits in is its parent, running scripts/levels/level_base.gd. It sits at the
## world origin, so every point here is a world point.

const ARM := preload("res://scripts/props/pressure_arm.gd")
const BUTTON := preload("res://scripts/props/kick_button.gd")
const FODDER := preload("res://scenes/enemies/fodder.tscn")
const HUNTER := preload("res://scenes/enemies/hunter.tscn")
const RAMMER := preload("res://scenes/enemies/rammer.tscn")
## Enemies sharing a hatch climb out this far apart.
const HATCH_GAP := 0.7
## Levels here are 4 apart; an enemy more than this above or below the player is on another.
const OTHER_LEVEL := 2.0
## A regrouping enemy climbs out at the nearest hatch at least this far from the player.
const REGROUP_CLEARANCE := 6.0
## How close to a socket counts as standing on it: the arm waits rather than land on you.
const SOCKET_CLEARANCE := 1.4
const ALARM_EVERY := 0.55
const HISS_EVERY := 2.4

## Box the player walks into to start the fight: centre and size.
@export var start_at := Vector3.ZERO
@export var start_size := Vector3(8, 4, 8)
## The pipe that falls across the way back: where it lands, radius, length along z.
@export var seal_at := Vector3.ZERO
@export var seal_radius := 1.6
@export var seal_length := 6.0
## Where a death respawns the player once the seal is down.
@export var respawn_at := Vector3.ZERO
## The arms, each a Dictionary: n, shoulder, elbow and socket (elbow and socket with it down).
@export var arms: Array = []
## Arm numbers in the order they come down.
@export var order: Array = []
## How far a lifted arm's elbow rises above its down pose.
@export var lift := 5.0
## Seconds from the fight starting to the first arm's warning.
@export var first_arm_seconds := 4.0
## The beacon and alarm run this long before an arm comes down.
@export var warning_seconds := 3.0
## After a wave climbs out, pressure forces the next arm down after this long even if the
## wave isn't dead. It also stands in for anything stuck where it can't be reached.
@export var pressure_seconds := 45.0
## With the wave dead, a breath of pressure before the next warning.
@export var cleared_pause := 1.5
## How long an arm takes to come down or go up.
@export var move_seconds := 1.4
## One wave per pipe but the last: [fodder, hunters, rammers], as in the arena set piece.
@export var waves: Array = []
## Floor points enemies climb out at. Melee hatches are used by level; ranged ones anywhere.
@export var melee_hatches: Array = []
@export var ranged_hatches: Array = []
## The button kicked after the last pipe: where it stands and which way its front faces.
@export var button_at := Vector3.ZERO
@export var button_yaw := 0.0
## The shut high exit: centre and size of the shutter.
@export var exit_at := Vector3.ZERO
@export var exit_size := Vector3(2.5, 3.2, 0.5)
## The lit pad at the level exit, shown once the machine goes critical.
@export var end_zone_at := Vector3.ZERO
@export var end_zone_size := Vector3(8, 4, 12)
## Where steam jets out. The ones in the pit also show pressure building between arms.
@export var vents: Array = []
@export var escape_seconds := 90.0
## The place falling apart once the machine is critical. Each is a Dictionary: kind "fall"
## (a pipe, beam or crate dropping to rest at "at" with "size") or "steam" (a jet at "at" for
## "duration"). With a "trigger" it fires when the player comes within "radius" of it,
## otherwise "delay" seconds after critical.
@export var escape_events: Array = []
## Red lights that pulse once the machine is critical.
@export var alarms: Array = []
@export var line_start := "COMMANDER: Those are coolant pipes. Break them."
@export var line_last_pipe := "COMMANDER: Now find the button to lock it in."
@export var line_critical := "COMMANDER: That's done it. Now get out of there."
## A melee enemy that spends this long on a different level from the player climbs out
## again at a hatch on the player's level. No navmesh, so otherwise it waits under a wall.
@export var regroup_after := 5.0

enum State { WAITING, FIGHT, BUTTON, CRITICAL, DONE }
## Where the current arm is in its cycle.
enum Phase { PRESSURE, WARN, DROP, EXPOSED, LIFT }

var state := State.WAITING
var phase := Phase.PRESSURE
var escape_left := 0.0
var button: StaticBody3D
var _level: Node
var _player: Node3D
var _arm_nodes := {}
## How many arms have been through their cycle, which is also the index into `order`.
var _cycle := 0
var _broken := 0
var _phase_time := 0.0
var _alarm_in := 0.0
var _hiss_in := 0.0
var _waiting_logged := false
var _exit: StaticBody3D
var _exit_lamp: MeshInstance3D
var _end_zone: Node3D
var _steam: Array = []
var _pit_steam: Array = []
var _clang_in := 0.0
var _line_left := 0.0
## [seconds until it climbs out, scene, position]
var _queue: Array = []
var _melee_turn := 0
var _ranged_turn := 0
var _since_critical := -1.0
var _fired := {}
var _alarm_lights: Array = []
## The current wave's enemies, to tell when it's dead.
var _wave_members: Array = []
## Wave melee enemies still alive -> seconds spent on a different level from the player.
var _stranded := {}
## Hatch -> clock time it can let a regrouping enemy out again.
var _hatch_free_at := {}
var _clock := 0.0

func _ready() -> void:
	_level = get_parent()
	# Children are ready before their parent, so the level's kill total picks these up.
	var total := 0
	for wave in waves:
		total += int(wave[0]) + int(wave[1]) + int(wave[2])
	if _level and "extra_expected_kills" in _level:
		_level.extra_expected_kills += total
	for spec in arms:
		var arm := Node3D.new()
		arm.set_script(ARM)
		arm.name = "PressureArm%d" % int(spec["n"])
		arm.set("number", int(spec["n"]))
		arm.set("shoulder", spec["shoulder"])
		arm.set("elbow", spec["elbow"])
		arm.set("socket", spec["socket"])
		arm.set("lift", lift)
		add_child(arm)
		arm.connect("broken", _on_arm_broken)
		_arm_nodes[int(spec["n"])] = arm
	button = StaticBody3D.new()
	button.set_script(BUTTON)
	button.name = "ActivateButton"
	button.position = button_at
	button.rotation.y = button_yaw
	add_child(button)
	button.connect("pressed", _on_button_pressed)
	_build_exit()
	_build_start()
	_build_end_zone()
	for at in vents:
		var jet := _steam_jet(at)
		_steam.append(jet)
		if (at as Vector3).y < 0.0:
			_pit_steam.append(jet)
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
	_broken = _arm_nodes.size()
	for arm in _arm_nodes.values():
		arm.pipe.set("is_broken", true)
	button.set("armed", true)
	button.set("is_pressed", true)
	_open_exit()
	if with_escape_events:
		_since_critical = 0.0

## The arm whose turn it is (scripts/props/pressure_arm.gd), or null once they're all done.
func current_arm():
	if _cycle >= order.size():
		return null
	return _arm_nodes.get(int(order[_cycle]))

func _process(delta: float) -> void:
	_clock += delta
	_release_queue(delta)
	if state == State.FIGHT:
		_run_cycle(delta)
	if state == State.FIGHT or state == State.BUTTON:
		_regroup_stranded(delta)
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
		if not vents.is_empty():
			_sound("kick_prop", vents[randi() % vents.size()], 2.0)
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
	_log("machine fight started, way back sealed")
	_enter_pressure()

# --- the arm cycle -------------------------------------------------------------

func _run_cycle(delta: float) -> void:
	_phase_time += delta
	var arm = current_arm()
	if arm == null:
		return
	match phase:
		Phase.PRESSURE:
			var build := clampf(_phase_time / (first_arm_seconds if _cycle == 0 else pressure_seconds), 0.0, 1.0)
			_pressure_steam(0.3 + 0.7 * build)
			_hiss_in -= delta
			if _hiss_in <= 0.0:
				_hiss_in = HISS_EVERY * (1.0 - 0.5 * build)
				_sound("steam_hiss", arm.socket + Vector3(0, 1, 0), -4.0 + 6.0 * build)
			if _cycle == 0:
				if _phase_time >= first_arm_seconds:
					_enter_warning()
			elif _queue.is_empty() and _wave_cleared():
				if _phase_time >= cleared_pause:
					_enter_warning()
			elif _phase_time >= pressure_seconds:
				_log("pressure forces arm %d down with %d of its wave still up" % [arm.number, _alive_in_wave()])
				_enter_warning()
		Phase.WARN:
			_pressure_steam(1.0)
			_alarm_in -= delta
			if _alarm_in <= 0.0:
				_alarm_in = ALARM_EVERY
				_sound("machine_alarm", arm.elbow)
			if _phase_time >= warning_seconds:
				phase = Phase.DROP
				_phase_time = 0.0
		Phase.DROP:
			if arm.moving or arm.lowered > 0.0:
				return
			if _player_on_socket(arm):
				if not _waiting_logged:
					_waiting_logged = true
					_log("arm %d waits for the player to step off its socket" % arm.number)
				return
			_sound("arm_move", arm.elbow)
			arm.lower(move_seconds).tween_callback(_on_arm_seated.bind(arm))

func _enter_pressure() -> void:
	phase = Phase.PRESSURE
	_phase_time = 0.0
	_hiss_in = 0.0

func _enter_warning() -> void:
	var arm = current_arm()
	phase = Phase.WARN
	_phase_time = 0.0
	_alarm_in = 0.0
	_waiting_logged = false
	arm.warn(true)
	_log("arm %d warning" % arm.number)

func _on_arm_seated(arm) -> void:
	if state != State.FIGHT or arm != current_arm():
		return
	phase = Phase.EXPOSED
	_phase_time = 0.0
	arm.warn(false)
	arm.pipe.set("exposed", true)
	# Plugging in is what lets the pressure out.
	_pressure_steam(0.0)
	_sound("arm_clunk", arm.socket, 2.0)
	_shake_near(arm.socket, 0.6)
	arm.vent(0.6)
	_hint(line_start if _cycle == 0 else "COOLANT PIPES  %d / %d" % [_broken, _arm_nodes.size()])
	_log("arm %d down, its pipe can be broken" % arm.number)

func _on_arm_broken(arm) -> void:
	if state != State.FIGHT or arm != current_arm():
		return
	_broken += 1
	phase = Phase.LIFT
	_phase_time = 0.0
	_log("coolant pipe %d / %d broken (arm %d)" % [_broken, _arm_nodes.size(), arm.number])
	_hint("COOLANT PIPES  %d / %d" % [_broken, _arm_nodes.size()])
	_sound("arm_move", arm.elbow)
	arm.vent(1.2)
	arm.raise(move_seconds).tween_callback(_on_arm_lifted.bind(arm))

func _on_arm_lifted(arm) -> void:
	if state != State.FIGHT or arm != current_arm():
		return
	_cycle += 1
	if _cycle >= order.size():
		state = State.BUTTON
		button.call("arm")
		_hint(line_last_pipe)
		_log("all pipes broken, the button is armed")
		return
	_send_wave(_cycle - 1)
	_enter_pressure()

func _on_button_pressed() -> void:
	if state != State.BUTTON:
		return
	_log("button kicked")
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
	_sound("steam_hiss", button_at, 6.0)
	_sound("arm_clunk", button_at, 4.0)
	_shake_near(button_at, 1.6)
	_log("machine critical, escape countdown %d s" % int(escape_seconds))

func _on_exit(body: Node) -> void:
	if state == State.CRITICAL and body.is_in_group("player"):
		state = State.DONE
		_log("escaped with %.1f s left" % escape_left)
		_hint("")

## Steam from the pit vents at a strength from 0, off, to 1, full.
func _pressure_steam(strength: float) -> void:
	for jet in _pit_steam:
		jet.emitting = strength > 0.0
		jet.initial_velocity_min = lerpf(1.5, 7.0, strength)
		jet.initial_velocity_max = lerpf(3.0, 10.0, strength)

func _player_on_socket(arm) -> bool:
	for body in get_tree().get_nodes_in_group("player"):
		var p: Vector3 = (body as Node3D).global_position
		var s: Vector3 = arm.socket
		if Vector2(p.x - s.x, p.z - s.z).length() < SOCKET_CLEARANCE and absf(p.y - s.y) < 3.0:
			return true
	return false

## True once every enemy in the current wave is dead, not counting a Rammer stranded below
## a player up on the walks, which can't reach them anyway.
func _wave_cleared() -> bool:
	return _alive_in_wave() == 0

func _alive_in_wave() -> int:
	var alive := 0
	var floor_y := _player.global_position.y if _player else start_at.y
	for enemy in _wave_members:
		if not is_instance_valid(enemy):
			continue
		var body := enemy as Node3D
		if String(body.scene_file_path).ends_with("rammer.tscn") and floor_y > OTHER_LEVEL and absf(body.global_position.y - floor_y) > OTHER_LEVEL:
			continue
		alive += 1
	return alive

# --- waves ----------------------------------------------------------------------

func _send_wave(index: int) -> void:
	if index >= waves.size():
		return
	_wave_members.clear()
	var spec: Array = waves[index]
	var fodder := int(spec[0])
	var hunters := int(spec[1])
	var rammers := int(spec[2])
	var floor_y := _player.global_position.y if _player else start_at.y
	# A Rammer is too wide for the walks, so up there it comes as fodder.
	if floor_y > 2.0:
		fodder += rammers
		rammers = 0
	# Without ranged hatches, Hunters climb out with the melee.
	if ranged_hatches.is_empty():
		fodder += hunters
		hunters = 0
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
			_wave_members.append(enemy)
			if _queue[i][1] != HUNTER:
				_stranded[enemy] = 0.0
			_queue.remove_at(i)
		else:
			i += 1

## Wave melee that has spent regroup_after on another level from the player climbs out
## again at a hatch on the player's level. A Rammer can't fit on the walks, so it waits
## below for the player to come back down.
func _regroup_stranded(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var floor_y := _player.global_position.y
	for enemy in _stranded.keys():
		if not is_instance_valid(enemy):
			_stranded.erase(enemy)
			continue
		var body := enemy as Node3D
		if absf(body.global_position.y - floor_y) <= OTHER_LEVEL:
			_stranded[enemy] = 0.0
			continue
		_stranded[enemy] = float(_stranded[enemy]) + delta
		var kind := String(body.scene_file_path).get_file().get_basename()
		if float(_stranded[enemy]) < regroup_after or (kind == "rammer" and floor_y > OTHER_LEVEL):
			continue
		var at = _regroup_hatch(floor_y)
		if at == null:
			continue
		body.global_position = (at as Vector3) + Vector3(0, 0.4, 0)
		body.set("velocity", Vector3.ZERO)
		_stranded[enemy] = 0.0
		_log("stranded %s climbed out again at %s" % [kind, at])

## The nearest melee hatch on the player's level that hasn't just let someone out, or null
## if they all have. Hatches right beside the player are only used if there are no others.
func _regroup_hatch(floor_y: float) -> Variant:
	var hatches := _hatches_on_level(floor_y)
	var clear := hatches.filter(func(at) -> bool: return (at as Vector3).distance_to(_player.global_position) >= REGROUP_CLEARANCE)
	if not clear.is_empty():
		hatches = clear
	var best = null
	var best_distance := INF
	for at in hatches:
		if _clock < float(_hatch_free_at.get(at, -INF)):
			continue
		var distance := (at as Vector3).distance_to(_player.global_position)
		if distance < best_distance:
			best = at
			best_distance = distance
	if best != null:
		_hatch_free_at[best] = _clock + HATCH_GAP
	return best

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
		_sound("kick_prop", at, 6.0)
		var burst := _steam_jet(at + Vector3(0, size.y / 2.0, 0))
		burst.one_shot = true
		burst.amount = 24
		burst.initial_velocity_max = 4.0
		burst.emitting = true
		_shake_near(at))

func _steam_burst(at: Vector3, duration: float) -> void:
	var jet := _steam_jet(at)
	jet.emitting = true
	_sound("steam_hiss", at, 2.0)
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		if is_instance_valid(jet):
			jet.emitting = false)

## A camera shake for anyone within 14 of `at`, scaled by `strength`.
func _shake_near(at: Vector3, strength := 1.0) -> void:
	for body in get_tree().get_nodes_in_group("player"):
		var camera = body.get("camera")
		if camera == null or (body as Node3D).global_position.distance_to(at) > 14.0 * maxf(strength, 1.0):
			continue
		var start: Vector3 = camera.position
		var tw := create_tween()
		tw.tween_property(camera, "position", start + Vector3(0.12, -0.08, 0.0) * strength, 0.05)
		tw.tween_property(camera, "position", start + Vector3(-0.08, 0.05, 0.0) * strength, 0.06)
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
		var up := create_tween()
		up.tween_property(_exit, "position:y", exit_at.y + exit_size.y + 0.2, 1.2)
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
		_sound("kick_prop", seal.global_position, 6.0))

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

func _sound(event: String, at: Vector3, volume_offset := 0.0) -> void:
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.play_at(event, at, volume_offset)

func _hint(text: String) -> void:
	if _level and _level.has_method("set_hint"):
		_level.set_hint(text)

func _log(text: String) -> void:
	var tag: String = _level.level_tag if _level and "level_tag" in _level else "LEVEL"
	var at: String = _level.stamp(_level.clock()) if _level and _level.has_method("stamp") else "?"
	print("%s %s at %s" % [tag, text, at])
