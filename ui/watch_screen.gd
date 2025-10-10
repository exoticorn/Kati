extends PanelContainer

class Row:
	var game: PlaytakInterface.Game
	var controls: Array[Control]
	var avg_rating: int = 0

var playtak: PlaytakInterface
var rows: Array[Row]

func setup(ptk: PlaytakInterface):
	playtak = ptk
	playtak.game_list_changed.connect(sync_games)
	playtak.ratings_changed.connect(update_ratings)

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
			
			update_ratings()

func update_ratings():
	var ratings = playtak.ratings
	for row in rows:
		var sum = 0
		var count = 0
		var names = " " if row.game.game_type == PlaytakInterface.GameType.TOURNAMENT else ""
		if ratings.has(row.game.player_white):
			var entry = ratings[row.game.player_white]
			names += Common.format_player(row.game.player_white, entry)
			sum += entry.rating
			count += 1
		else:
			names += row.game.player_white
		names += " - "
		if ratings.has(row.game.player_black):
			var entry = ratings[row.game.player_black]
			names += Common.format_player(row.game.player_black, entry)
			sum += entry.rating
			count += 1
		else:
			names += row.game.player_black
		if count > 0:
			row.avg_rating = sum / count
		row.controls[0].text = names

	for i in rows.size() - 1:
		for j in range(i + 1, rows.size()):
			if rows[i].avg_rating < rows[j].avg_rating:
				var row = rows.pop_at(j)
				rows.insert(i, row)
				for k in row.controls.size():
					$Box/Games.move_child(row.controls[k], (i + 1) * 3 + k)
