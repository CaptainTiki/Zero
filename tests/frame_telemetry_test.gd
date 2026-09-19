extends SceneTree
class ReportLevel extends "res://scripts/levels/level_base.gd":
	var destination:="res://.godot/frame_telemetry_report_%d.txt" % Time.get_ticks_usec()
	func _report_path() -> String: return destination
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1
func run() -> void:
	var sampler=preload("res://scripts/debug/frame_sampler.gd").new()
	check(sampler.snapshot().window_source=="warming_up","First sample is explicitly warming up")
	sampler.tick(0)
	for i in range(1,250): check_silent(sampler.tick(i*20000).is_empty())
	var result: Dictionary=sampler.tick(5000000)
	check(result.frames==250 and result.fps==50.0 and result.frame_ms_mean==20.0 and result.frame_ms_p95==20.0,"Five-second wall-clock window reports expected FPS and frame times")
	sampler.tick(5020000)
	sampler.restart_clock()
	sampler.tick(30000000)
	sampler.tick(30020000)
	check(sampler.snapshot().frame_ms_max==20.0 and sampler.snapshot().frames==2,"Pause gap excluded without losing active samples")
	sampler.tick(30220000)
	check(sampler.snapshot().frame_ms_max==200.0,"Long frames remain visible rather than delta-clamped")
	var level:=ReportLevel.new()
	level.add_child(load("res://scenes/player/player.tscn").instantiate())
	root.add_child(level)
	current_scene=level
	level.get_node("Player").set_physics_process(false)
	level.set_process(false)
	level._frame_sampler=sampler
	level._elapsed=12.0
	var context: Dictionary=level._performance_context(sampler.snapshot())
	check(context.has("player_position") and context.has("facing") and context.has("yaw_degrees") and context.has("viewport_pixels") and context.has("draw_calls"),"Sample carries location, view, resolution and rendering counters")
	var marker: Dictionary=preload("res://scripts/debug/debug_pointer.gd").sample(level.get_node("Player"),level.get_node("Player").camera)
	level.record_debug_pointer(marker)
	check(not marker.has("performance"),"Q enriches a copy without mutating the original probe")
	# Exercise the real level process integration with a due sample, not only the helper.
	level._frame_sampler.total_usec=5000000
	level._frame_sampler.previous_usec=Time.get_ticks_usec()-20000
	level._process(0.02)
	check(level._report.any(func(line): return " PERF " in line),"Periodic sample reaches the run event buffer")
	paused=true
	check(level._frame_sampler.previous_usec==-1,"Scene pause resets wall-clock anchor")
	paused=false
	check(level.save_quit_report(),"Report saves")
	var report:=FileAccess.get_file_as_string(level.destination)
	check(report.contains(" PERF ") and report.contains('"performance":') and report.contains('"frame_ms_max":200.0') and report.contains("QUIT TO MENU"),"Periodic and Q timing survive the actual saved quit report")
	level.queue_free()
	await process_frame
	print("FRAME TELEMETRY: ","PASS" if failures==0 else "FAIL")
	quit(1 if failures else 0)
func check_silent(ok: bool) -> void:
	if not ok: failures+=1
