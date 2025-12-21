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
		$Grid/EngineLabel.hide()
		$Grid/Engine.hide()
		%NodesLabel.hide()
		%NodesBox.hide()

func _on_play_pressed() -> void:
	var board_size := 5
	if $Grid/Sizes/Six.button_pressed:
		board_size = 6
	elif $Grid/Sizes/Seven.button_pressed:
		board_size = 7
	var komi: float = $Grid/Komis.selected * 0.5
	var engine_mask := 0
	var analyze := false
	if $Grid/Colors/White.button_pressed:
		engine_mask = 2
	elif $Grid/Colors/Black.button_pressed:
		engine_mask = 1
	elif $Grid/Colors/Analyze.button_pressed:
		analyze = true
	
	var engine_path = ""
	var engine_parameters = ""
	if (engine_mask != 0 || analyze) && $Grid/Engine.selected >= 0:
		var section = "engine%d" % $Grid/Engine.selected
		if config.has_section(section):
			engine_path = config.get_value(section, "path")
			engine_parameters = config.get_value(section, "parameters")
	
	var node_count = roundi(%NodesSlider.value)
	
	var settings = {
		"size": board_size,
		"komi": komi,
		"engine_mask": engine_mask,
		"engine_path": engine_path,
		"engine_parameters": engine_parameters,
		"analyze": analyze,
		"node_count": node_count
	}
	start_game.emit(settings)

func setup_engine_list():
	var index = 0
	$Grid/Engine.clear()
	while config.has_section("engine%d" % index):
		$Grid/Engine.add_item(config.get_value("engine%d" % index, "name"), index)
		index += 1

func _on_color_changed() -> void:
	var needs_engine = !$Grid/Colors/Both.button_pressed
	var is_engine_game = needs_engine and !$Grid/Colors/Analyze.button_pressed
	$Grid/EngineLabel.visible = needs_engine
	$Grid/Engine.visible = needs_engine
	%NodesLabel.visible = is_engine_game
	%NodesBox.visible = is_engine_game

func _on_nodes_slider_value_changed(value: float) -> void:
	%NodesCount.text = str(roundi(value))
