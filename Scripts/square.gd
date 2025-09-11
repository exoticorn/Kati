extends MeshInstance3D

var white_flat_mesh: Mesh = preload("res://Assets/imported/white flat.res")

var tween: Tween
var flat_aabb: AABB

func _init():
	flat_aabb = white_flat_mesh.get_aabb()

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

func set_move_highlight(color: Color, height: int = 0):
	if tween != null:
		tween.kill()
	var pos = Vector3(0, height * flat_aabb.size.y, 0)
	tween = create_tween()
	tween.tween_property(self, "highlight_alpha", 1.0, 0.1)
	if !is_visible_in_tree():
		highlight_color = color
		$Highlight.position = pos
	else:
		tween.parallel().tween_property($Highlight, "position", pos, 0.1)
		tween.parallel().tween_property(self, "highlight_color", color, 0.1)		
	$Highlight.show()
