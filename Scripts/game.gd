extends Node3D

var square_scene = preload("res://Scenes/square.tscn")
var piece_scene = preload("res://Scenes/piece.tscn")

var config: ConfigFile

var game_state = GameState.new(6)
#var game_state = GameState.from_tps("x3,2,x,1/x2,1S,2,2,1/1,1,1212C,1,1,1/1,2S,21,21C,1,2/x,2,2,21,x,2/2,x,121S,x,2,12 1 24")
var pieces_map = {}

var engine: EngineInterface

func _ready():
	config = ConfigFile.new()
	config.load("user://catak.cfg")
	setup_quality()
	create_board()
	engine = EngineInterface.new(game_state)
	engine.bestmove.connect(engine_move)
	add_child(engine)
	game_state.changed.connect(update_board)

func create_board():
	for x in range(game_state.size):
		for y in range(game_state.size):
			var square := square_scene.instantiate()
			square.position = Vector3(x, 0, -y)
			$Board.add_child(square)
				
	var center = (game_state.size - 1.0) / 2
	$Camera.target = Vector3(center, 0, -center)
	
	update_board()

func update_board():
	var piece_map = {}
	var pieces_to_place := []
	for piece in $Pieces.get_children():
		piece_map[piece.board_pos] = piece
	for x in range(game_state.size):
		for y in range(game_state.size):
			var stack: Array = game_state.board[x][y]
			for i in stack.size():
				var board_pos = Vector3i(x, i, y)
				var piece = stack[i]
				var existing = piece_map.get(board_pos)
				if existing != null && existing.can_be(piece.color, piece.type):
					existing.become(piece.type)
					piece_map.erase(board_pos)
				else:
					pieces_to_place.push_back({"pos": board_pos, "piece": piece})

	var pieces_to_move := []
	for pos in piece_map:
		pieces_to_move.push_back(piece_map[pos])
	
	pieces_to_move.sort_custom(func (a, b): return a.board_pos.y < b.board_pos.y)
	
	for piece in pieces_to_move:
		var pos_a = piece.board_pos
		var best_index = -1
		var best_distance = game_state.size ** 2 * 2
		for index in pieces_to_place.size():
			var to_place = pieces_to_place[index]
			if to_place.piece.color == piece.color && to_place.piece.type == piece.type:
				var pos_b = to_place.pos
				var distance = abs(pos_a.y - pos_b.y) * game_state.size + abs(pos_a.x - pos_b.x) + abs(pos_a.z - pos_b.z)
				if distance < best_distance:
					best_distance = distance
					best_index = index
		if best_index >= 0:
			piece.place(pieces_to_place[best_index].pos)
			pieces_to_place.remove_at(best_index)
		else:
			piece.queue_free()

	for to_place in pieces_to_place:
		var piece_node = piece_scene.instantiate()
		var piece = to_place.piece
		piece_node.setup(piece.color, piece.type)
		$Pieces.add_child(piece_node)
		piece_node.place(to_place.pos, false)
	

func engine_move(move: GameState.Move):
	game_state.do_move(move)
	await get_tree().create_timer(1).timeout
	engine.go()

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
