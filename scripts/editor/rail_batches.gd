@tool
extends Node3D
## Explicit offline/editor bake only. No startup callbacks or runtime construction.
const CELL := Vector3(5.0,4.0,5.0)
const FLAGS := ["cast_shadow","layers","transparency","extra_cull_margin","gi_mode","ignore_occlusion_culling","visibility_range_begin","visibility_range_end","visibility_range_begin_margin","visibility_range_end_margin","visibility_range_fade_mode"]
@export_tool_button("Edit Rail Sources") var edit_action: Callable = edit_sources
@export_tool_button("Bake Rail Batches") var bake_action: Callable = rebake

func edit_sources() -> void:
	if not Engine.is_editor_hint(): return
	for child in get_children():
		if child.get_meta("rail_batch",false): child.hide()
		elif child.get_meta("rail_batch_source",false): child.visible=child.get_meta("rail_source_enabled",true)
	set_meta("rail_source_view",true)
	EditorInterface.mark_scene_as_unsaved()

func rebake() -> void:
	if not Engine.is_editor_hint(): return
	bake(self,EditorInterface.get_edited_scene_root())
	EditorInterface.mark_scene_as_unsaved()

static func is_rail(node: Node) -> bool:
	return node is MeshInstance3D and ("Post" in str(node.name) or "Handrail" in str(node.name) or "Midrail" in str(node.name))

static func bake(group: Node3D,save_owner: Node) -> void:
	var buckets: Dictionary={}
	var materials: Array=[]
	var source_count:=0
	var editing: bool=group.get_meta("rail_source_view",false)
	for child in group.get_children():
		if child.get_meta("rail_batch",false):
			# Reuse inherited nodes: removing them cannot be serialized as an override.
			child.hide()
			child.mesh=null
			child.set_meta("rail_sources",PackedStringArray())
	for node in group.get_children():
		if not is_rail(node): continue
		if not node.get_meta("rail_batch_source",false) or editing:
			node.set_meta("rail_source_enabled",node.visible)
		node.set_meta("rail_batch_source",true)
		node.hide()
		if not node.get_meta("rail_source_enabled",true): continue
		source_count+=1
		var cell: Vector3i=Vector3i((node.position/CELL).floor())
		var properties: Array=[]
		for property in FLAGS: properties.append(node.get(property))
		for surface in node.mesh.get_surface_count():
			var material: Material=node.get_active_material(surface)
			if not materials.has(material): materials.append(material)
			var key:=str(cell,"/",materials.find(material),"/",properties,"/",node.material_overlay)
			if not buckets.has(key): buckets[key]={"cell":cell,"material":material,"items":[]}
			buckets[key].items.append([node,surface])
	var index:=0
	for bucket: Dictionary in buckets.values():
		var origin: Vector3=Vector3(bucket.cell)*CELL
		var surface_tool:=SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface_tool.set_material(bucket.material)
		var names:=PackedStringArray()
		for item: Array in bucket.items:
			var source: MeshInstance3D=item[0]
			var placement:=source.transform
			placement.origin-=origin
			surface_tool.append_from(source.mesh,item[1],placement)
			names.append(str(source.name))
		var label:="RailBatch%03d" % index
		var batch:=group.get_node_or_null(NodePath(label)) as MeshInstance3D
		if batch==null:
			batch=MeshInstance3D.new()
			batch.name=label
			group.add_child(batch)
			batch.owner=save_owner
		batch.show()
		batch.position=origin
		batch.mesh=surface_tool.commit()
		batch.set_meta("rail_batch",true)
		batch.set_meta("rail_sources",names)
		var exemplar: MeshInstance3D=bucket.items[0][0]
		for property in FLAGS: batch.set(property,exemplar.get(property))
		batch.material_overlay=exemplar.material_overlay
		index+=1
	group.set_meta("rail_source_view",false)
	print("RAIL BATCHES ",group.name,": ",source_count," saved sources -> ",index," local meshes")
