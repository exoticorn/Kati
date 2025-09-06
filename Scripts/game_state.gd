class_name GameState

enum Col {
	WHITE,
	BLACK
}

enum Type {
	FLAT,
	WALL,
	CAP
}

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT
}

class Piece:
	var color: Col
	var type: Type
	func _init(color: Col, type: Type):
		self.color = color
		self.type = type

class Move:
	var square: Vector2i
	var count: int
	var direction: Direction
	var drops: Array[int]
	var type: Type
	
	static func place(square: Vector2i, type: Type) -> Move:
		var move := Move.new()
		move.square = square
		move.type = type
		move.count = 0
		return move
	
	static func stack(square: Vector2i, count: int, direction: Direction, drops: Array[int]) -> Move:
		var move := Move.new()
		move.square = square
		move.count = count
		move.direction = direction
		move.drops = drops
		return move

var size: int
var flats_left: Array
var caps_left: Array
var board: Array # Array[Array[Array[Piece]]]

func _init(size: int, flats: int, caps: int):
	self.size = size
	self.flats_left = [flats, flats]
	self.caps_left = [caps, caps]
	board = []
	for x in range(size):
		var col := []
		for y in range(size):
			col.push_back([])
		board.push_back(col)

#	board[1][1].push_back(Piece.new(Col.WHITE, Type.FLAT))
#	board[2][3].push_back(Piece.new(Col.WHITE, Type.FLAT))
#	board[2][3].push_back(Piece.new(Col.BLACK, Type.FLAT))
#	board[2][2].push_back(Piece.new(Col.BLACK, Type.CAP))
#	board[4][3].push_back(Piece.new(Col.WHITE, Type.WALL))
#	board[1][1].push_back(Piece.new(Col.BLACK, Type.WALL))

static func from_tps(tps: String, flats: int, caps: int) -> GameState:
	var parts = tps.split(" ")
	var rows = parts[0].split("/")
	var size = rows.size()
	var game_state := GameState.new(size, flats, caps)
	
	for y in rows.size():
		var x = 0
		for pile in rows[y].split(","):
			if pile[0] == "x":
				x += pile[1].to_int() if pile.length() > 1 else 1
			else:
				for i in pile.length():
					var color: Col
					match pile[i]:
						"1": color = Col.WHITE
						"2": color = Col.BLACK
						_: break
					var type = Type.FLAT
					if i == pile.length() - 2:
						match pile[i + 1]:
							"S": type = Type.WALL
							"C": type = Type.CAP
					game_state.board[x][size - y - 1].push_back(Piece.new(color, type))
				x += 1
	
	return game_state
	
