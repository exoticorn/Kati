extends MeshInstance3D

var white_flat_mesh: Mesh = preload("res://Assets/imported/white flat.res")
var highlight_scene = preload("res://Scenes/square_highlight.tscn")

var meshes = [
	preload("res://Assets/square2_mesh.tres"),
	preload("res://Assets/square1_mesh.tres"),
	preload("res://Assets/square3_mesh.tres"),
]

var tween: Tween
var flat_aabb: AABB

var square: Vector2i

var has_move_highlight := false
var move_highlight_color: Color
var move_highlight_height: int

var has_hover_highlight := false
var hover_highlight_color: Color
var hover_highlight_height: int

var highlight
var _highlight_color: Color
var _highlight_alpha: float

signal entered(Vector2)
signal exited(Vector2)
signal clicked(Vector2i)

func _init():
	flat_aabb = white_flat_mesh.get_aabb()

func set_ring(ring: int):
	mesh = meshes[ring % meshes.size()]

var highlight_color: Color:
	get: return _highlight_color
	set(color):
		_highlight_color = color
		if highlight:
			highlight.set_instance_shader_parameter("color", color)
var highlight_alpha: float:
	get: return _highlight_alpha
	set(alpha):
		_highlight_alpha = alpha
		if highlight:
			highlight.set_instance_shader_parameter("alpha", alpha)

func _process(_delta: float):
	var labels = $Analysis.get_children()
	var total_size = 0.0
	var max_width = 0.0
	for label in labels:
		total_size += label.get_aabb().size.y
		max_width = max(max_width, label.get_aabb().size.x)
	$Analysis.scale.x = 1.0 / max(1.0, max_width)
	if labels.size() > 1:
		var z_offset = -total_size / 2
		for label in labels:
			var size = label.get_aabb().size.y
			label.position.z = z_offset + size / 2
			z_offset += size

func set_move_highlight(color: Color, height: int):
	has_move_highlight = true
	move_highlight_color = color
	move_highlight_height = height
	update_highlight()

func clear_move_highlight():
	has_move_highlight = false
	update_highlight()

func set_hover_highlight(color: Color, height: int = 0):
	has_hover_highlight = true
	hover_highlight_color = color
	hover_highlight_height = height
	update_highlight()

func clear_hover_highlight():
	has_hover_highlight = false
	update_highlight()

func remove_highlight():
	if highlight:
		highlight.queue_free()
	highlight = null

func update_highlight():
	if tween != null:
		tween.kill()
	var has_highlight = has_move_highlight || has_hover_highlight
	if !has_highlight:
		if highlight:
			tween = create_tween()
			tween.tween_property(self, "highlight_alpha", 0.0, 0.1)
			tween.tween_callback(remove_highlight)
		return
	
	var color: Color
	var height: int
	if has_hover_highlight:
		color = hover_highlight_color
		if has_move_highlight:
			color = lerp(color, move_highlight_color, 0.33)
		height = hover_highlight_height
	else:
		color = move_highlight_color
		height = move_highlight_height
	
	var pos = Vector3(0, height * flat_aabb.size.y, 0)	

	tween = create_tween()
	tween.tween_property(self, "highlight_alpha", 1.0, 0.1)
	if !highlight:
		highlight = highlight_scene.instantiate()
		add_child(highlight)
		highlight_color = color
		highlight.position = pos
	else:
		tween.parallel().tween_property($Highlight, "position", pos, 0.1)
		tween.parallel().tween_property(self, "highlight_color", color, 0.1)		

func _on_mouse_entered() -> void:
	entered.emit(square)

func _on_mouse_exited() -> void:
	exited.emit(square)

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed && event.button_index == 1:
			clicked.emit(square)

func set_stack_height(height: float):
	$Analysis.position.y = height + 0.03

func clear_move_infos():
	for label in $Analysis.get_children():
		label.queue_free()

func set_move_infos(infos: Array, best_move: EngineInterface.MoveInfo):
	if infos.size() > 3:
		infos = infos.slice(0, 3)
	var labels = $Analysis.get_children()
	while labels.size() > infos.size():
		labels.pop_back().queue_free()
	while labels.size() < infos.size():
		var label := Label3D.new()
		label.rotate_x(-PI/2)
		$Analysis.add_child(label)
		labels.push_back(label)
	for i in infos.size():
		var info = infos[i]
		var label = labels[i]
		var text = "%s|" % info.move.to_short_ptn()
		if info.score_is_winrate:
			text += "%d%%" % roundi(info.score * 100)
		else:
			text += "%.2f" % info.score
		var suffix = ""
		var visits = info.visits
		if visits >= 100000:
			suffix = "M"
			visits /= 1000000.0
		elif visits > 100:
			suffix = "k"
			visits /= 1000.0
		if visits >= 10:
			visits = "%d%s" % [visits, suffix]
		elif visits >= 1:
			visits = "%.1f%s" % [visits, suffix]
		else:
			visits = "%.2f%s" % [visits, suffix]
			visits = visits.right(-1)
		if infos.size() == 1:
			text += "\n%sn" % visits
		else:
			text += "|%s" % visits
		label.text = text
		var winrate_drop = abs(best_move.score - info.score)
		var alpha = clamp(pow(2.0, log(float(info.visits) / best_move.visits) / log(30)), 0.0, 1.0)
		label.modulate = Color.from_hsv(max(0, 0.333 - winrate_drop), 1.0, 1.0, alpha)
		label.outline_modulate = Color(0, 0, 0, alpha)
		label.position.z = 0
	
