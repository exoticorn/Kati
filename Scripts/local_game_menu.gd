extends PanelContainer

signal start_game(settings: Dictionary)

func _ready():
	if OS.has_feature('web'):
		$Grid/Colors/Both.button_pressed = true
		$Grid/YouPlay.hide()
		$Grid/Colors.hide()

func _on_play_pressed() -> void:
	var board_size := 5
	if $Grid/Sizes/Six.button_pressed:
		board_size = 6
	elif $Grid/Sizes/Seven.button_pressed:
		board_size = 7
	var komi: float = $Grid/Komis.selected * 0.5
	var engine_mask := 0
	if $Grid/Colors/White.button_pressed:
		engine_mask = 2
	elif $Grid/Colors/Black.button_pressed:
		engine_mask = 1
	
	var settings = { "size": board_size, "komi": komi, "engine_mask": engine_mask }
	start_game.emit(settings)
