class_name EngineInterface extends Node

enum State {
	STARTING,
	IDLE,
	SEARCHING,
	ERROR
}

var pid: int
var stdio: FileAccess
var state: State = State.STARTING

var game_state: GameState

signal engine_ready
signal bestmove(move: GameState.Move)

func _init(gs: GameState):
	game_state = gs
	var args = ["--cobblebot"]
	var result = OS.execute_with_pipe("tmp/tiltak", PackedStringArray(args), false)
	if result.is_empty():
		printerr("Failed to start engine exe")
		state = State.ERROR
		return
	pid = result["pid"]
	stdio = result["stdio"]
	send("tei")

func _process(_delta):
	if state == State.ERROR:
		return
	var line = stdio.get_line()
	match stdio.get_error():
		OK:
			pass
		ERR_FILE_CANT_READ:
			if !OS.is_process_running(pid):
				printerr("Engine died")
				state = State.ERROR
			return
		var err:
			printerr("Failed to read from engine pipe: %s" % err)
			state = State.ERROR
			return

	match Array(line.split(" ")):
		["teiok"]:
			if state == State.STARTING:
				send("setoption name HalfKomi value 4")
				send("teinewgame %d" % game_state.size)
				engine_ready.emit()
			state = State.IDLE
		["bestmove", var move]:
			bestmove.emit(GameState.Move.from_ptn(move))

func go():
	if state != State.IDLE:
		printerr("Trying to search in wrong state %s" % state)
	var position = "position startpos moves"
	for mv in game_state.moves:
		position += " " + mv.to_tpn()
	send(position)
	send("go nodes 100")

func send(line):
	stdio.store_line(line)
