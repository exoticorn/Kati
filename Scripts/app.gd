extends Control

const Login = preload("res://Scripts/login.gd")
const ChatWindow = preload("res://Scripts/chat_window.gd")

var playtak: PlaytakInterface
var login: Login
var settings := ConfigFile.new()

enum Screen {
	NONE,
	MAIN_MENU,
	SEEKS,
	WATCH,
	LOCAL_GAME,
	HELP,
	SETTINGS,
	CHAT
}

var active_screen := Screen.MAIN_MENU

func _ready():
	settings.load("user://settings.cfg")
	apply_settings()
	playtak = PlaytakInterface.new()
	playtak.state_changed.connect(_on_playtak_state_changed)
	playtak.game_started.connect(_on_playtak_game_started)
	playtak.chat_message.connect(_on_chat_received)
	playtak.add_chat_room.connect($Screens/Chat.add_room)
	playtak.game_list_changed.connect(_on_game_list_changed)
	$Screens/Chat.send_message.connect(playtak.send_chat_message)
	$Screens/Chat.leave_room.connect(playtak.leave_room)
	add_child(playtak)
	login = Login.load()
	%SeeksScreen.set_playtak(playtak)
	$Screens/Games.setup(playtak)
	$Screens/Watch.setup(playtak)
	$Screens/Settings.setup(settings)
	$Screens/LocalGameScreen.setup(settings)
	$TopBar/Username.setup(playtak)
	switch_screen(Screen.MAIN_MENU)
	if OS.has_feature("web"):
		%MainMenu/Box/Settings.hide()
	if login.is_valid() && !login.is_guest():
		playtak.login(login)

func _process(_delta: float):
	if Input.is_action_just_pressed("cancel"):
		switch_screen(Screen.NONE)
	if Input.is_action_just_pressed("open_chat", true):
		switch_screen(Screen.CHAT if active_screen != Screen.CHAT else Screen.NONE)

func _on_local_game_pressed() -> void:
	switch_screen(Screen.LOCAL_GAME)

func _on_local_game_start_game(game_settings: Dictionary) -> void:
	switch_screen(Screen.NONE)
	var game
	if game_settings.analyze:
		game = AnalyzeGame.new(game_settings, settings)
	else:
		game = LocalGame.new(game_settings, settings)
	$Screens/Games.add_game(game)

func _on_seeks_pressed() -> void:
	switch_screen(Screen.SEEKS)

func _on_login_pressed() -> void:
	login.user = %MainMenu/Box/LoginGrid/Username.text
	login.password = %MainMenu/Box/LoginGrid/Password.text
	login.remember_me = %MainMenu/Box/LoginGrid/RememberMe.button_pressed
	playtak.login(login)

func _on_guest_login_pressed() -> void:
	login.make_guest()
	playtak.login(login)

func _on_playtak_state_changed():
	var is_online = playtak.state == PlaytakInterface.State.ONLINE
	var is_disconnected = playtak.state == PlaytakInterface.State.DISCONNECTED
	%MainMenu/Box/LoginGrid.visible = playtak.state == PlaytakInterface.State.OFFLINE
	%MainMenu/Box/Connecting.visible = playtak.state == PlaytakInterface.State.CONNECTING || playtak.state == PlaytakInterface.State.LOGGING_IN
	%MainMenu/Box/LoggedIn.visible = is_online || is_disconnected
	if is_online:
		%MainMenu/Box/LoggedIn/Name.text = playtak.username
		$TopBar/Username.user = playtak.username
	$TopBar/Seeks.visible = is_online
	$TopBar/Watch.visible = is_online
	$TopBar/Chat.visible = is_online
	$TopBar/Username.visible = is_online || is_disconnected
	$TopBar/ReconnectButton.visible = is_disconnected
	if !is_online:
		%Screens/Games.remove_playtak_games()

func _on_menu_button_pressed() -> void:
	switch_screen(Screen.MAIN_MENU)

func _on_playtak_game_started(game: PlaytakInterface.Game):
	switch_screen(Screen.NONE)
	var game_control: PlaytakGame = preload("res://Scenes/playtak_game.tscn").instantiate()
	game_control.setup(game, playtak, settings)
	$Screens/Games.add_game(game_control)

func _on_game_list_changed():
	$TopBar/Watch.count = playtak.game_list.size()
	var has_tournament_game = false
	for game in playtak.game_list:
		if game.game_type == PlaytakInterface.GameType.TOURNAMENT:
			has_tournament_game = true
	$TopBar/Watch.red = has_tournament_game

func switch_screen(screen: Screen):
	%MainMenu.visible = screen == Screen.MAIN_MENU
	%SeeksScreen.visible = screen == Screen.SEEKS
	%LocalGameScreen.visible = screen == Screen.LOCAL_GAME
	%Screens/Watch.visible = screen == Screen.WATCH
	%Screens/Help.visible = screen == Screen.HELP
	%Screens/Settings.visible = screen == Screen.SETTINGS
	%Screens/Chat.visible = screen == Screen.CHAT
	active_screen = screen

func _on_games_pressed() -> void:
	if active_screen == Screen.NONE:
		%Screens/Games.switch_game()
	else:
		switch_screen(Screen.NONE)

func _on_watch_pressed() -> void:
	switch_screen(Screen.WATCH)

func apply_settings():
	var env: Environment
	var quality: String = settings.get_value("display", "quality", "mid")
	var rendering_method := RenderingServer.get_current_rendering_method()
	if rendering_method == "gl_compatibility":
		quality = "low"
		settings.set_value("display", "quality", "low")
	var viewport = get_viewport()
	match quality:
		"high":
			env = load("res://Scenes/env_high.tres")
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
			viewport.scaling_3d_scale = 0.75
		"low":
			env = load("res://Scenes/env_low.tres")
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			viewport.scaling_3d_scale = 1.0
		_:
			env = load("res://Scenes/env_mid.tres")
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
			viewport.scaling_3d_scale = 0.5
	$WorldEnvironment.environment = env


func _on_help_pressed() -> void:
	switch_screen(Screen.HELP if active_screen != Screen.HELP else Screen.NONE)

func _on_reconnect_button_pressed() -> void:
	if playtak.state == PlaytakInterface.State.DISCONNECTED:
		playtak.reconnect()


func _on_settings_pressed() -> void:
	switch_screen(Screen.SETTINGS)


func _on_settings_settings_changed() -> void:
	apply_settings()
	$Screens/Games.apply_settings()
	$Screens/LocalGameScreen.setup_engine_list()
	settings.save("user://settings.cfg")


func _on_chat_pressed() -> void:
	switch_screen(Screen.CHAT)

func _on_chat_received(type: ChatWindow.Type, room: String, user: String, text: String):
	$Screens/Chat.add_message(type, room, user, text)
	if user != playtak.username:
		$Screens/Toasts.add_toast("%s: %s" % [user, text])


func _on_chat_unread_count(count: int, direct: bool) -> void:
	$TopBar/Chat.count = count
	$TopBar/Chat.red = direct

func _on_log_out_pressed() -> void:
	playtak.close_connection()
	if login.is_valid() && !login.is_guest():
		login.forget()
