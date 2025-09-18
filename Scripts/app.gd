extends Control

var playtak: PlayTakInterface

func _ready():
	playtak = PlayTakInterface.new()
	playtak.state_changed.connect(_on_playtak_state_changed)
	add_child(playtak)

func _on_local_game_pressed() -> void:
	$MainMenu.hide()
	$LocalGame.show()
	$MenuButton.show()

func _on_local_game_start_game(settings: Dictionary) -> void:
	$LocalGame.hide()
	var game = load("res://Scenes/local_game.tscn").instantiate()
	game.settings = settings
	$Games.add_child(game)

func _on_seeks_pressed() -> void:
	$MainMenu.hide()
	$MenuButton.show()
	$Seeks.show()

func _on_login_pressed() -> void:
	if playtak.state == PlayTakInterface.State.ONLINE:
		playtak.close_connection()
	else:
		playtak.login("Guest")
	$MainMenu/Box/Login.disabled = true

func _on_playtak_state_changed():
	if playtak.state == PlayTakInterface.State.ONLINE:
		$MainMenu/Box/Login.text = "Logout " + playtak.username
		$MainMenu/Box/Seeks.disabled = false
	else:
		$MainMenu/Box/Login.text = "Login"
		$MainMenu/Box/Seeks.disabled = true
	$MainMenu/Box/Login.disabled = false


func _on_menu_button_pressed() -> void:
	$MenuButton.hide()
	$Seeks.hide()
	$MainMenu.show()
