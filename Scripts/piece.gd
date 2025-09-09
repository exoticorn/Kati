extends MeshInstance3D

var white_flat_mesh: Mesh = preload("res://Assets/imported/white flat.res")
var black_flat_mesh: Mesh = preload("res://Assets/imported/black flat.res")
var white_cap_mesh: Mesh = preload("res://Assets/imported/white capstone.res")
var black_cap_mesh: Mesh = preload("res://Assets/imported/black capstone.res")

var flat_aabb: AABB
var type: GameState.Type
var color: GameState.Col
var base_rotation: Quaternion
var board_pos: Vector3i

var tween: Tween

func _init():
	flat_aabb = white_flat_mesh.get_aabb()

func setup(c: GameState.Col, t: GameState.Type):
	color = c
	type = t
	match [color, type]:
		[GameState.Col.WHITE, GameState.Type.FLAT], [GameState.Col.WHITE, GameState.Type.WALL]:
			mesh = white_flat_mesh
		[GameState.Col.BLACK, GameState.Type.FLAT], [GameState.Col.BLACK, GameState.Type.WALL]:
			mesh = black_flat_mesh
		[GameState.Col.WHITE, GameState.Type.CAP]:
			mesh = white_cap_mesh
		[GameState.Col.BLACK, GameState.Type.CAP]:
			mesh = black_cap_mesh
	var flip = randi_range(0, 1) if type != GameState.Type.CAP else 0
	base_rotation = Quaternion.from_euler(Vector3(flip * PI, randi_range(0, 3) * PI / 2, 0))
	if type == GameState.Type.WALL:
		var dir = 1 if color == GameState.Col.WHITE else -1
		base_rotation = Quaternion.from_euler(Vector3(PI / 2, PI / 4 * dir, 0)) * base_rotation

func place(pos: Vector3i, animate: bool = true):
	board_pos = pos
	var offset = 0.0
	if type == GameState.Type.FLAT:
		offset = flat_aabb.size.y * 0.5
	elif type == GameState.Type.WALL:
		offset = flat_aabb.size.x * 0.5
	var base_pos = Vector3(pos.x, pos.y * flat_aabb.size.y, -pos.z)
	var target_pos = base_pos + Vector3(randf_range(-0.03, 0.03), offset, randf_range(-0.03, 0.03))
	var target_quat = Quaternion.from_euler(Vector3(0, randf_range(-0.1, 0.1), 0)) * base_rotation
	if tween != null:
		tween.kill()
	if animate:
		tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "position", target_pos, 0.2)
		tween.parallel().tween_property(self, "quaternion", target_quat, 0.2)
	else:
		position = target_pos + Vector3(0, 3, 0)
		quaternion = target_quat
		tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(self, "position", target_pos, 0.2)

func can_be(c: GameState.Col, t: GameState.Type):
	if c != color:
		return false
	if t == type:
		return true
	return type == GameState.Type.WALL && t == GameState.Type.FLAT

func become(t: GameState.Type):
	if t != type:
		setup(color, t)
		place(board_pos)
