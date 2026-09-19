@tool
extends StaticBody3D
## A coolant pipe on the smog machine. Kicks and shots both break it: three kicks, or
## about ten pistol hits. Every hit vents gas, harder as it weakens; the last one
## bursts it and it vents until told to stop. While not exposed (its pressure arm is up
## or moving) hits only clang off it.

signal broken(pipe: Node)

var size := Vector3(0.9, 3.0, 0.9)
## Ten pistol hits at 22. A kick takes a third of this whatever the kick damage is.
@export var hp := 220.0

var is_broken := false
## Only an exposed pipe takes damage.
var exposed := true
var _hp := 0.0
var _body: Node3D
var _gas: CPUParticles3D

func _ready() -> void:
	_hp = hp
	_body = $Body
	_gas = $Gas
	# Size follows the saved hitbox; no geometry or material is rebuilt here.
	size = ($Shape.shape as BoxShape3D).size

func apply_kick(_damage: float, _from: Vector3, _force: float) -> void:
	_hit(hp / 3.0 + 0.01, "kick_prop")

func apply_shot(amount: float, _from: Vector3, _push: float, _weak := false) -> void:
	_hit(amount, "weak_hit")

func take_damage(amount: float, _weak := false) -> void:
	_hit(amount, "weak_hit")

func _hit(amount: float, sound: String) -> void:
	if is_broken:
		return
	if not exposed:
		var clang := get_tree().root.get_node_or_null("Sound")
		if clang:
			clang.play_at("kick_prop", global_position, -6.0)
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

## Snaps `amount` off the bottom. The arm carries what's left away, and its pipe foot stays
## behind in the socket, which scripts/props/pressure_arm.gd builds. The broken end vents.
func snap(amount: float) -> void:
	var left := maxf(0.5, size.y - amount)
	# Where the shortened pipe's middle sits, measured from the whole pipe's middle.
	var centre := size.y / 2.0 - left / 2.0
	var foot := centre - left / 2.0
	for child in _body.get_children():
		var part := child as MeshInstance3D
		if part == null:
			continue
		if part.mesh is CylinderMesh:
			(part.mesh as CylinderMesh).height = left
			part.position.y = centre
		elif part.mesh is BoxMesh and absf((part.mesh as BoxMesh).size.y - size.y) < 0.01:
			(part.mesh as BoxMesh).size.y = left
			part.position.y = centre
		elif part.position.y < foot + 0.25:
			# A hazard collar below the break comes up to sit just above it.
			part.position.y = foot + 0.25
	for child in get_children():
		var shape := child as CollisionShape3D
		if shape == null or not (shape.shape is BoxShape3D):
			continue
		(shape.shape as BoxShape3D).size.y = left
		shape.position.y = centre
	if _gas:
		_gas.position.y = foot + 0.1

## Ends the venting a burst started.
func stop_venting() -> void:
	_gas.emitting = false
