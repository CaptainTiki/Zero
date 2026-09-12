extends RefCounted
## One-shot impact visuals: dust puffs on scenery, splashes on flesh.
## Static helpers so any weapon can spawn them into the level.

static func _spawn(world: Node, at: Vector3, color: Color, size: float, life: float, drift: Vector3) -> void:
	if world == null:
		return
	var puff := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = m
	puff.mesh = mesh
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(puff)
	puff.global_position = at
	var tween := puff.create_tween().set_parallel(true)
	tween.tween_property(puff, "scale", Vector3.ONE * 2.6, life)
	tween.tween_property(puff, "global_position", at + drift, life)
	tween.tween_property(m, "albedo_color:a", 0.0, life)
	tween.chain().tween_callback(puff.queue_free)

## Dust and chips where a bullet lands on scenery.
static func puff(world: Node, at: Vector3, normal: Vector3) -> void:
	_spawn(world, at + normal * 0.03, Color(0.78, 0.72, 0.6, 0.85), 0.05, 0.28, normal * 0.25 + Vector3(0, 0.12, 0))
	var speck := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.035
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.32, 0.28)
	box.material = m
	speck.mesh = box
	speck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(speck)
	speck.global_position = at + normal * 0.02
	var side := normal.cross(Vector3.UP)
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var target := at + normal * randf_range(0.2, 0.5) + side * randf_range(-0.3, 0.3) + Vector3(0, randf_range(0.1, 0.3), 0)
	var tween := speck.create_tween()
	tween.tween_property(speck, "global_position", target, 0.14)
	tween.tween_property(speck, "global_position:y", at.y - 0.4, 0.3)
	tween.tween_callback(speck.queue_free)

## Splash where a shot connects with an enemy; brighter and larger on weak spots.
static func flesh(world: Node, at: Vector3, weak: bool) -> void:
	var color := Color(1.0, 0.85, 0.3, 0.95) if weak else Color(0.55, 0.16, 0.12, 0.9)
	_spawn(world, at, color, 0.09 if weak else 0.06, 0.3 if weak else 0.22, Vector3(0, 0.25, 0))
	if weak:
		_spawn(world, at, Color(1.0, 1.0, 0.8, 0.8), 0.14, 0.16, Vector3.ZERO)
