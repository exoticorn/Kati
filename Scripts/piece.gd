extends MeshInstance3D

const PieceType = BoardState.PieceType
const PlayerColor = BoardState.PlayerColor

var white_flat_mesh: Mesh = preload("res://Assets/imported/white flat.res")
var black_flat_mesh: Mesh = preload("res://Assets/imported/black flat.res")
var white_cap_mesh: Mesh = preload("res://Assets/imported/white capstone.res")
var black_cap_mesh: Mesh = preload("res://Assets/imported/black capstone.res")
var highlight_overlay_material: Material = preload("res://Shaders/highlight.tres")
var ghost_material: Material = preload("res://Shaders/ghost.tres")

var samples = [
	[preload("res://sfx/flat1.wav"), preload("res://sfx/flat2.wav")],
	[preload("res://sfx/wall1.wav"), preload("res://sfx/wall2.wav"), preload("res://sfx/wall3.wav")],
	[preload("res://sfx/cap1.wav"), preload("res://sfx/cap2.wav")]
]

var flat_aabb: AABB
var type: PieceType
var color: PlayerColor
var base_rotation: Quaternion
var board_pos: Vector3i
var temp_board_pos
var is_placed := false
var is_ghost := false
var mesh_height: float

var tween: Tween

func _init():
	flat_aabb = white_flat_mesh.get_aabb()

func setup(c: PlayerColor, t: PieceType):
	color = c
	type = t
	match [color, type]:
		[PlayerColor.WHITE, PieceType.FLAT], [PlayerColor.WHITE, PieceType.WALL]:
			mesh = white_flat_mesh
		[PlayerColor.BLACK, PieceType.FLAT], [PlayerColor.BLACK, PieceType.WALL]:
			mesh = black_flat_mesh
		[PlayerColor.WHITE, PieceType.CAP]:
			mesh = white_cap_mesh
		[PlayerColor.BLACK, PieceType.CAP]:
			mesh = black_cap_mesh
	if is_ghost:
		material_override = ghost_material
		set_instance_shader_parameter("color", Color(0.459, 0.611, 0.471, 1.0) if color == PlayerColor.WHITE else Color(0.164, 0.196, 0.141, 1.0))
	var flip = randi_range(0, 1) if type != PieceType.CAP else 0
	base_rotation = Quaternion.from_euler(Vector3(flip * PI, randi_range(0, 3) * PI / 2, 0))
	if type == PieceType.WALL:
		var dir = 1 if color == PlayerColor.WHITE else -1
		base_rotation = Quaternion.from_euler(Vector3(PI / 2, PI / 4 * dir, 0)) * base_rotation
	if is_placed:
		update_transform(true, false)
	mesh_height = piece_height()

func place(pos: Vector3i, animate: bool = true):
	board_pos = pos
	if pos == temp_board_pos:
		temp_board_pos = null
		return
	temp_board_pos = null
	update_transform(animate, animate)

func piece_height() -> float:
	match type:
		PieceType.FLAT:
			return flat_aabb.size.y
		PieceType.WALL:
			return flat_aabb.size.x
		_:
			return white_cap_mesh.get_aabb().size.y

func top_height():
	return board_pos.y * flat_aabb.size.y + piece_height()

func set_temp_pos(pos, sfx: bool):
	if temp_board_pos != pos:
		temp_board_pos = pos
		update_transform(true, sfx)

func calc_target_pos():
	var pos = temp_board_pos if temp_board_pos != null else board_pos
	var offset = 0.0
	if type == PieceType.FLAT:
		offset = flat_aabb.size.y * 0.5
	elif type == PieceType.WALL:
		offset = flat_aabb.size.x * 0.5
	var base_pos = Vector3(pos.x, pos.y * flat_aabb.size.y, -pos.z)
	if is_ghost:
		base_pos.y += flat_aabb.size.y * 0.5
	return base_pos + Vector3(randf_range(-0.03, 0.03), offset, randf_range(-0.03, 0.03))

func update_transform(animate: bool, sfx: bool):
	var target_pos = calc_target_pos()
	var target_quat = Quaternion.from_euler(Vector3(0, randf_range(-0.1, 0.1), 0)) * base_rotation
	if tween != null:
		tween.kill()
	var sample_options = samples[type]
	$StreamPlayer.stream = sample_options[randi_range(0, sample_options.size()-1)]
	if animate:
		if is_placed:
			var duration = (target_pos - position).length() * 0.2
			tween = create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "position", target_pos, duration)
			tween.parallel().tween_property(self, "quaternion", target_quat, duration)
			if sfx:
				tween.parallel().tween_interval(duration - randf_range(0, 0.1))
				tween.tween_callback($StreamPlayer.play)
		else:
			position = target_pos + Vector3(0, 3, 0)
			quaternion = target_quat
			tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_IN)
			tween.tween_property(self, "position", target_pos, 0.2)
			if sfx:
				tween.tween_callback($StreamPlayer.play)
	else:
		position = target_pos
		quaternion = target_quat
	is_placed = true

func can_be(c: PlayerColor, t: PieceType):
	if c != color:
		return false
	return t == type || (t != PieceType.CAP && type != PieceType.CAP)

func become(t: PieceType):
	if t != type:
		setup(color, t)
		update_transform(true, false)

func set_highlight(flag: bool):
	material_overlay = highlight_overlay_material if flag else null

func move_off():
	if tween != null:
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", calc_target_pos() + Vector3.UP * 10, 0.4)
	tween.tween_callback(self.queue_free)
