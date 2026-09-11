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
