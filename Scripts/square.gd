extends MeshInstance3D

var white_flat_mesh: Mesh = preload("res://Assets/imported/white flat.res")

var tween: Tween
var flat_aabb: AABB

var square: Vector2i

var has_move_highlight := false
var move_highlight_color: Color
var move_highlight_height: int

var has_hover_highlight := false

signal entered(Vector2)
signal exited(Vector2)
signal clicked(Vector2i)

func _init():
	flat_aabb = white_flat_mesh.get_aabb()

var highlight_color: Color:
	get: return $Highlight.get_instance_shader_parameter("color")
	set(color): $Highlight.set_instance_shader_parameter("color", color)
var highlight_alpha: float:
	get: return $Highlight.get_instance_shader_parameter("alpha")
	set(alpha): $Highlight.set_instance_shader_parameter("alpha", alpha)

func clear_move_highlight():
	has_move_highlight = false
	update_highlight()

func set_move_highlight(color: Color, height: int = 0):
	has_move_highlight = true
	move_highlight_color = color
	move_highlight_height = height
	update_highlight()

func set_hover_highlight(active: bool):
	has_hover_highlight = active
	update_highlight()
	
func update_highlight():
	if tween != null:
		tween.kill()
	var has_highlight = has_move_highlight || has_hover_highlight
	if !has_highlight:
		if $Highlight.is_visible_in_tree():
			tween = create_tween()
			tween.tween_property(self, "highlight_alpha", 0.0, 0.1)
			tween.tween_callback($Highlight.hide)
		return
	
	var color: Color
	var height: int
	if has_hover_highlight:
		color = Color(0.3, 0.6, 0.3)
		height = 0
	else:
		color = move_highlight_color
		height = move_highlight_height

	var pos = Vector3(0, height * flat_aabb.size.y, 0)
	tween = create_tween()
	tween.tween_property(self, "highlight_alpha", 1.0, 0.1)
	if !$Highlight.is_visible_in_tree():
		highlight_color = color
		$Highlight.position = pos
	else:
		tween.parallel().tween_property($Highlight, "position", pos, 0.1)
		tween.parallel().tween_property(self, "highlight_color", color, 0.1)		
	$Highlight.show()

func _on_mouse_entered() -> void:
	entered.emit(square)

func _on_mouse_exited() -> void:
	exited.emit(square)

func _on_input_event(_camera: Node, _event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	clicked.emit(square)
