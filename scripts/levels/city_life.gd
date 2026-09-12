extends Node3D
## Ambient life for the slice: smoke and fire on the wrecks, steam from vents,
## paper blowing down the street, swinging signs, a chasing marquee, the cordon
## light bar, and pigeons that flush when the player gets close. Purely visual.

var _time := 0.0
var _swingers: Array = [] # [node, base_rotation, axis_index, amplitude, rate, phase]
var _bulbs: Array[StandardMaterial3D] = []
var _bulb_on := Color(1.0, 0.9, 0.45)
var _bulb_off := Color(0.45, 0.35, 0.15)
var _beacons: Array[OmniLight3D] = []
var _fire_lights: Array[OmniLight3D] = []
var _pigeons: Array = [] # dictionaries: node, home, state, timer, target, wing
var _player: Node3D

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D
	var dress := get_parent().get_node_or_null("CityDress")
	if dress:
		_hook_swingers(dress)
		_hook_marquee(dress)
	_build_smoke()
	_build_steam()
	_build_paper()
	_build_beacons()
	_build_pigeons()

# --- dressing that moves ------------------------------------------------------

func _hook_swingers(dress: Node) -> void:
	for name_text in ["PharmacyBlade", "PharmacyBladeLettering"]:
		var node := dress.get_node_or_null(name_text) as Node3D
		if node:
			_swingers.append([node, node.rotation, 2, 0.05, 1.3, 0.0])
	for name_text in ["Banner", "BannerLettering"]:
		var node := dress.get_node_or_null(name_text) as Node3D
		if node:
			_swingers.append([node, node.rotation, 0, 0.035, 0.9, 0.4])
	for child in dress.get_children():
		if child is Node3D and (child.name.begins_with("CafeAwning") or child.name.begins_with("LaundryCanopy") or child.name.begins_with("PharmacyCanopy")):
			_swingers.append([child, child.rotation, 2, 0.012, 2.6, randf() * TAU])
		if child is Node3D and child.name.begins_with("TerraceTableUmbrella"):
			_swingers.append([child, child.rotation, 0, 0.02, 1.1, randf() * TAU])

func _hook_marquee(dress: Node) -> void:
	for child in dress.get_children():
		if child is MeshInstance3D and child.name.begins_with("MarqueeBulb"):
			var m := StandardMaterial3D.new()
			m.albedo_color = _bulb_off
			m.emission_enabled = true
			m.emission = _bulb_on
			m.emission_energy_multiplier = 0.0
			child.material_override = m
			_bulbs.append(m)

# --- particles ----------------------------------------------------------------

func _smoke_column(at: Vector3, radius: float, height: float, amount: int, color: Color, speed: float, life: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = at
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0.35, 0.9, 0.1)
	p.initial_velocity_min = speed * 0.7
	p.initial_velocity_max = speed
	p.angular_velocity_min = -30.0
	p.angular_velocity_max = 30.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.35))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 1.6))
	p.scale_amount_curve = curve
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.0))
	gradient.add_point(0.15, Color(color.r, color.g, color.b, color.a))
	gradient.set_color(gradient.get_point_count() - 1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = gradient
	var quad := QuadMesh.new()
	quad.size = Vector2(height, height)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.WHITE
	m.albedo_texture = _soft_disc()
	quad.material = m
	p.mesh = quad
	add_child(p)
	return p

var _disc: GradientTexture2D

## Soft radial sprite so smoke reads as puffs rather than squares.
func _soft_disc() -> GradientTexture2D:
	if _disc == null:
		_disc = GradientTexture2D.new()
		_disc.width = 64
		_disc.height = 64
		_disc.fill = GradientTexture2D.FILL_RADIAL
		_disc.fill_from = Vector2(0.5, 0.5)
		_disc.fill_to = Vector2(0.5, 0.0)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.55, Color(1, 1, 1, 0.55))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		_disc.gradient = g
	return _disc

func _build_smoke() -> void:
	# Helicopter wreck burns; the street car and a rooftop smoulder.
	_smoke_column(Vector3(-6.5, 1.6, 1.2), 0.9, 1.8, 26, Color(0.16, 0.15, 0.15, 0.55), 1.6, 5.0)
	_smoke_column(Vector3(-6.2, 1.2, 1.0), 0.5, 0.9, 14, Color(1.0, 0.55, 0.15, 0.7), 1.4, 0.7)
	_smoke_column(Vector3(4.5, 1.0, -5.5), 0.6, 1.4, 14, Color(0.25, 0.24, 0.23, 0.45), 1.1, 4.5)
	_smoke_column(Vector3(68, 1.5, 2), 0.6, 1.4, 16, Color(0.2, 0.19, 0.18, 0.5), 1.3, 4.5)
	_smoke_column(Vector3(66, 13.5, -14), 1.2, 2.4, 18, Color(0.3, 0.28, 0.26, 0.4), 1.8, 7.0)
	for at in [Vector3(-6.3, 1.4, 1.0), Vector3(68, 1.2, 2)]:
		var light := OmniLight3D.new()
		light.position = at
		light.light_color = Color(1.0, 0.55, 0.2)
		light.light_energy = 1.2
		light.omni_range = 7.0
		add_child(light)
		_fire_lights.append(light)

func _build_steam() -> void:
	for x in [18.0, 28.0, 35.0]:
		var p := _smoke_column(Vector3(x, 4.4, 5.3), 0.4, 0.7, 8, Color(0.9, 0.9, 0.9, 0.35), 0.9, 2.2)
		p.direction = Vector3(0, 1, -0.3)
	var kitchen := _smoke_column(Vector3(77, 10.5, 12.5), 0.3, 0.6, 8, Color(0.92, 0.92, 0.9, 0.3), 0.8, 2.5)
	kitchen.gravity = Vector3(0.6, 0.7, 0)

func _build_paper() -> void:
	# Scraps tumble down the high street and across the plaza.
	for region in [[Vector3(70, 0.6, 0), Vector3(9, 0.4, 8)], [Vector3(88, 0.6, 0), Vector3(12, 0.4, 8)], [Vector3(26, 0.6, 0), Vector3(8, 0.4, 5)]]:
		var p := CPUParticles3D.new()
		p.position = region[0]
		p.amount = 10
		p.lifetime = 6.0
		p.preprocess = 6.0
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = region[1]
		p.direction = Vector3(1, 0.2, 0)
		p.spread = 35.0
		p.gravity = Vector3(1.2, -0.15, 0.3)
		p.initial_velocity_min = 0.6
		p.initial_velocity_max = 1.6
		p.angular_velocity_min = -180.0
		p.angular_velocity_max = 180.0
		var quad := QuadMesh.new()
		quad.size = Vector2(0.22, 0.16)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.85, 0.8, 0.7)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		quad.material = m
		p.mesh = quad
		add_child(p)

func _build_beacons() -> void:
	# Red and blue sweep on the cordon light bar.
	for i in 2:
		var light := OmniLight3D.new()
		light.position = Vector3(42, 5.2, 0)
		light.light_color = Color(0.2, 0.4, 1.0) if i == 0 else Color(1.0, 0.15, 0.1)
		light.light_energy = 0.0
		light.omni_range = 11.0
		add_child(light)
		_beacons.append(light)

# --- pigeons ------------------------------------------------------------------

func _build_pigeons() -> void:
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.42, 0.42, 0.46)
	var wing_mat := StandardMaterial3D.new()
	wing_mat.albedo_color = Color(0.3, 0.3, 0.34)
	for home in [Vector3(84, 0, 3.5), Vector3(85.5, 0, 2.2), Vector3(83, 0, 4.6), Vector3(92, 0, -3), Vector3(93.2, 0, -2.1), Vector3(106, 0, 5.5)]:
		var bird := Node3D.new()
		var body := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.14, 0.12, 0.3)
		mesh.material = grey
		body.mesh = mesh
		body.position.y = 0.12
		bird.add_child(body)
		var head := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(0.08, 0.08, 0.1)
		hm.material = wing_mat
		head.mesh = hm
		head.position = Vector3(0, 0.2, -0.16)
		head.name = "Head"
		bird.add_child(head)
		var wings := Node3D.new()
		wings.name = "Wings"
		wings.position.y = 0.16
		for side in [-1.0, 1.0]:
			var wing := MeshInstance3D.new()
			var wm := BoxMesh.new()
			wm.size = Vector3(0.22, 0.02, 0.18)
			wm.material = wing_mat
			wing.mesh = wm
			wing.position.x = side * 0.15
			wings.add_child(wing)
		wings.visible = false
		bird.add_child(wings)
		bird.position = home
		bird.rotation.y = randf() * TAU
		add_child(bird)
		_pigeons.append({"node": bird, "home": home, "state": "ground", "timer": randf_range(0.5, 2.0), "target": home, "wing": 0.0, "peck": randf() * TAU})

func _update_pigeons(delta: float) -> void:
	for p in _pigeons:
		var bird: Node3D = p["node"]
		var head: Node3D = bird.get_node("Head")
		var wings: Node3D = bird.get_node("Wings")
		match p["state"]:
			"ground":
				p["timer"] -= delta
				p["peck"] += delta * 6.0
				head.position.y = 0.2 - maxf(0.0, sin(p["peck"])) * 0.08
				if p["timer"] <= 0.0:
					p["timer"] = randf_range(1.0, 3.0)
					bird.rotation.y += randf_range(-1.2, 1.2)
					p["target"] = p["home"] + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
				var to_target: Vector3 = p["target"] - bird.position
				to_target.y = 0.0
				if to_target.length() > 0.05:
					bird.position += to_target.normalized() * minf(delta * 0.7, to_target.length())
				if _player and _player.global_position.distance_to(bird.global_position) < 4.5:
					p["state"] = "fly"
					p["timer"] = randf_range(4.0, 7.0)
					wings.visible = true
					var away := (bird.global_position - _player.global_position)
					away.y = 0.0
					p["target"] = bird.position + away.normalized() * 9.0 + Vector3(randf_range(-3, 3), randf_range(5.0, 8.0), randf_range(-3, 3))
			"fly":
				p["timer"] -= delta
				p["wing"] += delta * 22.0
				wings.scale.y = 1.0
				wings.rotation.z = sin(p["wing"]) * 0.7
				var to_target: Vector3 = p["target"] - bird.position
				if to_target.length() < 0.5:
					if p["timer"] <= 0.0:
						p["target"] = p["home"] + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
						if bird.position.distance_to(p["target"]) < 0.6:
							p["state"] = "ground"
							bird.position.y = 0.0
							wings.visible = false
							continue
					else:
						p["target"] = bird.position + Vector3(randf_range(-6, 6), randf_range(-1.0, 1.5), randf_range(-6, 6))
						p["target"].y = clampf(p["target"].y, 4.0, 9.0)
				else:
					var step := to_target.normalized() * delta * 5.5
					bird.position += step
					var flat := Vector3(to_target.x, 0, to_target.z)
					if flat.length() > 0.01:
						bird.rotation.y = lerp_angle(bird.rotation.y, atan2(-flat.x, -flat.z), delta * 4.0)

# --- per frame ----------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	for entry in _swingers:
		var node: Node3D = entry[0]
		var base: Vector3 = entry[1]
		var rot := base
		rot[entry[2]] = base[entry[2]] + sin(_time * entry[4] + entry[5]) * entry[3]
		node.rotation = rot
	if not _bulbs.is_empty():
		var step := int(_time * 6.0)
		for i in _bulbs.size():
			var on := (i + step) % 3 == 0
			_bulbs[i].emission_energy_multiplier = 1.8 if on else 0.0
			_bulbs[i].albedo_color = _bulb_on if on else _bulb_off
	for i in _beacons.size():
		var phase := _time * 3.2 + float(i) * PI
		_beacons[i].light_energy = maxf(0.0, sin(phase)) * 2.2
	for light in _fire_lights:
		light.light_energy = 1.0 + sin(_time * 17.0) * 0.25 + sin(_time * 7.3) * 0.2
	_update_pigeons(delta)
