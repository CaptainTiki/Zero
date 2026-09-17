@tool
extends Node3D
## One of the smog machine's pressure arms: a shoulder on the machine's roof edge, an upper
## arm out to an elbow, and a forearm hanging straight down from the elbow with a coolant pipe
## at its foot. Breaking the pipe snaps it off at the floor: the arm pulls the rest away and a
## torn stub of pipe stays in the socket, wisping gas. Down, the pipe plugs into a socket in the pit floor and can be broken. Up, the
## elbow rises by `lift` and the pipe hangs out of reach. A beacon on the elbow spins while the
## arm is about to come down. Driven by scripts/levels/machine_set_piece.gd, which sits at the
## world origin, so the points here are world points.

signal broken(arm: Node)

const PIPE := preload("res://scripts/props/coolant_pipe.gd")
const PIPE_SIZE := Vector3(0.9, 3.0, 0.9)
const ARM_WIDTH := 0.7
const BEACON_SPIN := 9.0
## How much of the pipe snaps off and stays standing in the socket, and the teeth round its
## torn rim.
const STUB_HEIGHT := 0.75
const STUB_TEETH := 5

@export var number := 1
@export var shoulder := Vector3.ZERO
## Elbow and socket with the arm down.
@export var elbow := Vector3.ZERO
@export var socket := Vector3.ZERO
@export var lift := 5.0

## 0 is up, 1 is down and plugged in.
var lowered := 0.0:
	set(value):
		lowered = value
		_pose()
## The coolant pipe at the forearm's foot, scripts/props/coolant_pipe.gd.
var pipe: Node3D
## The broken-off foot of the pipe, once its pipe has been broken.
var stub: Node3D
var moving := false
var warning := false
var _hang: Node3D
var _upper: MeshInstance3D
var _solids: Array[CollisionShape3D] = []
var _beacon: Node3D
var _beacon_lamp: MeshInstance3D
var _beacon_light: SpotLight3D
var _socket_steam: CPUParticles3D

func _ready() -> void:
	var shoulder_cap := _mesh(BoxMesh.new(), "dark", self)
	(shoulder_cap.mesh as BoxMesh).size = Vector3(1.3, 0.9, 1.3)
	shoulder_cap.position = shoulder + Vector3(0, 0.45, 0)
	_upper = _mesh(BoxMesh.new(), "rust", self)
	(_upper.mesh as BoxMesh).size = Vector3(ARM_WIDTH, ARM_WIDTH, 1.0)
	var plate := _mesh(CylinderMesh.new(), "hazard", self)
	var disc := plate.mesh as CylinderMesh
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.06
	plate.position = socket + Vector3(0, 0.03, 0)

	_hang = Node3D.new()
	add_child(_hang)
	var joint := _mesh(BoxMesh.new(), "metal_blue", _hang)
	(joint.mesh as BoxMesh).size = Vector3(1.1, 1.1, 1.1)
	# The forearm runs from the elbow down to the top of the pipe.
	var reach := elbow.y - socket.y
	var forearm_length := reach - PIPE_SIZE.y
	var forearm := StaticBody3D.new()
	forearm.position = Vector3(0, -forearm_length / 2.0, 0)
	_hang.add_child(forearm)
	var arm_shape := CollisionShape3D.new()
	var arm_box := BoxShape3D.new()
	arm_box.size = Vector3(ARM_WIDTH, forearm_length, ARM_WIDTH)
	arm_shape.shape = arm_box
	forearm.add_child(arm_shape)
	_solids.append(arm_shape)
	var forearm_mesh := _mesh(BoxMesh.new(), "rust", forearm)
	(forearm_mesh.mesh as BoxMesh).size = arm_box.size
	pipe = StaticBody3D.new()
	pipe.set_script(PIPE)
	pipe.name = "CoolantPipe%d" % number
	pipe.set("size", PIPE_SIZE)
	pipe.position = Vector3(0, -reach + PIPE_SIZE.y / 2.0, 0)
	_hang.add_child(pipe)
	pipe.set("exposed", false)
	pipe.connect("broken", func(_p: Node) -> void:
		_snap_off()
		broken.emit(self))
	for child in pipe.get_children():
		if child is CollisionShape3D:
			_solids.append(child)

	_beacon = Node3D.new()
	_beacon.position = Vector3(0, 0.75, 0)
	_hang.add_child(_beacon)
	_beacon_lamp = MeshInstance3D.new()
	var dome := CylinderMesh.new()
	dome.top_radius = 0.2
	dome.bottom_radius = 0.35
	dome.height = 0.45
	_beacon_lamp.mesh = dome
	_beacon_lamp.material_override = _glow(Color(0.35, 0.05, 0.04), 0.0)
	_beacon.add_child(_beacon_lamp)
	_beacon_light = SpotLight3D.new()
	_beacon_light.light_color = Color(1.0, 0.15, 0.08)
	_beacon_light.light_energy = 6.0
	_beacon_light.spot_range = 22.0
	_beacon_light.spot_angle = 28.0
	_beacon_light.visible = false
	# Out and a little down, so the sweep crosses the pit walls and floor.
	_beacon_light.rotation = Vector3(deg_to_rad(-25.0), 0, 0)
	_beacon.add_child(_beacon_light)

	_socket_steam = CPUParticles3D.new()
	_socket_steam.emitting = false
	_socket_steam.amount = 30
	_socket_steam.lifetime = 1.0
	_socket_steam.direction = Vector3(0, 1, 0)
	_socket_steam.spread = 20.0
	_socket_steam.initial_velocity_min = 5.0
	_socket_steam.initial_velocity_max = 8.0
	_socket_steam.damping_min = 2.0
	_socket_steam.damping_max = 4.0
	_socket_steam.scale_amount_min = 0.8
	_socket_steam.scale_amount_max = 1.8
	var puff := QuadMesh.new()
	puff.size = Vector2(0.7, 0.7)
	var steam := StandardMaterial3D.new()
	steam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	steam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	steam.albedo_color = Color(0.95, 0.95, 0.95, 0.5)
	puff.material = steam
	_socket_steam.mesh = puff
	_socket_steam.position = socket + Vector3(0, 0.2, 0)
	add_child(_socket_steam)
	_pose()
	# In the editor, show where the broken stub will be left standing.
	if Engine.is_editor_hint():
		var ghost := StandardMaterial3D.new()
		ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost.albedo_color = Color(1.0, 0.45, 0.1, 0.35)
		var mark := Node3D.new()
		mark.name = "BrokenPipeMark%d" % number
		add_child(mark)
		mark.position = socket
		_stub_meshes(mark, ghost)

func _process(delta: float) -> void:
	if warning and not Engine.is_editor_hint():
		_beacon.rotate_y(delta * BEACON_SPIN)

## Comes down and plugs in. Solid only once it has arrived, so it never lands on anyone.
func lower(seconds: float) -> Tween:
	return _move(1.0, seconds, Tween.EASE_IN)

func raise(seconds: float) -> Tween:
	pipe.set("exposed", false)
	return _move(0.0, seconds, Tween.EASE_OUT)

func warn(on: bool) -> void:
	warning = on
	_beacon_light.visible = on
	_beacon_lamp.material_override = _glow(Color(1.0, 0.15, 0.08), 3.0) if on else _glow(Color(0.35, 0.05, 0.04), 0.0)

## Steam from both broken ends: the pipe's foot and the socket it came out of.
func vent(seconds: float) -> void:
	_socket_steam.emitting = true
	get_tree().create_timer(seconds, false).timeout.connect(func() -> void:
		_socket_steam.emitting = false
		if pipe.get("is_broken"):
			pipe.call("stop_venting"))

## The pipe breaks off at the floor: the arm pulls what's left away, and this foot stays in
## the socket, torn open and wisping gas. Its collision is low and round, so a chase slides
## round it and the player can jump it.
func _snap_off() -> void:
	if stub != null:
		return
	if pipe.has_method("snap"):
		pipe.call("snap", STUB_HEIGHT)
	var body := StaticBody3D.new()
	body.name = "BrokenPipe%d" % number
	add_child(body)
	body.position = socket
	var shape := CollisionShape3D.new()
	var post := CylinderShape3D.new()
	post.radius = PIPE_SIZE.x / 2.0
	post.height = STUB_HEIGHT
	shape.shape = post
	shape.position.y = STUB_HEIGHT / 2.0
	body.add_child(shape)
	_stub_meshes(body, null)
	# A thin curl of gas from then on: the pressure it was holding, still leaking.
	var wisp := CPUParticles3D.new()
	wisp.amount = 5
	wisp.lifetime = 1.0
	wisp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	wisp.emission_sphere_radius = 0.2
	wisp.direction = Vector3(0, 1, 0)
	wisp.spread = 30.0
	wisp.initial_velocity_min = 0.9
	wisp.initial_velocity_max = 1.8
	wisp.damping_min = 1.0
	wisp.damping_max = 2.0
	wisp.scale_amount_min = 0.3
	wisp.scale_amount_max = 0.7
	wisp.mesh = _puff(0.45, 0.18)
	wisp.position.y = STUB_HEIGHT
	body.add_child(wisp)
	wisp.emitting = true
	stub = body

## The stub's pieces: a short length of pipe, a hazard collar, and a torn rim of metal teeth,
## no two the same height. Pass a material for the editor's see-through stand-in.
func _stub_meshes(parent: Node3D, ghost: StandardMaterial3D) -> void:
	var metal := ghost if ghost else load("res://materials/retro/metal_blue.tres")
	var mesh := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = PIPE_SIZE.x / 2.0
	tube.bottom_radius = PIPE_SIZE.x / 2.0
	tube.height = STUB_HEIGHT
	tube.radial_segments = 10
	mesh.mesh = tube
	mesh.position.y = STUB_HEIGHT / 2.0
	mesh.material_override = metal
	parent.add_child(mesh)
	var collar := MeshInstance3D.new()
	var band := BoxMesh.new()
	band.size = Vector3(PIPE_SIZE.x + 0.12, 0.2, PIPE_SIZE.z + 0.12)
	collar.mesh = band
	collar.position.y = 0.22
	collar.material_override = ghost if ghost else load("res://materials/retro/hazard.tres")
	parent.add_child(collar)
	for i in STUB_TEETH:
		var angle := TAU * float(i) / float(STUB_TEETH)
		var high := 0.1 + fmod(float(number) * 0.37 + float(i) * 0.23, 0.26)
		var tooth := MeshInstance3D.new()
		var chip := BoxMesh.new()
		chip.size = Vector3(0.22, high, 0.16)
		tooth.mesh = chip
		tooth.material_override = metal
		tooth.position = Vector3(sin(angle) * (PIPE_SIZE.x / 2.0 - 0.08), STUB_HEIGHT + high / 2.0 - 0.05, cos(angle) * (PIPE_SIZE.z / 2.0 - 0.08))
		tooth.rotation = Vector3(0.18 * cos(angle), -angle, 0.18 * sin(angle))
		parent.add_child(tooth)

## A soft billboarded steam quad.
func _puff(size: float, alpha: float) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var steam := StandardMaterial3D.new()
	steam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	steam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	steam.billboard_keep_scale = true
	steam.albedo_color = Color(0.95, 0.95, 0.95, alpha)
	# Particle colour fades the puff out over its life.
	steam.vertex_color_use_as_albedo = true
	quad.material = steam
	return quad

## Where the pipe's foot is now.
func pipe_foot() -> Vector3:
	return _hang.position + Vector3(0, socket.y - elbow.y, 0)

func _move(target: float, seconds: float, easing: Tween.EaseType) -> Tween:
	moving = true
	for shape in _solids:
		shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "lowered", target, seconds).set_trans(Tween.TRANS_QUAD).set_ease(easing)
	tween.tween_callback(func() -> void:
		moving = false
		for shape in _solids:
			shape.set_deferred("disabled", false))
	return tween

func _pose() -> void:
	if _hang == null:
		return
	_hang.position = elbow + Vector3(0, lift * (1.0 - lowered), 0)
	var from := shoulder + Vector3(0, 0.45, 0)
	var dir := _hang.position - from
	_upper.position = from + dir / 2.0
	_upper.basis = Basis.looking_at(dir.normalized(), Vector3.UP)
	_upper.scale = Vector3(1, 1, dir.length())

func _mesh(mesh: Mesh, material: String, parent: Node) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = load("res://materials/retro/%s.tres" % material)
	parent.add_child(node)
	return node

func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = energy > 0.0
	m.emission = color
	m.emission_energy_multiplier = energy
	return m
