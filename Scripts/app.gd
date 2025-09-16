extends Control

func _on_local_game_pressed() -> void:
	$MainMenu.hide()
	var game = load("res://Scenes/local_game.tscn").instantiate()
	$Games.add_child(game)
	$Games.show()
