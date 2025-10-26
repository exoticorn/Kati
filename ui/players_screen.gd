extends PanelContainer


signal challenge_pressed(player: String)
signal chat_pressed(player: String)


var _playtak: PlaytakInterface
var _players: Array[PlayerRow] = []


func setup(playtak: PlaytakInterface):
	_playtak = playtak
	_playtak.players_changed.connect(_update_list)
	_playtak.ratings_changed.connect(_update_ratings)
	_update_list()


func _update_list():
	var player_index = _players.size() - 1
	while player_index >= 0:
		var player = _players[player_index]
		if _playtak.online_players.find_custom(func (p): return p == player.name) < 0:
			for c in player.controls:
				%Grid.remove_child(c)
				c.queue_free()
			_players.remove_at(player_index)
		player_index -= 1
	
	for player in _playtak.online_players:
		if _players.find_custom(func (p): return p.name == player) < 0:
			var row = PlayerRow.new()
			row.name = player
			var label = preload("res://ui/player_name.tscn").instantiate()
			label.setup(_playtak)
			label.user = player
			row.controls.push_back(label)
			var me = player == _playtak.username
			var challenge = Button.new()
			challenge.text = "Challenge"
			challenge.disabled = me
			challenge.pressed.connect(challenge_pressed.emit.bind(player))
			row.controls.push_back(challenge)
			var chat = Button.new()
			chat.text = "Chat"
			chat.disabled = me
			chat.pressed.connect(chat_pressed.emit.bind(player))
			row.controls.push_back(chat)
			for c in row.controls:
				%Grid.add_child(c)
			_players.push_back(row)

	_update_ratings()


func _update_ratings():
	for player in _players:
		if _playtak.ratings.has(player.name):
			player.rating = _playtak.ratings[player.name].rating
	
	for i in _players.size() - 1:
		for j in range(i + 1, _players.size()):
			if _players[i].rating < _players[j].rating:
				var player = _players.pop_at(j)
				_players.insert(i, player)
				for k in player.controls.size():
					%Grid.move_child(player.controls[k], i * 3 + k)


class PlayerRow:
	var name: String
	var rating: int = 0
	var controls: Array[Control]
