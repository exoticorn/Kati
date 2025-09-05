class_name GameState

var size: int
var flats_left: Array
var caps_left: Array

enum Col {
	WHITE = 0,
	BLACK = 1
}

enum Type {
	FLAT = 0,
	WALL = 1,
	CAP = 2
}

class Piece:
	var color: Col
	var type: Type
	func _init(color: Col, type: Type):
		self.color = color
		self.type = type

var board: Array

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

	board[1][1].push_back(Piece.new(Col.WHITE, Type.FLAT))
	board[2][3].push_back(Piece.new(Col.WHITE, Type.FLAT))
	board[2][3].push_back(Piece.new(Col.BLACK, Type.FLAT))
