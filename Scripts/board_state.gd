class_name BoardState

const Move = MoveList.Move

enum PlayerColor {
	WHITE,
	BLACK
}

enum PieceType {
	FLAT,
	WALL,
	CAP
}

class Piece:
	var color: PlayerColor
	var type: PieceType
	func _init(c: PlayerColor, t: PieceType):
		color = c
		type = t


var size: int
var flats_left: Array
var caps_left: Array
var board: Array # Array[Array[Array[Piece]]]
var half_move_count: int = 0
var last_move
var half_komi := 4

signal changed

func _init(rules: Common.GameRules):
	size = rules.size
	half_komi = rules.half_komi
	var f = rules.flats
	var c = rules.caps
	flats_left = [f, f]
	caps_left = [c, c]
	board = []
	for x in range(size):
		var col := []
		for y in range(size):
			col.push_back([])
		board.push_back(col)

func is_setup_turn() -> bool:
	return half_move_count < 2

func side_to_move() -> PlayerColor:
	return (half_move_count & 1) as PlayerColor

func color_to_place() -> PlayerColor:
	if is_setup_turn():
		return (1 - side_to_move()) as PlayerColor
	else:
		return side_to_move()

func apply_move(move: Move):
	var move_count := half_move_count / 2
	var color := half_move_count % 2
	if move_count == 0:
		color = 1 - color
	var square = move.square
	if move.count == 0:
		board[square.x][square.y].push_back(Piece.new(color, move.type))
		if move.type == PieceType.CAP:
			caps_left[color] -= 1
		else:
			flats_left[color] -= 1
	else:
		var stack: Array = board[move.square.x][move.square.y]
		var pieces: Array = stack.slice(-move.count)
		board[square.x][square.y] = stack.slice(0, -move.count)
		for drop_count in move.drops:
			square += Move.DIR_VEC[move.direction]
			stack = board[square.x][square.y]
			if !stack.is_empty():
				var top_piece: Piece = stack.back()
				if top_piece.type == PieceType.WALL:
					top_piece.type = PieceType.FLAT
					move.smash = true
			for i in drop_count:
				board[square.x][square.y].push_back(pieces.pop_front())
	last_move = move
	half_move_count += 1
	changed.emit()

func unapply_move(prev_move):
	var move = last_move
	last_move = prev_move
	half_move_count -= 1
	var move_count := half_move_count / 2
	var color := half_move_count % 2
	if move_count == 0:
		color = 1 - color
	var square = move.square
	if move.count == 0:
		board[square.x][square.y].clear()
		if move.type == PieceType.CAP:
			caps_left[color] += 1
		else:
			flats_left[color] += 1
	else:
		var pieces: Array[Piece] = []
		square += Move.DIR_VEC[move.direction] * move.drops.size()
		var drops = move.drops.duplicate()
		drops.reverse()
		for drop_count in drops:
			var stack = board[square.x][square.y]
			if pieces.is_empty() && move.smash:
				stack[-drop_count - 1].type = PieceType.WALL
			for i in drop_count:
				pieces.push_front(stack.pop_back())
			square -= Move.DIR_VEC[move.direction]
		board[square.x][square.y].append_array(pieces)
	changed.emit()

static func from_tps(tps: String, hk: int) -> BoardState:
	var parts = tps.split(" ")
	var rows = parts[0].split("/")
	var sze = rows.size()
	var game_state := BoardState.new(Common.GameRules.new(sze, hk))
	
	for y in rows.size():
		var x = 0
		for pile in rows[y].split(","):
			if pile[0] == "x":
				x += pile[1].to_int() if pile.length() > 1 else 1
			else:
				for i in pile.length():
					var color: PlayerColor
					match pile[i]:
						"1": color = PlayerColor.WHITE
						"2": color = PlayerColor.BLACK
						_: break
					var type = PieceType.FLAT
					if i == pile.length() - 2:
						match pile[i + 1]:
							"S": type = PieceType.WALL
							"C": type = PieceType.CAP
					game_state.board[x][sze - y - 1].push_back(Piece.new(color, type))
				x += 1
	
	return game_state

func game_result() -> GameResult:
	var color = 1 - side_to_move()
	var road = find_road(color)
	if road != null:
		return GameResult.road_win(color)
	
	road = find_road(1 - color)
	if road != null:
		return GameResult.road_win(1 - color)
	
	var has_empty_squares = false
	for row in board:
		for stack in row:
			if stack.is_empty():
				has_empty_squares = true
	
	if !has_empty_squares || (flats_left[color] == 0 && caps_left[color] == 0):
		var count = flat_count()
		var w = count[0] * 2
		var b = count[1] * 2 + half_komi
		if w > b:
			return GameResult.flats_win(PlayerColor.WHITE)
		elif b > w:
			return GameResult.flats_win(PlayerColor.BLACK)
		else:
			return GameResult.draw()
	return GameResult.new()

func flat_count() -> Array[int]:
	var count: Array[int] = [0, 0]
	for row in board:
		for stack in row:
			if !stack.is_empty() && stack.back().type == PieceType.FLAT:
				count[stack.back().color] += 1
	return count

func find_road(color: PlayerColor) -> Variant:
	var reachable = []
	for x in size:
		var row = []
		for y in size:
			row.push_back(0)
		reachable.push_back(row)
	var candidates = []
	for i in size:
		candidates.push_back([i, 0, 1])
		candidates.push_back([i, size-1, 2])
		candidates.push_back([0, i, 4])
		candidates.push_back([size-1, i, 8])
	while !candidates.is_empty():
		var c = candidates.pop_back()
		var x = c[0]
		var y = c[1]
		var mask = c[2]
		var stack = board[x][y]
		if stack.is_empty() || stack.back().color != color || stack.back().type == PieceType.WALL:
			continue
		var prev_mask = reachable[x][y]
		if prev_mask == mask:
			continue
		mask |= prev_mask
		reachable[x][y] = mask
		if x > 0: candidates.push_back([x - 1, y, mask])
		if x < size - 1: candidates.push_back([x + 1, y, mask])
		if y > 0: candidates.push_back([x, y - 1, mask])
		if y < size - 1: candidates.push_back([x, y + 1, mask])
	var road_squares = []
	for x in size:
		for y in size:
			var mask = reachable[x][y]
			if (mask & (mask >> 1) & 5) != 0:
				road_squares.push_back(Vector2i(x, y))

	if road_squares.is_empty():
		return null
	return road_squares
