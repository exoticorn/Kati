extends Label

var _playtak: PlaytakInterface
var _user: String
var _rating: int = 0
var _is_bot: bool = false

var user: String:
	get(): return _user
	set(n):
		_user = n
		_rating = 0
		_is_bot = false
		if _playtak == null:
			text = n
		else:
			update()

func setup(playtak: PlaytakInterface):
	_playtak = playtak
	playtak.ratings_changed.connect(update)

func update():
	var name_text = _user
	var ratings = _playtak.ratings
	if ratings.has(_user):
		var entry = ratings[_user]
		_rating = entry.rating
		_is_bot = entry.is_bot
		name_text = Common.format_player(_user, entry)
	text = name_text
