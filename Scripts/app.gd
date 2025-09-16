extends Control

func _on_local_game_pressed() -> void:
	$MainMenu.hide()
	$LocalGame.show()


func _on_local_game_start_game(settings: Dictionary) -> void:
	$LocalGame.hide()
	var game = load("res://Scenes/local_game.tscn").instantiate()
	game.settings = settings
	$Games.add_child(game)
