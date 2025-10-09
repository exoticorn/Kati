class_name EngineInterface extends Node

const Move = MoveList.Move

enum State {
	STARTING,
	IDLE,
	SEARCHING,
	ERROR
}

class MoveInfo:
	var pv_index: int
	var move: Move
	var depth: int
	var seldepth: int
	var visits: int
	var pv: Array[Move]
	var score: float
	var score_is_winrate: bool

class Position:
	var size: int
	var half_komi: int
	var moves: Array[Move]
	
	func _init(s: int, hk: int, mvs: Array[Move] = []):
		size = s
		half_komi = hk
		moves = mvs

var pid: int
var stdio: FileAccess
var stderr: FileAccess
var state: State = State.STARTING

var log_lines = []

var position: Position
var search_selected_move := false
var pending_go_cmd
var move_count := 0
var options := {}
var max_multipv = 0

signal engine_ready
signal bestmove(move: Move)
signal info(info: MoveInfo)

func _init(pos: Position, path: String, parameters: String = ""):
	position = pos
	var args := parameters.split(" ")
	var result = OS.execute_with_pipe(path, args, false)
	if result.is_empty():
		printerr("Failed to start engine exe")
		state = State.ERROR
		return
	pid = result["pid"]
	stdio = result["stdio"]
	stderr = result.stderr
	send("tei")

func _process(_delta):
	var line = stderr.get_line()
	if stderr.get_error() == OK:
		log_line("E> ", line)
	
	while state != State.ERROR:
		line = stdio.get_line()
		match stdio.get_error():
			OK:
				pass
			ERR_FILE_CANT_READ:
				if !OS.is_process_running(pid):
					printerr("Engine died, log:")
					for l in log_lines:
						printerr(l)
					state = State.ERROR
				return
			var err:
				printerr("Failed to read from engine pipe: %s" % err)
				state = State.ERROR
				return
		
		log_line("> ", line)

		var parts = line.split(" ")
		match Array(parts):
			["teiok"]:
				var is_starting := state == State.STARTING
				state = State.IDLE
				if is_starting:
					if options.has("HalfKomi"):
						send("setoption name HalfKomi value %d" % position.half_komi)
					if max_multipv > 1 && options.has("MultiPV"):
						var pvs = min(max_multipv, options.MultiPV.max) if options.MultiPV.has("max") else max_multipv
						send("setoption name MultiPV value %d" % pvs)
					send("teinewgame %d" % position.size)
					engine_ready.emit()
			["bestmove", var move]:
				state = State.IDLE
				bestmove.emit(Move.from_ptn(move))
				if pending_go_cmd != null:
					go_cmd(position, pending_go_cmd)
			["option", "name", var name_, "type", var type, ..]:
				var data := { "type": type }
				var index = 3
				while index + 1 < parts.size():
					var field = parts[index]
					var value = parts[index + 1]
					index += 2
					match field:
						"min", "max":
							value = value.to_int()
						"default" when type == "spin":
							value = value.to_int()
						"var":
							var vars = data.var if data.has("var") else []
							vars.push_back(value)
							value = vars
					data[field] = value
				options[name_] = data
			["info", ..]:
				if pending_go_cmd == null:
					var data := {}
					var index = 1
					while index < parts.size():
						var field = parts[index]
						index += 1
						match field:
							"depth":
								data.depth = parts[index].to_int()
								index += 1
							"seldepth":
								data.seldepth = parts[index].to_int()
								index += 1
							"nodes":
								data.nodes = parts[index].to_int()
								index += 1
							"visits":
								data.visits = parts[index].to_int()
								index += 1
							"cp":
								data.cp = parts[index].to_int() / 100.0
								index += 1
							"wdl":
								data.winrate = parts[index].to_int() / 1000.0
								index += 1
							"multipv":
								data.multipv = parts[index].to_int()
								index += 1
							"pv":
								data.pv = parts.slice(index)
								index = parts.size()
					if data.has("depth") && (data.has("cp") || data.has("winrate")) && data.has("pv") && !data.pv.is_empty():
						var move_info = MoveInfo.new()
						move_info.pv_index = data.multipv - 1 if data.has("multipv") else 0
						move_info.depth = data.depth
						move_info.seldepth = data.seldepth if data.has("seldepth") else data.depth
						move_info.visits = data.visits if data.has("visits") else data.nodes if data.has("nodes") else 1
						var white_to_move = (move_count & 1) == 0
						if data.has("winrate"):
							move_info.score = data.winrate if white_to_move else 1.0 - data.winrate
						else:
							move_info.score = data.cp if white_to_move else -data.cp
						move_info.score_is_winrate = data.has("winrate")
						var pv: Array[Move] = []
						for move in data.pv:
							pv.push_back(Move.from_ptn(move))
						move_info.move = pv[0]
						move_info.pv = pv
						info.emit(move_info)

func go(pos: Position):
	go_cmd(pos, "go nodes 100")

func go_infinite(pos: Position):
	go_cmd(pos, "go infinite")

func go_cmd(pos: Position, cmd: String):
	position = pos
	if state == State.SEARCHING:
		send("stop")
		pending_go_cmd = cmd
		return
	elif state != State.IDLE:
		printerr("Trying to search in wrong state %s" % state)
	send_position()
	send(cmd)
	pending_go_cmd = null
	state = State.SEARCHING	

func send_position():
	var pos_str = "position startpos moves"
	var moves = position.moves
	move_count = moves.size()
	for mv in moves:
		pos_str += " " + mv.to_ptn()
	send(pos_str)
	state = State.SEARCHING

func is_ready() -> bool:
	return state == State.IDLE

func send(line):
	stdio.store_line(line)
	log_line("< ", line)

func log_line(prefix, line):
	if log_lines.size() > 20:
		log_lines.pop_front()
	log_lines.push_back(prefix + line)
