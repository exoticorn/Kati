extends Camera3D

var rot := Vector2(0, 0.8)
var speed := Vector2(0, 0)
var distance := 8.0
var target := Vector3(2.5, 0.0, -2.5)

var last_drag_pos = null

var bounding_points: Array[Vector3] = []

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
	position = basis * pos
	
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

func calculate_camera_pos() -> Vector3:
	var inv_basis = basis.inverse()
	var ps = []
	for p in bounding_points:
		ps.push_back(inv_basis * p)
	
	var viewport := get_viewport()
	var fov_h := fov
	var fov_v := fov
	if viewport.size.x > viewport.size.y:
		fov_h = rad_to_deg(atan(tan(deg_to_rad(fov)) * viewport.size.x as float / viewport.size.y))
	else:
		fov_v = rad_to_deg(atan(tan(deg_to_rad(fov)) * viewport.size.y as float / viewport.size.x))
	
	var ps2: Array[Vector2] = []
	for p in ps:
		ps2.push_back(Vector2(p.x, p.z))	
	var px = calculate_camera_pos2d(ps2, fov_h)

	ps2 = []
	for p in ps:
		ps2.push_back(Vector2(p.y, p.z))
	var py = calculate_camera_pos2d(ps2, fov_v)
	
	return Vector3(px.x, py.x, max(px.y, py.y))

func calculate_camera_pos2d(pts: Array[Vector2], fov2: float) -> Vector2:
	var nl := Vector2.from_angle(deg_to_rad(fov2 / 2 + 180))
	var nr := Vector2(-nl.x, nl.y)
	var minl := 1000.0
	var minr := 1000.0
	for p in pts:
		minl = min(minl, nl.dot(p))
		minr = min(minr, nr.dot(p))
	var y = (minr * nl.x - minl * nr.x) / (nr.y * nl.x - nl.y * nr.x)
	var x = (minl - y * nl.y) / nl.x
	return Vector2(x, y)

func set_content_box(box: AABB):
	var p = box.position
	var x := Vector3(1, 0, 0) * box.size.x
	var y := Vector3(0, 1, 0) * box.size.y
	var z := Vector3(0, 0, 1) * box.size.z
	bounding_points = [p, p + x, p + y, p + z, p + x + y, p + x + z, p + y + z, p + x + y + z]
