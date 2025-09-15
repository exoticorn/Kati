extends Node3D

var square_scene = preload("res://Scenes/square.tscn")
var piece_scene = preload("res://Scenes/piece.tscn")

var config: ConfigFile

var game_state = GameState.new(6)
#var game_state = GameState.from_tps("x3,2,x,1/x2,1S,2,2,1/1,1,1212C,1,1,1/1,2S,21,21C,1,2/x,2,2,21,x,2/2,x,121S,x,2,12 1 24")

var squares = {}

var engine: EngineInterface
var selected_piece_type := GameState.Type.FLAT
var current_hover_square

enum PlayerType { LOCAL, ENGINE }
var player_types: Array[PlayerType] = [PlayerType.LOCAL, PlayerType.ENGINE]

var held_pieces := []
var pending_move

var right_click_time: int = 0
var right_click_position: Vector2

func _ready():
	config = ConfigFile.new()
	config.load("user://catak.cfg")
	setup_quality()
	create_board()
	engine = EngineInterface.new(game_state)
	engine.bestmove.connect(engine_move)
	add_child(engine)
	game_state.changed.connect(update_board)
	$MovePreview.is_ghost = true

func _process(_delta: float):
	if !game_state.is_setup_turn():
		var old = selected_piece_type
		if Input.is_action_just_pressed("select_flat"):
			selected_piece_type = GameState.Type.FLAT
		if Input.is_action_just_pressed("select_wall"):
			selected_piece_type = GameState.Type.WALL
		if Input.is_action_just_pressed("select_cap"):
			selected_piece_type = GameState.Type.CAP
		if Input.is_action_just_pressed("toggle_flat_wall"):
			selected_piece_type = GameState.Type.WALL if selected_piece_type == GameState.Type.FLAT else GameState.Type.FLAT
		if selected_piece_type != old:
			setup_move_preview()

func _unhandled_input(event: InputEvent) -> void:
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
					elif !game_state.is_setup_turn():
						match selected_piece_type:
							GameState.Type.FLAT:
								selected_piece_type = GameState.Type.CAP
							GameState.Type.WALL:
								selected_piece_type = GameState.Type.FLAT
							_:
								selected_piece_type = GameState.Type.WALL
						setup_move_preview()

func setup_move_preview():
	if game_state.is_setup_turn():
		selected_piece_type = GameState.Type.FLAT
	else:
		var c = game_state.side_to_move()
		if selected_piece_type == GameState.Type.CAP:
			if game_state.caps_left[c] == 0:
				selected_piece_type = GameState.Type.WALL
		elif game_state.flats_left[c] == 0:
			selected_piece_type = GameState.Type.CAP
	$MovePreview.setup(game_state.color_to_place(), selected_piece_type)

func create_board():
	squares = {}
	for x in range(game_state.size):
		for y in range(game_state.size):
			var square := square_scene.instantiate()
			square.position = Vector3(x, 0, -y)
			square.square = Vector2i(x, y)
			$Board.add_child(square)
			squares[Vector2i(x, y)] = square
			square.entered.connect(square_entered)
			square.exited.connect(square_exited)
			square.clicked.connect(square_clicked)
				
	var center = (game_state.size - 1.0) / 2
	$Camera.target = Vector3(center, 0, -center)
	
	update_board()

func update_board():
	var piece_map = {}
	var pieces_to_place := []
	for piece in $Pieces.get_children():
		piece_map[piece.board_pos] = piece
	
	# don't touch pieces that didn't move
	for x in range(game_state.size):
		for y in range(game_state.size):
			var stack: Array = game_state.board[x][y]
			for i in stack.size():
				var board_pos = Vector3i(x, i, y)
				var piece = stack[i]
				var existing = piece_map.get(board_pos)
				if existing != null && existing.can_be(piece.color, piece.type):
					existing.become(piece.type)
					existing.set_temp_pos(null)
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
		var best_distance = game_state.size * 200
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
			piece.queue_free()

	# put down pieces left to place
	for to_place in pieces_to_place:
		var piece_node = piece_scene.instantiate()
		var piece = to_place.piece
		piece_node.setup(piece.color, piece.type)
		$Pieces.add_child(piece_node)
		piece_node.place(to_place.pos)

	# apply move highlights
	for c in squares:
		squares[c].clear_move_highlight()

	piece_map = {}
	for piece in $Pieces.get_children():
		piece_map[piece.board_pos] = piece
		
	if !game_state.moves.is_empty():
		var highlight_squares = game_state.moves.back().highlight_squares()
		for square in highlight_squares:
			var count = highlight_squares[square]
			var color = Color(0.3, 0.45, 0.75) if count > 0 else Color(0.1, 0.15, 0.3)
			var height = game_state.board[square.x][square.y].size()
			squares[square].set_move_highlight(color, height - count)

	var aabb := AABB(Vector3(-0.5, 0, 0.5), Vector3(game_state.size, 0, -game_state.size)).abs()
	for piece in $Pieces.get_children():
		aabb.size.y = max(aabb.size.y, piece.mesh_height + piece.board_pos.y * piece.flat_aabb.size.y)
	$Camera.set_content_box(aabb)

	# update ui
	$UI/FlatsWhite/Box/Count.text = str(game_state.flats_left[GameState.Col.WHITE])
	$UI/CapsWhite/Box/Count.text = str(game_state.caps_left[GameState.Col.WHITE])
	$UI/FlatsBlack/Box/Count.text = str(game_state.flats_left[GameState.Col.BLACK])
	$UI/CapsBlack/Box/Count.text = str(game_state.caps_left[GameState.Col.BLACK])
	
	if game_state.result != GameState.Result.ONGOING:
		var result_string
		match game_state.result:
			GameState.Result.WHITE_ROAD:
				result_string = "White won by road"
			GameState.Result.BLACK_ROAD:
				result_string = "Black won by road"
			GameState.Result.WHITE_FLATS:
				result_string = "White won by flats"
			GameState.Result.BLACK_FLATS:
				result_string = "Black won by flats"
			_:
				result_string = "Draw"
		$UI/GameOver/Box/Result.text = result_string
		var flat_count = game_state.flat_count()
		$UI/GameOver/Box/FlatCount.text = "%d - %d+%d flats" % [flat_count[0], flat_count[1], game_state.komi]
		$UI/GameOver.show()

	selected_piece_type = GameState.Type.FLAT
	held_pieces = []
	pending_move = null
	
	if current_hover_square != null:
		square_entered(current_hover_square)
	
	if game_state.result == GameState.Result.ONGOING:
		match player_types[game_state.side_to_move()]:
			PlayerType.ENGINE:
				engine.go()

func can_enter_move():
	return game_state.result == GameState.Result.ONGOING && player_types[game_state.side_to_move()] == PlayerType.LOCAL

func square_entered(square):
	current_hover_square = square
	var sq = squares[square]
	if !can_enter_move():
		sq.clear_hover_highlight()
		$MovePreview.hide()
		return
		
	var stack = game_state.board[square.x][square.y]
	
	if pending_move != null:
		if pending_move.can_continue_on_square(game_state, square) || (square == pending_move.square && pending_move.drops.is_empty()):
			var height = stack.size()
			if square == pending_move.square:
				height -= pending_move.count
			sq.set_hover_highlight(Color(0.3, 0.6, 0.3))#, height)
			var next_height = height + pending_move.drops_on(square) + 3
			for piece in held_pieces:
				piece.set_temp_pos(Vector3i(square.x, next_height, square.y))
				next_height += 1
		else:
			sq.set_hover_highlight(Color(0.5, 0.2, 0.2))
		return
	
	if stack.is_empty():
		sq.set_hover_highlight(Color(0.3, 0.6, 0.3))
		setup_move_preview()
		$MovePreview.place(Vector3i(square.x, 0, square.y), false)
		$MovePreview.show()
	else:
		if !game_state.is_setup_turn() && stack.back().color == game_state.side_to_move():
			sq.set_hover_highlight(Color(0.3, 0.6, 0.3))#, max(0, stack.size() - game_state.size))
		else:
			sq.set_hover_highlight(Color(0.5, 0.2, 0.2))
		$MovePreview.hide()

func square_exited(square):
	current_hover_square = null
	var sq = squares[square]
	sq.clear_hover_highlight()
	$MovePreview.hide()

func square_clicked(square):
	if !can_enter_move():
		return
	
	var stack = game_state.board[square.x][square.y]
	
	if pending_move != null:
		if square == pending_move.square:
			if pending_move.drops.size() != 0 || pending_move.count <= 1:
				cancel_stack_move()
			else:
				held_pieces.pop_front().set_temp_pos(null)
				pending_move.count -= 1
		elif pending_move.can_continue_on_square(game_state, square):
			var dropped_piece = held_pieces.pop_front()
			var height = stack.size() + pending_move.drops_on(square)
			pending_move.add_drop(square)
			if held_pieces.is_empty():
				game_state.do_move(pending_move)
			else:
				dropped_piece.set_temp_pos(Vector3i(square.x, height, square.y))
		return
	
	if stack.is_empty():
		game_state.do_move(GameState.Move.place(square, selected_piece_type))
	elif !game_state.is_setup_turn() && stack.back().color == game_state.side_to_move():
		held_pieces = []
		for piece in $Pieces.get_children():
			if piece.board_pos.x == square.x && piece.board_pos.z == square.y:
				held_pieces.push_back(piece)
		held_pieces.sort_custom(func (a, b): return a.board_pos.y < b.board_pos.y)
		while held_pieces.size() > game_state.size:
			held_pieces.pop_front()
		for piece in held_pieces:
			piece.set_temp_pos(piece.board_pos + Vector3i(0, 3, 0))
		pending_move = GameState.Move.pending_stack(square, held_pieces.size())

func cancel_stack_move():
	pending_move = null
	held_pieces = []
	for piece in $Pieces.get_children():
		piece.set_temp_pos(null)

func engine_move(move: GameState.Move):
	game_state.do_move(move)

func setup_quality():
	var env: Environment
	var light_energy := 6.0
	var quality: String = config.get_value("display", "quality", "mid")
	var rendering_method := RenderingServer.get_current_rendering_method()
	if rendering_method == "gl_compatibility":
		quality = "low"
	var viewport = get_viewport()
	match quality:
		"high":
			env = load("res://Scenes/env_high.tres")
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
			viewport.scaling_3d_scale = 0.75
		"low":
			env = load("res://Scenes/env_low.tres")
			light_energy = 2.0
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			viewport.scaling_3d_scale = 1.0
		_:
			env = load("res://Scenes/env_mid.tres")
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
			viewport.scaling_3d_scale = 0.5
	$WorldEnvironment.environment = env
	if rendering_method == "gl_compatibility":
		$Camera.attributes = load("res://Scenes/cam_attr_compat.tres")
		light_energy = 1.0
	$Light.light_energy = light_energy
