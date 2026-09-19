extends SceneTree
## Render-only A/B benchmark. Changes only the transient instance, never the saved level.
var viewport: SubViewport
var rails: Array[GeometryInstance3D] = []
var lights: Array[Light3D] = []
var light_shadows: Array[bool] = []
var results: Array = []
var captures_only := "--rail-captures" in OS.get_cmdline_user_args()
var diagnostic := "--rail-diagnostic" in OS.get_cmdline_user_args()
var rail_pass := "--rail-pass" in OS.get_cmdline_user_args()
func _initialize() -> void:
	call_deferred("run")
func stats(values: Array) -> Dictionary:
	values.sort()
	var sum := 0.0
	for value in values: sum+=value
	return {"mean":sum/values.size(),"median":values[values.size()/2],"p95":values[int(values.size()*0.95)]}
func run() -> void:
	Engine.max_fps=0
	OS.low_processor_usage_mode=false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size=Vector2i(1280,720)
	var views := [
		["hall",Vector3(-29,3,-28),Vector3(-35,6,-59)],
		["tank",Vector3(-18.5,9.6,-89),Vector3(-25,6,-108)],
		["plant",Vector3(68,1.6,-118),Vector3(47,6,-96)],
		["warehouse",Vector3(48,9.6,-60),Vector3(66,4,-37)]]
	var modes := ["rail_sources","rail_batches","rail_sources_repeat","rail_batches_repeat"] if rail_pass else ["baseline","rails_hidden","local_shadows_off","all_shadows_off","720p","baseline_repeat"]
	if diagnostic:
		views.resize(1)
		modes=["rail_sources","rail_batches","rails_hidden","rail_sources_unshadowed","rail_batches_unshadowed"]
	if captures_only: modes=["rail_sources","rail_batches"]
	for view in views:
		for mode in modes:
			await sample_case(view,mode)
	print("FACTORY PROFILE COMPLETE")
	quit()

func sample_case(view: Array,mode: String) -> void:
	rails.clear()
	lights.clear()
	light_shadows.clear()
	viewport=SubViewport.new()
	viewport.size=Vector2i(2560,1440)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_4X
	root.add_child(viewport)
	var display:=TextureRect.new()
	display.texture=viewport.get_texture()
	display.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	display.size=Vector2(1280,720)
	root.add_child(display)
	var level: Node3D=load("res://scenes/levels/factory.tscn").instantiate()
	viewport.add_child(level)
	level.process_mode=Node.PROCESS_MODE_DISABLED
	level.get_node("Player").hide()
	for child in level.find_children("*","CanvasLayer",true,false): child.hide()
	for group in ["HallWalkways","FactoryWalkways"]:
		for node in level.get_node(group).get_children():
			if node.get_meta("rail_batch_source",false):
				node.visible=mode.begins_with("rail_sources") and node.get_meta("rail_source_enabled",true)
			elif node.get_meta("rail_batch",false): node.visible=not mode.begins_with("rail_sources")
			if node is MeshInstance3D and node.visible and (node.get_meta("rail_batch",false) or "Post" in str(node.name) or "Handrail" in str(node.name) or "Midrail" in str(node.name)):
				rails.append(node)
	for node in level.find_children("*","Light3D",true,false):
		lights.append(node)
		light_shadows.append(node.shadow_enabled)
	var camera:=Camera3D.new()
	viewport.add_child(camera)
	camera.current=true
	camera.fov=75
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(),true)
	viewport.size=Vector2i(1280,720) if mode=="720p" else Vector2i(2560,1440)
	viewport.positional_shadow_atlas_size=root.positional_shadow_atlas_size
	camera.position=view[1]
	camera.look_at(view[2])
	if mode=="rails_hidden":
		for rail in rails: rail.hide()
	if mode in ["local_shadows_off","all_shadows_off"] or mode.ends_with("unshadowed"):
		for light in lights:
			if mode=="all_shadows_off" or mode.ends_with("unshadowed") or not light is DirectionalLight3D: light.shadow_enabled=false
	for i in (15 if diagnostic or captures_only else 90): await process_frame
	var frames: Array=[]
	var cpu: Array=[]
	var gpu: Array=[]
	var calls: Array=[]
	var shadow_calls: Array=[]
	var triangles: Array=[]
	var previous:=Time.get_ticks_usec()
	for i in (1 if captures_only else 20 if diagnostic else 150):
		await process_frame
		var now:=Time.get_ticks_usec()
		frames.append((now-previous)/1000.0)
		previous=now
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport.get_viewport_rid()))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport.get_viewport_rid()))
		calls.append(viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME))
		shadow_calls.append(viewport.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME))
		triangles.append(viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME))
	var result: Dictionary={"view":view[0],"mode":mode,"resolution":[viewport.size.x,viewport.size.y],"shadow_atlas_size":viewport.positional_shadow_atlas_size,"frame_ms":stats(frames),"render_cpu_ms":stats(cpu),"render_gpu_ms":stats(gpu),"visible_draw_calls":stats(calls),"shadow_draw_calls":stats(shadow_calls),"visible_primitives":stats(triangles)}
	results.append(result)
	print("PROFILE ",JSON.stringify(result))
	if not captures_only: save_results()
	if (rail_pass or captures_only) and not mode.ends_with("repeat"):
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://.godot/rail_captures")
		viewport.get_texture().get_image().save_png("res://.godot/rail_captures/%s_%s.png" % [view[0],mode])
	display.queue_free()
	viewport.queue_free()
	for i in 4: await process_frame

func save_results() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/performance")
	var file:=FileAccess.open("res://.godot/rail_diagnostic.json" if diagnostic else "res://docs/performance/factory_rail_batch_profile.json" if rail_pass else "res://docs/performance/factory_render_profile.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"gpu":RenderingServer.get_video_adapter_name(),"method":"fresh scene and viewport per case; uncapped; 4x MSAA; game scripts/physics paused; same shadow atlas as root; no saved level changes","warmup_frames":15 if diagnostic else 90,"sampled_frames":20 if diagnostic else 150,"rail_mesh_count":rails.size(),"results":results},"  "))
