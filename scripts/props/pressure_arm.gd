@tool
extends Node3D
@export var warning_on: Material
@export var warning_off: Material
@export var stub_scene: PackedScene
## One of the smog machine's pressure arms: a shoulder on the machine's roof edge, an upper
## arm out to an elbow, and a forearm hanging straight down from the elbow with a coolant pipe
## at its foot. Breaking the pipe snaps it off at the floor: the arm pulls the rest away and a
## torn stub of pipe stays in the socket, wisping gas. Down, the pipe plugs into a socket in the pit floor and can be broken. Up, the
## elbow rises by `lift` and the pipe hangs out of reach. A beacon on the elbow spins while the
## arm is about to come down. Driven by scripts/levels/machine_set_piece.gd, which sits at the
## world origin, so the points here are world points.

signal broken(arm: Node)

const PIPE_SIZE := Vector3(0.9, 3.0, 0.9)
const ARM_WIDTH := 0.7
const BEACON_SPIN := 9.0
## How much of the pipe snaps off and stays standing in the socket, and the teeth round its
## torn rim.
const STUB_HEIGHT := 0.75
const STUB_TEETH := 5

@export var number := 1
var shoulder := Vector3.ZERO
## Elbow and socket with the arm down.
var elbow := Vector3.ZERO
var socket := Vector3.ZERO
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
var _rest_hang := Vector3.ZERO
var _anchor := Vector3.ZERO
var _upper_thickness := Vector2.ONE
var _hang: Node3D
var _upper: MeshInstance3D
var _solids: Array[CollisionShape3D] = []
var _beacon: Node3D
var _beacon_lamp: MeshInstance3D
var _beacon_light: SpotLight3D
var _socket_steam: CPUParticles3D

func _ready() -> void:
	_hang = $Hang
	_upper = $UpperArm
	pipe = $Hang/CoolantPipe
	_beacon = $Hang/Beacon
	_beacon_lamp = $Hang/Beacon/Lamp
	_beacon_light = $Hang/Beacon/Light
	_socket_steam = $SocketSteam
	_rest_hang = _hang.position
	_anchor = $ShoulderPivot.position
	_upper_thickness = Vector2(_upper.scale.x,_upper.scale.y)
	socket = $Socket.global_position
	elbow = to_global(_rest_hang-Vector3.UP*lift)
	shoulder = to_global(_anchor)-Vector3.UP*0.45
	_solids.assign([$Hang/Forearm/Shape,$Hang/CoolantPipe/Shape])
	if Engine.is_editor_hint(): return
	pipe.set("exposed", false)
	pipe.connect("broken",func(_p: Node) -> void:
		_snap_off()
		broken.emit(self))

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
	_beacon_lamp.material_override = warning_on if on else warning_off

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
	if stub != null: return
	pipe.call("snap",STUB_HEIGHT)
	stub = stub_scene.instantiate()
	stub.name = "BrokenPipe%d" % number
	add_child(stub)
	stub.position = $Socket.position
	for child in stub.get_children():
		if child is CPUParticles3D: child.emitting = true

## World position of the pipe foot, including a moved assembly root.

func pipe_foot() -> Vector3:
	return to_global(_hang.position + Vector3(0, socket.y - elbow.y, 0))

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
	if _hang == null: return
	_hang.position = _rest_hang-Vector3.UP*lift*lowered
	var direction := _hang.position-_anchor
	_upper.position = _anchor+direction/2.0
	_upper.basis = Basis.looking_at(direction.normalized(),Vector3.UP)
	_upper.scale = Vector3(_upper_thickness.x,_upper_thickness.y,direction.length()/maxf(_upper.mesh.get_aabb().size.z,0.001))
