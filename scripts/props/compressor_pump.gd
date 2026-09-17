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
@export var width := 5.0
@export var depth := 4.0
## How far the ram travels, and the frame's crossbeam height above the housing.
@export var stroke := 3.0
@export var frame_height := 6.5
## Seconds for one stroke: down, a hold, then the slow climb back.
@export var period := 5.0
## Seconds into the stroke at the start, so a row of pumps ripples.
@export var phase := 0.0

var _ram: Node3D
var _steam: CPUParticles3D
var _clock := 0.0
var _bottomed := false

func _ready() -> void:
	var collar := _mesh(CylinderMesh.new(), "dark", self)
	var ring := collar.mesh as CylinderMesh
	ring.top_radius = RAM_RADIUS + 0.3
	ring.bottom_radius = RAM_RADIUS + 0.4
	ring.height = COLLAR
	collar.position.y = COLLAR / 2.0
	for side in [-1.0, 1.0]:
		var upright := _mesh(BoxMesh.new(), "metal_blue", self)
		(upright.mesh as BoxMesh).size = Vector3(0.5, frame_height, minf(0.7, depth))
		upright.position = Vector3(side * (width / 2.0 - 0.35), frame_height / 2.0, 0)
	var beam := _mesh(BoxMesh.new(), "metal_blue", self)
	(beam.mesh as BoxMesh).size = Vector3(width, 0.7, 0.9)
	beam.position.y = frame_height
	var band := _mesh(BoxMesh.new(), "hazard", self)
	(band.mesh as BoxMesh).size = Vector3(width + 0.02, 0.22, 0.92)
	band.position.y = frame_height - 0.2

	# The ram: a head that seats in the collar and a rod up through the crossbeam. Its node
	# rises by up to `stroke`.
	_ram = Node3D.new()
	add_child(_ram)
	var head := _mesh(CylinderMesh.new(), "rust", _ram)
	var drum := head.mesh as CylinderMesh
	drum.top_radius = RAM_RADIUS
	drum.bottom_radius = RAM_RADIUS
	drum.height = RAM_LENGTH
	head.position.y = COLLAR + RAM_LENGTH / 2.0
	var rod_length := frame_height + 0.6 - COLLAR - RAM_LENGTH
	var rod := _mesh(CylinderMesh.new(), "dark", _ram)
	var bar := rod.mesh as CylinderMesh
	bar.top_radius = 0.3
	bar.bottom_radius = 0.3
	bar.height = rod_length
	rod.position.y = COLLAR + RAM_LENGTH + rod_length / 2.0
	_ram.position.y = stroke

	_steam = CPUParticles3D.new()
	_steam.emitting = false
	_steam.one_shot = true
	_steam.explosiveness = 0.7
	_steam.amount = 24
	_steam.lifetime = 1.1
	_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_steam.emission_sphere_radius = RAM_RADIUS
	_steam.direction = Vector3(0, 1, 0)
	_steam.spread = 70.0
	_steam.initial_velocity_min = 2.5
	_steam.initial_velocity_max = 5.0
	_steam.damping_min = 2.0
	_steam.damping_max = 4.0
	_steam.scale_amount_min = 0.8
	_steam.scale_amount_max = 1.8
	var puff := QuadMesh.new()
	puff.size = Vector2(0.8, 0.8)
	var steam := StandardMaterial3D.new()
	steam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	steam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	steam.billboard_keep_scale = true
	steam.albedo_color = Color(0.95, 0.95, 0.95, 0.45)
	puff.material = steam
	_steam.mesh = puff
	_steam.position.y = COLLAR + 0.2
	add_child(_steam)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_clock += delta
	var t := fmod(_clock + phase, period)
	var hold_end := DOWN_SECONDS + HOLD_SECONDS
	if t < DOWN_SECONDS:
		# Speeding up all the way down.
		var u := t / DOWN_SECONDS
		_ram.position.y = stroke * (1.0 - u * u)
	elif t < hold_end:
		_ram.position.y = 0.0
	else:
		_ram.position.y = stroke * smoothstep(0.0, 1.0, (t - hold_end) / (period - hold_end))
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

func _mesh(mesh: Mesh, material: String, parent: Node) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = load("res://materials/retro/%s.tres" % material)
	parent.add_child(node)
	return node
