class_name GameResult

const PlayerColor = BoardState.PlayerColor

enum State { ONGOING, WIN_WHITE, WIN_BLACK, DRAW }
enum Reason { DEFAULT, ROAD, FLATS }

var state := State.ONGOING
var reason := Reason.DEFAULT

func _init(state_: State = State.ONGOING, reason_: Reason = Reason.DEFAULT):
	state = state_
	reason = reason_

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

static func flats_win(color: PlayerColor) -> GameResult:
	return GameResult.new(State.WIN_WHITE + color, Reason.FLATS)

static func draw() -> GameResult:
	return GameResult.new(State.DRAW, Reason.FLATS)

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

func is_ongoing() -> bool:
	return state == State.ONGOING

func is_win() -> bool:
	return state == State.WIN_WHITE || state == State.WIN_BLACK

func winner() -> PlayerColor:
	return PlayerColor.WHITE if state == State.WIN_WHITE else PlayerColor.BLACK
