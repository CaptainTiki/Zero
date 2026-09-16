extends SceneTree
## Renders reference stills of a level in its own lighting, including a top-down
## orthographic map. Run WITHOUT --headless, since headless has no renderer:
##   godot --path . -s tools/shoot_level.gd
## Edit SCENE and SHOTS for whatever needs looking at. Images go to user://.

const SCENE := "res://scenes/levels/factory.tscn"

## [name, camera position, look-at target, ortho size or 0 for perspective]
const SHOTS := [
	["factory_map", Vector3(-8, 150, -14), Vector3(-8, 0, -14), 236.0],
	["factory_lot", Vector3(4, 1.7, 92), Vector3(-70, 2.0, 48), 0.0],
	["factory_admin", Vector3(-85, 1.7, 37), Vector3(-85, 1.5, 24), 0.0],
	["factory_hall", Vector3(-28, 1.7, -28), Vector3(-42, -1.0, -56), 0.0],
	["factory_catwalk", Vector3(-61, 5.7, -64), Vector3(-30, 2.0, -48), 0.0],
	["factory_tank", Vector3(-18.5, 9.7, -89), Vector3(-26, 3.0, -114), 0.0],
	["factory_plant", Vector3(68, 5.7, -95), Vector3(45, -1.0, -97), 0.0],
	["factory_warehouse", Vector3(83, 5.7, -58), Vector3(44, 0.0, -24), 0.0],
	["factory_warehouse_floor", Vector3(76, 1.7, -18), Vector3(50, 1.0, -40), 0.0],
	["factory_yard", Vector3(-48, 1.7, 20), Vector3(-28, 1.0, -20), 0.0],
	["factory_office_door", Vector3(-84, 1.7, 8), Vector3(-76, 1.4, 8), 0.0],
	["factory_dock", Vector3(40, 2.9, -2), Vector3(38, 0.5, 10), 0.0],
	["factory_lobby", Vector3(-73, 1.7, 47), Vector3(-68, 2.2, 34), 0.0],
	["factory_office", Vector3(-75, 1.7, 8), Vector3(-56, 1.6, 20), 0.0],
	["factory_machine", Vector3(59, -2.3, -84), Vector3(47, -2.5, -97), 0.0],
	["factory_machine_roof", Vector3(47.25, 9.7, -88), Vector3(47.25, 8.5, -101), 0.0],
]

func _initialize() -> void:
	call_deferred("run")

func _set_roofs_visible(node: Node, shown: bool) -> void:
	for child in node.get_children():
		var n := String(child.name)
		if child is Node3D and (n.contains("Roof") or n.contains("Ceil")):
			(child as Node3D).visible = shown
		_set_roofs_visible(child, shown)

func run() -> void:
	var level = load(SCENE).instantiate()
	root.add_child(level)
	var player = level.get_node_or_null("Player")
	if player:
		player.queue_free()
	for actor in get_nodes_in_group("enemies"):
		actor.process_mode = Node.PROCESS_MODE_DISABLED
	var cam := Camera3D.new()
	cam.fov = 70.0
	cam.far = 600.0
	root.add_child(cam)
	for i in 20:
		await process_frame
	for shot in SHOTS:
		var ortho: float = shot[3]
		# A top-down map has to see into the rooms, so roofs and ceilings come off
		# and the ambient comes up while the shot is taken.
		_set_roofs_visible(level, ortho <= 0.0)
		var world: WorldEnvironment = level.get_node_or_null("WorldEnvironment")
		if world and world.environment:
			world.environment.ambient_light_energy = 1.1 if ortho > 0.0 else 0.35
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL if ortho > 0.0 else Camera3D.PROJECTION_PERSPECTIVE
		cam.position = shot[1]
		if ortho > 0.0:
			cam.size = ortho
			# Straight down, with north (-Z) up the screen.
			cam.rotation_degrees = Vector3(-90, 0, 0)
		else:
			cam.look_at(shot[2], Vector3.UP)
		cam.current = true
		for i in 8:
			await process_frame
		await process_frame
		var image := root.get_viewport().get_texture().get_image()
		var path: String = "user://" + String(shot[0]) + ".png"
		var err := image.save_png(path)
		print("saved %s (%s)" % [ProjectSettings.globalize_path(path), "ok" if err == OK else "FAILED"])
	level.queue_free()
	await process_frame
	quit(0)
