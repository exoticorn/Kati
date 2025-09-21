extends Control

func setup(playtak_interface: PlaytakInterface):
	playtak_interface.game_move.connect(game_move)
	playtak_interface.update_clock.connect(update_clock)

func game_move(id: int, move: GameState.Move):
	var game := find_game(id)
	if game != null:
		game.remote_move(move)

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
