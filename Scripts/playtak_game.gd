class_name PlaytakGame extends Control

const Move = MoveList.Move
const PlayerColor = BoardState.PlayerColor

const TakBoard = preload("res://Scenes/tak_board.tscn")
const Clock = preload("res://Scenes/clock.tscn")
const GameAction = preload("res://Scripts/game_actions.gd").Action

var playtak_interface: PlaytakInterface
var config: ConfigFile
var game: PlaytakInterface.Game
var move_list: MoveList
var board: Node
var game_result := GameResult.new()
var clocks: Array[Control]
var game_actions

var shown:
	set(s):
		visible = s
		board.shown = s
	get():
		return visible

func setup(g: PlaytakInterface.Game, i: PlaytakInterface, c: ConfigFile):
	game = g
	playtak_interface = i
	config = c

func _ready():
	move_list = MoveList.new(game.size, game.komi)
	move_list.changed.connect(setup_move_input)
	
	board = TakBoard.instantiate()
	board.config = config
	board.board_state = move_list.display_board
	board.move_input.connect(move_input)
	board.step_move.connect(move_list.step_move)
	if game.color != PlaytakInterface.ColorChoice.NONE:
		game_actions = preload("res://Scenes/game_actions.tscn").instantiate()
		game_actions.send_action.connect(send_game_action)
		board.add_ui(game_actions, game.color == PlaytakInterface.ColorChoice.BLACK, false)
	for i in 2:
		clocks.push_back(Clock.instantiate())
		clocks[i].setup(game.player_white if i == 0 else game.player_black, game.time)
		board.add_ui(clocks[i], i == 1, false)
	add_child(board)
	setup_move_input()

func move_input(move: Move):
	move_list.push_move(move)
	playtak_interface.send_move(game.id, move)
	update_clock_running()
	if game_actions != null:
		game_actions.reset()

func remote_move(move: Move):
	move_list.push_move(move)
	update_clock_running()
	if game_actions != null:
		game_actions.reset()

func undo_move():
	move_list.pop_move()
	update_clock_running()
	if game_actions != null:
		game_actions.reset()

func update_clock(wtime: float, btime: float):
	clocks[0].time = wtime
	clocks[1].time = btime
	update_clock_running()

func update_clock_running():
	var running = game_result.is_ongoing()
	var white_to_move = move_list.display_board.side_to_move() == PlayerColor.WHITE
	clocks[0].running = running && white_to_move
	clocks[1].running = running && !white_to_move

func set_result(result: GameResult):
	game_result = result
	board.show_result(result)
	setup_move_input()
	update_clock_running()

func setup_move_input():
	var can_move = false
	if move_list.display_move == move_list.moves.size():
		if game_result.is_ongoing() && move_list.display_board.game_result().is_ongoing():
			var side_to_move = move_list.display_board.side_to_move()
			if side_to_move == PlayerColor.WHITE && game.color == PlaytakInterface.ColorChoice.WHITE:
				can_move = true
			elif side_to_move == PlayerColor.BLACK && game.color == PlaytakInterface.ColorChoice.BLACK:
				can_move = true
	board.can_input_move = can_move

func send_game_action(action: GameAction):
	playtak_interface.send_game_action(game.id, action)

func receive_game_action(action: GameAction):
	game_actions.receive_action(action)
