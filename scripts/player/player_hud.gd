extends CanvasLayer

@onready var hint: Label = $Root/Hint
@onready var weapon: Label = $Root/Weapon
@onready var hp_label: Label = $Root/HP
@onready var hurt: ColorRect = $Root/HurtFlash

func _ready() -> void:
	if hurt:
		hurt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hurt.color = Color(0.8, 0.05, 0.05, 0.0)
	set_status(false, 100.0, 100.0)
	hint.text = "WASD · Mouse · LMB melee · RMB fire · E grab/throw · Esc"

func set_has_gun(has_gun: bool) -> void:
	set_status(has_gun, 100.0, 100.0)

func set_status(has_gun: bool, hp: float, max_hp: float) -> void:
	weapon.text = "WEAPON: SIDEARM" if has_gun else "WEAPON: FISTS / MELEE"
	if hp_label:
		hp_label.text = "HP: %d / %d" % [int(hp), int(max_hp)]

func flash_hurt() -> void:
	if hurt == null:
		return
	hurt.color = Color(0.85, 0.05, 0.05, 0.45)
	var tw := create_tween()
	tw.tween_property(hurt, "color:a", 0.0, 0.25)
