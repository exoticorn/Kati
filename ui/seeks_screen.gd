extends PanelContainer

const ColorChoice = PlaytakInterface.ColorChoice
const GameType = PlaytakInterface.GameType

class SeekRow:
	var seek: PlaytakInterface.Seek
	var rating: int = 0
	var controls: Array[Control]

var playtak: PlaytakInterface
var seeks: Array[SeekRow]

func set_playtak(p: PlaytakInterface):
	playtak = p
	playtak.seeks_changed.connect(sync_seeks)
	playtak.ratings_changed.connect(update_ratings)

func sync_seeks():
	var seek_index = seeks.size() - 1
	while seek_index >= 0:
		var seek = seeks[seek_index]
		var found = false
		for s in playtak.seeks:
			if s.id == seek.seek.id:
				found = true
				break
		if !found:
			for c in seek.controls:
				c.queue_free()
			seeks.remove_at(seek_index)
		seek_index -= 1
	
	for seek in playtak.seeks:
		var found = false
		for s in seeks:
			if seek.id == s.seek.id:
				found = true
				break
		if !found:
			var s = SeekRow.new()
			s.seek = seek
			var name_ = LinkButton.new()
			var name_str = seek.user if seek.user != playtak.username else "-> " + seek.opponent
			if seek.bot:
				name_str = " " + name_str
			if seek.game_type == PlaytakInterface.GameType.TOURNAMENT:
				name_str = " " + name_str
			name_.text = name_str
			name_.pressed.connect(playtak.accept_seek.bind(seek.id))
			s.controls.push_back(name_)
			s.controls.push_back(Label.new())
			var rules = Label.new()
			rules.text = seek.rules.format()
			s.controls.push_back(rules)
			var time = Label.new()
			time.text = seek.clock.format()
			s.controls.push_back(time)
			var color = Label.new()
			color.text = "black" if seek.color == ColorChoice.WHITE else "white" if seek.color == ColorChoice.BLACK else "random"
			s.controls.push_back(color)
			var mode = Label.new()
			mode.text = "tournament" if seek.game_type == GameType.TOURNAMENT else "unrated" if seek.game_type == GameType.UNRATED else "rated"
			s.controls.push_back(mode)

			seeks.push_back(s)
			for c in s.controls:
				$MainBox/Seeks.add_child(c)
			
			if seek.direct && seek.user != playtak.username:
				$AudioStreamPlayer.play()

	update_ratings()

func update_ratings():
	var ratings = playtak.ratings
	for seek in seeks:
		if ratings.has(seek.seek.user):
			var entry = ratings[seek.seek.user]
			seek.rating = entry.rating
			seek.controls[1].text = str(seek.rating)

	for i in seeks.size() - 1:
		for j in range(i + 1, seeks.size()):
			if seeks[i].rating < seeks[j].rating:
				var seek = seeks.pop_at(j)
				seeks.insert(i, seek)
				for k in seek.controls.size():
					$MainBox/Seeks.move_child(seek.controls[k], (i + 1) * 6 + k)
