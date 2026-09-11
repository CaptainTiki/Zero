extends StaticBody3D
## A latched door that swings away from the kicker and stays open.

signal kicked_open
signal opening_finished

var is_open := false
var _hinge: Node3D
var _panel_collision: CollisionShape3D
var _impact_audio: AudioStreamPlayer3D

func _ready() -> void:
	_impact_audio = AudioStreamPlayer3D.new()
	_impact_audio.stream = AudioStreamWAV.load_from_file("res://audio/sfx/props/door_kick.wav")
	_impact_audio.volume_db = -5.0
	_impact_audio.position.y = 1.3
	add_child(_impact_audio)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.28, 0.37, 0.32)
	paint.roughness = 0.75
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.13, 0.15, 0.16)
	metal.metallic = 0.5
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color(0.47, 0.45, 0.40)
	# Fill the existing six-metre opening with a connected wall and door frame.
	_frame_piece(Vector3(2, 6, 0.6), Vector3(-2, 3, 0), concrete)
	_frame_piece(Vector3(2, 6, 0.6), Vector3(2, 3, 0), concrete)
	_frame_piece(Vector3(2, 3.2, 0.6), Vector3(0, 4.4, 0), concrete)
	_hinge = Node3D.new()
	_hinge.position = Vector3(-1, 0, 0)
	add_child(_hinge)
	_mesh(_hinge, Vector3(1.96, 2.76, 0.14), Vector3(1, 1.4, 0), paint)
	_mesh(_hinge, Vector3(1.8, 0.35, 0.17), Vector3(1, 0.35, 0), metal)
	_mesh(_hinge, Vector3(0.12, 0.28, 0.23), Vector3(1.78, 1.25, 0), metal)
	_panel_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 2.8, 0.18)
	_panel_collision.shape = shape
	_panel_collision.position = Vector3(0, 1.4, 0)
	add_child(_panel_collision)
	var label := Label3D.new()
	label.text = "MAINTENANCE\n[F] KICK"
	label.font_size = 56
	label.pixel_size = 0.003
	label.position = Vector3(1, 1.95, 0.09)
	_hinge.add_child(label)

func _mesh(parent: Node3D, size: Vector3, offset: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	visual.mesh = box
	visual.material_override = material
	visual.position = offset
	parent.add_child(visual)

func _frame_piece(size: Vector3, offset: Vector3, material: Material) -> void:
	var wall := StaticBody3D.new()
	wall.position = offset
	add_child(wall)
	_mesh(wall, size, Vector3.ZERO, material)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	wall.add_child(collision)

func apply_kick(_damage: float, from: Vector3, _force: float) -> void:
	if is_open:
		return
	is_open = true
	kicked_open.emit()
	_impact_audio.play()
	_panel_collision.set_deferred("disabled", true)
	var swing := 1.0 if to_local(from).z >= 0.0 else -1.0
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(_hinge, "rotation:y", swing * deg_to_rad(105.0), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hinge, "rotation:y", swing * deg_to_rad(96.0), 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): opening_finished.emit())
