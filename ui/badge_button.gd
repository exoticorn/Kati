extends MarginContainer

const StyleZero = preload("res://ui/badge_zero_style.tres")
const StyleNonZero = preload("res://ui/badge_nonzero_style.tres")
const StyleRed = preload("res://ui/badge_red_style.tres")

var _text: String
@export var text: String:
	set(t):
		_text = t
		update()
	get():
		return _text

var _count: int
@export var count: int:
	set(c):
		_count = c
		update()
	get():
		return _count

var _red: bool
@export var red: bool:
	set(r):
		_red = r
		update()
	get():
		return _red

signal pressed

func _ready():
	$Button.pressed.connect(pressed.emit)
	update()

func update():
	if !is_inside_tree():
		return
	$Margins/HBox/Label.text = _text
	$Margins/HBox/Badge.text = str(_count)
	var style := StyleZero
	if _count > 0:
		style = StyleRed if _red else StyleNonZero
	$Margins/HBox/Badge.add_theme_stylebox_override("normal", style)
