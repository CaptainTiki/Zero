extends Area3D
## Energy drink: a short burst of faster movement and higher jumps.

@export var duration := 8.0
var _collected := false
var _spin := 0.0

func _ready() -> void:
	add_to_group("boost_pickups")

func _physics_process(delta: float) -> void:
	_spin += delta
	rotation.y = _spin * 2.2
	position.y += sin(_spin * 3.0) * 0.0015
	for body in get_overlapping_bodies():
		if not _collected and body.is_in_group("player") and body.has_method("apply_boost"):
			body.apply_boost(duration)
			_collected = true
			queue_free()
