class_name AnalyzeGame extends Control

const Move = MoveList.Move

const TakBoard = preload("res://Scenes/tak_board.tscn")
const Analysis = preload("res://Scenes/analysis.tscn")

var settings: Dictionary
var config: ConfigFile

var move_list: MoveList

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
	
	move_list = MoveList.new(Common.GameRules.new(settings.size, roundi(settings.komi * 2)))
	move_list.changed.connect(game_state_changed)

	engine = EngineInterface.new(engine_position(), settings.engine_path, settings.engine_parameters);
	engine.search_selected_move = true
	engine.max_multipv = 16
	engine.engine_ready.connect(engine_ready)
	engine.info.connect(info)
	add_child(engine)
	
	analysis = Analysis.instantiate()
	var move_list_ui = preload("res://ui/move_list.tscn").instantiate()
	move_list_ui.setup(move_list)
	
	board = TakBoard.instantiate()
	board.config = config
	board.board_state = move_list.display_board
	board.move_input.connect(move_input)
	board.step_move.connect(move_list.step_move)
	board.add_ui(move_list_ui, false)
	var close_button = Button.new()
	close_button.text = "Close analysis"
	close_button.pressed.connect(get_parent().remove_game.bind(self))
	board.add_ui(close_button, true)
	board.add_ui(analysis, true)
	board.can_input_move = true
	add_child(board)

func engine_position() -> EngineInterface.Position:
	return EngineInterface.Position.new(move_list.display_board.size, move_list.display_board.half_komi, move_list.moves.slice(0, move_list.display_move))

func move_input(move: Move):
	move_list.truncate_moves()
	move_list.push_move(move)

func game_state_changed():
	var result = move_list.display_board.game_result()
	board.can_input_move = result.is_ongoing()
	board.show_result(result)
	if result.is_ongoing():
		engine.go_infinite(engine_position())
	move_infos = []
	board.set_move_infos(move_infos)
	analysis.move_count = move_list.display_move

func engine_ready():
	engine.go_infinite(engine_position())

func info(move_info: EngineInterface.MoveInfo):
	if move_info.pv_index == 0:
		analysis.set_info(move_info)
	if move_infos.size() == move_info.pv_index:
		move_infos.push_back(move_info)
	elif move_info.pv_index < move_infos.size():
		move_infos[move_info.pv_index] = move_info
	board.set_move_infos(move_infos)
