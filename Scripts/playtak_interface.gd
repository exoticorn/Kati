class_name PlaytakInterface extends Node

const Login = preload("res://Scripts/login.gd")

enum State {
	OFFLINE,
	CONNECTING,
	LOGGING_IN,
	ONLINE,
	DISCONNECTED
}

#var ws_url = "ws://localhost:9999/ws"
var ws_url = "wss://playtak.com/ws"

var ws := WebSocketPeer.new()
var state := State.OFFLINE
var user_pw: String
var username: String
var was_online := false
var reconnect_timer := 0.0

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
var game_list: Array[Game] = []

signal state_changed
signal seeks_changed
signal players_changed
signal game_list_changed
signal game_started(game: Game)
signal game_move(id: int, move: GameState.Move)
signal update_clock(id: int, wtime: float, btime: float)

func login(lgn: Login):
	user_pw = "%s %s" % [lgn.user, lgn.password]
	if state != State.OFFLINE:
		close_connection()
	ws.supported_protocols = PackedStringArray(["binary"])
	ws.heartbeat_interval = 5.0
	ws.connect_to_url(ws_url)
	state = State.CONNECTING

func accept_seek(id: int):
	send("Accept %d" % id)

func observe(id: int):
	send("Observe %d" % id)

func send_move(game_id:int, move: GameState.Move):
	var move_string = "Game#%d " % game_id

	if move.count == 0:
		move_string += "P %s" % GameState.Move.square_to_str(move.square).to_upper()
		if move.type == GameState.Type.WALL:
			move_string += " W"
		elif move.type == GameState.Type.CAP:
			move_string += " C"
	else:
		move_string += "M %s %s" % [GameState.Move.square_to_str(move.square).to_upper(), GameState.Move.square_to_str(move.square + GameState.DIR_VEC[move.direction] * move.drops.size()).to_upper()]
		for drop in move.drops:
			move_string += " %d" % drop
		
	send(move_string)

func _process(delta):
	if state == State.DISCONNECTED:
		reconnect_timer -= delta
		if reconnect_timer <= 0:
			reconnect()
		else:
			return
	
	if state == State.OFFLINE:
		return
	
	ws.poll()
	match ws.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			return
		WebSocketPeer.STATE_CLOSING:
			return
		WebSocketPeer.STATE_CLOSED:
			state = State.DISCONNECTED if was_online else State.OFFLINE
			reconnect_timer = 10.0
			state_changed.emit()
			return
	
	while ws.get_available_packet_count() > 0:
		var line = ws.get_packet().get_string_from_ascii().rstrip(" \n")
		
		print("> " + line)
		
		if line.begins_with("Game#"):
			var parts = line.right(-5).split(" ")
			var id = parts[0].to_int()
			match Array(parts.slice(1)):
				["P", var square, ..]:
					var sqr = GameState.Move.square_from_str(square)
					var type = GameState.Type.FLAT
					if parts.size() > 3:
						type = GameState.Type.WALL if parts[3] == "W" else GameState.Type.CAP
					game_move.emit(id, GameState.Move.place(sqr, type))
				["M", var from, var to, ..]:
					var sqr = GameState.Move.square_from_str(from)
					var diff = GameState.Move.square_from_str(to) - sqr
					var dir = GameState.Direction.LEFT if diff.x < 0 else GameState.Direction.RIGHT if diff.x > 0 else GameState.Direction.DOWN if diff.y < 0 else GameState.Direction.UP
					var drops: Array[int] = []
					var count = 0
					for d in parts.slice(4):
						var drop = d.to_int()
						drops.push_back(drop)
						count += drop
					game_move.emit(id, GameState.Move.stack(sqr, count, dir, drops))
				["Timems", var wtime, var btime]:
					update_clock.emit(id, wtime.to_int() / 1000.0, btime.to_int() / 1000.0)
		else:
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
					was_online = true
					last_ping = Time.get_unix_time_from_system()
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
				["GameList", "Add", var id, var player_white, var player_black, var size, var time, var inc, var komi, var flat_count, var capstone_count, var unrated, var tournament, var extra_time_move, var extra_time]:
					var game := Game.new()
					game.id = id.to_int()
					game.player_white = player_white
					game.player_black = player_black
					game.color = ColorChoice.NONE
					game.size = size.to_int()
					game.time = time.to_int()
					game.inc = inc.to_int()
					game.komi = komi.to_int() * 0.5
					game.flat_count = flat_count.to_int()
					game.capstone_count = capstone_count.to_int()
					game.game_type = GameType.TOURNAMENT if tournament == "1" else GameType.UNRATED if unrated == "1" else GameType.RATED
					game.extra_time_move = extra_time_move.to_int()
					game.extra_time = extra_time.to_int()
					game.bot = false
					game_list.push_back(game)
					game_list_changed.emit()
				["GameList", "Remove", var id, ..]:
					var int_id = id.to_int()
					var index = game_list.find_custom(func (g): return g.id == int_id)
					if index >= 0:
						game_list.remove_at(index)
						game_list_changed.emit()
				["Observe", var id, var player_white, var player_black, var size, var time, var inc, var komi, var flat_count, var capstone_count, var unrated, var tournament, var extra_time_move, var extra_time]:
					var game := Game.new()
					game.id = id.to_int()
					game.player_white = player_white
					game.player_black = player_black
					game.color = ColorChoice.NONE
					game.size = size.to_int()
					game.time = time.to_int()
					game.inc = inc.to_int()
					game.komi = komi.to_int() * 0.5
					game.flat_count = flat_count.to_int()
					game.capstone_count = capstone_count.to_int()
					game.game_type = GameType.TOURNAMENT if tournament == "1" else GameType.UNRATED if unrated == "1" else GameType.RATED
					game.extra_time_move = extra_time_move.to_int()
					game.extra_time = extra_time.to_int()
					game.bot = false
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
	was_online = false
	state = State.OFFLINE
	state_changed.emit()

func reconnect():
	if state != State.DISCONNECTED:
		return
	ws.connect_to_url(ws_url)
	state = State.CONNECTING
