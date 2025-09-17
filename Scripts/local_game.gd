extends Node

const TakBoard = preload("res://Scenes/tak_board.tscn")

var settings: Dictionary

var game_state: GameState

var engine: EngineInterface
var board

enum PlayerType { LOCAL, ENGINE }
var player_types: Array[PlayerType] = []

func _ready():
	game_state = GameState.new(settings.size, settings.komi)
	for i in 2:
		player_types.push_back(PlayerType.ENGINE if (settings.engine_mask & (1 << i)) != 0 else PlayerType.LOCAL)

	if settings.engine_mask != 0:
		engine = EngineInterface.new(game_state);
		engine.bestmove.connect(move_input)
		engine.engine_ready.connect(engine_ready)
		add_child(engine)
	board = TakBoard.instantiate()
	board.game_state = game_state
	board.move_input.connect(move_input)
	add_child(board)
	setup_move_input()
	
func move_input(move: GameState.Move):
	game_state.do_move(move)
	setup_move_input()

func engine_ready():
	setup_move_input()

func setup_move_input():
	if game_state.result != GameState.Result.ONGOING:
		board.can_input_move = false
		return
	if player_types[game_state.side_to_move()] == PlayerType.LOCAL:
		board.can_input_move = true
	else:
		board.can_input_move = false
		if engine.is_ready():
			engine.go()
