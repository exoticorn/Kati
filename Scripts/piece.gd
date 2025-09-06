extends MeshInstance3D

var white_flat_mesh: Mesh = preload("res://Assets/imported/white flat.res")
var black_flat_mesh: Mesh = preload("res://Assets/imported/black flat.res")
var white_cap_mesh: Mesh = preload("res://Assets/imported/white capstone.res")
var black_cap_mesh: Mesh = preload("res://Assets/imported/black capstone.res")

var flat_aabb: AABB
var type: GameState.Type
var color: GameState.Col
var base_rotation: Quaternion

func _init():
	flat_aabb = white_flat_mesh.get_aabb()

func setup(color: GameState.Col, type: GameState.Type):
	self.color = color
	self.type = type
	match [color, type]:
		[GameState.Col.WHITE, GameState.Type.FLAT], [GameState.Col.WHITE, GameState.Type.WALL]:
			mesh = white_flat_mesh
		[GameState.Col.BLACK, GameState.Type.FLAT], [GameState.Col.BLACK, GameState.Type.WALL]:
			mesh = black_flat_mesh
		[GameState.Col.WHITE, GameState.Type.CAP]:
			mesh = white_cap_mesh
		[GameState.Col.BLACK, GameState.Type.CAP]:
			mesh = black_cap_mesh
	base_rotation = Quaternion.IDENTITY

func place(pos: Vector3i):
	var offset = 0.0
	if type == GameState.Type.FLAT:
		offset = flat_aabb.size.y * 0.5
	elif type == GameState.Type.WALL:
		offset = flat_aabb.size.x * 0.5
	var base_pos = Vector3(pos.x, pos.y * flat_aabb.size.y, -pos.z)
	position = base_pos + Vector3(randf_range(-0.03, 0.03), offset, randf_range(-0.03, 0.03))
	quaternion = base_rotation * Quaternion.from_euler(Vector3(0, randf_range(-0.1, 0.1), 0))
