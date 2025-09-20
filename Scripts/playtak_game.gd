class_name PlaytakGame extends Control

const TakBoard = preload("res://Scenes/tak_board.tscn")

var playtak_interface: PlaytakInterface
var game: PlaytakInterface.Game
var game_state: GameState
var board: Node

func _init(g: PlaytakInterface.Game, i: PlaytakInterface):
	game = g
	playtak_interface = i

func _ready():
	anchor_left = ANCHOR_BEGIN
	anchor_right = ANCHOR_END
	anchor_top = ANCHOR_BEGIN
	anchor_bottom = ANCHOR_END
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	game_state = GameState.new(game.size, game.komi)
	
	board = TakBoard.instantiate()
	board.game_state = game_state
	board.move_input.connect(move_input)
	add_child(board)
	setup_move_input()

func move_input(move: GameState.Move):
	game_state.do_move(move)
	playtak_interface.send_move(game.id, move)

func remote_move(move: GameState.Move):
	game_state.do_move(move)
	setup_move_input()

func setup_move_input():
	var can_move = false
	if game_state.result == GameState.Result.ONGOING:
		var side_to_move = game_state.side_to_move()
		if side_to_move == GameState.Col.WHITE && game.color == PlaytakInterface.ColorChoice.WHITE:
			can_move = true
		elif side_to_move == GameState.Col.BLACK && game.color == PlaytakInterface.ColorChoice.BLACK:
			can_move = true
	board.can_input_move = can_move
