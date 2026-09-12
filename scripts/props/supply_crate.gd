extends StaticBody3D

@export var hit_points := 30.0
@export var reward_scene: PackedScene = preload("res://scenes/props/health_pickup.tscn")
var _broken := false
var _reward: Node3D
var _chips: Array[MeshInstance3D] = []

func _ready() -> void:
	# Prepare contents at level load, not on the impact frame.
	_reward = reward_scene.instantiate() as Node3D
	add_child(_reward)
	_reward.hide()
	_reward.process_mode = Node.PROCESS_MODE_DISABLED
	for i in 8:
		var chip := MeshInstance3D.new()
		# Reuse the already-rendered crate mesh/material instead of creating meshes.
		chip.mesh = $Body.mesh
		chip.scale = Vector3(0.35, 0.12, 0.22) / 1.2
		add_child(chip)
		chip.hide()
		_chips.append(chip)

func apply_kick(_damage: float, _from: Vector3, _force: float) -> void:
	_break_open()

func apply_prop_impact() -> void:
	_break_open()

func take_damage(amount: float) -> void:
	if _broken or amount <= 0.0:
		return
	hit_points -= amount
	if hit_points <= 0.0:
		_break_open()

func _break_open() -> void:
	if _broken:
		return
	_broken = true
	var bank := get_tree().root.get_node_or_null("Sound")
	if bank:
		bank.play_at("crate_break", global_position)
	hide()
	$CollisionShape3D.set_deferred("disabled", true)
	call_deferred("_release_contents")

func _release_contents() -> void:
	_reward.reparent(get_parent())
	_reward.global_position = global_position
	_reward.show()
	_reward.process_mode = Node.PROCESS_MODE_INHERIT
	for i in _chips.size():
		var chip := _chips[i]
		chip.reparent(get_parent())
		chip.global_position = global_position + Vector3(0, 0.6, 0)
		chip.show()
		var angle := TAU * float(i) / 8.0
		var offset := Vector3(cos(angle), 0, sin(angle)) * 0.8
		var tween := chip.create_tween()
		tween.tween_property(chip, "global_position", chip.global_position + offset + Vector3(0, 0.4, 0), 0.15)
		tween.tween_property(chip, "global_position:y", global_position.y + 0.08, 0.25)
		tween.tween_property(chip, "scale", Vector3.ZERO, 0.3).set_delay(0.4)
		tween.tween_callback(chip.queue_free)
	queue_free()
