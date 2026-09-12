extends RefCounted
class_name ViewKit
## Procedural first-person rigs: gloved fists, pistol, pump shotgun, boot.
## Each builder returns a Node3D whose children are plain MeshInstance3Ds, so
## the controller can nudge named parts (slide, pump) for animation.

static func _mat(color: Color, metallic := 0.0, roughness := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

static func _box(parent: Node3D, name_text: String, size: Vector3, at: Vector3, m: Material, tilt := Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name_text
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = m
	part.mesh = mesh
	part.position = at
	part.rotation = tilt
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part

static func _cyl(parent: Node3D, name_text: String, radius: float, height: float, at: Vector3, m: Material, tilt := Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name_text
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.material = m
	part.mesh = mesh
	part.position = at
	part.rotation = tilt
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part

const GLOVE := Color(0.24, 0.16, 0.1)
const SLEEVE := Color(0.27, 0.31, 0.18)
const SKIN := Color(0.85, 0.66, 0.5)
const STEEL := Color(0.16, 0.17, 0.19)
const WOOD := Color(0.42, 0.24, 0.12)

static func hand(name_text: String, mirror: float) -> Node3D:
	var rig := Node3D.new()
	rig.name = name_text
	var glove := _mat(GLOVE)
	var sleeve := _mat(SLEEVE)
	_box(rig, "Palm", Vector3(0.16, 0.12, 0.18), Vector3.ZERO, glove)
	for i in 4:
		_box(rig, "Finger%d" % i, Vector3(0.035, 0.05, 0.11), Vector3(-0.058 + i * 0.038, 0.0, -0.13), glove, Vector3(-0.35, 0, 0))
	_box(rig, "Thumb", Vector3(0.04, 0.05, 0.09), Vector3(mirror * 0.1, 0.02, -0.04), glove, Vector3(0, mirror * -0.6, 0))
	_box(rig, "Cuff", Vector3(0.19, 0.15, 0.08), Vector3(0, 0.0, 0.12), sleeve)
	_box(rig, "Forearm", Vector3(0.17, 0.14, 0.4), Vector3(0, -0.01, 0.34), sleeve)
	return rig

static func fists() -> Node3D:
	var rig := Node3D.new()
	rig.name = "FistsRig"
	var right := hand("Right", 1.0)
	right.position = Vector3(0.14, 0.0, 0.0)
	right.rotation = Vector3(0.1, -0.15, 0.3)
	rig.add_child(right)
	var left := hand("Left", -1.0)
	left.position = Vector3(-0.3, -0.03, 0.06)
	left.rotation = Vector3(0.1, 0.15, -0.3)
	rig.add_child(left)
	return rig

static func pistol() -> Node3D:
	var rig := Node3D.new()
	rig.name = "PistolRig"
	var steel := _mat(STEEL, 0.6, 0.35)
	var grip := _mat(Color(0.1, 0.1, 0.11), 0.0, 0.8)
	_box(rig, "Frame", Vector3(0.07, 0.07, 0.24), Vector3(0, -0.02, 0.0), steel)
	_box(rig, "Slide", Vector3(0.075, 0.06, 0.28), Vector3(0, 0.045, -0.02), steel)
	_box(rig, "Muzzle", Vector3(0.03, 0.03, 0.04), Vector3(0, 0.045, -0.18), grip)
	_box(rig, "FrontSight", Vector3(0.012, 0.025, 0.012), Vector3(0, 0.085, -0.14), grip)
	_box(rig, "RearSight", Vector3(0.05, 0.02, 0.012), Vector3(0, 0.082, 0.1), grip)
	_box(rig, "Grip", Vector3(0.065, 0.16, 0.08), Vector3(0, -0.12, 0.09), grip, Vector3(0.28, 0, 0))
	_box(rig, "TriggerGuard", Vector3(0.02, 0.05, 0.06), Vector3(0, -0.075, 0.0), steel)
	var hand_rig := hand("Hand", 1.0)
	hand_rig.position = Vector3(0.0, -0.13, 0.12)
	hand_rig.rotation = Vector3(0.25, 0, 0)
	rig.add_child(hand_rig)
	return rig

static func shotgun() -> Node3D:
	var rig := Node3D.new()
	rig.name = "ShotgunRig"
	var steel := _mat(STEEL, 0.55, 0.4)
	var wood := _mat(WOOD, 0.0, 0.7)
	var dark := _mat(Color(0.08, 0.08, 0.09), 0.2, 0.6)
	_cyl(rig, "Barrel", 0.022, 0.62, Vector3(0, 0.03, -0.3), steel, Vector3(PI / 2, 0, 0))
	_cyl(rig, "MagTube", 0.02, 0.5, Vector3(0, -0.02, -0.26), steel, Vector3(PI / 2, 0, 0))
	_box(rig, "Receiver", Vector3(0.075, 0.09, 0.22), Vector3(0, 0.0, 0.08), steel)
	_box(rig, "Ejection", Vector3(0.08, 0.035, 0.07), Vector3(0.0, 0.02, 0.05), dark)
	_box(rig, "Pump", Vector3(0.06, 0.06, 0.16), Vector3(0, -0.02, -0.26), wood)
	for i in 4:
		_box(rig, "PumpGroove%d" % i, Vector3(0.065, 0.065, 0.008), Vector3(0, -0.02, -0.32 + i * 0.04), dark)
	_box(rig, "FrontBead", Vector3(0.012, 0.02, 0.012), Vector3(0, 0.065, -0.58), dark)
	_box(rig, "Grip", Vector3(0.06, 0.13, 0.08), Vector3(0, -0.1, 0.16), wood, Vector3(0.35, 0, 0))
	_box(rig, "TriggerGuard", Vector3(0.02, 0.04, 0.07), Vector3(0, -0.065, 0.06), steel)
	_box(rig, "Stock", Vector3(0.06, 0.1, 0.34), Vector3(0, -0.04, 0.38), wood, Vector3(-0.12, 0, 0))
	var trigger_hand := hand("TriggerHand", 1.0)
	trigger_hand.position = Vector3(0.0, -0.11, 0.2)
	trigger_hand.rotation = Vector3(0.3, 0, 0)
	rig.add_child(trigger_hand)
	var pump_hand := hand("PumpHand", -1.0)
	pump_hand.name = "PumpHand"
	# Palm cups the pump from below; the forearm drops away toward the body.
	pump_hand.position = Vector3(-0.03, -0.1, -0.26)
	pump_hand.rotation = Vector3(0.9, 0.35, -1.6)
	rig.add_child(pump_hand)
	return rig

static func boot() -> Node3D:
	var rig := Node3D.new()
	rig.name = "ViewBoot"
	var leather := _mat(Color(0.19, 0.12, 0.07))
	var sole := _mat(Color(0.045, 0.04, 0.035))
	var trousers := _mat(SLEEVE)
	var lace := _mat(Color(0.7, 0.62, 0.45))
	_box(rig, "Upper", Vector3(0.23, 0.23, 0.55), Vector3.ZERO, leather)
	_box(rig, "Toe", Vector3(0.24, 0.16, 0.14), Vector3(0, -0.04, -0.3), leather)
	_box(rig, "Sole", Vector3(0.25, 0.065, 0.62), Vector3(0, -0.14, -0.03), sole)
	_box(rig, "Heel", Vector3(0.25, 0.05, 0.16), Vector3(0, -0.18, 0.2), sole)
	for i in 3:
		_box(rig, "Lace%d" % i, Vector3(0.14, 0.015, 0.02), Vector3(0, 0.12, -0.12 + i * 0.09), lace)
	_box(rig, "Shin", Vector3(0.18, 0.2, 0.65), Vector3(0, 0.1, 0.48), trousers)
	return rig
