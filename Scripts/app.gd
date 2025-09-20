extends Control

var playtak: PlaytakInterface

func _ready():
	playtak = PlaytakInterface.new()
	playtak.state_changed.connect(_on_playtak_state_changed)
	playtak.game_started.connect(_on_playtak_game_started)
	add_child(playtak)
	%SeeksScreen.set_playtak(playtak)
	$Screens/Games.setup(playtak)

func _on_local_game_pressed() -> void:
	%MainMenu.hide()
	%LocalGameScreen.show()

func _on_local_game_start_game(settings: Dictionary) -> void:
	%LocalGameScreen.hide()
	var game = LocalGame.new(settings)
	$Screens/Games.add_child(game)

func _on_seeks_pressed() -> void:
	%MainMenu.hide()
	%SeeksScreen.show()

func _on_login_pressed() -> void:
	if playtak.state == PlaytakInterface.State.ONLINE:
		playtak.close_connection()
	else:
		playtak.login("Guest")
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
	%SeeksScreen.hide()
	%LocalGameScreen.hide()
	%MainMenu.show()

func _on_playtak_game_started(game: PlaytakInterface.Game):
	%MainMenu.hide()
	%SeeksScreen.hide()
	var game_control = PlaytakGame.new(game, playtak)
	$Screens/Games.add_child(game_control)
