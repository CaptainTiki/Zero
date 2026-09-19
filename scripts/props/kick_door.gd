@tool
extends StaticBody3D
## A saved door assembly. Runtime only swings the hinge and updates input prompts.

signal kicked_open
signal opening_finished


var is_open := false
var _hinge: Node3D
var _panel_collision: CollisionShape3D
var _impact_audio: AudioStreamPlayer3D

func _ready() -> void:
	_hinge = $Hinge
	_panel_collision = $PanelCollision
	_impact_audio = $ImpactAudio
	if Engine.is_editor_hint(): return
	var label: Label3D = $Hinge/Prompt
	var source_text := label.text
	var inputs := get_node_or_null("/root/InputBootstrap")
	if inputs and "[F]" in source_text:
		var refresh := func() -> void: label.text = source_text.replace("[F]", "[%s]" % inputs.button_label("kick"))
		inputs.device_changed.connect(refresh)
		refresh.call()

func apply_kick(_damage: float, from: Vector3, _force: float) -> void:
	if is_open:
		return
	is_open = true
	get_tree().call_group("run_stats", "record_door_kick", name)
	kicked_open.emit()
	_impact_audio.play()
	_panel_collision.set_deferred("disabled", true)
	var swing := 1.0 if to_local(from).z >= 0.0 else -1.0
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(_hinge, "rotation:y", swing * deg_to_rad(105.0), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hinge, "rotation:y", swing * deg_to_rad(96.0), 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): opening_finished.emit())
