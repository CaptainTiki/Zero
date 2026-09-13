extends Area3D
## The Hunter's projectile: big, bright, slow enough to sidestep. Damages the
## player on contact, pops on anything else, and fades out after `lifetime`.

@export var speed := 13.0
@export var damage := 14.0
@export var lifetime := 4.0

var _direction := Vector3.FORWARD
var _age := 0.0
var _mesh: MeshInstance3D
var _light: OmniLight3D

func launch(from: Vector3, direction: Vector3) -> void:
	global_position = from
	_direction = direction.normalized()

func _ready() -> void:
	collision_layer = 0
	collision_mask = 3 # world and player
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	shape.shape = sphere
	add_child(shape)
	_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	sm.radial_segments = 8
	sm.rings = 4
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.55, 0.15)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.45, 0.1)
	m.emission_energy_multiplier = 2.5
	sm.material = m
	_mesh.mesh = sm
	add_child(_mesh)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.55, 0.2)
	_light.light_energy = 1.4
	_light.omni_range = 4.0
	add_child(_light)
	body_entered.connect(_on_body)
	monitoring = true

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	global_position += _direction * speed * delta
	_mesh.scale = Vector3.ONE * (1.0 + sin(_age * 25.0) * 0.12)

func _on_body(body: Node) -> void:
	if body.is_in_group("enemies"):
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.play_at("weak_hit", global_position, -4.0)
	queue_free()
