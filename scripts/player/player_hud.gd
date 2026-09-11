extends CanvasLayer

@onready var hint: Label = $Root/Hint
@onready var weapon: Label = $Root/Weapon
@onready var hp_label: Label = $Root/HP
@onready var hurt: ColorRect = $Root/HurtFlash

func _ready() -> void:
	if hurt:
		hurt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hurt.color = Color(0.8, 0.05, 0.05, 0.0)
	hint.text = "1 fists · 2 pistol · LMB use · RMB ADS · F kick · E throw · Esc"

func set_status(weapon_name: String, hp: float, max_hp: float, has_gun: bool, ads: bool) -> void:
	var extra := " (ADS)" if ads else ""
	var locked := "" if has_gun or weapon_name == "FISTS" else ""
	weapon.text = "WEAPON: %s%s" % [weapon_name, extra]
	if hp_label:
		hp_label.text = "HP: %d / %d" % [int(hp), int(max_hp)]

func flash_hurt() -> void:
	if hurt == null:
		return
	hurt.color = Color(0.85, 0.05, 0.05, 0.45)
	var tw := create_tween()
	tw.tween_property(hurt, "color:a", 0.0, 0.25)
