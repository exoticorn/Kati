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
	stdio.store_line("tei")

func _process(_delta):
	if state == State.ERROR:
		return
	var line = stdio.get_line()
	match stdio.get_error():
		OK:
			pass
		ERR_FILE_CANT_READ:
			return
		var err:
			printerr("Failed to read from engine pipe: %s" % err)
			state = State.ERROR
			return

	print(line)

	match Array(line.split(" ")):
		["teiok"]:
			if state == State.STARTING:
				stdio.store_line("setoption name HalfKomi value 4")
				stdio.store_line("teinewgame %d" % game_state.size)
			state = State.IDLE
			go()
		["bestmove", var move]:
			bestmove.emit(GameState.Move.from_ptn(move))

func go():
	if state != State.IDLE:
		printerr("Trying to search in wrong state %s" % state)
	var position = "position startpos moves"
	for mv in game_state.moves:
		position += " " + mv.to_tpn()
	stdio.store_line(position)
	stdio.store_line("go nodes 100")
