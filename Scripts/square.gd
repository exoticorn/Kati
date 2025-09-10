extends MeshInstance3D

var tween: Tween
var highlight_color: Color:
	get: return $Highlight.get_instance_shader_parameter("color")
	set(color): $Highlight.set_instance_shader_parameter("color", color)
var highlight_alpha: float:
	get: return $Highlight.get_instance_shader_parameter("alpha")
	set(alpha): $Highlight.set_instance_shader_parameter("alpha", alpha)

func clear_move_highlight():
	if highlight_alpha == 0:
		return
	if tween != null:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "highlight_alpha", 0.0, 0.1)
	tween.tween_callback($Highlight.hide)

func set_move_highlight(color: Color):
	if tween != null:
		tween.kill()
	if highlight_alpha == 0:
		highlight_color = color
	tween = create_tween()
	$Highlight.show()
	tween.tween_property(self, "highlight_alpha", 1.0, 0.1)
	tween.parallel().tween_property(self, "highlight_color", color, 0.1)
