extends SceneTree
## Renders reference stills of a level in its own lighting, including a top-down
## orthographic map. Run WITHOUT --headless, since headless has no renderer:
##   godot --path . -s tools/shoot_level.gd
## Edit SCENE and SHOTS for whatever needs looking at. Images go to user://.

const SCENE := "res://scenes/levels/factory.tscn"

## [name, camera position, look-at target, ortho size or 0 for perspective]
const SHOTS := [
	["factory_map", Vector3(10, 150, -40), Vector3(10, 0, -40), 170.0],
	["factory_goodsin", Vector3(41, 1.7, -13), Vector3(30, 1.5, -24), 0.0],
	["factory_hall", Vector3(30, 1.7, -30), Vector3(-2, 3.0, -60), 0.0],
	["factory_packing", Vector3(-22, 1.7, -14), Vector3(-22, 1.5, -46), 0.0],
	["factory_mezz", Vector3(-4, 7.6, -30), Vector3(-26, 4.0, -28), 0.0],
	["factory_annex", Vector3(-18, 1.7, -50), Vector3(-26, 1.5, -64), 0.0],
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
