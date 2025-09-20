class_name PlayTakInterface extends Node

enum State {
	OFFLINE,
	CONNECTING,
	LOGGING_IN,
	ONLINE
}

var ws_url = "ws://localhost:9999/ws"

var ws := WebSocketPeer.new()
var state := State.OFFLINE
var user_pw: String
var username: String

var last_ping: float = 0

enum ColorChoice { WHITE, BLACK, NONE}
enum GameType { RATED, UNRATED, TOURNAMENT }

class Seek:
	var id: int
	var user: String
	var size: int
	var time: int
	var inc: int
	var color: ColorChoice
	var komi: float
	var flat_count: int
	var capstone_count: int
	var game_type: GameType
	var extra_time_move: int
	var extra_time: int
	var bot: bool

class Game:
	var id
	var player_white: String
	var player_black: String
	var color: ColorChoice
	var size: int
	var time: int
	var inc: int
	var komi: float
	var flat_count: int
	var capstone_count: int
	var game_type: GameType
	var extra_time_move: int
	var extra_time: int
	var bot: bool

var seeks: Array[Seek] = []
var online_players: Array[String] = []

signal state_changed
signal seeks_changed
signal players_changed
signal game_started(game: Game)

func login(upw: String):
	user_pw = upw
	if state != State.OFFLINE:
		close_connection()
	ws.supported_protocols = PackedStringArray(["binary"])
	ws.connect_to_url(ws_url)
	state = State.CONNECTING

func accept_seek(id: int):
	send("Accept %d" % id)

func _process(_delta):
	if state == State.OFFLINE:
		return
	
	ws.poll()
	match ws.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			return
		WebSocketPeer.STATE_CLOSING:
			return
		WebSocketPeer.STATE_CLOSED:
			state = State.OFFLINE # TODO: reconnect when we were ONLINE
			state_changed.emit()
			return
	
	while ws.get_available_packet_count() > 0:
		var line = ws.get_packet().get_string_from_ascii().rstrip(" \n")
		
		print("> " + line)
		
		match Array(line.split(" ")):
			["Login", "or", "Register"] when state == State.CONNECTING:
				send("Client Kati")
				send("Protocol 2")
				send("Login " + user_pw)
				state = State.LOGGING_IN
			["Authentication", "failure"]:
				printerr("Failed to login to playtak server")
				close_connection()
			["Welcome", var uname]:
				username = uname.left(-1)
				state = State.ONLINE
				last_ping = Time.get_unix_time_from_system()
				print("Connected as " + username)
				state_changed.emit()
			["Seek", "new", var id, var user, var size, var time, var inc, var color, var half_komi, var flat_count, var capstone_count, var unrated, var tournament, var extra_time_move, var extra_time, var opp, var bot_seek]:
				if opp != "0" && opp.to_lower() != username.to_lower():
					return
				var seek := Seek.new()
				seek.id = id.to_int()
				seek.user = user
				seek.size = size.to_int()
				seek.time = time.to_int()
				seek.inc = inc.to_int()
				seek.color = ColorChoice.WHITE if color == "W" else ColorChoice.BLACK if color == "B" else ColorChoice.NONE
				seek.komi = half_komi.to_int() / 2.0
				seek.flat_count = flat_count.to_int()
				seek.capstone_count = capstone_count.to_int()
				seek.game_type = GameType.TOURNAMENT if tournament == "1" else GameType.UNRATED if unrated == "1" else GameType.RATED
				seek.extra_time_move = extra_time_move.to_int()
				seek.extra_time = extra_time.to_int()
				seek.bot = bot_seek == "1"
				seeks.push_back(seek)
				seeks_changed.emit()
			["Seek", "remove", var id, ..]:
				var int_id = id.to_int()
				var index = seeks.find_custom(func (s): return s.id == int_id)
				seeks.remove_at(index)
				seeks_changed.emit()
			["Game", "Start", var id, var player_white, "vs", var player_black, var color, var size, var time, var inc, var komi, var flat_count, var capstone_count, var unrated, var tournament, var extra_time_move, var extra_time, var is_bot]:
				var game := Game.new()
				game.id = id.to_int()
				game.player_white = player_white
				game.player_black = player_black
				game.color = ColorChoice.WHITE if color == "white" else ColorChoice.BLACK
				game.size = size.to_int()
				game.time = time.to_int()
				game.inc = inc.to_int()
				game.komi = komi.to_int() * 0.5
				game.flat_count = flat_count.to_int()
				game.capstone_count = capstone_count.to_int()
				game.game_type = GameType.TOURNAMENT if tournament == "1" else GameType.UNRATED if unrated == "1" else GameType.RATED
				game.extra_time_move = extra_time_move.to_int()
				game.extra_time = extra_time.to_int()
				game.bot = is_bot == "1"
				game_started.emit(game)
			["OnlinePlayers", ..]:
				online_players = []
				for player in line.right(-14).split(","):
					online_players.push_back(player.lstrip("[\" ").rstrip("]\"")) # advanced parsing!
				players_changed.emit()
	
	if state == State.ONLINE:
		var t = Time.get_unix_time_from_system()
		if t >= last_ping + 30:
			send("PING")
			last_ping = t

func send(line: String):
	print("< " + line)
	ws.send_text(line)

func close_connection():
	ws.close()
	while ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		await get_tree().create_timer(0.1).timeout
	state = State.OFFLINE
	state_changed.emit()
