extends SceneTree
## Shared helpers for baked art generators. Subclasses call build() from
## _initialize(), add nodes to `art`, then call save_scene().

var art := Node3D.new()
var _mats := {}

func mat(name_text: String) -> Material:
	if not _mats.has(name_text):
		_mats[name_text] = load("res://materials/retro/%s.tres" % name_text)
	return _mats[name_text]

func add(node: Node, name_text: String, parent: Node = art) -> void:
	node.name = name_text
	parent.add_child(node)
	node.owner = art

func box(label: String, at: Vector3, size: Vector3, material: String, yaw: float = 0.0, solid: bool = false, tilt: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat(material)
	node.mesh = mesh
	node.position = at
	node.rotation = Vector3(0.0, yaw, tilt)
	add(node, label)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.position = at
		body.rotation = node.rotation
		add(body, label + "Solid")
		body.add_child(collision)
		collision.owner = art
	return node

func pipe(label: String, at: Vector3, height: float, radius: float, material: String, yaw: float = 0.0, tilt: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	mesh.material = mat(material)
	node.mesh = mesh
	node.position = at
	node.rotation = Vector3(0.0, yaw, tilt)
	add(node, label)
	return node

func sign_board(label: String, text: String, at: Vector3, width: float, yaw: float = 0.0, backing: String = "teal", ink: Color = Color("e7ce93"), height: float = 1.1) -> void:
	var board := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, 0.14)
	mesh.material = mat(backing)
	board.mesh = mesh
	board.position = at
	board.rotation.y = yaw
	add(board, label)
	var lettering := Label3D.new()
	lettering.text = text
	lettering.font_size = 64
	lettering.pixel_size = minf(0.009 * height / 1.1, width / maxf(text.length() * 36.0, 1.0))
	lettering.modulate = ink
	lettering.outline_size = 0
	lettering.position = at + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.09)
	lettering.rotation.y = yaw
	add(lettering, label + "Lettering")

## Sign with a per-shop look. Style keys: backing, ink, font (system font names,
## falls back to the default font when absent), height, outline, outline_color,
## scale (letter size relative to the board), depth (board thickness).
func styled_sign(label: String, text: String, at: Vector3, width: float, yaw: float, style: Dictionary) -> void:
	var height: float = style.get("height", 1.1)
	var board := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, style.get("depth", 0.14))
	mesh.material = mat(style.get("backing", "teal"))
	board.mesh = mesh
	board.position = at
	board.rotation.y = yaw
	add(board, label)
	var lettering := Label3D.new()
	lettering.text = text
	lettering.font_size = 64
	if style.has("font"):
		var font := SystemFont.new()
		font.font_names = PackedStringArray(style["font"])
		font.font_weight = style.get("weight", 400)
		font.font_italic = style.get("italic", false)
		lettering.font = font
	var fit := minf(0.009 * height / 1.1, width / maxf(text.length() * 36.0, 1.0))
	lettering.pixel_size = fit * style.get("scale", 1.0)
	lettering.modulate = style.get("ink", Color("e7ce93"))
	lettering.outline_size = style.get("outline", 0)
	lettering.outline_modulate = style.get("outline_color", Color.BLACK)
	lettering.position = at + Basis(Vector3.UP, yaw) * Vector3(0, 0, mesh.size.z / 2.0 + 0.02)
	lettering.rotation.y = yaw
	add(lettering, label + "Lettering")

## Boxy parked car with collision. `yaw` 0 points the nose down +X.
func car(label: String, at: Vector3, yaw: float, paint: String, solid: bool = true) -> void:
	var basis := Basis(Vector3.UP, yaw)
	box(label + "Body", at + basis * Vector3(0, 0.62, 0), Vector3(4.2, 0.62, 1.8), paint, yaw, solid)
	box(label + "Cabin", at + basis * Vector3(-0.3, 1.2, 0), Vector3(2.1, 0.62, 1.62), paint, yaw, solid)
	box(label + "Glass", at + basis * Vector3(-0.3, 1.2, 0), Vector3(1.9, 0.5, 1.66), "glass", yaw)
	box(label + "Windscreen", at + basis * Vector3(0.85, 1.15, 0), Vector3(0.5, 0.48, 1.5), "glass", yaw)
	box(label + "Bumper", at + basis * Vector3(2.15, 0.42, 0), Vector3(0.12, 0.2, 1.7), "dark", yaw)
	box(label + "BumperB", at + basis * Vector3(-2.15, 0.42, 0), Vector3(0.12, 0.2, 1.7), "dark", yaw)
	for corner in [Vector3(1.4, 0.34, 0.95), Vector3(-1.4, 0.34, 0.95), Vector3(1.4, 0.34, -0.95), Vector3(-1.4, 0.34, -0.95)]:
		pipe(label + "Wheel", at + basis * corner, 0.24, 0.34, "tyre", yaw, PI / 2)

## Horizontal strip of dark glass that reads as a row of windows at distance.
func window_band(label: String, at: Vector3, width: float, yaw: float = 0.0, height: float = 1.2) -> void:
	box(label, at, Vector3(width, height, 0.12), "glass", yaw)

func save_scene(path: String) -> void:
	var packed := PackedScene.new()
	assert(packed.pack(art) == OK)
	assert(ResourceSaver.save(packed, path) == OK)
	print("Baked ", art.name, " nodes: ", art.get_child_count(), " -> ", path)
	art.free()
	quit()
