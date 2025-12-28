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
var clean_move_list: MoveList
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
	if is_observe():
		clean_move_list = MoveList.new(game.rules)
		move_list.parent_moves = clean_move_list
	else:
		clean_move_list = move_list
	game_board = BoardState.new(game.rules)
	move_list.changed.connect(setup_move_input)
	
	board = TakBoard.instantiate()
	board.config = config
	board.board_state = move_list.display_board
	board.move_input.connect(move_input)
	board.step_move.connect(move_list.step_move)
	board.rematch.connect(rematch)
	if game.color != PlaytakInterface.ColorChoice.NONE:
		game_actions = preload("res://Scenes/game_actions.tscn").instantiate()
		game_actions.send_action.connect(send_game_action)
		board.add_ui(game_actions, game.color == PlaytakInterface.ColorChoice.BLACK, false)
		stream_player.stream = load("res://sfx/start.wav")
		stream_player.play.call_deferred()
	else:
		var close_button = Button.new()
		close_button.text = "Close game"
		close_button.pressed.connect(unobserve_game)
		board.add_ui(close_button, true, false)
	var game_rules = preload("res://ui/game_rules.tscn").instantiate()
	game_rules.setup(game.rules, game.clock)
	board.add_ui(game_rules, game.color != PlaytakInterface.ColorChoice.WHITE, false)
	var move_list_ui = preload("res://ui/move_list.tscn").instantiate()
	move_list_ui.setup(move_list)
	board.add_ui(move_list_ui, game.color == PlaytakInterface.ColorChoice.WHITE, false)
	for i in 2:
		clocks.push_back(Clock.instantiate())
		clocks[i].setup(playtak_interface, game.player_white if i == 0 else game.player_black, game.clock.time, game.color == i)
		board.add_ui(clocks[i], i == 1, false)
	add_child(board)
	add_child(stream_player)
	setup_move_input()


func _unhandled_input(event: InputEvent) -> void:
	if !is_visible_in_tree():
		return
	if event is InputEventKey:
		if event.is_pressed() && event.ctrl_pressed:
			match event.keycode:
				KEY_Y:
					DisplayServer.clipboard_set(move_list.branch_ptn())


func move_input(move: Move):
	if is_observe():
		move_list.truncate_moves()
	else:
		game_board.apply_move(move)
		playtak_interface.send_move(game.id, move)
		update_clock_running()
		if game_actions != null:
			game_actions.reset()
	move_list.push_move(move)

func remote_move(move: Move):
	clean_move_list.push_move(move)
	game_board.apply_move(move)
	update_clock_running()
	if game_actions != null:
		game_actions.reset()
	if !visible:
		new_moves += 1

func undo_move():
	clean_move_list.pop_move(game_board)
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
	var white_to_move = game_board.side_to_move() == PlayerColor.WHITE
	clocks[0].running = running && white_to_move
	clocks[1].running = running && !white_to_move

func set_result(result: GameResult):
	game_result = result
	game_result.set_flat_count(game_board.flat_count(), game_board.half_komi)
	board.show_result(result, game)
	var sample = null
	if !result.is_ongoing():
		if result.state == GameResult.State.DRAW:
			sample = load("res://sfx/draw.wav")
		elif game.color == ColorChoice.NONE || game.color == result.winner():
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
	if is_observe():
		can_move = move_list.display_board.game_result().is_ongoing()
	else:
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

func rematch():
	var seek = PlaytakInterface.Seek.new()
	seek.id = game.id
	seek.rules = game.rules
	seek.clock = game.clock
	seek.color = ColorChoice.WHITE if game.color == ColorChoice.BLACK else ColorChoice.BLACK
	seek.game_type = game.game_type
	seek.opponent = game.player_black if game.color == ColorChoice.WHITE else game.player_white
	playtak_interface.send_rematch(seek)

func unobserve_game():
	playtak_interface.unobserve(game.id)
	get_parent().remove_game(self)
