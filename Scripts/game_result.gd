class_name GameResult

const PlayerColor = BoardState.PlayerColor

enum State { ONGOING, WIN_WHITE, WIN_BLACK, DRAW }
enum Reason { DEFAULT, ROAD, FLATS }

var state := State.ONGOING
var reason := Reason.DEFAULT
var flat_count: Array[int] = [0, 0]
var half_komi := 0

func _init(state_: State = State.ONGOING, reason_: Reason = Reason.DEFAULT, flat_count_: Array[int] = [0, 0], half_komi_ = 0):
	state = state_
	reason = reason_
	flat_count = flat_count_
	half_komi = half_komi_

static func parse(string: String) -> GameResult:
	match string:
		"R-0": return GameResult.new(State.WIN_WHITE, Reason.ROAD)
		"0-R": return GameResult.new(State.WIN_BLACK, Reason.ROAD)
		"F-0": return GameResult.new(State.WIN_WHITE, Reason.FLATS)
		"0-F": return GameResult.new(State.WIN_BLACK, Reason.FLATS)
		"1-0": return GameResult.new(State.WIN_WHITE, Reason.DEFAULT)
		"0-1": return GameResult.new(State.WIN_BLACK, Reason.DEFAULT)
		"1/2-1/2": return GameResult.new(State.DRAW, Reason.FLATS)
	return GameResult.new(State.ONGOING, Reason.DEFAULT)

static func road_win(color: PlayerColor) -> GameResult:
	return GameResult.new(State.WIN_WHITE + color, Reason.ROAD)

static func flats_win(color: PlayerColor, flats: Array[int], half_komi_: int) -> GameResult:
	return GameResult.new(State.WIN_WHITE + color, Reason.FLATS, flats, half_komi_)

static func draw() -> GameResult:
	return GameResult.new(State.DRAW, Reason.FLATS)

func set_flat_count(flat_count_: Array[int], half_komi_: int):
	flat_count = flat_count_
	half_komi = half_komi_

func to_str() -> String:
	match state:
		State.WIN_WHITE:
			match reason:
				Reason.DEFAULT: return "1-0"
				Reason.ROAD: return "R-0"
				Reason.FLATS: return "F-0"
		State.WIN_BLACK:
			match reason:
				Reason.DEFAULT: return "0-1"
				Reason.ROAD: return "0-R"
				Reason.FLATS: return "0-F"
		State.DRAW:
			return "½-½"
	return "0-0"

func to_long_str() -> String:
	var flats_str: String
	if half_komi > 0:
		flats_str = "\n%d - %d+%s flats" % [flat_count[0], flat_count[1], Common.format_komi(half_komi)]
	else:
		flats_str = "\n%d - %d flats" % [flat_count[0], flat_count[1]]
	if is_win():
		var reason_str = ""
		match reason:
			Reason.DEFAULT:
				reason_str = "default."
			Reason.ROAD:
				reason_str = "road."
			Reason.FLATS:
				reason_str = "flat count." + flats_str
		var color = "White" if state == State.WIN_WHITE else "Black"
		return "%s wins by %s" % [color, reason_str]
	elif state == State.DRAW:
		return "Game is drawn." + flats_str
	else:
		return "No result"

func is_ongoing() -> bool:
	return state == State.ONGOING

func is_win() -> bool:
	return state == State.WIN_WHITE || state == State.WIN_BLACK

func is_flat_win() -> bool:
	return is_win() && reason == Reason.FLATS

func winner() -> PlayerColor:
	return PlayerColor.WHITE if state == State.WIN_WHITE else PlayerColor.BLACK
