extends PanelContainer

var _minimized := false
var _result: GameResult

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

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			_minimized = !_minimized
			update()
