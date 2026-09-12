extends Area3D
## Weapon pickup. `weapon` selects which grant call the player receives.

@export_enum("pistol", "shotgun") var weapon := "pistol"
var _spin := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_spin += delta
	rotation.y = _spin * 1.2

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var method := "grant_gun" if weapon == "pistol" else "grant_shotgun"
	if body.has_method(method):
		body.call(method)
		queue_free()
