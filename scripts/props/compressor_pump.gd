@tool
extends Node3D
## A compressor pump in the factory's compressor hall: a frame over its housing, and a ram that
## drives down, hisses steam as it bottoms out, then creeps back up. Visual only; the housing
## under it is a blocker from the plan. It sits at the middle of the housing's top.
## A tool script, so the editor shows the frame with the ram at the top of its stroke.

const DOWN_SECONDS := 0.5
const HOLD_SECONDS := 0.6
const RAM_RADIUS := 1.1
const RAM_LENGTH := 1.4
const COLLAR := 0.5
## Hisses only when the player is near enough to hear, so a hall of pumps doesn't use up the
## sound bank's players while the fight is elsewhere.
const HEAR_RANGE := 36.0

## The housing's footprint, x by z, which the frame straddles.
var width := 5.0
var depth := 4.0
## How far the ram travels, and the frame's crossbeam height above the housing.
@export var stroke := 3.0
var frame_height := 6.5
## Seconds for one stroke: down, a hold, then the slow climb back.
@export var period := 5.0
## Seconds into the stroke at the start, so a row of pumps ripples.
@export var phase := 0.0

var _base_y := 0.0
var _ram: Node3D
var _steam: CPUParticles3D
var _clock := 0.0
var _bottomed := false

func _ready() -> void:
	_ram = $Ram
	_steam = $Steam
	_base_y = _ram.position.y-stroke

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_clock += delta
	var t := fmod(_clock + phase, period)
	var hold_end := DOWN_SECONDS + HOLD_SECONDS
	if t < DOWN_SECONDS:
		# Speeding up all the way down.
		var u := t / DOWN_SECONDS
		_ram.position.y = _base_y + stroke * (1.0 - u * u)
	elif t < hold_end:
		_ram.position.y = _base_y
	else:
		_ram.position.y = _base_y + stroke * smoothstep(0.0, 1.0, (t - hold_end) / (period - hold_end))
	var bottomed := t >= DOWN_SECONDS and t < hold_end
	if bottomed and not _bottomed:
		_hiss()
	_bottomed = bottomed

func _hiss() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or player.global_position.distance_to(global_position) > HEAR_RANGE:
		return
	_steam.restart()
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.play_at("steam_hiss", global_position + Vector3(0, 1.0, 0), -10.0)
