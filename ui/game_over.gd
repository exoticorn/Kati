extends PanelContainer

var _minimized := false
var _result: GameResult
var playtak_game # needs to be set before result

var result: GameResult:
	set(r):
		_result = r
		update()
	get(): return _result

func update():
	if _minimized:
		%Result.text = _result.to_str()
		set_anchors_preset(PRESET_CENTER_TOP, true)
	else:
		%Result.text = _result.to_long_str()
		set_anchors_preset(PRESET_CENTER, true)
	%Title.visible = !_minimized
	$Box/Rematch.visible = !_minimized && playtak_game != null && playtak_game.color != PlaytakInterface.ColorChoice.NONE
	$Box/CopyId.visible = !_minimized && playtak_game != null
	$Box/Actions.visible = !_minimized && playtak_game != null

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			_minimized = !_minimized
			update()

func _on_open_playtak_pressed() -> void:
	OS.shell_open("https://playtak.com/games/%d/playtakviewer" % playtak_game.id)

func _on_open_ptn_ninja_pressed() -> void:
	OS.shell_open("https://playtak.com/games/%d/ninjaviewer" % playtak_game.id)

func _on_copy_id_pressed() -> void:
	DisplayServer.clipboard_set(str(playtak_game.id))
