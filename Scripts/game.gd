extends Node3D

var square_scene = preload("res://Scenes/square.tscn")
var piece_scene = preload("res://Scenes/piece.tscn")

var game_state = GameState.new(5, 21, 1)
func _ready():
	create_board()

func create_board():
	for x in range(game_state.size):
		for y in range(game_state.size):
			var square := square_scene.instantiate()
			square.position = Vector3(x, 0, -y)
			$Board.add_child(square)
			var stack: Array = game_state.board[x][y]
			for i in stack.size():
				var piece = stack[i]
				var piece_node = piece_scene.instantiate()
				piece_node.setup(piece.color, piece.type)
				$Pieces.add_child(piece_node)
				piece_node.place(Vector3i(x, i, y))
				
	var center = (game_state.size - 1.0) / 2
	$Camera.target = Vector3(center, 0, -center)	
