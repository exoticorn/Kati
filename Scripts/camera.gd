extends Camera3D

var rot := Vector2(0, 0.8)
var speed := Vector2(0, 0)
var board_size := 6
var distance_factor := 1.0

var last_drag_pos = null

func _process(delta: float):
	if Input.is_action_pressed("cam_left"):
		speed.x += (-1 - speed.x) * delta
	if Input.is_action_pressed("cam_right"):
		speed.x += (1 - speed.x) * delta
	if Input.is_action_pressed("cam_up"):
		speed.y += (-1 - speed.y) * delta
	if Input.is_action_pressed("cam_down"):
		speed.y += (1 - speed.y) * delta
	speed *= 0.05 ** delta
	rot += speed * (delta * 3)
	rot.x = fmod(rot.x, PI * 2)
	rot.y = clampf(rot.y, 0.1, 1.4)
	
	var viewport := get_viewport()
	keep_aspect = Camera3D.KEEP_HEIGHT if viewport.size.x > viewport.size.y else Camera3D.KEEP_WIDTH
	
	basis = Basis.from_euler(Vector3(-rot.y, -rot.x, 0))
	var pos := calculate_camera_pos()
	pos = basis * pos
	var board_center = Vector3(board_size * 0.5 - 0.5, 0.0, 0.5 - board_size * 0.5)
	var distance = basis.z.dot(pos - board_center)
	distance_factor = clamp(distance_factor, 0.5, 2.0)
	position = pos + (distance_factor - 1) * distance * basis.z
	
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				last_drag_pos = event.position
			else:
				last_drag_pos = null
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP && event.pressed:
			distance_factor *= 0.9
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN && event.pressed:
			distance_factor /= 0.9
	elif event is InputEventMouseMotion:
		if last_drag_pos:
			var delta = event.position - last_drag_pos
			last_drag_pos = event.position
			rot += delta * 4 / get_viewport().get_visible_rect().size

func calculate_camera_pos() -> Vector3:
	var inv_basis := basis.inverse()
	var center_world := Vector3(board_size * 0.5 - 0.5, 0, 0.5 - board_size * 0.5)
	var to_front := Vector3(basis.z.x, 0, basis.z.z).normalized()
	var radius := sqrt((board_size * 0.5) ** 2 * 2)
	var front_world := center_world + to_front * radius
	var center := inv_basis * center_world
	var front_pos := inv_basis * front_world
	
	var viewport := get_viewport()
	var fov_h := fov
	var fov_v := fov
	if viewport.size.x > viewport.size.y:
		fov_h = rad_to_deg(atan(tan(deg_to_rad(fov)) * viewport.size.x as float / viewport.size.y))
	else:
		fov_v = rad_to_deg(atan(tan(deg_to_rad(fov)) * viewport.size.y as float / viewport.size.x))
	
	var px = calculate_camera_pos2d(Vector2(center.x, center.z), radius, Vector2(center.x, center.z), radius, fov_h)

	var py = calculate_camera_pos2d(Vector2(center.y, center.z), radius, Vector2(front_pos.y, front_pos.z), 0, fov_v)
	
	return Vector3(px.x, py.x, max(px.y, py.y))

func calculate_camera_pos2d(centerl: Vector2, radiusl: float, centerr: Vector2, radiusr: float, fov2: float) -> Vector2:
	var nl := Vector2.from_angle(deg_to_rad(fov2 / 2 + 180))
	var nr := Vector2(-nl.x, nl.y)
	var minl := nl.dot(centerl) - radiusl
	var minr := nr.dot(centerr) - radiusr
	var y := (minr * nl.x - minl * nr.x) / (nr.y * nl.x - nl.y * nr.x)
	var x := (minl - y * nl.y) / nl.x
	return Vector2(x, y)
