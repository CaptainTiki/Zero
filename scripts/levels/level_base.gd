extends Node3D
## Shared level runtime: run timer, beat lines, secrets, ambushes, Johns, run
## stats, the console log, the run report, end-of-run beacons and the tally.
## Nothing in here knows about a particular level. Set pieces like the plaza
## arena or the factory escape are child nodes that listen to `beat_reached`.

## Emitted the first time the player crosses each beat line.
signal beat_reached(beat: int, elapsed: float)

## Shown in the console and the HUD timer.
@export var level_tag := "L01"
## Par is a time to beat, not to coast under: about 2.5x the route test's walk
## time. Full time credit at or under par, fading to none at double par.
@export var par_time := 480.0
## Below this the player has fallen out of the world: log it and put them back.
## Set 10 under the lowest geometry in the level.
@export var fall_plane := -16.0
## Golden path length from the level's route test, for the wander ratio.
@export var golden_path_units := 933.0
## Ambience bed started on load, or "" for none.
@export var ambience := "ambience_wind"
## Headline on the end-of-run tally.
@export var tally_title := "LEVEL 01 PLAYTEST  (one section of Mission 01)"
## Deaths put the player back at the furthest beat line they have crossed instead of
## where the level set respawn_point. A stopgap until losing restarts the level. A set
## piece that seals the way back must move the respawn behind its seal itself, as the
## factory's machine does; Level 01's arena doesn't, so Level 01 leaves this off.
@export var respawn_at_beats := false

## Ambushes spawn these, so the base owns them. Scenes baked before ambushes had a kind
## spawn fodder.
const FODDER := preload("res://scenes/enemies/fodder.tscn")
const AMBUSH_KINDS := {
	"fodder": FODDER,
	"rammer": preload("res://scenes/enemies/rammer.tscn"),
	"brute": preload("res://scenes/enemies/brute.tscn"),
	"hunter": preload("res://scenes/enemies/hunter.tscn"),
}

const WEIGHT_KILLS := 0.4
const WEIGHT_SECRETS := 0.4
const WEIGHT_TIME := 0.2

## Set pieces are armed unless a test turns them off.
var arena_enabled := true
## Set pieces add the enemies they will spawn here, from their own _ready, which
## runs before this node's.
var extra_expected_kills := 0

## Beat lines sit 1.5 above the floor they cross; a respawn goes 0.5 above it.
const BEAT_RESPAWN_DROP := 1.0
## Where a finished level hands off to, and the list it reads the order from.
const MENU := "res://scenes/ui/main_menu.tscn"
const LEVEL_LIST := preload("res://scripts/levels/level_list.gd")
const PAUSE_MENU := preload("res://scripts/ui/pause_menu.gd")

## Five-second active-play frame samples retained with the normal run report.
@export var performance_logging := true
var _frame_sampler = preload("res://scripts/debug/frame_sampler.gd").new()

var _elapsed := 0.0
var _label: Label
var _hint: Label
var _stats_label: Label
var _reached := {}
var _respawn_beat := 0
var _finished := false
var _dead := false
var _transitioning := false
var _end_input_armed := false
var _world_modes := {}
var _collision_modes := {}
var _lift_open := false
var _kills := 0
var _shots := {"pistol": 0, "shotgun": 0}
var _damage_taken := 0.0
var _secrets_found := 0
var _secrets_total := 0
var _kills_total := 0
var _debug_visible := true
var _kills_at_beat := {}
var _walk_at_beat := {}
var _secrets_at_beat := {}
var _johns := 0
var _hits := 0
var _deaths := 0
var _falls := 0
var _doors_kicked := 0
var _dry_fires := {}
var _refused := {}
var _specials := {}
var _shot_hits := {"pistol": 0, "shotgun": 0}
var _walked := 0.0
var _last_pos := Vector3.ZERO
var _safe_pos := Vector3.ZERO
var _safe_timer := 0.0
var _refuse_cooldown := {}
var _report: Array[String] = []
var _heals := 0
var _healed_total := 0.0
var _johns_total := 0
var _beacons: Array[Node3D] = []
var _debug: CanvasLayer
var _tally: Label
var _pause_menu: CanvasLayer
var _unstuck_at := Vector3.ZERO
var _unstuck_beat := 0

## Set pieces use these rather than reaching into private state.
func clock() -> float:
	return _elapsed

func stamp(seconds: float) -> String:
	return _stamp(seconds)

func set_hint(text: String) -> void:
	if _hint:
		_hint.text = text

func _ready() -> void:
	add_to_group("run_stats")
	var starting_player := get_tree().get_first_node_in_group("player") as Node3D
	if starting_player:
		_unstuck_at = starting_player.global_position
	_pause_menu = PAUSE_MENU.new()
	add_child(_pause_menu)
	get_node("/root/InputBootstrap").controller_lost.connect(_on_controller_lost)
	get_node("/root/InputBootstrap").device_changed.connect(_refresh_end_controls)
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
	var tally_back := ColorRect.new()
	tally_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tally_back.color = Color(0.02, 0.025, 0.03, 0.88)
	tally_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tally_back.visible = false
	overlay.add_child(tally_back)
	_tally = Label.new()
	_tally.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tally.offset_left = 32.0
	_tally.offset_right = -32.0
	_tally.offset_top = 80.0
	_tally.offset_bottom = -32.0
	_tally.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tally.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tally.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tally.add_theme_font_size_override("font_size", 24)
	_tally.visibility_changed.connect(func() -> void: tally_back.visible = _tally.visible)
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
	var ambush_total := 0
	for area in get_tree().get_nodes_in_group("ambush"):
		ambush_total += int(area.get_meta("count"))
	_kills_total = get_tree().get_nodes_in_group("enemies").size() + extra_expected_kills + ambush_total
	_johns_total = get_tree().get_nodes_in_group("johns").size()
	_push_progress()
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		if ambience != "":
			bank.start_ambience(ambience)
	print("%s: timer started" % level_tag)

func _on_controller_lost() -> void:
	if not run_ended() and not _transitioning:
		_pause_menu.open()

func _refresh_end_controls() -> void:
	if not run_ended() or _tally == null:
		return
	var text := _tally.text
	var split := text.rfind("\n\n")
	if split < 0:
		return
	var inputs := get_node("/root/InputBootstrap")
	var confirm: String = inputs.button_label("ui_accept") if inputs.using_controller else "Fire, F or Enter"
	var back: String = inputs.button_label("ui_cancel")
	var destination := "restart" if _dead else "continue"
	_tally.text = text.substr(0, split) + "\n\n%s to %s   ·   %s %s" % [confirm, destination, back, "for menu" if _dead else "to inspect / return"]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle", false, true):
		_debug_visible = not _debug_visible
		_debug.visible = _debug_visible
	if event.is_action_pressed("hud_toggle", false, true):
		_hint.visible = not _hint.visible

## Own end-screen input before a player's Escape handler can toggle the mouse again.
func _input(event: InputEvent) -> void:
	if not run_ended():
		if event.is_action_pressed("pause") and not _transitioning:
			get_viewport().set_input_as_handled()
			_pause_menu.open()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _transitioning:
			return
		if _dead:
			_change_level(MENU)
		else:
			_tally.visible = not _tally.visible
			_set_world_active(not _tally.visible)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _tally.visible else Input.MOUSE_MODE_CAPTURED
			_end_input_armed = false
	elif _tally.visible and (event.is_action_pressed("primary") or event.is_action_pressed("kick") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		if _end_input_armed:
			_go_on()

func run_ended() -> bool:
	return _finished or _dead

## Stop the world while a tally is up, without pausing the app or its input.
## Restore each child's original mode when inspecting a completed level. Defer changes
## because exits and damage can end a run inside a physics callback.
func _set_world_active(active: bool) -> void:
	if active:
		for child in _world_modes:
			if is_instance_valid(child):
				child.set_deferred("process_mode", _world_modes[child])
		_world_modes.clear()
		for body in _collision_modes:
			if is_instance_valid(body):
				body.set_deferred("disable_mode", _collision_modes[body])
		_collision_modes.clear()
	else:
		# Disabled bodies normally leave physics entirely. Keep the frozen world's
		# collisions in place, and make rigid bodies static until inspection resumes.
		var pending: Array[Node] = []
		pending.assign(get_children())
		while not pending.is_empty():
			var node: Node = pending.pop_back()
			pending.append_array(node.get_children())
			if node is CollisionObject3D and not _collision_modes.has(node):
				_collision_modes[node] = node.disable_mode
				node.set_deferred("disable_mode", CollisionObject3D.DISABLE_MODE_MAKE_STATIC)
		for child in get_children():
			if child is CanvasLayer or _world_modes.has(child):
				continue
			_world_modes[child] = child.process_mode
			child.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func _process(delta: float) -> void:
	if run_ended():
		if not Input.is_action_pressed("primary") and not Input.is_action_pressed("kick") and not Input.is_action_pressed("ui_accept"):
			_end_input_armed = true
		return
	if performance_logging:
		var frame_window: Dictionary=_frame_sampler.tick(Time.get_ticks_usec())
		if not frame_window.is_empty():
			_say("%s PERF at %.2fs %s" % [level_tag,_elapsed,JSON.stringify(_performance_context(frame_window))])
	_elapsed += delta
	_track_player(delta)
	_label.text = "%s  %s" % [level_tag, _stamp(_elapsed)]
	_update_stats_label()

func record_shot(kind: String) -> void:
	_shots[kind] = _shots.get(kind, 0) + 1

func record_kill() -> void:
	_kills += 1
	_push_progress()

func _push_progress() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.get("hud") and player.hud.has_method("set_progress"):
		player.hud.set_progress(_secrets_found, _secrets_total, _kills, _kills_total, _johns, _johns_total)

func _on_secret(body: Node, area: Area3D) -> void:
	if not body.is_in_group("player"):
		return
	_secrets_found += 1
	print("%s " % level_tag + "secret %d/%d at %s (%s)" % [_secrets_found, _secrets_total, _stamp(_elapsed), area.name])
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
	var kind := String(area.get_meta("kind", "fodder"))
	# A group needs spreading out; one enemy lands exactly where the plan put it, which is what
	# lets a single brute be spawned into a 3-wide tunnel.
	var spread := 1.5 if count > 1 else 0.0
	for i in count:
		var e: Node3D = (AMBUSH_KINDS.get(kind, FODDER) as PackedScene).instantiate()
		add_child(e)
		e.global_position = spawn + Vector3(randf_range(-spread, spread), 0.5, randf_range(-spread, spread))
		e.set("_alerted", true)
	print("%s " % level_tag + "ambush %s: %d %s at %s" % [area.name, count, kind, _stamp(_elapsed)])
	area.queue_free()

## Cardboard Johns are a bonus on top of completion, never part of it.

func record_john() -> void:
	_johns += 1
	print("%s " % level_tag + "john %d/%d at %s" % [_johns, _johns_total, _stamp(_elapsed)])

func record_damage(amount: float, hp_after := -1.0) -> void:
	_damage_taken += amount
	_hits += 1
	if hp_after >= 0.0:
		print("%s " % level_tag + "hit  -%d at %s  (hp %d)" % [int(round(amount)), _stamp(_elapsed), int(round(hp_after))])

## Healing is logged too, so a playtest shows when a player spent a pickup and
## how long they held on to it.

func _track_player(delta: float) -> void:
	# Prefer a player that is actually running: the route test parks the level's
	# own body and drives a second one.
	var player: Node3D = null
	for candidate in get_tree().get_nodes_in_group("player"):
		if candidate is Node3D:
			player = candidate as Node3D
			if candidate.process_mode != Node.PROCESS_MODE_DISABLED:
				break
	if player == null:
		return
	var at: Vector3 = player.global_position
	if _last_pos == Vector3.ZERO:
		_last_pos = at
		_safe_pos = at
	var step := at - _last_pos
	step.y = 0.0
	_walked += step.length()
	_last_pos = at
	_safe_timer -= delta
	if _safe_timer <= 0.0:
		_safe_timer = 0.5
		if player.has_method("is_on_floor") and player.is_on_floor():
			_safe_pos = at
	if at.y < fall_plane:
		_falls += 1
		print("%s " % level_tag + "FELL OUT OF THE WORLD at %s  from %s, put back at %s" % [_stamp(_elapsed), at, _safe_pos])
		player.global_position = _safe_pos + Vector3(0, 0.5, 0)
		if player.has_method("set_velocity"):
			player.set("velocity", Vector3.ZERO)
		_last_pos = player.global_position

func record_death(at: Vector3) -> void:
	_deaths += 1
	print("%s " % level_tag + "DEATH %d at %s  at %s" % [_deaths, _stamp(_elapsed), at])

func record_door_kick(door_name: String) -> void:
	_doors_kicked += 1
	print("%s " % level_tag + "door kicked: %s at %s" % [door_name, _stamp(_elapsed)])

func record_dry_fire(weapon: String) -> void:
	_dry_fires[weapon] = int(_dry_fires.get(weapon, 0)) + 1
	print("%s " % level_tag + "dry fired %s at %s" % [weapon, _stamp(_elapsed)])

## Pickups retry every frame while the player stands on them, so only report a
## refusal once every few seconds per kind.

func record_pickup_refused(kind: String) -> void:
	var last: float = float(_refuse_cooldown.get(kind, -99.0))
	if _elapsed - last < 4.0:
		return
	_refuse_cooldown[kind] = _elapsed
	_refused[kind] = int(_refused.get(kind, 0)) + 1
	print("%s " % level_tag + "pickup refused (%s full) at %s" % [kind, _stamp(_elapsed)])

func record_special(kind: String) -> void:
	_specials[kind] = int(_specials.get(kind, 0)) + 1
	print("%s " % level_tag + "special used: %s at %s" % [kind, _stamp(_elapsed)])

func record_hit(kind: String) -> void:
	if _shot_hits.has(kind):
		_shot_hits[kind] += 1

func record_heal(amount: float, hp_after := -1.0) -> void:
	if amount <= 0.0:
		return
	_heals += 1
	_healed_total += amount
	print("%s " % level_tag + "heal +%d at %s  (hp %d)" % [int(round(amount)), _stamp(_elapsed), int(round(hp_after))])

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
	_walk_at_beat[beat] = _walked
	_secrets_at_beat[beat] = _secrets_found
	print("%s beat %d reached at %s  (kills so far %d)" % [level_tag, beat, _stamp(_elapsed), _kills])
	# The furthest beat wins, so wandering back over an earlier line doesn't set a player back.
	if respawn_at_beats and beat > _respawn_beat and "respawn_point" in body:
		_respawn_beat = beat
		body.set("respawn_point", area.global_position - Vector3(0, BEAT_RESPAWN_DROP, 0))
	if beat > _unstuck_beat:
		_unstuck_beat = beat
		# Use where the player crossed, not the centre of a wide trigger that may
		# span a ramp or obstacles. A little clearance avoids a floor overlap.
		_unstuck_at = body.global_position + Vector3(0, 0.1, 0)
	beat_reached.emit(beat, _elapsed)

## Set pieces move the checkpoint inside a seal that closes behind the player.
func set_unstuck_checkpoint(at: Vector3) -> void:
	_unstuck_at = at

func unstuck_player() -> bool:
	if run_ended():
		return false
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return false
	var from := player.global_position
	player.global_position = _unstuck_at
	if player is CharacterBody3D:
		player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	# Teleport distance is not walking, and fall recovery must not return to the trap.
	_last_pos = _unstuck_at
	_safe_pos = _unstuck_at
	_safe_timer = 0.5
	_specials["unstuck"] = int(_specials.get("unstuck", 0)) + 1
	_say("%s UNSTUCK at %s: from %s to %s (beat %d)" % [level_tag, _stamp(_elapsed), from, _unstuck_at, _unstuck_beat])
	return true

## Lets the level exit finish the run. Level 01 opens it when the museum lift arrives,
## the factory when the machine goes critical.
func open_exit() -> void:
	_lift_open = true

func open_lift() -> void:
	if _lift_open:
		return
	open_exit()
	_hint.text = "LIFT HERE"
	print("%s " % level_tag + "lift arrived at %s" % _stamp(_elapsed))
	var solid := get_node_or_null("LiftDoorSolid")
	if solid:
		solid.queue_free()
	var visual := get_node_or_null("LiftDoor") as Node3D
	if visual:
		var tween := create_tween()
		tween.tween_property(visual, "position:y", visual.position.y + 5.0, 0.9)
		tween.tween_callback(visual.queue_free)

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		finish()

## Losing costs the whole run. Both lethal damage and set-piece failure use this screen.
func player_died(at: Vector3) -> void:
	fail_run("YOU DIED", at)

func fail_run(reason: String, at := Vector3.ZERO) -> void:
	if run_ended():
		return
	_dead = true
	_set_world_active(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hint.text = ""
	_label.text = "RUN FAILED  %s" % _stamp(_elapsed)
	_say("%s " % level_tag + "run failed: %s at %s, at %s" % [reason, _stamp(_elapsed), at])
	_tally.text = tally_title + "\n\n%s at %s\n\nKILLS  %d / %d\nSECRETS  %d / %d\n\nFire, F or Enter to restart   ·   Esc for menu" % [reason, _stamp(_elapsed), _kills, _kills_total, _secrets_found, _secrets_total]
	_tally.visible = true
	_refresh_end_controls()
	_print_kills_per_beat()
	_say("%s " % level_tag + "health: %d hits for %d damage, %d pickups for %d healed" % [_hits, int(round(_damage_taken)), _heals, int(round(_healed_total))])
	_print_run_summary()
	var report := _write_report()
	if report != "":
		print("%s " % level_tag + "run report written to: %s" % report)

## Fire or kick on the end screen: a finished level hands off to the next one, the last level
## hands back to the menu, and a death starts this level again.
func _go_on() -> void:
	if not run_ended():
		return
	var next := scene_file_path if _dead else LEVEL_LIST.next_path(scene_file_path)
	_change_level(next if next != "" else MENU)

func _change_level(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	_load_level.call_deferred(path)

func _load_level(path: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		_transitioning = false
		_hint.text = "Could not open the level. Try again."
		push_error("Could not open %s: %s" % [path, error_string(error)])

## Save an abandoned run before its nodes are removed. Keep the live event buffer intact
## if saving or the subsequent scene change fails and the player resumes instead.
func save_quit_report() -> bool:
	if run_ended():
		return true
	var previous_size := _report.size()
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var at := player.global_position if player else Vector3.ZERO
	_say("%s QUIT TO MENU at %s from %s  [%s]  secrets %d/%d kills %d/%d johns %d/%d" % [level_tag, _stamp(_elapsed), at, _stats_summary(), _secrets_found, _secrets_total, _kills, _kills_total, _johns, _johns_total])
	_print_kills_per_beat("quit")
	_say("%s health: %d hits for %d damage, %d pickups for %d healed" % [level_tag, _hits, int(round(_damage_taken)), _heals, int(round(_healed_total))])
	_print_run_summary()
	var report := _write_report()
	_report.resize(previous_size)
	if report == "":
		return false
	print("%s run report written to: %s" % [level_tag, report])
	return true

func finish() -> void:
	if run_ended() or not _lift_open:
		return
	_finished = true
	_set_world_active(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_say("%s " % level_tag + "finished at %s  [%s]  secrets %d/%d kills %d/%d johns %d/%d" % [_stamp(_elapsed), _stats_summary(), _secrets_found, _secrets_total, _kills, _kills_total, _johns, _johns_total])
	_print_kills_per_beat()
	_hint.text = ""
	_label.text = "PLAYTEST COMPLETE  %s" % _stamp(_elapsed)
	var kill_part := WEIGHT_KILLS * float(_kills) / maxf(float(_kills_total), 1.0)
	var secret_part := WEIGHT_SECRETS * float(_secrets_found) / maxf(float(_secrets_total), 1.0)
	var time_part := WEIGHT_TIME * clampf(1.0 - maxf(_elapsed - par_time, 0.0) / par_time, 0.0, 1.0)
	var complete := 100.0 * (kill_part + secret_part + time_part)
	var par_note := "UNDER PAR" if _elapsed <= par_time else "OVER PAR"
	# Flattened Johns are worth 10 points in total, however many the level holds.
	# They ride on top of completion and never count toward it.
	var john_bonus := 0.0
	if _johns_total > 0:
		john_bonus = 10.0 * float(_johns) / float(_johns_total)
	var john_line := ""
	if _johns_total > 0:
		john_line = "\nJOHNS  %d / %d   (+%d%%)\n\nTOTAL  %d%%" % [_johns, _johns_total, int(round(john_bonus)), int(round(complete + john_bonus))]
	var onward := LEVEL_LIST.name_for(LEVEL_LIST.next_path(scene_file_path))
	var go_on := "Fire, F or Enter for %s" % onward if onward != "" else "Fire, F or Enter for the menu"
	_tally.text = tally_title + "\n\nTIME  %s   (par %s, %s)\nKILLS  %d / %d\nSECRETS  %d / %d\n\nMAP COMPLETE  %d%%%s\n\n%s   ·   Esc to inspect / return" % [_stamp(_elapsed), _stamp(par_time), par_note, _kills, _kills_total, _secrets_found, _secrets_total, int(round(complete)), john_line, go_on]
	_tally.visible = true
	_refresh_end_controls()
	_say("%s " % level_tag + "health: %d hits for %d damage, %d pickups for %d healed" % [_hits, int(round(_damage_taken)), _heals, int(round(_healed_total))])
	_print_run_summary()
	_mark_survivors()
	_mark_missed_secrets()
	var report := _write_report()
	if report != "":
		print("%s " % level_tag + "run report written to: %s" % report)
		_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		_hint.offset_left = 24.0
		_hint.offset_right = -24.0
		_hint.offset_top = 48.0
		_hint.add_theme_font_size_override("font_size", 16)
		_hint.text = "Run report saved: %s" % report.get_file()
		_hint.visible = true

## Everything a playtest wants that would be noise as it happened.
## Print and keep, so the run report says exactly what the console said.

func _notification(what: int) -> void:
	if what==NOTIFICATION_PAUSED or what==NOTIFICATION_UNPAUSED:
		if _frame_sampler: _frame_sampler.restart_clock()

func _performance_context(window: Dictionary) -> Dictionary:
	var record:=window.duplicate(true)
	var player:=get_tree().get_first_node_in_group("player") as Node3D
	var viewport:=get_viewport()
	var camera:=viewport.get_camera_3d()
	record["scene"]=scene_file_path
	record["elapsed_seconds"]=snappedf(_elapsed,0.01)
	record["beat"]=_unstuck_beat
	if player: record["player_position"]=preload("res://scripts/debug/debug_pointer.gd").vector(player.global_position)
	if camera:
		var facing: Vector3=-camera.global_basis.z.normalized()
		record["camera_position"]=preload("res://scripts/debug/debug_pointer.gd").vector(camera.global_position)
		record["facing"]=preload("res://scripts/debug/debug_pointer.gd").vector(facing)
		record["yaw_degrees"]=snappedf(rad_to_deg(atan2(-facing.x,-facing.z)),0.01)
		record["pitch_degrees"]=snappedf(rad_to_deg(asin(clampf(facing.y,-1.0,1.0))),0.01)
	record["viewport_pixels"]=[viewport.get_visible_rect().size.x,viewport.get_visible_rect().size.y]
	record["window_pixels"]=[get_window().size.x,get_window().size.y]
	record["render_target_pixels"]=[viewport.get_texture().get_width(),viewport.get_texture().get_height()]
	record["render_scale"]=viewport.scaling_3d_scale
	record["msaa_3d"]=viewport.msaa_3d
	record["vsync"]=DisplayServer.window_get_vsync_mode()
	record["fps_cap"]=Engine.max_fps
	record["display_server"]=DisplayServer.get_name()
	record["draw_calls"]=viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	record["primitives"]=viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
	return record

func record_debug_pointer(marker: Dictionary) -> void:
	if _finished:
		return
	marker=marker.duplicate(true)
	marker["performance"]=_performance_context(_frame_sampler.snapshot())
	_say("%s POINTER at %.2fs %s" % [level_tag, _elapsed, JSON.stringify(marker)])

func _say(text: String) -> void:
	print(text)
	_report.append(text)

## Testers can't be asked to copy a console. Write the run to a text file next to
## the game they were given, and tell them where it is.

func _report_path() -> String:
	var dir := OS.get_executable_path().get_base_dir()
	if OS.has_feature("editor"):
		# In the editor that folder is Godot's own; use the project's user dir.
		dir = OS.get_user_data_dir()
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	return dir.path_join("superzero_run_%s.txt" % stamp)

## Quick menu tests can end several runs in the same second. Never replace an older report.
func _unused_report_path(path: String) -> String:
	var candidate := path
	var suffix := 2
	while FileAccess.file_exists(candidate):
		candidate = "%s_%d.%s" % [path.get_basename(), suffix, path.get_extension()]
		suffix += 1
	return candidate

func _write_report() -> String:
	# Header first, so a report always says which build and machine produced it.
	var header: Array[String] = [
		"SUPER ZERO run report",
		"build    %s" % ProjectSettings.get_setting("application/config/version", "unversioned"),
		"level    %s" % scene_file_path.get_file(),
		"when     %s" % Time.get_datetime_string_from_system(false, true),
		"engine   Godot %s" % Engine.get_version_info().get("string", "?"),
		"system   %s, %s" % [OS.get_name(), RenderingServer.get_video_adapter_name()],
		"",
	]
	var path := _unused_report_path(_report_path())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		# Read-only install folder: fall back somewhere always writable.
		path = _unused_report_path(OS.get_user_data_dir().path_join(path.get_file()))
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write a run report")
		return ""
	var report_lines:=_report.duplicate()
	if performance_logging:
		report_lines.append("%s PERF FINAL at %.2fs %s" % [level_tag,_elapsed,JSON.stringify(_performance_context(_frame_sampler.snapshot()))])
	file.store_string("\n".join(header + report_lines) + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		push_warning("Could not finish writing a run report: %s" % error_string(error))
		return ""
	return path

func _print_run_summary() -> void:
	var lines := []
	lines.append("  deaths %d, falls out of world %d, doors kicked %d" % [_deaths, _falls, _doors_kicked])
	for kind in ["pistol", "shotgun"]:
		var fired: int = int(_shots.get(kind, 0))
		var landed: int = int(_shot_hits.get(kind, 0))
		var pct := 0.0 if fired == 0 else 100.0 * float(landed) / float(fired)
		lines.append("  %s: %d fired, %d hit, %d%% accuracy" % [kind, fired, landed, int(round(pct))])
	if _johns_total > 0:
		lines.append("  johns flattened %d / %d" % [_johns, _johns_total])
	if not _dry_fires.is_empty():
		lines.append("  dry fired: %s" % _dry_fires)
	if not _refused.is_empty():
		lines.append("  pickups refused while full: %s" % _refused)
	if not _specials.is_empty():
		lines.append("  specials used: %s" % _specials)
	var wander := 0.0 if golden_path_units <= 0.0 else _walked / golden_path_units
	lines.append("  walked %d units against a %d unit golden path (%.2fx)" % [int(round(_walked)), int(round(golden_path_units)), wander])
	_say("%s " % level_tag + "run summary:")
	for line in lines:
		_say(String(line))

## Per stretch between beat lines: time, kills, distance walked and secrets found.
## Read together these separate the reasons a player covers extra ground. Lots of
## distance with kills is combat movement; with secrets it is hunting; with
## neither it is being lost.

func _print_kills_per_beat(end_label := "finish") -> void:
	var beats := _kills_at_beat.keys()
	beats.sort_custom(func(a, b): return float(_reached[a]) < float(_reached[b]))
	var last_time := 0.0
	var last_kills := 0
	var last_walk := 0.0
	var last_secrets := 0
	var lines := []
	for beat in beats:
		var t: float = _reached[beat]
		var k: int = _kills_at_beat[beat]
		var w: float = float(_walk_at_beat.get(beat, 0.0))
		var s: int = int(_secrets_at_beat.get(beat, 0))
		lines.append("  to beat %d: %s, %d kills, %d units, %d secrets" % [beat, _stamp(t - last_time), k - last_kills, int(round(w - last_walk)), s - last_secrets])
		last_time = t
		last_kills = k
		last_walk = w
		last_secrets = s
	lines.append("  to %s: %s, %d kills, %d units, %d secrets" % [end_label, _stamp(_elapsed - last_time), _kills - last_kills, int(round(_walked - last_walk)), _secrets_found - last_secrets])
	_report.append("%s " % level_tag + "per segment:")
	for line in lines:
		_report.append(String(line))
	print("%s " % level_tag + "kills per segment:\n" + "\n".join(lines))

## Tall beacons over any enemy still alive so a missed kill can be found.

func _beacon(at: Vector3, tint: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tint.r, tint.g, tint.b, 0.55)
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = 2.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var beacon := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.25
	mesh.bottom_radius = 0.6
	mesh.height = 60.0
	mesh.radial_segments = 6
	mesh.material = m
	beacon.mesh = mesh
	add_child(beacon)
	beacon.global_position = at + Vector3(0, 30.0, 0)
	_beacons.append(beacon)

## Cyan over anything still breathing.

func _mark_survivors() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D):
			continue
		_beacon((e as Node3D).global_position, Color(0.2, 0.9, 1.0))
		_say("%s " % level_tag + "survivor: %s at %s" % [e.name, e.global_position])

## Yellow over every secret that was never found. Found ones free their trigger,
## so whatever is left in the group is what the player walked past.

func _mark_missed_secrets() -> void:
	for area in get_tree().get_nodes_in_group("secrets"):
		if not (area is Node3D):
			continue
		_beacon((area as Node3D).global_position, Color(1.0, 0.85, 0.2))
		_say("%s " % level_tag + "missed secret: %s at %s" % [area.name, (area as Node3D).global_position])
