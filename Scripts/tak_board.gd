extends Control

const PieceType = BoardState.PieceType
const PlayerColor = BoardState.PlayerColor
const Move = MoveList.Move

var square_scene = preload("res://Scenes/square.tscn")
var piece_scene = preload("res://Scenes/piece.tscn")

var config: ConfigFile

var board_state: BoardState
var squares = {}

var selected_piece_type := PieceType.FLAT
var current_hover_square

var held_pieces := []
var pending_move

var right_click_time: int = 0
var right_click_position: Vector2

var _can_input_move := false
var can_input_move:
	set(can):
		_can_input_move = can
		if current_hover_square:
			square_entered(current_hover_square)

var shown:
	set(s):
		visible = s
		$Root3D.visible = s
		$Root3D/Camera.current = s
	get():
		return visible

var move_infos: Array[EngineInterface.MoveInfo] = []
var move_infos_changed = false

signal move_input(move: Move)
signal step_move(by: int)

func _ready():
	setup_quality()
	create_board()
	board_state.changed.connect(update_board)
	$Root3D/MovePreview.is_ghost = true

func _process(_delta: float):
	if is_visible_in_tree() && !board_state.is_setup_turn():
		var viewport = get_viewport()
		if viewport.gui_get_focus_owner() == null:
			var old = selected_piece_type
			if Input.is_action_just_pressed("select_flat"):
				selected_piece_type = PieceType.FLAT
			if Input.is_action_just_pressed("select_wall"):
				selected_piece_type = PieceType.WALL
			if Input.is_action_just_pressed("select_cap"):
				selected_piece_type = PieceType.CAP
			if Input.is_action_just_pressed("toggle_flat_wall"):
				selected_piece_type = PieceType.WALL if selected_piece_type == PieceType.FLAT else PieceType.FLAT
			if Input.is_action_just_pressed("toggle_cap_wall"):
				selected_piece_type = PieceType.WALL if selected_piece_type == PieceType.CAP else PieceType.CAP
			if selected_piece_type != old:
				setup_move_preview()
			if Input.is_action_just_pressed("cancel") && pending_move != null:
				cancel_stack_move()
	if is_visible_in_tree():
		update_analysis()

func _unhandled_input(event: InputEvent) -> void:
	if !is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				right_click_time = Time.get_ticks_msec()
				right_click_position = event.position
			else:
				var elapsed_ticks = Time.get_ticks_msec() - right_click_time
				var distance = (event.position - right_click_position).length()
				if elapsed_ticks < 300 && distance < 8:
					if pending_move != null:
						cancel_stack_move()
					elif !board_state.is_setup_turn():
						match selected_piece_type:
							PieceType.FLAT:
								selected_piece_type = PieceType.CAP
							PieceType.WALL:
								selected_piece_type = PieceType.FLAT
							_:
								selected_piece_type = PieceType.WALL
						setup_move_preview()
	elif event is InputEventKey:
		if event.is_pressed():
			match event.keycode:
				KEY_LEFT: step_move.emit(-1)
				KEY_RIGHT: step_move.emit(1)
				KEY_UP: step_move.emit(-1000)
				KEY_DOWN: step_move.emit(1000)

func setup_move_preview():
	if board_state.is_setup_turn():
		selected_piece_type = PieceType.FLAT
	else:
		var c = board_state.side_to_move()
		if selected_piece_type == PieceType.CAP:
			if board_state.caps_left[c] == 0:
				selected_piece_type = PieceType.WALL
		elif board_state.flats_left[c] == 0:
			selected_piece_type = PieceType.CAP
	$Root3D/MovePreview.setup(board_state.color_to_place(), selected_piece_type)

func create_board():
	squares = {}
	for x in range(board_state.size):
		for y in range(board_state.size):
			var square := square_scene.instantiate()
			square.position = Vector3(x, 0, -y)
			square.square = Vector2i(x, y)
			$Root3D/Board.add_child(square)
			squares[Vector2i(x, y)] = square
			square.entered.connect(square_entered)
			square.exited.connect(square_exited)
			square.clicked.connect(square_clicked)
	
	var border_mesh_original = preload("res://Assets/imported/border.res")
	var tool = MeshDataTool.new()
	tool.create_from_surface(border_mesh_original, 0)
	var size_inc = (board_state.size - 1) * 0.5
	for i in tool.get_vertex_count():
		var vertex = tool.get_vertex(i)
		if vertex.x < 0:
			vertex.x -= size_inc
		else:
			vertex.x += size_inc
		tool.set_vertex(i, vertex)
		var uv = tool.get_vertex_uv(i)
		uv.x = vertex.x * 0.25
		tool.set_vertex_uv(i, uv)
	var border_mesh = ArrayMesh.new()
	tool.commit_to_surface(border_mesh, 0)
	border_mesh.surface_set_material(0, border_mesh_original.surface_get_material(0))
	for i in 4:
		var border = MeshInstance3D.new()
		var transform = Transform3D.IDENTITY
		transform.origin = Vector3(0, 0, board_state.size * 0.5)
		transform = transform.rotated(Vector3.UP, i * PI / 2)
		transform = transform.translated(Vector3(size_inc, 0, -size_inc))
		border.mesh = border_mesh
		border.transform = transform
		add_child(border)
	for i in board_state.size:
		var color = Color(0.635, 0.603, 0.593, 1.0)
		var label = Label3D.new()
		label.outline_size = 4
		label.text = str(i + 1)
		label.position = Vector3(-0.75, 0.04, -i)
		label.rotate_x(-PI / 2)
		label.modulate = color
		label.shaded = true
		add_child(label)
		label = Label3D.new()
		label.outline_size = 4
		label.text = char(97 + i)
		label.position = Vector3(i, 0.04, 0.75)
		label.rotate_x(-PI / 2)
		label.modulate = color
		label.shaded = true
		add_child(label)
		label = Label3D.new()
		label.outline_size = 4
		label.text = str(i + 1)
		label.position = Vector3(board_state.size - 0.25, 0.04, -i)
		label.rotate_x(-PI / 2)
		label.rotate_y(PI)
		label.modulate = color
		label.shaded = true
		add_child(label)
		label = Label3D.new()
		label.outline_size = 4
		label.text = char(97 + i)
		label.position = Vector3(i, 0.04, 0.25 - board_state.size)
		label.rotate_x(-PI / 2)
		label.rotate_y(PI)
		label.modulate = color
		label.shaded = true
		add_child(label)
	
	$Root3D/Camera.board_size = board_state.size
	
	update_board()

func update_board():
	var piece_map = {}
	var pieces_to_place := []
	for piece in $Root3D/Pieces.get_children():
		piece_map[piece.board_pos] = piece
	
	# don't touch pieces that didn't move
	for x in range(board_state.size):
		for y in range(board_state.size):
			var stack: Array = board_state.board[x][y]
			for i in stack.size():
				var board_pos = Vector3i(x, i, y)
				var piece = stack[i]
				var existing = piece_map.get(board_pos)
				if existing != null && existing.can_be(piece.color, piece.type):
					existing.become(piece.type)
					existing.set_temp_pos(null, false)
					piece_map.erase(board_pos)
				else:
					pieces_to_place.push_back({"pos": board_pos, "piece": piece})

	# either move or remove the remaining pieces
	var pieces_to_move := []
	for pos in piece_map:
		pieces_to_move.push_back(piece_map[pos])
	
	pieces_to_move.sort_custom(func (a, b): return a.board_pos.y < b.board_pos.y)
	
	for piece in pieces_to_move:
		var pos_a = piece.board_pos
		var best_index = -1
		var best_distance = board_state.size * 200
		for index in pieces_to_place.size():
			var to_place = pieces_to_place[index]
			if to_place.piece.color == piece.color && to_place.piece.type == piece.type:
				var pos_b = to_place.pos
				var distance = pos_b.y + 100 * (abs(pos_a.x - pos_b.x) + abs(pos_a.z - pos_b.z))
				if distance < best_distance:
					best_distance = distance
					best_index = index
		if best_index >= 0:
			piece.place(pieces_to_place[best_index].pos)
			pieces_to_place.remove_at(best_index)
		else:
			$Root3D/Pieces.remove_child(piece)
			$Root3D.add_child(piece)
			piece.move_off()

	# put down pieces left to place
	for to_place in pieces_to_place:
		var piece_node = piece_scene.instantiate()
		var piece = to_place.piece
		piece_node.setup(piece.color, piece.type)
		$Root3D/Pieces.add_child(piece_node)
		piece_node.place(to_place.pos)

	# apply move highlights
	for c in squares:
		squares[c].clear_move_highlight()

	piece_map = {}
	var stack_heights = {}
	for piece in $Root3D/Pieces.get_children():
		piece_map[piece.board_pos] = piece
		var sq = Vector2i(piece.board_pos.x, piece.board_pos.z)
		var height = stack_heights[sq] if stack_heights.has(sq) else 0.0
		stack_heights[sq] = max(height, piece.top_height())
	
	for sq in squares:
		var height = stack_heights[sq] if stack_heights.has(sq) else 0.0
		squares[sq].set_stack_height(height)
		
	if board_state.last_move != null:
		var highlight_squares = board_state.last_move.highlight_squares()
		for square in highlight_squares:
			var count = highlight_squares[square]
			var color = Color(0.3, 0.45, 0.75) if count > 0 else Color(0.1, 0.15, 0.3)
			var height = board_state.board[square.x][square.y].size()
			squares[square].set_move_highlight(color, height - count)

	# update ui
	%FlatsWhite/Box/Count.text = str(board_state.flats_left[PlayerColor.WHITE])
	%CapsWhite/Box/Count.text = str(board_state.caps_left[PlayerColor.WHITE])
	%FlatsBlack/Box/Count.text = str(board_state.flats_left[PlayerColor.BLACK])
	%CapsBlack/Box/Count.text = str(board_state.caps_left[PlayerColor.BLACK])
	

	selected_piece_type = PieceType.FLAT
	held_pieces = []
	pending_move = null
	
	if current_hover_square != null:
		square_entered(current_hover_square)

func show_result(result: GameResult):
	if !result.is_ongoing():
		$UI/GameOver.result = result
		$UI/GameOver.show()
	else:
		$UI/GameOver.hide()

func square_entered(square):
	current_hover_square = square
	var sq = squares[square]
	if !_can_input_move:
		sq.clear_hover_highlight()
		$Root3D/MovePreview.hide()
		return
		
	var stack = board_state.board[square.x][square.y]
	
	if pending_move != null:
		if pending_move.can_continue_on_square(board_state, square) || (square == pending_move.square && pending_move.drops.is_empty()):
			var height = stack.size()
			if square == pending_move.square:
				height -= pending_move.count
			sq.set_hover_highlight(Color(0.3, 0.6, 0.3))#, height)
			var next_height = height + pending_move.drops_on(square) + 3
			for piece in held_pieces:
				piece.set_temp_pos(Vector3i(square.x, next_height, square.y), false)
				next_height += 1
		else:
			sq.set_hover_highlight(Color(0.5, 0.2, 0.2))
		return
	
	if stack.is_empty():
		sq.set_hover_highlight(Color(0.3, 0.6, 0.3))
		setup_move_preview()
		$Root3D/MovePreview.place(Vector3i(square.x, 0, square.y), false)
		$Root3D/MovePreview.show()
	else:
		if !board_state.is_setup_turn() && stack.back().color == board_state.side_to_move():
			sq.set_hover_highlight(Color(0.3, 0.6, 0.3))#, max(0, stack.size() - game_state.size))
		else:
			sq.set_hover_highlight(Color(0.5, 0.2, 0.2))
		$Root3D/MovePreview.hide()

func square_exited(square):
	current_hover_square = null
	var sq = squares[square]
	sq.clear_hover_highlight()
	$Root3D/MovePreview.hide()

func square_clicked(square):
	if !_can_input_move:
		return
	
	var stack = board_state.board[square.x][square.y]
	
	if pending_move != null:
		if square == pending_move.square:
			if pending_move.drops.size() != 0 || pending_move.count <= 1:
				cancel_stack_move()
			else:
				held_pieces.pop_front().set_temp_pos(null, true)
				pending_move.count -= 1
		elif pending_move.can_continue_on_square(board_state, square):
			var dropped_piece = held_pieces.pop_front()
			var height = stack.size() + pending_move.drops_on(square)
			pending_move.add_drop(square)
			dropped_piece.set_temp_pos(Vector3i(square.x, height, square.y), true)
			if held_pieces.is_empty():
				can_input_move = false
				var move = pending_move
				pending_move = null
				move_input.emit(move)
		return
	
	if stack.is_empty():
		can_input_move = false
		move_input.emit(Move.place(square, selected_piece_type))
	elif !board_state.is_setup_turn() && stack.back().color == board_state.side_to_move():
		held_pieces = []
		for piece in $Root3D/Pieces.get_children():
			if piece.board_pos.x == square.x && piece.board_pos.z == square.y:
				held_pieces.push_back(piece)
		held_pieces.sort_custom(func (a, b): return a.board_pos.y < b.board_pos.y)
		while held_pieces.size() > board_state.size:
			held_pieces.pop_front()
		for piece in held_pieces:
			piece.set_temp_pos(piece.board_pos + Vector3i(0, 3, 0), false)
		pending_move = Move.pending_stack(square, held_pieces.size())

func cancel_stack_move():
	pending_move = null
	held_pieces = []
	for piece in $Root3D/Pieces.get_children():
		piece.set_temp_pos(null, false)

func setup_quality():
	var quality: String = config.get_value("display", "quality", "mid")
	var light_energy := 2.0 if quality == "low" else 6.0
	$Root3D/Light.light_energy = light_energy

func add_ui(control: Control, right: bool, end: bool = true):
	control.size_flags_horizontal = Control.SIZE_SHRINK_END if right else Control.SIZE_SHRINK_BEGIN
	var box = $UI/RightBox if right else $UI/LeftBox
	box.add_child(control)
	if !end:
		box.move_child(control, 0)

func set_move_infos(infos: Array[EngineInterface.MoveInfo]):
	move_infos = infos
	move_infos_changed = true

func update_analysis():
	if !move_infos_changed:
		return
	
	if move_infos.is_empty():
		for sq in squares:
			squares[sq].clear_move_infos()
		return
	
	var best_move = move_infos[0]
	
	var square_infos = {}
	for info in move_infos:
		var sq = info.move.square
		if !square_infos.has(sq):
			square_infos[sq] = []
		square_infos[sq].push_back(info)

	for sq in squares:
		var square = squares[sq]
		if square_infos.has(sq):
			square.set_move_infos(square_infos[sq], best_move)
		else:
			square.clear_move_infos()
