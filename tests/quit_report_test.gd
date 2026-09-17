extends SceneTree
## Read actual saved files across menu teardown, fast successive runs and a failed save.
class ReportLevel extends "res://scripts/levels/level_base.gd":
	var destination := ""
	var reject_write := false
	func _report_path() -> String:
		return destination
	func _write_report() -> String:
		return "" if reject_write else super._write_report()

var failures := 0
var report_path := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1

func frames(n := 5) -> void:
	for i in n:
		await process_frame

func make_level(label: String) -> Node:
	if current_scene:
		current_scene.queue_free()
		await frames()
	var level := ReportLevel.new()
	level.destination = report_path
	level.level_tag = label
	level.scene_file_path = "res://scenes/levels/%s.tscn" % label.to_lower()
	level.add_child(load("res://scenes/player/player.tscn").instantiate())
	root.add_child(level)
	current_scene = level
	await frames()
	return level

func contents(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""

func run() -> void:
	root.size = Vector2i(1152, 648)
	report_path = "res://.godot/quit_report_%d_%d.txt" % [OS.get_process_id(), Time.get_ticks_usec()]
	var level: Node = await make_level("FACTORY")
	level._pause_menu.open()
	level._elapsed = 13.0
	level._kills = 3
	level._secrets_found = 1
	level.unstuck_player()
	level._pause_menu._exit_to_menu()
	level._pause_menu._exit_to_menu()
	await frames(10)
	var factory_report := contents(report_path)
	check(current_scene.scene_file_path == "res://scenes/ui/main_menu.tscn", "Menu exit succeeds after saving")
	check(factory_report.contains("FACTORY QUIT TO MENU at 0:13"), "Quit reason and elapsed time survive level teardown")
	check(factory_report.contains("FACTORY UNSTUCK") and factory_report.contains("from ") and factory_report.contains("to "), "Saved report retains Unstuck coordinates")
	check(factory_report.contains("kills 3/") and factory_report.contains("secrets 1/") and factory_report.contains("to quit:"), "Quit report includes partial progress and segment data")
	check(factory_report.count("QUIT TO MENU") == 1 and not factory_report.contains("finished at"), "Double activation saves one quit, never a completion")
	check(not paused, "Menu remains usable after saving")

	level = await make_level("DISTRICT")
	level._pause_menu.open()
	level.unstuck_player()
	level._pause_menu._exit_to_menu()
	await frames(10)
	var second_path := report_path.get_basename() + "_2.txt"
	var district_report := contents(second_path)
	check(district_report.contains("DISTRICT QUIT TO MENU") and district_report.contains("DISTRICT UNSTUCK"), "Second run saves its own quit and Unstuck events")
	check(contents(report_path) == factory_report, "An identical timestamp cannot overwrite the first run")

	level = await make_level("RETRY")
	level._pause_menu.open()
	level.unstuck_player()
	level.reject_write = true
	level._pause_menu._exit_to_menu()
	await frames()
	check(current_scene == level and paused and level._pause_menu.visible, "Failed save keeps the run available in the pause menu")
	check(not level._pause_menu._leaving and level._pause_menu._hint.text.contains("could not be saved"), "Save failure is visible and retry remains possible")
	check(level._report.size() == 1 and level._report[0].contains("UNSTUCK"), "Failed save preserves events without duplicate summaries")
	level.reject_write = false
	level._pause_menu._exit_to_menu()
	await frames(10)
	var retry_report := contents(report_path.get_basename() + "_3.txt")
	check(retry_report.count("QUIT TO MENU") == 1 and retry_report.count("SUPER ZERO run report") == 1 and retry_report.contains("UNSTUCK"), "Retry writes one complete report with the original event")

	level = await make_level("FINISH")
	level._lift_open = true
	level.finish()
	var finish_report := contents(report_path.get_basename() + "_4.txt")
	check(finish_report.contains("FINISH finished at") and not finish_report.contains("QUIT TO MENU"), "Completion still writes a completed-run report")
	check(level.save_quit_report() and not FileAccess.file_exists(report_path.get_basename() + "_5.txt"), "Already-ended runs are not saved again as abandoned")
	level = await make_level("DEATH")
	level.fail_run("YOU DIED")
	var death_report := contents(report_path.get_basename() + "_5.txt")
	check(death_report.contains("run failed: YOU DIED") and not death_report.contains("QUIT TO MENU"), "Failure still writes a failed-run report")
	print("Quit report failures: ", failures)
	quit(1 if failures else 0)
