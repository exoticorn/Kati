class_name AnalyzeGame extends Control


const TakBoard = preload("res://Scenes/tak_board.tscn")
const Analysis = preload("res://Scenes/analysis.tscn")

var settings: Dictionary
var config: ConfigFile

var game_state: GameState

var engine: EngineInterface
var board: Node
var analysis: Node
var move_infos: Array[EngineInterface.MoveInfo] = []

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
	game_state.changed.connect(game_state_changed)

	engine = EngineInterface.new(game_state, settings.engine_path, settings.engine_parameters);
	engine.search_selected_move = true
	engine.max_multipv = 16
	engine.engine_ready.connect(engine_ready)
	engine.info.connect(info)
	add_child(engine)
	
	analysis = Analysis.instantiate()
	
	board = TakBoard.instantiate()
	board.config = config
	board.game_state = game_state
	board.move_input.connect(move_input)
	board.add_ui(analysis, true)
	board.can_input_move = true
	add_child(board)
	
func move_input(move: GameState.Move):
	game_state.truncate_moves()
	game_state.push_move(move)

func game_state_changed():
	board.can_input_move = game_state.result == GameState.Result.ONGOING || !game_state.is_at_latest_move()
	engine.go_infinite()
	move_infos = []
	board.set_move_infos(move_infos)
	analysis.move_count = game_state.moves.size()

func engine_ready():
	engine.go_infinite()

func info(move_info: EngineInterface.MoveInfo):
	if move_info.pv_index == 0:
		analysis.set_info(move_info)
	if move_infos.size() == move_info.pv_index:
		move_infos.push_back(move_info)
	elif move_info.pv_index < move_infos.size():
		move_infos[move_info.pv_index] = move_info
	board.set_move_infos(move_infos)
