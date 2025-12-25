extends PanelContainer

var _move_list: MoveList

func setup(move_list: MoveList):
	_move_list = move_list
	move_list.changed.connect(update)

func _ready():
	update()

func update():
	if !is_inside_tree():
		return
	%BackToGame.visible = _move_list.branch_move <= _move_list.moves.size()
	for child in %Grid.get_children():
		%Grid.remove_child(child)
		child.queue_free()
	if _move_list.moves.is_empty():
		var move_number = Label.new()
		move_number.text = "1."
		%Grid.add_child(move_number)
		var move = Label.new()
		move.text = "---"
		%Grid.add_child(move)
	else:
		var display_move = max(0, _move_list.display_move - 1) / 2
		var move_count = (_move_list.moves.size() + 1) / 2
		var start = max(min(move_count - 3, display_move - 1), 0)
		var end = min(max(start + 3, display_move + 2), move_count)
		for i in range(start, end):
			var move_number = Label.new()
			move_number.text = "%d." % (i + 1)
			%Grid.add_child(move_number)
			for j in 2:
				var move_index = i * 2 + j
				if move_index < _move_list.moves.size():
					var move = Label.new()
					if move_index + 1 >= _move_list.branch_move:
						move.add_theme_color_override("font_color", Color.RED if _move_list.is_diverging else Color.CORAL)
					move.text = _move_list.moves[move_index].to_ptn()
					if move_index + 1 == _move_list.display_move:
						move.theme_type_variation = "CurrentMoveLabel"
					%Grid.add_child(move)


func _on_back_to_game_pressed() -> void:
	_move_list.step_move(0)
