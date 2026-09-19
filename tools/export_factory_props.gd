extends SceneTree
## One-time extraction of approved baked art. Existing authored assets are never overwritten.
const FOLDER := "res://scenes/props/factory/"
const ASSETS := {
	"Blocker50Crates": "case_stack_six",
	"Blocker51PressA": "press_wide",
	"Blocker52PressB": "press_compact",
	"Blocker53Hoppers": "feed_hoppers",
	"Blocker54Conveyor": "sorting_conveyor",
	"Blocker55DrumWasher": "delivery_stack_large",
	"Blocker56DrumWasher": "delivery_stack_small",
	"Blocker57DrumWasher": "parked_forklift",
	"Blocker58HopperTower": "feed_tower",
	"Blocker103LooseSupplyCase": "loose_supply_case",
}
var copies := {}
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for asset in ASSETS.values()+["shipping_case"]:
		if FileAccess.file_exists(FOLDER+asset+".tscn"):
			push_error("Refusing to overwrite authored prop: "+asset)
			quit(1)
			return
	DirAccess.make_dir_recursive_absolute(FOLDER)
	# Do not add to the tree: runtime animation and gameplay must never run while exporting.
	var level: Node3D = load("res://scenes/levels/factory.tscn").instantiate()
	var hall := level.get_node("HallMachinery")
	var source: Node3D = hall.get_node("Blocker103LooseSupplyCase/LooseCase")
	var single: Node3D = source.duplicate()
	single.name = "ShippingCase"
	single.transform = Transform3D.IDENTITY
	save_asset(single,"shipping_case")
	single.free()
	var case_scene: PackedScene = load(FOLDER+"shipping_case.tscn")
	for label in ASSETS:
		var prop: Node3D = hall.get_node(label).duplicate()
		var placed_transform := prop.transform
		prop.transform = Transform3D.IDENTITY
		prop.name = String(ASSETS[label]).to_pascal_case()
		for key in ["collision_source","blocker_size"]:
			if prop.has_meta(key): prop.remove_meta(key)
		# Props that formerly relied on an external greybox now carry that collision.
		var old_body: StaticBody3D = level.get_node(String(label)+"Solid")
		if not old_body.get_child(0).disabled:
			var body: StaticBody3D = old_body.duplicate()
			body.name = "FootprintCollision"
			body.transform = placed_transform.affine_inverse()*old_body.transform
			prop.add_child(body)
		# Every supply case is the same reusable scene, including those inside stacks.
		for child in prop.get_children():
			if child.has_node("ShellCollision") and child.has_node("Shell"):
				var instance := case_scene.instantiate()
				instance.name = child.name
				instance.transform = child.transform
				var index := child.get_index()
				prop.remove_child(child)
				child.free()
				prop.add_child(instance)
				prop.move_child(instance,index)
		save_asset(prop,ASSETS[label])
		prop.free()
	level.free()
	print("FACTORY PROP EXPORT: 11 authored scenes saved; no level changes")
	quit()
func material_copy(source: Material) -> Material:
	if source == null: return null
	var id := source.get_instance_id()
	if not copies.has(id): copies[id] = source.duplicate()
	return copies[id]
func mesh_copy(source: Mesh) -> Mesh:
	if source == null: return null
	var id := source.get_instance_id()
	if not copies.has(id):
		var copy: Mesh = source.duplicate()
		for i in copy.get_surface_count():
			copy.surface_set_material(i,material_copy(source.surface_get_material(i)))
		copies[id] = copy
	return copies[id]
func own_contents(node: Node, asset: Node) -> void:
	if node != asset:
		node.owner = asset
		# Keep instances linked. Their children belong to their own source scene.
		if not node.scene_file_path.is_empty(): return
	if node is MeshInstance3D:
		node.mesh = mesh_copy(node.mesh)
		node.material_override = material_copy(node.material_override)
		for i in node.get_surface_override_material_count():
			node.set_surface_override_material(i,material_copy(node.get_surface_override_material(i)))
	if node is CPUParticles3D: node.mesh = mesh_copy(node.mesh)
	if node is CollisionShape3D and node.shape: node.shape = node.shape.duplicate()
	for child in node.get_children(): own_contents(child,asset)
func save_asset(asset: Node, filename: String) -> void:
	own_contents(asset,asset)
	var packed := PackedScene.new()
	assert(packed.pack(asset)==OK)
	assert(ResourceSaver.save(packed,FOLDER+filename+".tscn")==OK)
	print("EXPORTED ",filename)
