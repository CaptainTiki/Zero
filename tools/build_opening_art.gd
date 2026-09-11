extends SceneTree

var art := Node3D.new()
var mats := {}

func add(node: Node, name_text: String) -> void:
	node.name = name_text
	art.add_child(node)
	node.owner = art

func box(label: String, at: Vector3, size: Vector3, material: String, tilt: float = 0.0, solid: bool = false) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mats[material]
	node.mesh = mesh
	node.position = at
	node.rotation.z = tilt
	add(node, label)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.position = at
		body.rotation.z = tilt
		add(body, label + "Solid")
		body.add_child(collision)
		collision.owner = art

func pipe(label: String, at: Vector3, height: float, radius: float, material: String) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	mesh.material = mats[material]
	node.mesh = mesh
	node.position = at
	add(node, label)

func sign_board(label: String, text: String, at: Vector3, width: float, yaw: float = 0.0) -> void:
	var backing := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 1.1, 0.14)
	mesh.material = mats["teal"]
	backing.mesh = mesh
	backing.position = at
	backing.rotation.y = yaw
	add(backing, label)
	var lettering := Label3D.new()
	lettering.text = text
	lettering.font_size = 64
	lettering.pixel_size = minf(0.009, width / maxf(text.length() * 36.0, 1.0))
	lettering.modulate = Color("e7ce93")
	lettering.outline_size = 0
	lettering.position = at + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.09)
	lettering.rotation.y = yaw
	add(lettering, label + "Lettering")

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	art.name = "OpeningArt"
	for entry in [["plaster", "plaster", Color("c4a478")], ["brick", "brick", Color("b78265")], ["teal", "metal", Color("557b76")], ["rust", "metal", Color("a16b46")], ["dark", "metal", Color("343c39")], ["concrete", "concrete", Color("aaa18b")], ["asphalt", "asphalt", Color("777c75")]]:
		var material := ShaderMaterial.new()
		material.shader = load("res://materials/retro/world_surface.gdshader")
		material.set_shader_parameter("surface_texture", load("res://textures/" + entry[1] + ".png"))
		material.set_shader_parameter("tint", entry[2])
		material.set_shader_parameter("texels_per_metre", 24.0)
		mats[entry[0]] = material
		ResourceSaver.save(material, "res://materials/retro/" + entry[0] + ".tres")
	# Architectural rhythm inside existing walls, with chunky cornices and repairs.
	for x in [-8, -3, 2, 7]:
		box("YardPier", Vector3(x, 3, -10.55), Vector3(0.45, 6.2, 0.5), "concrete")
		box("YardCornice", Vector3(x + 2, 5.9, -10.55), Vector3(4.6, 0.4, 0.65), "dark")
	box("YardRepair", Vector3(6.6, 1.4, -10.52), Vector3(3.5, 2.7, 0.18), "plaster")
	box("RepairDiagonal", Vector3(6.6, 1.4, -10.35), Vector3(3.5, 0.22, 0.16), "rust", 0.18)
	sign_board("DepotSign", "MUNICIPAL WORKS / YARD 04", Vector3(-0.5, 4.9, -10.1), 8.0)
	sign_board("DoorSign", "SERVICE EXIT", Vector3(10.5, 3.6, 0), 3.8, -PI / 2)
	for x in [-8.5, 8.5]:
		pipe("Drainpipe", Vector3(x, 2.9, -10.15), 5.8, 0.18, "rust")
	# Service lane facade: shuttered workshops, external ducting and fading paint.
	for x in [16, 24, 32]:
		box("WorkshopPanel", Vector3(x, 2.3, -5.65), Vector3(6.5, 4.5, 0.15), "plaster")
		box("Shutter", Vector3(x, 1.6, -5.48), Vector3(2.8, 3.1, 0.15), "teal")
		for y in [0.35, 0.7, 1.05, 1.4, 1.75, 2.1, 2.45, 2.8]:
			box("ShutterRib", Vector3(x, y, -5.35), Vector3(2.85, 0.06, 0.08), "dark")
		box("WorkshopCanopy", Vector3(x, 3.5, -4.95), Vector3(4, 0.18, 1.5), "rust", 0.035)
		pipe("ServiceDownpipe", Vector3(x + 3.2, 2.5, -5.35), 5, 0.17, "dark")
		box("RoofTrim", Vector3(x, 5, -5.9), Vector3(7.8, 0.35, 0.8), "dark")
	sign_board("RepairShop", "BELL'S REPAIRS", Vector3(24, 4.3, -5.25), 5.5)
	sign_board("StoreRoom", "STORES / 02", Vector3(16, 4.3, -5.25), 4.0)
	sign_board("WorkshopNotice", "BACK IN 5", Vector3(24, 1.8, -5.20), 1.2)
	for x in [18, 28, 35]:
		box("VentHousing", Vector3(x, 3.6, 5.5), Vector3(2.2, 1.5, 0.5), "rust")
		for y in [3.1, 3.35, 3.6, 3.85, 4.1]:
			box("VentSlat", Vector3(x, y, 5.2), Vector3(1.9, 0.11, 0.12), "dark")
		box("PaintBand", Vector3(x, 1.0, 5.68), Vector3(5.8, 1.4, 0.06), "teal")
	# Silhouette additions sit above existing shells.
	for x in [17, 25]:
		box("RoofUtility", Vector3(x, 10.6, -12), Vector3(3, 1.2, 2.4), "teal")
		pipe("RoofStack", Vector3(x + 0.5, 12.2, -12), 2.1, 0.45, "rust")
	# Checkpoint booth sits outside the central combat lane, with solid walls.
	for z in [-3.4, 3.4]:
		box("GatePier", Vector3(42, 2.4, z), Vector3(0.7, 4.8, 0.7), "concrete", 0, true)
	box("GateHeader", Vector3(42, 4.5, 0), Vector3(0.8, 0.7, 7.5), "teal", 0, true)
	sign_board("GateNumber", "CHECKPOINT / 04", Vector3(41.55, 4.5, 0), 5.5, -PI / 2)
	box("BoothBase", Vector3(49, 0.85, 8), Vector3(4, 1.7, 3), "teal", 0, true)
	box("BoothBack", Vector3(49, 2.1, 9.35), Vector3(4, 1.3, 0.3), "plaster", 0, true)
	for x in [47.15, 50.85]:
		box("BoothPost", Vector3(x, 2.2, 6.65), Vector3(0.25, 1.6, 0.25), "rust", 0, true)
	box("BoothRoof", Vector3(49, 3.1, 8), Vector3(4.9, 0.3, 3.8), "rust", -0.035, true)
	box("BoothCounter", Vector3(49, 1.75, 6.4), Vector3(4.3, 0.2, 0.7), "dark", 0, true)
	box("Radio", Vector3(50.1, 2.05, 6.7), Vector3(0.6, 0.4, 0.4), "dark")
	pipe("RadioAntenna", Vector3(50.25, 2.5, 6.7), 0.7, 0.025, "dark")
	pipe("Mug", Vector3(48.4, 1.97, 6.4), 0.25, 0.13, "concrete")
	sign_board("BoothSign", "PLEASE HAVE ID READY", Vector3(49, 2.75, 6.35), 3.8, PI)
	var booth_light := OmniLight3D.new()
	booth_light.position = Vector3(49, 2.5, 6.0)
	booth_light.light_color = Color("ffd597")
	booth_light.light_energy = 1.4
	booth_light.omni_range = 4.5
	add(booth_light, "BoothWarmLight")
	for x in [38, 44, 50, 56]:
		box("CheckPier", Vector3(x, 3, -10.55), Vector3(0.55, 6.3, 0.65), "concrete")
		box("CheckRoofline", Vector3(x + 2.5, 6, -10.5), Vector3(5.5, 0.35, 0.9), "rust")
	sign_board("CheckpointSign", "DISTRICT 04 / CHECKPOINT", Vector3(48, 4.9, -10.25), 10)
	box("PatchedCheckWall", Vector3(40, 2, -10.5), Vector3(3.4, 3.3, 0.15), "plaster")
	sign_board("CheckpointNotice", "REPORT ALL DAMAGE", Vector3(40, 2.5, -10.25), 3.0)
	var packed := PackedScene.new()
	assert(packed.pack(art) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/modules/opening_art.tscn") == OK)
	print("Baked opening art nodes: ", art.get_child_count())
	art.free()
	quit()
