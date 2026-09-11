extends Node
## One action-driven radio beat. No gameplay pause or input capture.

@export var approach_distance := 5.0
@export var reply_delay := 0.45 # Pause after the door has finished swinging.
var _stage := 0 # waiting, explanation, impact beat, reply, complete
var _remaining := 0.0
var _door: Node3D
var _player: Node3D
var _voice: AudioStreamPlayer
var _caption: Label
var _commander: AudioStreamWAV
var _zero: AudioStreamWAV

func _ready() -> void:
	_door = get_parent().get_node("CrashExitDoor")
	_player = get_parent().get_node("Player")
	_commander = AudioStreamWAV.load_from_file("res://audio/vo/temp/commander_door.wav")
	_zero = AudioStreamWAV.load_from_file("res://audio/vo/temp/zero_fixed_it.wav")
	_voice = AudioStreamPlayer.new()
	_voice.volume_db = -3.0
	add_child(_voice)
	var overlay := CanvasLayer.new()
	overlay.layer = 5
	add_child(overlay)
	_caption = Label.new()
	_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_left = 24
	_caption.offset_right = -24
	_caption.offset_top = -120
	_caption.offset_bottom = -40
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.add_theme_font_size_override("font_size", 24)
	_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	_caption.add_theme_constant_override("outline_size", 8)
	overlay.add_child(_caption)
	_caption.hide()
	_door.kicked_open.connect(_on_door_opened)
	_door.opening_finished.connect(_on_opening_finished)
	if _door.is_open:
		_stage = 4

func _physics_process(delta: float) -> void:
	if _stage == 0 and _player.global_position.distance_to(_door.global_position) <= approach_distance:
		_stage = 1
		_say("COMMANDER", "The latch is damaged. You'll have to find another way round. Maybe try and find a ladder?", _commander)
	if _remaining > 0.0:
		_remaining = maxf(0.0, _remaining - delta)
		if _remaining <= 0.0:
			if _stage == 2:
				_stage = 3
				_say("ZERO", "Fixed it.", _zero)
			else:
				_caption.hide()
				if _stage == 3:
					_stage = 4

func _say(speaker: String, line: String, clip: AudioStream) -> void:
	_caption.text = speaker + ": " + line
	_caption.show()
	_voice.stream = clip
	_voice.play()
	_remaining = maxf(clip.get_length(), 1.5)

func _on_door_opened() -> void:
	if _stage >= 2:
		return
	_voice.stop()
	_caption.hide()
	_stage = 2
	_remaining = 0.0

func _on_opening_finished() -> void:
	if _stage != 2:
		return
	_remaining = reply_delay
