extends Control

const Move = MoveList.Move
const GameAction = preload("res://Scripts/game_actions.gd").Action

func setup(playtak_interface: PlaytakInterface):
	playtak_interface.game_move.connect(game_move)
	playtak_interface.game_undo.connect(game_undo)
	playtak_interface.game_result.connect(game_result)
	playtak_interface.update_clock.connect(update_clock)
	playtak_interface.game_action.connect(game_action)

func add_game(game: Control):
	for child in get_children():
		var remove = false
		if child is LocalGame:
			remove = !child.game_result.is_ongoing() || game is LocalGame
		elif child is PlaytakGame:
			remove = !child.game_result.is_ongoing()
			if game is PlaytakGame:
				if child.is_observe() && !game.is_observe():
					remove = true
		elif child is AnalyzeGame:
			remove = true
		if remove:
			child.queue_free()
		else:
			child.shown = false
	add_child(game)

func remove_playtak_games():
	for game in get_children():
		if game is PlaytakGame:
			game.queue_free()
		else:
			game.shown = true

func game_move(id: int, move: Move):
	var game := find_game(id)
	if game != null:
		game.remote_move(move)

func game_undo(id: int):
	var game := find_game(id)
	if game != null:
		game.undo_move()

func game_result(id: int, result: GameResult):
	var game := find_game(id)
	if game != null:
		game.set_result(result)

func game_action(id: int, action: GameAction):
	var game := find_game(id)
	if game != null:
		game.receive_game_action(action)

func update_clock(id: int, wtime: float, btime: float):
	var game := find_game(id)
	if game != null:
		game.update_clock(wtime, btime)

func find_game(id: int) -> PlaytakGame:
	for child in get_children():
		if child is PlaytakGame:
			if child.game.id == id:
				return child
	return null

func switch_game() -> void:
	var games = get_children()
	if games.size() < 2:
		return
	var index = 0
	for i in games.size():
		if games[i].visible:
			index = i
	index = (index + 1) % games.size()
	for i in games.size():
		games[i].shown = i == index

func current_game() -> Variant:
	for game in get_children():
		if game.visible and game is PlaytakGame:
			return game.game
	return null

func apply_settings():
	for game in get_children():
		game.board.apply_settings()

func game_count() -> int:
	return get_children().size()

func remove_game(game):
	if game.shown:
		switch_game()
	game.queue_free()

func has_new_moves() -> bool:
	for game in get_children():
		if game is PlaytakGame:
			if game.new_moves > 0:
				return true
	return false
