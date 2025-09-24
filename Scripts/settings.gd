extends PanelContainer

var config: ConfigFile
var engine_count := 0
var engine_index := 0

signal settings_changed

func setup(c: ConfigFile):
	config = c
	match config.get_value("display", "quality", "low"):
		"mid": $Box/Quality/Mid.button_pressed = true
		"high": $Box/Quality/High.button_pressed = true
		_: $Box/Quality/Low.button_pressed = true
	$Box/Quality/Low.pressed.connect(change_quality.bind("low"))
	$Box/Quality/Mid.pressed.connect(change_quality.bind("mid"))
	$Box/Quality/High.pressed.connect(change_quality.bind("high"))
	setup_engine_grid()

func change_quality(quality: String):
	config.set_value("display", "quality", quality)
	settings_changed.emit()

func setup_engine_grid():
	for child in $Box/EngineGrid.get_children():
		child.queue_free()
	engine_count = 0
	while config.has_section("engine%d" % engine_count):
		var name = config.get_value("engine%d" % engine_count, "name")
		var label = Label.new()
		label.text = name
		$Box/EngineGrid.add_child(label)
		var edit_button = Button.new()
		edit_button.text = "Edit.."
		edit_button.pressed.connect(edit_engine.bind(engine_count))
		$Box/EngineGrid.add_child(edit_button)
		var delete_button = Button.new()
		delete_button.text = "Delete"
		delete_button.pressed.connect(delete_engine.bind(engine_count))
		$Box/EngineGrid.add_child(delete_button)
		engine_count += 1

func _on_add_engine_pressed() -> void:
	$EnginePopup/Box/Grid/Name.text = ""
	$EnginePopup/Box/Grid/Path.text = ""
	$EnginePopup/Box/Grid/Parameters.text = ""
	engine_index = engine_count
	$EnginePopup.popup_centered()

func edit_engine(index: int):
	var section = "engine%d" % index
	$EnginePopup/Box/Grid/Name.text = config.get_value(section, "name")
	$EnginePopup/Box/Grid/Path.text = config.get_value(section, "path")
	$EnginePopup/Box/Grid/Parameters.text = config.get_value(section, "parameters")
	engine_index = index
	$EnginePopup.popup_centered()

func delete_engine(index: int):
	var section = "engine%d" % index
	while config.has_section("engine%d" % (index + 1)):
		index += 1
		var next_section = "engine%d" % index
		config.set_value(section, "name", config.get_value(next_section, "name"))
		config.set_value(section, "path", config.get_value(next_section, "path"))
		config.set_value(section, "parameters", config.get_value(next_section, "parameters"))
		section = next_section
	config.erase_section(section)
	setup_engine_grid()
	settings_changed.emit()

func _on_ok_pressed() -> void:
	var section = "engine%d" % engine_index
	config.set_value(section, "name", $EnginePopup/Box/Grid/Name.text)
	config.set_value(section, "path", $EnginePopup/Box/Grid/Path.text)
	config.set_value(section, "parameters", $EnginePopup/Box/Grid/Parameters.text)
	setup_engine_grid()
	settings_changed.emit()
	$EnginePopup.hide()


func _on_cancel_pressed() -> void:
	$EnginePopup.hide()
