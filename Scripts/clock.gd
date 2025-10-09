extends PanelContainer

var _time: float
var time:
	set(t):
		_time = t
		display_time()
		running = false

var seconds := 0

var running := false

var is_local_player := false
var samples = []

func setup(playtak: PlaytakInterface, name_: String, initial_time: float, is_local_player_: bool):
	$Box/Name.setup(playtak)
	$Box/Name.user = name_
	_time = initial_time
	display_time()
	is_local_player = is_local_player_
	if is_local_player:
		samples = [
			load("res://sfx/1s.wav"),
			load("res://sfx/2s.wav"),
			load("res://sfx/3s.wav"),
			load("res://sfx/4s.wav"),
			load("res://sfx/5s.wav"),
			load("res://sfx/10s.wav"),
		]

func _process(delta: float):
	if running:
		_time = max(0, _time - delta)
		display_time()

func display_time():
	var s = ceili(_time)
	if s == seconds:
		return
	if is_local_player && s < seconds:
		var sample = null
		if s == 10:
			sample = samples[5]
		elif s >= 0 && s <= 5:
			sample = samples[s - 1]
		if sample:
			$AudioStreamPlayer.stream = sample
			$AudioStreamPlayer.play()
	seconds = s
	$Box/Time.text = "%d:%02d" % [s / 60, s % 60]
