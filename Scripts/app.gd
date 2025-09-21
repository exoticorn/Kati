extends Control

const Login = preload("res://Scripts/login.gd")

var playtak: PlaytakInterface
var login: Login

enum Screen {
	NONE,
	MAIN_MENU,
	SEEKS,
	LOCAL_GAME
}

var active_screen := Screen.MAIN_MENU

func _ready():
	playtak = PlaytakInterface.new()
	playtak.state_changed.connect(_on_playtak_state_changed)
	playtak.game_started.connect(_on_playtak_game_started)
	add_child(playtak)
	login = Login.load()
	%SeeksScreen.set_playtak(playtak)
	$Screens/Games.setup(playtak)
	switch_screen(Screen.MAIN_MENU)

func _on_local_game_pressed() -> void:
	switch_screen(Screen.LOCAL_GAME)

func _on_local_game_start_game(settings: Dictionary) -> void:
	switch_screen(Screen.NONE)
	var game = LocalGame.new(settings)
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
	if playtak.state == PlaytakInterface.State.ONLINE:
		%MainMenu/Box/Login.text = "Logout " + playtak.username
		%MainMenu/Box/Seeks.disabled = false
	else:
		%MainMenu/Box/Login.text = "Login"
		%MainMenu/Box/Seeks.disabled = true
	%MainMenu/Box/Login.disabled = false

func _on_menu_button_pressed() -> void:
	switch_screen(Screen.MAIN_MENU)

func _on_playtak_game_started(game: PlaytakInterface.Game):
	switch_screen(Screen.NONE)
	var game_control: PlaytakGame = preload("res://Scenes/playtak_game.tscn").instantiate()
	game_control.setup(game, playtak)
	$Screens/Games.add_game(game_control)

func switch_screen(screen: Screen):
	%MainMenu.visible = screen == Screen.MAIN_MENU
	%SeeksScreen.visible = screen == Screen.SEEKS
	%LocalGameScreen.visible = screen == Screen.LOCAL_GAME
	active_screen = screen

func _on_games_pressed() -> void:
	if active_screen == Screen.NONE:
		%Screens/Games.switch_game()
	else:
		switch_screen(Screen.NONE)
