extends Control

const Login = preload("res://Scripts/login.gd")

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
	SETTINGS
}

var active_screen := Screen.MAIN_MENU

func _ready():
	settings.load("user://settings.cfg")
	apply_settings()
	playtak = PlaytakInterface.new()
	playtak.state_changed.connect(_on_playtak_state_changed)
	playtak.game_started.connect(_on_playtak_game_started)
	add_child(playtak)
	login = Login.load()
	%SeeksScreen.set_playtak(playtak)
	$Screens/Games.setup(playtak)
	$Screens/Watch.setup(playtak)
	$Screens/Settings.setup(settings)
	$Screens/LocalGameScreen.setup(settings)
	switch_screen(Screen.MAIN_MENU)
	if OS.has_feature("web"):
		%MainMenu/Box/Settings.hide()

func _process(_delta: float):
	if Input.is_action_just_pressed("cancel"):
		switch_screen(Screen.NONE)

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
	if playtak.state == PlaytakInterface.State.ONLINE:
		playtak.close_connection()
	else:
		login.make_guest()
		login.save()
		playtak.login(login)
	%MainMenu/Box/Login.disabled = true

func _on_playtak_state_changed():
	var is_online = playtak.state == PlaytakInterface.State.ONLINE
	var is_disconnected = playtak.state == PlaytakInterface.State.DISCONNECTED
	if is_online:
		%MainMenu/Box/Login.text = "Logout " + playtak.username
		$TopBar/Username.text = playtak.username
	else:
		%MainMenu/Box/Login.text = "Login"
		$TopBar/Username.text = "Disconnected"
	%MainMenu/Box/Seeks.disabled = !is_online
	%MainMenu/Box/Watch.disabled = !is_online
	$TopBar/Seeks.visible = is_online
	$TopBar/Watch.visible = is_online
	%MainMenu/Box/Login.disabled = false
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

func switch_screen(screen: Screen):
	%MainMenu.visible = screen == Screen.MAIN_MENU
	%SeeksScreen.visible = screen == Screen.SEEKS
	%LocalGameScreen.visible = screen == Screen.LOCAL_GAME
	%Screens/Watch.visible = screen == Screen.WATCH
	%Screens/Help.visible = screen == Screen.HELP
	%Screens/Settings.visible = screen == Screen.SETTINGS
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
