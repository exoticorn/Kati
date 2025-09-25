extends Control

func setup(playtak_interface: PlaytakInterface):
	playtak_interface.game_move.connect(game_move)
	playtak_interface.game_undo.connect(game_undo)
	playtak_interface.update_clock.connect(update_clock)

func add_game(game: Control):
	for child in get_children():
		var remove = false
		if child is LocalGame:
			remove = child.game_state.result != GameState.Result.ONGOING || game is LocalGame
		elif child is PlaytakGame:
			remove = child.game_state.result != GameState.Result.ONGOING
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

func game_move(id: int, move: GameState.Move):
	var game := find_game(id)
	if game != null:
		game.remote_move(move)

func game_undo(id: int):
	var game := find_game(id)
	if game != null:
		game.undo_move()

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

func apply_settings():
	for game in get_children():
		game.board.setup_quality()
