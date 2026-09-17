extends Area3D
## Weapon pickup. `weapon` selects which grant call the player receives.
## So nobody walks past a weapon (factory playtest 5 missed the shotgun), its model spins,
## bobs, and sits in a faint warm glow: a soft halo and a small light on the floor round it.
## Kept slight on purpose. The trigger stays put; only the model moves.

@export_enum("pistol", "shotgun") var weapon := "pistol"
const SPIN_SPEED := 1.6
const BOB_HEIGHT := 0.12
const BOB_SPEED := 2.2
const GLOW := Color(1.0, 0.82, 0.45)

var _time := 0.0
var _display: Node3D
var _display_y := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_display = Node3D.new()
	_display.name = "Display"
	add_child(_display)
	for child in get_children():
		if child is MeshInstance3D:
			child.reparent(_display, false)
	_display_y = _display.position.y
	var centre := _model_centre()
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.7, 1.7)
	var soft := GradientTexture2D.new()
	soft.fill = GradientTexture2D.FILL_RADIAL
	soft.fill_from = Vector2(0.5, 0.5)
	soft.fill_to = Vector2(1.0, 0.5)
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	soft.gradient = fade
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = false
	m.albedo_texture = soft
	m.albedo_color = Color(GLOW.r, GLOW.g, GLOW.b, 0.3)
	quad.material = m
	halo.mesh = quad
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = centre
	_display.add_child(halo)
	var light := OmniLight3D.new()
	light.name = "GlowLight"
	light.light_color = GLOW
	light.light_energy = 0.7
	light.omni_range = 2.8
	light.shadow_enabled = false
	light.distance_fade_enabled = true
	light.distance_fade_begin = 30.0
	light.distance_fade_length = 8.0
	light.position = centre + Vector3(0, 0.3, 0)
	add_child(light)

func _physics_process(delta: float) -> void:
	_time += delta
	_display.rotation.y = _time * SPIN_SPEED
	_display.position.y = _display_y + (sin(_time * BOB_SPEED) * 0.5 + 0.5) * BOB_HEIGHT

## The middle of the model's meshes, where the halo sits.
func _model_centre() -> Vector3:
	var box := AABB()
	var first := true
	for child in _display.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh:
			var part: AABB = (child as MeshInstance3D).transform * (child as MeshInstance3D).mesh.get_aabb()
			box = part if first else box.merge(part)
			first = false
	return box.get_center() if not first else Vector3.ZERO

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var method := "grant_gun" if weapon == "pistol" else "grant_shotgun"
	if body.has_method(method):
		body.call(method)
		queue_free()
