class_name PlaytakGame extends Control

const Move = MoveList.Move
const PlayerColor = BoardState.PlayerColor
const ColorChoice = PlaytakInterface.ColorChoice

const TakBoard = preload("res://Scenes/tak_board.tscn")
const Clock = preload("res://Scenes/clock.tscn")
const GameAction = preload("res://Scripts/game_actions.gd").Action

var playtak_interface: PlaytakInterface
var config: ConfigFile
var game: PlaytakInterface.Game
var game_board: BoardState
var move_list: MoveList
var board: Node
var stream_player: AudioStreamPlayer = AudioStreamPlayer.new()
var game_result := GameResult.new()
var clocks: Array[Control]
var game_actions
var new_moves: int = 0

var shown:
	set(s):
		visible = s
		board.shown = s
		if visible:
			new_moves = 0
	get():
		return visible

func setup(g: PlaytakInterface.Game, i: PlaytakInterface, c: ConfigFile):
	game = g
	playtak_interface = i
	config = c

func _ready():
	move_list = MoveList.new(game.rules)
	game_board = BoardState.new(game.rules)
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
		clocks[i].setup(playtak_interface, game.player_white if i == 0 else game.player_black, game.clock.time, game.color == i)
		board.add_ui(clocks[i], i == 1, false)
	add_child(board)
	add_child(stream_player)
	setup_move_input()

func move_input(move: Move):
	move_list.push_move(move)
	game_board.apply_move(move)
	playtak_interface.send_move(game.id, move)
	update_clock_running()
	if game_actions != null:
		game_actions.reset()

func remote_move(move: Move):
	move_list.push_move(move)
	game_board.apply_move(move)
	update_clock_running()
	if game_actions != null:
		game_actions.reset()
	if !visible:
		new_moves += 1

func undo_move():
	move_list.pop_move(game_board)
	update_clock_running()
	if game_actions != null:
		game_actions.reset()
	if !visible:
		new_moves += 1

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
	game_result.set_flat_count(game_board.flat_count(), game_board.half_komi)
	board.show_result(result)
	var sample = null
	if result.is_win():
		if game.color == ColorChoice.NONE || game.color == result.winner():
			sample = load("res://sfx/win.wav")
		else:
			sample = load("res://sfx/loss.wav")
	if sample != null:
		stream_player.stream = sample
		stream_player.play()
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

func is_observe() -> bool:
	return game.color == ColorChoice.NONE
