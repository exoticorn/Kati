extends PanelContainer

var _time: float
var time:
	set(t):
		_time = t
		display_time()
		running = false

var seconds := 0

var running := false

func setup(name_: String, initial_time: float):
	$Box/Name.text = name_
	_time = initial_time
	display_time()

func _process(delta: float):
	if running:
		_time -= delta
		display_time()

func display_time():
	var s = ceili(_time)
	if s == seconds:
		return
	seconds = s
	$Box/Time.text = "%d:%02d" % [s / 60, s % 60]
