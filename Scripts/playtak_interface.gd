class_name PlaytakInterface extends Node

const Move = MoveList.Move
const PieceType = BoardState.PieceType

const Login = preload("res://Scripts/login.gd")
const ChatWindow = preload("res://Scripts/chat_window.gd")
const GameAction = preload("res://Scripts/game_actions.gd").Action

enum State {
	OFFLINE,
	CONNECTING,
	LOGGING_IN,
	ONLINE,
	DISCONNECTED
}

const RATING_URL = "https://api.playtak.com/v1/ratings/"

#const ws_url = "ws://localhost:9999/ws"
#const ws_url = "ws://localhost:3003"
const ws_url = "wss://playtak.com/ws"
const ENABLE_LOGGING = false

var ws := WebSocketPeer.new()
var http := HTTPRequest.new()
var state := State.OFFLINE
var _login: Login
var username: String
var was_online := false
var reconnect_timer := 0.0

var last_ping: float = 0

enum ColorChoice { WHITE, BLACK, NONE}
enum GameType { RATED, UNRATED, TOURNAMENT }

class Seek:
	var id: int
	var user: String
	var rules: Common.GameRules
	var clock: Common.ClockSettings
	var color: ColorChoice
	var game_type: GameType
	var bot: bool

class Game:
	var id
	var player_white: String
	var player_black: String
	var color: ColorChoice
	var rules: Common.GameRules
	var clock: Common.ClockSettings
	var game_type: GameType
	var bot: bool

var seeks: Array[Seek] = []
var online_players: Array[String] = []
var game_list: Array[Game] = []
var ratings = {}
var pending_ratings: Array[String] = []

signal state_changed
signal seeks_changed
signal players_changed
signal game_list_changed
signal game_started(game: Game)
signal game_move(id: int, move: Move)
signal game_undo(id: int)
signal game_result(id: int, result: GameResult)
signal game_action(id: int, action: GameAction)
signal update_clock(id: int, wtime: float, btime: float)
signal add_chat_room(type: ChatWindow.Type, room: String)
signal chat_message(type: ChatWindow.Type, room: String, user: String, message: String)
signal ratings_changed()

func _ready():
	add_child(http)

func login(lgn: Login):
	_login = lgn
	if state != State.OFFLINE:
		close_connection()
	ws.supported_protocols = PackedStringArray(["binary"])
	ws.heartbeat_interval = 5.0
	ws.connect_to_url(ws_url)
	state = State.CONNECTING
	state_changed.emit()

func accept_seek(id: int):
	send("Accept %d" % id)

func observe(id: int):
	send("Observe %d" % id)

func send_move(game_id: int, move: Move):
	var move_string = "Game#%d " % game_id

	if move.count == 0:
		move_string += "P %s" % Move.square_to_str(move.square).to_upper()
		if move.type == PieceType.WALL:
			move_string += " W"
		elif move.type == PieceType.CAP:
			move_string += " C"
	else:
		move_string += "M %s %s" % [Move.square_to_str(move.square).to_upper(), Move.square_to_str(move.square + Move.DIR_VEC[move.direction] * move.drops.size()).to_upper()]
		for drop in move.drops:
			move_string += " %d" % drop
		
	send(move_string)

func send_game_action(game_id: int, action: GameAction):
	match action:
		GameAction.REQUEST_UNDO: send("Game#%d RequestUndo" % game_id)
		GameAction.REMOVE_UNDO: send("Game#%d RemoveUndo" % game_id)
		GameAction.OFFER_DRAW: send("Game#%d OfferDraw" % game_id)
		GameAction.REMOVE_DRAW: send("Game#%d RemoveDraw" % game_id)
		GameAction.RESIGN: send("Game#%d Resign" % game_id)

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
			seeks = []
			online_players = []
			game_list = []
			state = State.DISCONNECTED if was_online else State.OFFLINE
			if was_online:
				chat_message.emit(ChatWindow.Type.SYSTEM, "<system>", "<client>", "Connection lost")
			reconnect_timer = 10.0
			state_changed.emit()
			return
	
	while ws.get_available_packet_count() > 0:
		var line = ws.get_packet().get_string_from_ascii().rstrip(" \n")
		
		if ENABLE_LOGGING:
			print("> " + line)
		
		if line.begins_with("Game#"):
			var parts = line.right(-5).split(" ")
			var id = parts[0].to_int()
			match Array(parts.slice(1)):
				["P", var square, ..]:
					var sqr = Move.square_from_str(square)
					var type = PieceType.FLAT
					if parts.size() > 3:
						type = PieceType.WALL if parts[3] == "W" else PieceType.CAP
					game_move.emit(id, Move.place(sqr, type))
				["M", var from, var to, ..]:
					var sqr = Move.square_from_str(from)
					var diff = Move.square_from_str(to) - sqr
					var dir = MoveList.Direction.LEFT if diff.x < 0 else MoveList.Direction.RIGHT if diff.x > 0 else MoveList.Direction.DOWN if diff.y < 0 else MoveList.Direction.UP
					var drops: Array[int] = []
					var count = 0
					for d in parts.slice(4):
						var drop = d.to_int()
						drops.push_back(drop)
						count += drop
					game_move.emit(id, Move.stack(sqr, count, dir, drops))
				["Timems", var wtime, var btime]:
					update_clock.emit(id, wtime.to_int() / 1000.0, btime.to_int() / 1000.0)
				["Undo"]:
					game_undo.emit(id)
				["Over", var result]:
					game_result.emit(id, GameResult.parse(result))
				["RequestUndo"]:
					game_action.emit(id, GameAction.REQUEST_UNDO)
				["RemoveUndo"]:
					game_action.emit(id, GameAction.REMOVE_UNDO)
				["OfferDraw"]:
					game_action.emit(id, GameAction.OFFER_DRAW)
				["RemoveDraw"]:
					game_action.emit(id, GameAction.REMOVE_DRAW)
		else:
			match Array(line.split(" ")):
				["Login", "or", "Register"] when state == State.CONNECTING:
					send("Client Kati")
					send("Protocol 2")
					send("Login %s %s" % [_login.user, _login.password])
					state = State.LOGGING_IN
				["Authentication", "failure"]:
					printerr("Failed to login to playtak server")
					close_connection()
				["Welcome", var uname]:
					username = uname.left(-1)
					state = State.ONLINE
					fetch_rating(username)
					if was_online:
						chat_message.emit(ChatWindow.Type.SYSTEM, "<system>", "<client>", "Reconnected")
					was_online = true
					last_ping = Time.get_unix_time_from_system()
					_login.save()
					state_changed.emit()
				["Seek", "new", var id, var user, var size, var time, var inc, var color, var half_komi, var flat_count, var capstone_count, var unrated, var tournament, var extra_time_move, var extra_time, var opp, var bot_seek]:
					if opp != "0" && opp.to_lower() != username.to_lower():
						return
					var seek := Seek.new()
					seek.id = id.to_int()
					seek.user = user
					seek.rules = Common.GameRules.new(size.to_int(), half_komi.to_int(), flat_count.to_int(), capstone_count.to_int())
					seek.clock = Common.ClockSettings.new(time.to_int(), inc.to_int(), extra_time_move.to_int(), extra_time.to_int())
					seek.color = ColorChoice.WHITE if color == "W" else ColorChoice.BLACK if color == "B" else ColorChoice.NONE
					seek.game_type = GameType.TOURNAMENT if tournament == "1" else GameType.UNRATED if unrated == "1" else GameType.RATED
					seek.bot = bot_seek == "1"
					seeks.push_back(seek)
					seeks_changed.emit()
					fetch_rating(user)
				["Seek", "remove", var id, ..]:
					var int_id = id.to_int()
					var index = seeks.find_custom(func (s): return s.id == int_id)
					seeks.remove_at(index)
					seeks_changed.emit()
				["Game", "Start", var id, var player_white, "vs", var player_black, var color, var size, var time, var inc, var half_komi, var flat_count, var capstone_count, var unrated, var tournament, var extra_time_move, var extra_time, var is_bot]:
					var game := Game.new()
					game.id = id.to_int()
					game.player_white = player_white
					game.player_black = player_black
					game.color = ColorChoice.WHITE if color == "white" else ColorChoice.BLACK
					game.rules = Common.GameRules.new(size.to_int(), half_komi.to_int(), flat_count.to_int(), capstone_count.to_int())
					game.clock = Common.ClockSettings.new(time.to_int(), inc.to_int(), extra_time_move.to_int(), extra_time.to_int())
					game.game_type = GameType.TOURNAMENT if tournament == "1" else GameType.UNRATED if unrated == "1" else GameType.RATED
					game.bot = is_bot == "1"
					game_started.emit(game)
					var opponent = game.player_black if game.color == ColorChoice.WHITE else game.player_white
					add_chat_room.emit(ChatWindow.Type.DIRECT, opponent)
					fetch_rating(player_white)
					fetch_rating(player_black)
				["GameList", "Add", var id, var player_white, var player_black, var size, var time, var inc, var half_komi, var flat_count, var capstone_count, var unrated, var tournament, var extra_time_move, var extra_time]:
					var game := Game.new()
					game.id = id.to_int()
					game.player_white = player_white
					game.player_black = player_black
					game.color = ColorChoice.NONE
					game.rules = Common.GameRules.new(size.to_int(), half_komi.to_int(), flat_count.to_int(), capstone_count.to_int())
					game.clock = Common.ClockSettings.new(time.to_int(), inc.to_int(), extra_time_move.to_int(), extra_time.to_int())
					game.game_type = GameType.TOURNAMENT if tournament == "1" else GameType.UNRATED if unrated == "1" else GameType.RATED
					game.bot = false
					game_list.push_back(game)
					game_list_changed.emit()
					fetch_rating(player_white)
					fetch_rating(player_black)
				["GameList", "Remove", var id, ..]:
					var int_id = id.to_int()
					var index = game_list.find_custom(func (g): return g.id == int_id)
					if index >= 0:
						game_list.remove_at(index)
						game_list_changed.emit()
				["Observe", var id, var player_white, var player_black, var size, var time, var inc, var half_komi, var flat_count, var capstone_count, var unrated, var tournament, var extra_time_move, var extra_time]:
					var game := Game.new()
					game.id = id.to_int()
					game.player_white = player_white
					game.player_black = player_black
					game.color = ColorChoice.NONE
					game.rules = Common.GameRules.new(size.to_int(), half_komi.to_int(), flat_count.to_int(), capstone_count.to_int())
					game.clock = Common.ClockSettings.new(time.to_int(), inc.to_int(), extra_time_move.to_int(), extra_time.to_int())
					game.game_type = GameType.TOURNAMENT if tournament == "1" else GameType.UNRATED if unrated == "1" else GameType.RATED
					game.bot = false
					game_started.emit(game)
					var players = [player_white, player_black]
					players.sort()
					send("JoinRoom %s-%s" % [players[0], players[1]])
					fetch_rating(player_white)
					fetch_rating(player_black)
				["OnlinePlayers", ..]:
					var json = JSON.new()
					json.parse(line.right(-14))
					online_players = []
					for player in json.get_data():
						online_players.push_back(player)
					players_changed.emit()
				["Tell", var user, ..]:
					var cleaned_user = user.trim_prefix("<").trim_suffix(">")
					var message = line.split(" ", true, 2)[2]
					chat_message.emit(ChatWindow.Type.DIRECT, cleaned_user, cleaned_user, message)
				["Told", var user, ..]:
					var cleaned_user = user.trim_prefix("<").trim_suffix(">")
					var message = line.split(" ", true, 2)[2]
					chat_message.emit(ChatWindow.Type.DIRECT, cleaned_user, username, message)
				["Shout", var user, ..]:
					var cleaned_user = user.trim_prefix("<").trim_suffix(">")
					var message = line.split(" ", true, 2)[2]
					chat_message.emit(ChatWindow.Type.GROUP, "Global", cleaned_user, message)
				["ShoutRoom", var room, var user, ..]:
					var cleaned_user = user.trim_prefix("<").trim_suffix(">")
					var message = line.split(" ", true, 3)[3]
					chat_message.emit(ChatWindow.Type.GROUP, room, cleaned_user, message)
				["Joined", "room", var room]:
					add_chat_room.emit(ChatWindow.Type.GROUP, room)
				["Message", ..]:
					chat_message.emit(ChatWindow.Type.SYSTEM, "<system>", "<server>", line.split(" ", true, 1)[1])
				["Error", ..]:
					chat_message.emit(ChatWindow.Type.SYSTEM, "<system>", "<error>", line.split(" ", true, 1)[1])
	
	if state == State.ONLINE:
		var t = Time.get_unix_time_from_system()
		if t >= last_ping + 30:
			send("PING")
			last_ping = t

func send_chat_message(type: ChatWindow.Type, room: String, text: String):
	if state != State.ONLINE:
		return
	match type:
		ChatWindow.Type.DIRECT:
			send("Tell %s %s" % [room, text])
		ChatWindow.Type.GROUP when room == "Global":
			send("Shout %s" % text)
		ChatWindow.Type.GROUP:
			send("ShoutRoom %s %s" % [room, text])

func leave_room(room: String):
	send("LeaveRoom %s" % room)

func send(line: String):
	if ENABLE_LOGGING:
		if line.begins_with("Login "):
			print("< Login %s Swordfish" % line.get_slice(" ", 1))
		else:
			print("< " + line)
	ws.send_text(line)

func close_connection():
	ws.close()
	was_online = false
	while ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		await get_tree().create_timer(0.1).timeout
	state = State.OFFLINE
	state_changed.emit()

func reconnect():
	if state != State.DISCONNECTED:
		return
	ws.connect_to_url(ws_url)
	state = State.CONNECTING

func fetch_rating(user: String):
	if user.begins_with("Guest"):
		return
	if ratings.has(user):
		return
	if pending_ratings.find(user) >= 0:
		return
	pending_ratings.push_back(user)
	fetch_next_rating()

func fetch_next_rating():
	if pending_ratings.is_empty() || http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var user = pending_ratings.pop_front()
	if http.request(RATING_URL + user) != OK:
		pending_ratings.push_front(user)
		return
	var result = await http.request_completed
	if result[0] == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.new()
		json.parse(result[3].get_string_from_utf8())
		var response = json.get_data()
		ratings[response.name] = { "rating": response.rating, "is_bot": response.isbot }
		ratings_changed.emit()
		fetch_next_rating.call_deferred()
