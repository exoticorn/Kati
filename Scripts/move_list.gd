class_name MoveList

const PieceType = BoardState.PieceType

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT
}

class Move:
	var square: Vector2i
	var count: int
	var direction: Direction
	var drops: Array[int]
	var type: PieceType
	var smash: bool
	
	static func place(s: Vector2i, t: PieceType) -> Move:
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
	
	const DIR_VEC := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]

	func is_valid_next_square(s: Vector2i):
		if drops.size() == 0:
			return abs(square.x - s.x) + abs(square.y - s.y) == 1
		var v = DIR_VEC[direction]
		return s == square + v * drops.size() || s == square + v * (drops.size() + 1)
	
	func can_continue_on_square(board_state: BoardState, s: Vector2i) -> bool:
		if !is_valid_next_square(s):
			return false
		var stk = board_state.board[s.x][s.y]
		if !stk.is_empty():
			var top_piece = stk.back()
			if top_piece.type == PieceType.WALL:
				var drops_sum = 0
				for drop in drops:
					drops_sum += drop
				if drops_sum + 1 < count:
					return false
				return board_state.board[square.x][square.y].back().type == PieceType.CAP && drops_on(s) == 0
			if top_piece.type == PieceType.CAP:
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
	
	func is_same_move(o: Move) -> bool:
		return square == o.square && count == o.count && direction == o.direction && drops == o.drops && type == o.type && smash == o.smash
	
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
				PieceType.WALL:
					mv = "S"
				PieceType.CAP:
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
				PieceType.FLAT: return "F"
				PieceType.WALL: return "S"
				PieceType.CAP: return "C"
		var mv = str(count) if count > 1 else ""
		mv += DIR_TO_PTN[direction]
		if drops.size() > 1:
			for d in drops:
				mv += "%d" % d
		return mv

	static func from_ptn(move: String) -> Move:
		var tpe = PieceType.FLAT
		if move[0] == "S":
			tpe = PieceType.WALL
			move = move.right(-1)
		elif move[0] == "C":
			tpe = PieceType.CAP
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

var moves: Array[Move] = []
var display_move: int = 0
var display_board: BoardState

var _parent_moves
var parent_moves:
	set(ml):
		_parent_moves = ml
		ml.changed.connect(parent_changed)
var branch_move: int = 0
var is_diverging: bool = false

signal changed

func _init(rules: Common.GameRules):
	display_board = BoardState.new(rules)

func push_move(move: Move):
	moves.push_back(move)
	if display_move + 1 == moves.size():
		display_move += 1
		display_board.apply_move(move)
	changed.emit()
	update_branch()

func pop_move(board: BoardState = null):
	var prev_move = moves[-2] if moves.size() > 1 else null
	if board != null:
		board.unapply_move(prev_move)
	if display_move == moves.size():
		display_board.unapply_move(prev_move)
		display_move -= 1
	moves.pop_back()
	changed.emit()
	update_branch()

func step_move(by: int):
	var old = display_move
	var truncate = false
	if by == 0 && _parent_moves != null:
		by = branch_move - 1 - display_move
		truncate = true
	while by > 0 && display_move < moves.size():
		display_board.apply_move(moves[display_move])
		display_move += 1
		by -= 1
	while by < 0 && display_move > 0:
		display_move -= 1
		var prev_move = moves[display_move - 1] if display_move > 0 else null
		display_board.unapply_move(prev_move)
		by += 1
	if truncate:
		truncate_moves()
		update_branch()
	if display_move != old:
		changed.emit()

func truncate_moves():
	if moves.size() > display_move:
		moves = moves.slice(0, display_move)


func update_branch():
	if _parent_moves == null:
		branch_move = moves.size() + 1
		changed.emit()
		return
	var old_branch_move = branch_move
	var was_diverging = is_diverging
	var is_changed = false
	branch_move = 0
	while branch_move < moves.size() && branch_move < _parent_moves.moves.size() && moves[branch_move].is_same_move(_parent_moves.moves[branch_move]):
		branch_move += 1
	if branch_move == moves.size():
		while branch_move < _parent_moves.moves.size():
			moves.push_back(_parent_moves.moves[branch_move])
			is_changed = true
			branch_move += 1
	is_diverging = branch_move < moves.size() && branch_move < _parent_moves.moves.size()
	branch_move += 1
	if is_changed || old_branch_move != branch_move || was_diverging != is_diverging:
		changed.emit()


func parent_changed():
	var was_diverging = is_diverging
	var prev_branch_move = branch_move
	update_branch()
	if !was_diverging && branch_move < prev_branch_move:
		# undo
		step_move(0)
	if !is_diverging:
		if display_move + 1 >= prev_branch_move && display_move < branch_move:
			step_move(branch_move - display_move)
