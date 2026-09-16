extends StaticBody3D
## A coolant pipe on the smog machine. Kicks and shots both break it: three kicks, or
## about ten pistol hits. Every hit vents gas, harder as it weakens; the last one
## bursts it and it keeps venting.

signal broken(pipe: Node)

@export var size := Vector3(0.9, 3.0, 0.9)
## Ten pistol hits at 22. A kick takes a third of this whatever the kick damage is.
@export var hp := 220.0

var is_broken := false
var _hp := 0.0
var _body: Node3D
var _gas: CPUParticles3D

func _ready() -> void:
	_hp = hp
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	add_child(shape)
	_body = Node3D.new()
	add_child(_body)
	var round_pipe := absf(size.x - size.z) < 0.01
	var mesh := MeshInstance3D.new()
	if round_pipe:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = size.x / 2.0
		cylinder.bottom_radius = size.x / 2.0
		cylinder.height = size.y
		cylinder.radial_segments = 10
		mesh.mesh = cylinder
	else:
		var slab := BoxMesh.new()
		slab.size = size
		mesh.mesh = slab
	mesh.material_override = load("res://materials/retro/metal_blue.tres")
	_body.add_child(mesh)
	# Hazard collars, so the pipes read as the thing to hit.
	for y in [-0.3, 0.3]:
		var collar := MeshInstance3D.new()
		var band := BoxMesh.new()
		band.size = Vector3(size.x + 0.12, 0.22, size.z + 0.12)
		collar.mesh = band
		collar.material_override = load("res://materials/retro/hazard.tres")
		collar.position.y = size.y * y
		_body.add_child(collar)
	_gas = CPUParticles3D.new()
	_gas.emitting = false
	_gas.one_shot = true
	_gas.amount = 24
	_gas.lifetime = 0.9
	_gas.explosiveness = 0.85
	_gas.direction = Vector3(0, 1, 0)
	_gas.spread = 60.0
	_gas.initial_velocity_min = 2.0
	_gas.initial_velocity_max = 4.5
	_gas.gravity = Vector3(0, 1.5, 0)
	_gas.damping_min = 2.0
	_gas.damping_max = 3.0
	_gas.scale_amount_min = 0.5
	_gas.scale_amount_max = 1.4
	var puff := QuadMesh.new()
	puff.size = Vector2(0.6, 0.6)
	var smoke := StandardMaterial3D.new()
	smoke.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smoke.albedo_color = Color(0.85, 0.95, 0.9, 0.45)
	smoke.vertex_color_use_as_albedo = true
	puff.material = smoke
	_gas.mesh = puff
	_gas.position.y = size.y * 0.3
	add_child(_gas)

func apply_kick(_damage: float, _from: Vector3, _force: float) -> void:
	_hit(hp / 3.0 + 0.01, "kick_prop")

func apply_shot(amount: float, _from: Vector3, _push: float, _weak := false) -> void:
	_hit(amount, "weak_hit")

func take_damage(amount: float, _weak := false) -> void:
	_hit(amount, "weak_hit")

func _hit(amount: float, sound: String) -> void:
	if is_broken:
		return
	_hp -= amount
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.play_at(sound, global_position)
	var hurt := 1.0 - clampf(_hp / hp, 0.0, 1.0)
	_gas.amount = int(lerpf(12.0, 40.0, hurt))
	_gas.restart()
	var shake := create_tween()
	shake.tween_property(_body, "rotation:z", deg_to_rad(4.0 + 6.0 * hurt), 0.05)
	shake.tween_property(_body, "rotation:z", deg_to_rad(8.0 * hurt), 0.12)
	if _hp <= 0.0:
		_burst()

func _burst() -> void:
	is_broken = true
	_gas.one_shot = false
	_gas.explosiveness = 0.1
	_gas.amount = 40
	_gas.initial_velocity_max = 7.0
	_gas.emitting = true
	var bend := create_tween()
	bend.tween_property(_body, "rotation:z", deg_to_rad(28.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.play_at("kick_prop", global_position, 4.0)
	broken.emit(self)
