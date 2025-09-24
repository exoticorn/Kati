extends PanelContainer

var config: ConfigFile

signal start_game(settings: Dictionary)

func setup(c: ConfigFile):
	config = c
	setup_engine_list()

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
	
	var engine_path = ""
	var engine_parameters = ""
	if engine_mask != 0 && $Grid/Engine.selected >= 0:
		var section = "engine%d" % $Grid/Engine.selected
		if config.has_section(section):
			engine_path = config.get_value(section, "path")
			engine_parameters = config.get_value(section, "parameters")
	
	var settings = { "size": board_size, "komi": komi, "engine_mask": engine_mask, "engine_path": engine_path, "engine_parameters": engine_parameters }
	start_game.emit(settings)

func setup_engine_list():
	var index = 0
	$Grid/Engine.clear()
	while config.has_section("engine%d" % index):
		$Grid/Engine.add_item(config.get_value("engine%d" % index, "name"), index)
		index += 1

func _on_color_changed() -> void:
	var needs_engine = !$Grid/Colors/Both.button_pressed
	$Grid/EngineLabel.visible = needs_engine
	$Grid/Engine.visible = needs_engine
