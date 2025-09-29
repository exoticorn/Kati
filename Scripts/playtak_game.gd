class_name PlaytakGame extends Control

const TakBoard = preload("res://Scenes/tak_board.tscn")
const Clock = preload("res://Scenes/clock.tscn")

var playtak_interface: PlaytakInterface
var config: ConfigFile
var game: PlaytakInterface.Game
var game_state: GameState
var board: Node
var clocks: Array[Control]

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
	game_state = GameState.new(game.size, game.komi)
	
	board = TakBoard.instantiate()
	board.config = config
	board.game_state = game_state
	board.move_input.connect(move_input)
	for i in 2:
		clocks.push_back(Clock.instantiate())
		clocks[i].setup(game.player_white if i == 0 else game.player_black, game.time)
		board.add_ui(clocks[i], i == 1, false)
	add_child(board)
	setup_move_input()

func move_input(move: GameState.Move):
	game_state.push_move(move)
	playtak_interface.send_move(game.id, move)
	update_clock_running()

func remote_move(move: GameState.Move):
	game_state.push_move(move)
	setup_move_input()
	update_clock_running()

func undo_move():
	game_state.pop_move()
	setup_move_input()
	update_clock_running()

func update_clock(wtime: float, btime: float):
	clocks[0].time = wtime
	clocks[1].time = btime
	update_clock_running()

func update_clock_running():
	var running = game_state.result == GameState.Result.ONGOING
	var white_to_move = game_state.side_to_move() == GameState.Col.WHITE
	clocks[0].running = running && white_to_move
	clocks[1].running = running && !white_to_move

func setup_move_input():
	var can_move = false
	if game_state.result == GameState.Result.ONGOING:
		var side_to_move = game_state.side_to_move()
		if side_to_move == GameState.Col.WHITE && game.color == PlaytakInterface.ColorChoice.WHITE:
			can_move = true
		elif side_to_move == GameState.Col.BLACK && game.color == PlaytakInterface.ColorChoice.BLACK:
			can_move = true
	board.can_input_move = can_move
