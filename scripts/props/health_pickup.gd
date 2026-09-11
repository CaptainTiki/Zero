extends Area3D

@export var health_amount := 25.0
var _collected := false

func _ready() -> void:
	add_to_group("health_pickups")

func _physics_process(_delta: float) -> void:
	# Retry while overlapping so a full-health player can collect after damage.
	for body in get_overlapping_bodies():
		if not _collected and body.is_in_group("player") and body.has_method("restore_health"):
			if body.restore_health(health_amount):
				_collected = true
				queue_free()
