@tool
extends Node3D
## Saved stand-ins for future events. No meshes or materials are generated here.
func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()
		process_mode=Node.PROCESS_MODE_DISABLED
