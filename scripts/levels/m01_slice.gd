extends Node3D

func _ready() -> void:
	print("SUPER ZERO — M01 dressed pass (sky + longer spine)")
	var dialogue := Node.new()
	dialogue.name = "DoorDialogue"
	dialogue.set_script(preload("res://scripts/levels/door_dialogue.gd"))
	add_child(dialogue)
