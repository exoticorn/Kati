class_name LocalGame extends Control

const Move = MoveList.Move

const TakBoard = preload("res://Scenes/tak_board.tscn")

var settings: Dictionary
var config: ConfigFile

var move_list: MoveList
var game_board: BoardState

var engine: EngineInterface
var board: Node
var game_result = GameResult.new()

enum PlayerType { LOCAL, ENGINE }
var player_types: Array[PlayerType] = []

var shown:
	set(s):
		visible = s
		board.shown = s
	get():
		return visible

func _init(sttngs: Dictionary, cfg: ConfigFile):
	settings = sttngs
	config = cfg
	
func _ready():
	anchor_left = ANCHOR_BEGIN
	anchor_right = ANCHOR_END
	anchor_top = ANCHOR_BEGIN
	anchor_bottom = ANCHOR_END
	mouse_filter = Control.MOUSE_FILTER_PASS
	var game_rules = Common.GameRules.new(settings.size, roundi(settings.komi * 2))
	
	move_list = MoveList.new(game_rules)
	move_list.changed.connect(setup_move_input)
	for i in 2:
		player_types.push_back(PlayerType.ENGINE if (settings.engine_mask & (1 << i)) != 0 else PlayerType.LOCAL)
	game_board = BoardState.new(game_rules)

	if settings.engine_mask != 0:
		engine = EngineInterface.new(engine_position(), settings.engine_path, settings.engine_parameters);
		engine.bestmove.connect(move_input)
		engine.engine_ready.connect(engine_ready)
		add_child(engine)
	board = TakBoard.instantiate()
	board.config = config
	board.board_state = move_list.display_board
	board.move_input.connect(move_input)
	board.step_move.connect(move_list.step_move)
	var move_list_ui = preload("res://ui/move_list.tscn").instantiate()
	move_list_ui.setup(move_list)
	board.add_ui(move_list_ui, false, true)
	var close_button = Button.new()
	close_button.text = "Close game"
	close_button.pressed.connect(get_parent().remove_game.bind(self))
	board.add_ui(close_button, true)
	add_child(board)
	setup_move_input()
	
func move_input(move: Move):
	game_board.apply_move(move)
	game_result = game_board.game_result()
	board.show_result(game_result)
	move_list.push_move(move)

func engine_ready():
	setup_move_input()

func setup_move_input():
	board.can_input_move = false
	if game_result.is_ongoing():
		if player_types[move_list.moves.size() & 1] == PlayerType.LOCAL:
			if move_list.display_move == move_list.moves.size():
				board.can_input_move = true
		else:
			if engine.is_ready():
				engine.go(engine_position())

func engine_position() -> EngineInterface.Position:
	return EngineInterface.Position.new(move_list.display_board.size, move_list.display_board.half_komi, move_list.moves)
