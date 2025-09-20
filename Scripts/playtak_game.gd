class_name PlaytakGame extends Control

const TakBoard = preload("res://Scenes/tak_board.tscn")

var game: PlayTakInterface.Game
var game_state: GameState
var board: Node

func _init(g: PlayTakInterface.Game):
	game = g

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
	pass

func setup_move_input():
	pass
