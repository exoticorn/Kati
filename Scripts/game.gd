extends Node3D

var square_scene = preload("res://Scenes/square.tscn")
var piece_scene = preload("res://Scenes/piece.tscn")

var config: ConfigFile

#var game_state = GameState.new(5, 21, 1)
var game_state = GameState.from_tps("x3,1121,x,2/x2,1,1,121S,x/x2,1,x,2C,12S/x,212,112221C,x,2,221/1112,11,x,2,x2/1,1,112S,2,2,x 2 34", 30, 1)

func _ready():
	config = ConfigFile.new()
	config.load("user://catak.cfg")
	setup_quality()
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

func setup_quality():
	var env: Environment
	var light_energy := 6.0
	var quality: String = config.get_value("display", "quality", "high")
	var rendering_method := RenderingServer.get_current_rendering_method()
	if rendering_method == "gl_compatibility":
		quality = "compatibility"
	match quality:
		"high":
			env = load("res://Scenes/env_high.tres")
		"compatibility":
			env = load("res://Scenes/env_compat.tres")
			light_energy = 1.0
		_:
			env = load("res://Scenes/env_low.tres")
	$WorldEnvironment.environment = env
	$Light.light_energy = light_energy
	match rendering_method:
		"gl_compatibility", "mobile":
			get_viewport().scaling_3d_scale = 1.0
