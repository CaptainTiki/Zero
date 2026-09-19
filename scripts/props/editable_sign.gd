@tool
extends Node3D
## Saved board + Label3D. Fitting is explicit; startup never changes authored lettering.
@export_range(0.0,0.45) var horizontal_margin := 0.07
@export_range(0.0,0.45) var vertical_margin := 0.12
@export_tool_button("Fit Text to Board") var fit_action: Callable = fit_text_to_board
func fitted_pixel_size() -> float:
	var board: MeshInstance3D = $Board
	var label: Label3D = $Text
	var font: Font = label.font if label.font else ThemeDB.fallback_font
	var size := board.mesh.get_aabb().size*board.scale.abs()
	var lines := label.text.split("\n")
	var width := 0.0
	for line in lines:
		width=maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,label.font_size).x)
	var height := font.get_height(label.font_size)*lines.size()+label.line_spacing*maxi(0,lines.size()-1)
	var available := Vector2(size.x*(1.0-2.0*horizontal_margin),size.y*(1.0-2.0*vertical_margin))
	available -= Vector2(absf(label.position.x-board.position.x),absf(label.position.y-board.position.y))*2.0
	return maxf(0.00001,minf(available.x/maxf((width+label.outline_size*2.0)*absf(label.scale.x),1.0),available.y/maxf((height+label.outline_size*2.0)*absf(label.scale.y),1.0)))
func fit_text_to_board() -> void:
	if not Engine.is_editor_hint(): return
	$Text.pixel_size=fitted_pixel_size()
	EditorInterface.mark_scene_as_unsaved()
