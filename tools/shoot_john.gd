extends SceneTree
## Renders reference stills of the cardboard Johns in the level's own lighting.
## Run WITHOUT --headless, since headless has no renderer:
##   godot --path . -s tools/shoot_john.gd
## Images land in the path given by SHOT_DIR.

const SHOT_DIR := "user://"

## [name, camera position, look-at target]
const SHOTS := [
	["john_portrait", Vector3(2.74, 1.35, -4.73), Vector3(6.0, 1.05, -6.0)],
	["john_lane", Vector3(15.0, 1.7, 0.4), Vector3(36.0, 1.0, 0.0)],
	["john_yard_wide", Vector3(-1.0, 2.2, 2.0), Vector3(6.0, 1.0, -6.0)],
]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var level = load("res://scenes/levels/l01_district04.tscn").instantiate()
	root.add_child(level)
	# The player's own camera and HUD would be in the way.
	var player = level.get_node_or_null("Player")
	if player:
		player.queue_free()
	for actor in get_nodes_in_group("enemies"):
		actor.process_mode = Node.PROCESS_MODE_DISABLED
	var cam := Camera3D.new()
	cam.fov = 70.0
	root.add_child(cam)
	for i in 20:
		await process_frame
	for shot in SHOTS:
		cam.position = shot[1]
		cam.look_at(shot[2], Vector3.UP)
		cam.current = true
		for i in 8:
			await process_frame
		await process_frame
		var image := root.get_viewport().get_texture().get_image()
		var path: String = SHOT_DIR + String(shot[0]) + ".png"
		var err := image.save_png(path)
		print("saved %s -> %s (%s)" % [shot[0], ProjectSettings.globalize_path(path), "ok" if err == OK else "FAILED"])
	level.queue_free()
	await process_frame
	quit(0)
