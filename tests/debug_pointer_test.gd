extends SceneTree
class ReportLevel extends "res://scripts/levels/level_base.gd":
	var destination := "res://.godot/pointer_report_%d.txt" % Time.get_ticks_usec()
	func _report_path() -> String:
		return destination
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1
func frames(n := 3) -> void:
	for i in n:
		await physics_frame
	await process_frame
func press(echo := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_Q
	event.pressed = true
	event.echo = echo
	root.push_input(event)
func markers(level: Node) -> Array:
	return level._report.filter(func(line): return " POINTER " in line)
func run() -> void:
	var level := ReportLevel.new()
	level.name = "PointerTest"
	var player: Node = load("res://scenes/player/player.tscn").instantiate()
	level.add_child(player)
	root.add_child(level)
	current_scene = level
	player.set_physics_process(false)
	var body := StaticBody3D.new()
	body.name = "TargetWall"
	body.position = Vector3(0, player.camera.position.y + player.head.position.y, -5)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 5, 1)
	shape.shape = box
	body.add_child(shape)
	level.add_child(body)
	await frames()
	var health: float = player._hp
	var sample: Dictionary = player.DebugPointer.sample(player, player.camera)
	check(sample.hit and sample.collider == "TargetWall", "Ray hits named world surface, excludes player")
	check(absf(sample.hit_position[2] + 4.5) < 0.01 and sample.hit_normal == [0.0, 0.0, 1.0], "Hit position and normal are world coordinates")
	check(sample.facing == [0.0, 0.0, -1.0] and sample.yaw_degrees == 0.0 and sample.pitch_degrees == 0.0, "Facing follows the camera")
	if DisplayServer.get_name() != "headless":
		press()
		player._physics_process(0.0)
		check(markers(level).size() == 1, "Physical Q action records one pointer")
		press(true)
		player._physics_process(0.0)
		check(markers(level).size() == 1, "Key repeat does not spam markers")
		paused = true
		press()
		check(not player._pointer_requested, "Paused input does not queue a pointer")
		paused = false
	else:
		print("SKIP  Captured-mouse Q checks require a rendered run")
		level.record_debug_pointer(sample)
	player.camera.rotation.y = PI / 2.0
	player.camera.rotation.x = 0.2
	sample = player.DebugPointer.sample(player, player.camera)
	check(not sample.hit and sample.has("ray_end"), "Empty sky reports a miss and ray endpoint")
	check(absf(sample.yaw_degrees - 90.0) < 0.01 and absf(sample.pitch_degrees - rad_to_deg(0.2)) < 0.01, "Yaw and pitch include actual camera rotation")
	check(player._hp == health and level._shots.pistol == 0, "Pointer causes no damage or weapon shots")
	level.record_debug_pointer(sample)
	check(level.save_quit_report(), "Quit report saves successfully")
	var text := FileAccess.get_file_as_string(level.destination)
	check(text.contains("QUIT TO MENU") and text.contains("POINTER") and text.contains('"collider":"TargetWall"') and text.contains('"hit":false'), "Saved report retains hit and miss markers")
	level.queue_free()
	await frames()
	print("DEBUG POINTER: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
