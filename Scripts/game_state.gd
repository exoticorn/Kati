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

const DIR_VEC := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]

class Piece:
	var color: Col
	var type: Type
	func _init(c: Col, t: Type):
		color = c
		type = t

class Move:
	var square: Vector2i
	var count: int
	var direction: Direction
	var drops: Array[int]
	var type: Type
	var smash: bool
	
	static func place(s: Vector2i, t: Type) -> Move:
		var move := Move.new()
		move.square = s
		move.type = t
		move.count = 0
		return move
	
	static func stack(s: Vector2i, c: int, dir: Direction, drps: Array[int]) -> Move:
		var move := Move.new()
		move.square = s
		move.count = c
		move.direction = dir
		move.drops = drps
		return move
	
	static func pending_stack(s: Vector2i, c: int) -> Move:
		var move := Move.new()
		move.square = s
		move.count = c
		move.drops = []
		return move
	
	func is_valid_next_square(s: Vector2i):
		if drops.size() == 0:
			return abs(square.x - s.x) + abs(square.y - s.y) == 1
		var v = DIR_VEC[direction]
		return s == square + v * drops.size() || s == square + v * (drops.size() + 1)
	
	func can_continue_on_square(game_state: GameState, s: Vector2i) -> bool:
		if !is_valid_next_square(s):
			return false
		var stk = game_state.board[s.x][s.y]
		if !stk.is_empty():
			var top_piece = stk.back()
			if top_piece.type == GameState.Type.WALL:
				var drops_sum = 0
				for drop in drops:
					drops_sum += drop
				if drops_sum + 1 < count:
					return false
				return game_state.board[square.x][square.y].back().type == Type.CAP && drops_on(s) == 0
			if top_piece.type == GameState.Type.CAP:
				return false
		return true
	
	func add_drop(s: Vector2i):
		if drops.size() == 0:
			drops.push_back(1)
			for i in 4:
				if s == square + DIR_VEC[i]:
					direction = i as Direction
		else:
			var d = abs(square.x - s.x) + abs(square.y - s.y)
			if d == drops.size():
				drops[-1] += 1
			else:
				drops.push_back(1)
		
	func drops_on(s: Vector2i) -> int:
		if is_valid_next_square(s):
			var d = abs(square.x - s.x) + abs(square.y - s.y)
			if d <= drops.size():
				return drops[d-1]
		return 0
	
	const PTN_TO_DIR = {
		">": Direction.RIGHT,
		"-": Direction.DOWN,
		"<": Direction.LEFT,
		"+": Direction.UP
	}
	
	const DIR_TO_PTN = {
		Direction.RIGHT: ">",
		Direction.DOWN: "-",
		Direction.LEFT: "<",
		Direction.UP: "+"
	}
	
	func to_ptn() -> String:
		var sqr = square_to_str(square)
		var mv = ""
		if count == 0:
			match type:
				Type.WALL:
					mv = "S"
				Type.CAP:
					mv = "C"
			return mv + sqr
		if count > 1:
			mv = str(count)
		mv += sqr
		mv += DIR_TO_PTN[direction]
		if drops.size() > 1:
			for d in drops:
				mv += "%d" % d
		return mv

	func to_short_ptn() -> String:
		if count == 0:
			match type:
				Type.FLAT: return "F"
				Type.WALL: return "S"
				Type.CAP: return "C"
		var mv = str(count) if count > 1 else ""
		mv += DIR_TO_PTN[direction]
		if drops.size() > 1:
			for d in drops:
				mv += "%d" % d
		return mv

	static func from_ptn(move: String) -> Move:
		var tpe = Type.FLAT
		if move[0] == "S":
			tpe = Type.WALL
			move = move.right(-1)
		elif move[0] == "C":
			tpe = Type.CAP
			move = move.right(-1)
		var cnt = 0
		if move[0] >= "1" and move[0] < "9":
			cnt = move[0].to_int()
			move = move.right(-1)
		var squ = square_from_str(move.left(2))
		move = move.right(-2)
		if move.is_empty():
			return Move.place(squ, tpe)
		if cnt == 0:
			cnt = 1
		var dir = PTN_TO_DIR[move[0]]
		var dps: Array[int] = []
		for c in move.right(-1):
			dps.push_back(c.to_int())
		if dps.is_empty():
			dps = [cnt]
		return Move.stack(squ, cnt, dir, dps)
		
	static func square_to_str(sq: Vector2i) -> String:
		return String.chr(sq.x + 97) + String.chr(sq.y + 49)
	
	static func square_from_str(sqr: String) -> Vector2i:
		var lsqr = sqr.to_lower()
		var x = lsqr.unicode_at(0) - 97
		var y = lsqr.unicode_at(1) - 49
		return Vector2i(x, y)
	
	func highlight_squares() -> Dictionary:
		if count == 0:
			return { square: 1 }
		var squares = { square: 0 }
		var sq = square
		for cnt in drops:
			sq += DIR_VEC[direction]
			squares[sq] = cnt
		return squares

enum Result {
	ONGOING,
	WHITE_ROAD,
	BLACK_ROAD,
	WHITE_FLATS,
	BLACK_FLATS,
	DRAW
}

var size: int
var flats_left: Array
var caps_left: Array
var board: Array # Array[Array[Array[Piece]]]
var moves: Array[Move] = []
var result := Result.ONGOING
var komi := 2.0
var selected_move := -1

signal changed

const StoneCounts = {
	4: [15, 0],
	5: [21, 1],
	6: [30, 1],
	7: [40, 2],
	8: [50, 2]
}

func _init(s: int, k: float):
	size = s
	komi = k
	var f = StoneCounts[s][0]
	var c = StoneCounts[s][1]
	flats_left = [f, f]
	caps_left = [c, c]
	board = []
	for x in range(size):
		var col := []
		for y in range(size):
			col.push_back([])
		board.push_back(col)

func is_setup_turn() -> bool:
	return selected_move < 1

func side_to_move() -> Col:
	return ((selected_move + 1) & 1) as Col

func side_to_move_at_latest_move() -> Col:
	return (moves.size() & 1) as Col

func color_to_place() -> Col:
	if is_setup_turn():
		return (1 - side_to_move()) as Col
	else:
		return side_to_move()

func is_at_latest_move() -> bool:
	return selected_move + 1 == moves.size()

func truncate_moves():
	if !is_at_latest_move():
		moves = moves.slice(0, selected_move + 1)
		result = Result.ONGOING

func push_move(move: Move):
	moves.push_back(move)
	if selected_move + 2 == moves.size():
		selected_move += 1
		apply_move(selected_move)
	changed.emit()

func pop_move():
	if selected_move + 1 == moves.size():
		unapply_move(selected_move)
		selected_move -= 1
	moves.pop_back()
	changed.emit()

func step_move(by: int):
	var prev = selected_move
	while by > 0 && selected_move + 1 < moves.size():
		selected_move += 1
		apply_move(selected_move)
		by -= 1
	while by < 0 && selected_move >= 0:
		unapply_move(selected_move)
		selected_move -= 1
		by += 1
	if selected_move != prev:
		changed.emit()

func apply_move(move_index: int):
	var move := moves[move_index]
	var move_count := move_index / 2
	var color := move_index % 2
	if move_count == 0:
		color = 1 - color
	var square = move.square
	if move.count == 0:
		board[square.x][square.y].push_back(Piece.new(color, move.type))
		if move.type == Type.CAP:
			caps_left[color] -= 1
		else:
			flats_left[color] -= 1
	else:
		var stack: Array = board[move.square.x][move.square.y]
		var pieces: Array = stack.slice(-move.count)
		board[square.x][square.y] = stack.slice(0, -move.count)
		for drop_count in move.drops:
			square += DIR_VEC[move.direction]
			stack = board[square.x][square.y]
			if !stack.is_empty():
				var top_piece: Piece = stack.back()
				if top_piece.type == Type.WALL:
					top_piece.type = Type.FLAT
					move.smash = true
			for i in drop_count:
				board[square.x][square.y].push_back(pieces.pop_front())
	check_game_end(color)

func unapply_move(move_index: int):
	var move = moves[move_index]
	var move_count := move_index / 2
	var color := move_index % 2
	if move_count == 0:
		color = 1 - color
	var square = move.square
	if move.count == 0:
		board[square.x][square.y].clear()
		if move.type == Type.CAP:
			caps_left[color] += 1
		else:
			flats_left[color] += 1
	else:
		var pieces: Array[Piece] = []
		square += DIR_VEC[move.direction] * move.drops.size()
		var drops = move.drops.duplicate()
		drops.reverse()
		for drop_count in drops:
			var stack = board[square.x][square.y]
			if pieces.is_empty() && move.smash:
				stack[-drop_count - 1].type = Type.WALL
			for i in drop_count:
				pieces.push_front(stack.pop_back())
			square -= DIR_VEC[move.direction]
		board[square.x][square.y].append_array(pieces)

static func from_tps(tps: String, k: float) -> GameState:
	var parts = tps.split(" ")
	var rows = parts[0].split("/")
	var sze = rows.size()
	var game_state := GameState.new(sze, k)
	
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
					game_state.board[x][sze - y - 1].push_back(Piece.new(color, type))
				x += 1
	
	return game_state

func check_game_end(color: Col):
	var road = find_road(color)
	if road != null:
		result = (Result.WHITE_ROAD + color) as Result
		return
	
	road = find_road(1 - color)
	if road != null:
		result = (Result.BLACK_ROAD - color) as Result
		return
	
	var has_empty_squares = false
	for row in board:
		for stack in row:
			if stack.is_empty():
				has_empty_squares = true
	
	if !has_empty_squares || (flats_left[color] == 0 && caps_left[color] == 0):
		var count = flat_count()
		var w = count[0]
		var b = count[1] + komi
		if w > b:
			result = Result.WHITE_FLATS
		elif b > w:
			result = Result.BLACK_FLATS
		else:
			result = Result.DRAW

func flat_count() -> Array[int]:
	var count: Array[int] = [0, 0]
	for row in board:
		for stack in row:
			if !stack.is_empty() && stack.back().type == Type.FLAT:
				count[stack.back().color] += 1
	return count

func find_road(color: Col) -> Variant:
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
		if stack.is_empty() || stack.back().color != color || stack.back().type == Type.WALL:
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
