extends Node
## Autoload "Sound": event-name -> stream list, with random pick and pitch
## jitter. `play(event)` is 2D (player-side); `play_at(event, position)` is
## positional through a small pool of AudioStreamPlayer3D. Missing files are
## skipped silently so an empty slot never breaks gameplay.
## Sources and licences: docs/ASSETS.md.

const KENNEY_IMPACT := "res://audio/cc0/kenney/impact/Audio/"
const KENNEY_SCIFI := "res://audio/cc0/kenney/scifi/Audio/"
const OGA := "res://audio/cc0/oga/"

## event -> [paths, volume_db, pitch_min, pitch_max]
const EVENTS := {
	"pistol_shot": [[OGA + "firearms/walther_ppq_1.wav", OGA + "firearms/walther_ppq_2.wav"], -6.0, 0.95, 1.05],
	"shotgun_shot": [[OGA + "firearms/mossberg_1.wav", OGA + "firearms/mossberg_2.wav", OGA + "firearms/nova_1.wav"], -3.0, 0.92, 1.02],
	# shotgun_pump: MISSING, needs a designed pump-action rack. See docs/ASSETS.md.
	"shotgun_empty": [[KENNEY_IMPACT + "impactTin_medium_000.ogg"], -10.0, 1.2, 1.3],
	"punch_swing": [["res://audio/sfx/player/melee_punch_01.wav"], -8.0, 0.9, 1.1],
	"punch_hit": [[KENNEY_IMPACT + "impactPunch_medium_000.ogg", KENNEY_IMPACT + "impactPunch_medium_001.ogg", KENNEY_IMPACT + "impactPunch_medium_002.ogg"], -4.0, 0.9, 1.1],
	"kick_hit": [[KENNEY_IMPACT + "impactPunch_heavy_000.ogg", KENNEY_IMPACT + "impactPunch_heavy_001.ogg", KENNEY_IMPACT + "impactPunch_heavy_002.ogg", KENNEY_IMPACT + "impactPunch_heavy_003.ogg"], -2.0, 0.85, 1.0],
	"kick_prop": [[KENNEY_IMPACT + "impactMetal_heavy_000.ogg", KENNEY_IMPACT + "impactMetal_heavy_001.ogg"], -4.0, 0.9, 1.1],
	# hit_confirm: cut after playtest (read as a generated thump). The crosshair tick and the enemy hurt voice carry it.
	"weak_hit": [[KENNEY_IMPACT + "impactPlate_light_000.ogg", KENNEY_IMPACT + "impactPlate_light_001.ogg", KENNEY_IMPACT + "impactPlate_light_002.ogg"], -5.0, 1.1, 1.3],
	# Ricochet-style scenery hits were cut after playtest; dust puffs carry the miss.
	"footstep": [[KENNEY_IMPACT + "footstep_concrete_000.ogg", KENNEY_IMPACT + "footstep_concrete_001.ogg", KENNEY_IMPACT + "footstep_concrete_002.ogg", KENNEY_IMPACT + "footstep_concrete_003.ogg", KENNEY_IMPACT + "footstep_concrete_004.ogg"], -16.0, 0.9, 1.1],
	"land": [[KENNEY_IMPACT + "impactSoft_medium_000.ogg", KENNEY_IMPACT + "impactSoft_medium_001.ogg"], -10.0, 0.8, 0.9],
	"player_hurt": [[KENNEY_IMPACT + "impactSoft_heavy_003.ogg", KENNEY_IMPACT + "impactSoft_heavy_004.ogg"], -4.0, 0.7, 0.85],
	"pickup_ammo": [[KENNEY_IMPACT + "impactMetal_medium_000.ogg", KENNEY_IMPACT + "impactMetal_medium_001.ogg"], -8.0, 1.2, 1.35],
	"pickup_health": [[KENNEY_SCIFI + "forceField_002.ogg"], -8.0, 1.3, 1.4],
	"pickup_weapon": [[KENNEY_IMPACT + "impactMetal_heavy_002.ogg", KENNEY_IMPACT + "impactPlate_heavy_000.ogg"], -6.0, 1.0, 1.1],
	"boost": [[KENNEY_SCIFI + "forceField_000.ogg"], -4.0, 1.1, 1.2],
	"boost_end": [[KENNEY_SCIFI + "forceField_004.ogg"], -8.0, 0.8, 0.85],
	"gib": [[KENNEY_IMPACT + "impactSoft_medium_000.ogg", KENNEY_IMPACT + "impactSoft_medium_001.ogg"], -9.0, 0.55, 0.7],
	"crate_break": [[KENNEY_IMPACT + "impactWood_heavy_000.ogg", KENNEY_IMPACT + "impactWood_heavy_001.ogg", KENNEY_IMPACT + "impactPlank_medium_000.ogg"], -4.0, 0.9, 1.1],
	# Creature voices.
	"fodder_idle": [[OGA + "monster_starninjas/monster.3.ogg", OGA + "monster_starninjas/monster.5.ogg", OGA + "monster_starninjas/monster.9.ogg"], -8.0, 1.1, 1.3],
	"fodder_alert": [[OGA + "monster_starninjas/monster.1.ogg", OGA + "monster_starninjas/monster.2.ogg"], -6.0, 1.15, 1.3],
	"fodder_attack": [[OGA + "monster_starninjas/monster.7.ogg", OGA + "monster_starninjas/monster.12.ogg"], -6.0, 1.1, 1.3],
	"fodder_hurt": [[OGA + "monster_starninjas/monster.4.ogg", OGA + "monster_starninjas/monster.8.ogg", OGA + "monster_starninjas/monster.14.ogg"], -6.0, 1.2, 1.45],
	"fodder_death": [[OGA + "monster_starninjas/monster.10.ogg", OGA + "monster_starninjas/monster.15.ogg", OGA + "monster_starninjas/monster.16.ogg"], -4.0, 1.2, 1.4],
	"rammer_idle": [[OGA + "monster_ogrebane/Monster-Sounds-Volume-2/Monster-1.wav", OGA + "monster_ogrebane/Monster-Sounds-Volume-2/Monster-4.wav"], -6.0, 0.7, 0.8],
	"rammer_charge": [[OGA + "monster_ogrebane/Monster-Sounds-Volume-2/Monster-7.wav", OGA + "monster_ogrebane/Monster-Sounds-Volume-2/monster-12.wav"], -2.0, 0.65, 0.75],
	"rammer_hurt": [[OGA + "monster_ogrebane/Monster-Sounds-Volume-2/Monster-3.wav", OGA + "monster_ogrebane/Monster-Sounds-Volume-2/Monster-8.wav", OGA + "monster_ogrebane/Monster-Sounds-Volume-2/Monster-2.wav"], -5.0, 1.0, 1.15],
	"rammer_death": [[OGA + "monster_ogrebane/Monster-Sounds-Volume-2/monster-16.wav", OGA + "monster_ogrebane/Monster-Sounds-Volume-2/monster-18.wav"], -2.0, 0.6, 0.7],
	"hunter_idle": [[OGA + "monster_starninjas/monster.6.ogg", OGA + "monster_starninjas/monster.11.ogg"], -7.0, 0.85, 0.95],
	"hunter_burst": [[OGA + "monster_ogrebane/Monster-Sounds-Volume-2/monster-10.wav", OGA + "monster_ogrebane/Monster-Sounds-Volume-2/monster-14.wav"], -5.0, 0.95, 1.1],
	"hunter_hurt": [[OGA + "monster_starninjas/monster.13.ogg", OGA + "monster_ogrebane/Monster-Sounds-Volume-2/Monster-5.wav"], -6.0, 0.9, 1.05],
	"hunter_death": [[OGA + "monster_ogrebane/Monster-Sounds-Volume-2/monster-17.wav", OGA + "monster_ogrebane/Monster-Sounds-Volume-2/monster-15.wav"], -3.0, 0.85, 0.95],
	# Beds.
	"ambience_wind": [[OGA + "wind_whoosh_loop.ogg"], -18.0, 0.9, 0.9],
}

const POOL_SIZE := 14
var _streams := {}
var _pool: Array[AudioStreamPlayer3D] = []
var _flat: Array[AudioStreamPlayer] = []
var _next := 0
var _ambience: AudioStreamPlayer

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer3D.new()
		p.max_distance = 40.0
		p.unit_size = 6.0
		p.attenuation_filter_cutoff_hz = 8000.0
		add_child(p)
		_pool.append(p)
	for i in 6:
		var f := AudioStreamPlayer.new()
		add_child(f)
		_flat.append(f)

func _stream_for(event: String) -> AudioStream:
	if not EVENTS.has(event):
		return null
	var spec: Array = EVENTS[event]
	var paths: Array = spec[0]
	var path: String = paths[randi() % paths.size()]
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]

func has_event(event: String) -> bool:
	return EVENTS.has(event)

## Non-positional, for the player's own actions and UI.
func play(event: String, volume_offset := 0.0) -> void:
	var stream := _stream_for(event)
	if stream == null:
		return
	var spec: Array = EVENTS[event]
	var f: AudioStreamPlayer = _flat[_next % _flat.size()]
	_next += 1
	f.stream = stream
	f.volume_db = spec[1] + volume_offset
	f.pitch_scale = randf_range(spec[2], spec[3])
	f.play()

## Positional; `position` is world space.
func play_at(event: String, position: Vector3, volume_offset := 0.0) -> void:
	var stream := _stream_for(event)
	if stream == null:
		return
	var spec: Array = EVENTS[event]
	var p: AudioStreamPlayer3D = _pool[_next % _pool.size()]
	_next += 1
	p.global_position = position
	p.stream = stream
	p.volume_db = spec[1] + volume_offset
	p.pitch_scale = randf_range(spec[2], spec[3])
	p.play()

func start_ambience(event: String) -> void:
	var stream := _stream_for(event)
	if stream == null:
		return
	if _ambience == null:
		_ambience = AudioStreamPlayer.new()
		add_child(_ambience)
	var spec: Array = EVENTS[event]
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_ambience.stream = stream
	_ambience.volume_db = spec[1]
	_ambience.play()

## Convenience for scripts that may run without the autoload (headless tests).
static func bank(node: Node) -> Node:
	return node.get_tree().root.get_node_or_null("Sound") if node.is_inside_tree() else null
