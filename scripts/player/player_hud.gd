extends CanvasLayer

@onready var hint: Label = $Root/Hint
@onready var weapon: Label = $Root/Weapon

func _ready() -> void:
	set_has_gun(false)
	hint.text = "WASD move · Mouse look · LMB melee · Esc free mouse"

func set_has_gun(has_gun: bool) -> void:
	weapon.text = "WEAPON: SIDEARM" if has_gun else "WEAPON: FISTS / MELEE"
