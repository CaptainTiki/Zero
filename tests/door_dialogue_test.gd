extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	for mode in ["interrupt", "early", "wait"]:
		var world := Node3D.new()
		root.add_child(world)
		var door = load("res://scenes/props/kick_door.tscn").instantiate()
		door.name = "CrashExitDoor"
		world.add_child(door)
		var player := Node3D.new()
		player.name = "Player"
		player.position = Vector3(0, 0, 10)
		world.add_child(player)
		var dialogue := Node.new()
		dialogue.set_script(load("res://scripts/levels/door_dialogue.gd"))
		world.add_child(dialogue)
		dialogue.set_physics_process(false)
		check(dialogue.get("_commander").get_length() > 5.0, "Long Commander voice loaded")
		check(dialogue.get("_zero").get_length() > 0.2, "Zero voice loaded")
		dialogue._physics_process(0.01)
		check(dialogue.get("_stage") == 0, "No dialogue far from door")
		if mode != "early":
			player.position = Vector3(0, 0, 3)
			dialogue._physics_process(0.01)
			check(dialogue.get("_stage") == 1, "Approach starts Commander")
			check(dialogue.get("_voice").playing, "Commander audio playing")
			if mode == "wait":
				await dialogue.get("_voice").finished
				dialogue._physics_process(20.0)
				check(dialogue.get("_stage") == 1, "Finished commentary waits for kick")
				check(not door.is_open, "Listening never opens door")
				check(not dialogue.get("_caption").visible, "Finished subtitle clears")
		door.apply_kick(10, Vector3(0, 0, 1), 11)
		check(dialogue.get("_stage") == 2, "Kick enters impact beat")
		check(not dialogue.get("_voice").playing, "Kick cuts Commander audio")
		check(not dialogue.get("_caption").visible, "Old subtitle cleared")
		dialogue._physics_process(2.0)
		check(dialogue.get("_stage") == 2, "Reply waits for actual opening completion")
		await door.opening_finished
		dialogue._physics_process(0.2)
		check(dialogue.get("_stage") == 2, "Pause after door settles")
		dialogue._physics_process(0.3)
		check(dialogue.get("_stage") == 3, "Zero replies after beat")
		check(dialogue.get("_caption").text == "ZERO: Fixed it.", "Zero subtitle")
		dialogue._physics_process(10)
		check(dialogue.get("_stage") == 4, "Beat completes")
		dialogue._on_door_opened()
		check(dialogue.get("_stage") == 4, "No replay on repeated kick")
		check(not paused, "Gameplay stays unpaused")
		world.queue_free()
		await process_frame
	print("Door dialogue failures: ", failures)
	quit(1 if failures else 0)
