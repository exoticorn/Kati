class_name AnalyzeGame extends Control


const TakBoard = preload("res://Scenes/tak_board.tscn")

var settings: Dictionary
var config: ConfigFile

var game_state: GameState

var engine: EngineInterface
var board: Node

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
	
	game_state = GameState.new(settings.size, settings.komi)

	engine = EngineInterface.new(game_state, settings.engine_path, settings.engine_parameters);
	engine.engine_ready.connect(engine_ready)
	add_child(engine)
	
	board = TakBoard.instantiate()
	board.config = config
	board.game_state = game_state
	board.move_input.connect(move_input)
	board.can_input_move = true
	add_child(board)
	
func move_input(move: GameState.Move):
	game_state.push_move(move)
	board.can_input_move = game_state.result == GameState.Result.ONGOING && game_state.is_at_latest_move()
	engine.go_infinite()

func engine_ready():
	engine.go_infinite()
