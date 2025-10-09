extends PanelContainer

class Row:
	var game: PlaytakInterface.Game
	var controls: Array[Control]

var playtak: PlaytakInterface
var rows: Array[Row]

func setup(ptk: PlaytakInterface):
	playtak = ptk
	playtak.game_list_changed.connect(sync_games)

func sync_games():
	var row_index = rows.size() - 1
	while row_index >= 0:
		var row = rows[row_index]
		var found = false
		for game in playtak.game_list:
			if game.id == row.game.id:
				found = true
				break
		if !found:
			for c in row.controls:
				c.queue_free()
			rows.remove_at(row_index)
		row_index -= 1
	
	for game in playtak.game_list:
		var found = false
		for row in rows:
			if game.id == row.game.id:
				found = true
				break
		if !found:
			var row = Row.new()
			row.game = game
			var name_ = LinkButton.new()
			name_.text = "%s - %s" % [game.player_white, game.player_black]
			if game.game_type == PlaytakInterface.GameType.TOURNAMENT:
				name_.text = " " + name_.text
			name_.pressed.connect(playtak.observe.bind(game.id))
			row.controls.push_back(name_)
			var rules = Label.new()
			rules.text = game.rules.format()
			row.controls.push_back(rules)
			var time = Label.new()
			time.text = game.clock.format()
			row.controls.push_back(time)

			rows.push_back(row)
			for c in row.controls:
				$Box/Games.add_child(c)
