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
	var pieces_to_place = []
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

	for pos in piece_map:
		piece_map[pos].queue_free()
	for to_place in pieces_to_place:
		var piece_node = piece_scene.instantiate()
		var piece = to_place.piece
		piece_node.setup(piece.color, piece.type)
		$Pieces.add_child(piece_node)
		piece_node.place(to_place.pos)
	

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
	match quality:
		"high":
			env = load("res://Scenes/env_high.tres")
		"low":
			env = load("res://Scenes/env_low.tres")
			light_energy = 2.0
			var viewport = get_viewport()
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			viewport.scaling_3d_scale = 1.0
		_:
			env = load("res://Scenes/env_mid.tres")
	$WorldEnvironment.environment = env
	if rendering_method == "gl_compatibility":
		$Camera.attributes = load("res://Scenes/cam_attr_compat.tres")
		light_energy = 1.0
	$Light.light_energy = light_energy
