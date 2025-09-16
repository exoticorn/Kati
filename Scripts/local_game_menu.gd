extends PanelContainer

signal start_game(settings: Dictionary)

func _on_play_pressed() -> void:
	var size := 5
	if $Grid/Sizes/Six.button_pressed:
		size = 6
	elif $Grid/Sizes/Seven.button_pressed:
		size = 7
	var komi: float = $Grid/Komis.selected * 0.5
	var engine_mask = 0
	if $Grid/Colors/White.button_pressed:
		engine_mask = 2
	elif $Grid/Colors/Black.button_pressed:
		engine_mask = 1
	
	var settings = { "size": size, "komi": komi, "engine_mask": engine_mask }
	start_game.emit(settings)
