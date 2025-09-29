class_name EngineInterface extends Node

enum State {
	STARTING,
	IDLE,
	SEARCHING,
	ERROR
}

var pid: int
var stdio: FileAccess
var stderr: FileAccess
var state: State = State.STARTING

var log_lines = []

var game_state: GameState
var pending_go_cmd

signal engine_ready
signal bestmove(move: GameState.Move)

func _init(gs: GameState, path: String, parameters: String = ""):
	game_state = gs
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
	
	if state == State.ERROR:
		return
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

	match Array(line.split(" ")):
		["teiok"]:
			var is_starting := state == State.STARTING
			state = State.IDLE
			if is_starting:
				send("setoption name HalfKomi value %d" % roundi(game_state.komi * 2))
				send("teinewgame %d" % game_state.size)
				engine_ready.emit()
		["bestmove", var move]:
			state = State.IDLE
			bestmove.emit(GameState.Move.from_ptn(move))
			if pending_go_cmd != null:
				go_cmd(pending_go_cmd)

func go():
	go_cmd("go nodes 100")

func go_infinite():
	go_cmd("go infinite")

func go_cmd(cmd: String):
	if state == State.SEARCHING:
		send("stop")
		pending_go_cmd = cmd
		return
	elif state != State.IDLE:
		printerr("Trying to search in wrong state %s" % state)
	send_position()
	send("go infinite")
	pending_go_cmd = null
	state = State.SEARCHING	

func send_position():
	var position = "position startpos moves"
	for mv in game_state.moves:
		position += " " + mv.to_tpn()
	send(position)
	state = State.SEARCHING

func is_ready() -> bool:
	return state == State.IDLE

func send(line):
	stdio.store_line(line)
	log_line("< ", line)

func log_line(prefix, line):
	print(prefix, line)
	if log_lines.size() > 20:
		log_lines.pop_front()
	log_lines.push_back(prefix + line)
