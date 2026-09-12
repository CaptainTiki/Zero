extends Area3D
## Box of shotgun shells. Collected when the player can hold more.

@export var shells := 8
var _collected := false
var _spin := 0.0

func _ready() -> void:
	add_to_group("ammo_pickups")

func _physics_process(delta: float) -> void:
	_spin += delta
	rotation.y = _spin * 1.6
	position.y += sin(_spin * 3.0) * 0.0015
	for body in get_overlapping_bodies():
		if not _collected and body.is_in_group("player") and body.has_method("add_shells"):
			if body.add_shells(shells):
				_collected = true
				queue_free()
