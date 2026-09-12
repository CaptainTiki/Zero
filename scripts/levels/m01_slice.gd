extends Node3D

func _ready() -> void:
	print("SUPER ZERO — M01 dressed pass (sky + longer spine)")
	var dialogue := Node.new()
	dialogue.name = "DoorDialogue"
	dialogue.set_script(preload("res://scripts/levels/door_dialogue.gd"))
	add_child(dialogue)
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.start_ambience("ambience_wind")
	var life := Node3D.new()
	life.name = "CityLife"
	life.set_script(preload("res://scripts/levels/city_life.gd"))
	add_child(life)
