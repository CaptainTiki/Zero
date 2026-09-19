@tool
extends Node3D
## Saved open press geometry; runtime motion inherits the level's pause mode.
@export var phase := 0.0
@export var period := 5.2
@export var stroke := 1.08
var _rest_head_y := 0.0
var _rest_rod_y := 0.0
var _rest_rod_scale := 1.0
var _rod_mesh_height := 1.0
var clock := 0.0
var bottomed := false
var steam_pulses := 0
func _ready() -> void:
	# The saved pose is authoritative, including edits made directly in the asset.
	_rest_head_y = get_node("MovingHead").position.y
	var rod: MeshInstance3D = get_node("HydraulicRam")
	_rest_rod_y = rod.position.y
	_rest_rod_scale = rod.scale.y
	_rod_mesh_height = maxf(rod.mesh.get_aabb().size.y,0.001)
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	clock = phase
	set_pose(0.0)
func set_pose(lowered: float) -> void:
	var head: AnimatableBody3D = get_node("MovingHead")
	var travel := stroke*clampf(lowered,0.0,1.0)
	head.position.y = _rest_head_y-travel
	var rod: MeshInstance3D = get_node("HydraulicRam")
	rod.position.y = _rest_rod_y-travel/2.0
	rod.scale.y = _rest_rod_scale+travel/_rod_mesh_height
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	clock += delta
	var t := fmod(clock,period)
	var lowered := 0.0
	if t < 1.0:
		lowered = smoothstep(0.0,1.0,t)
	elif t < 1.5:
		lowered = 1.0
	elif t < 3.2:
		lowered = 1.0-smoothstep(1.5,3.2,t)
	set_pose(lowered)
	var down := t>=1.0 and t<1.5
	if down and not bottomed:
		get_node("ExhaustSteam").restart()
		steam_pulses += 1
	bottomed = down
