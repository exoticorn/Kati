extends Camera3D

var rot := Vector2(0, 0.8)
var distance := 7.0
var target := Vector3(2.5, 0.0, -2.5)

var last_drag_pos = null

func _process(_delta: float):
	var pos := Vector3(0.0, 0.0, distance).rotated(Vector3.RIGHT, -rot.y).rotated(Vector3.UP, -rot.x)
	look_at_from_position(target + pos, target)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				last_drag_pos = event.position
			else:
				last_drag_pos = null
	elif event is InputEventMouseMotion:
		if last_drag_pos:
			var delta = event.position - last_drag_pos
			last_drag_pos = event.position
			rot += delta * 4 / get_viewport().get_visible_rect().size
			rot.y = clampf(rot.y, 0.1, 1.4)
