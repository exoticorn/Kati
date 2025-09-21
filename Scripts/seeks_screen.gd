extends PanelContainer

class SeekRow:
	var seek: PlaytakInterface.Seek
	var controls: Array[Control]

var playtak: PlaytakInterface
var seeks: Array[SeekRow]

func set_playtak(p: PlaytakInterface):
	playtak = p
	playtak.seeks_changed.connect(sync_seeks)

func sync_seeks():
	var seek_index = seeks.size() - 1
	while seek_index >= 0:
		var seek = seeks[seek_index]
		var found = false
		for s in playtak.seeks:
			if s.id == seek.seek.id:
				found = true
				break
		if !found:
			for c in seek.controls:
				c.queue_free()
			seeks.remove_at(seek_index)
		seek_index -= 1
	
	for seek in playtak.seeks:
		var found = false
		for s in seeks:
			if seek.id == s.seek.id:
				found = true
				break
		if !found:
			var s = SeekRow.new()
			s.seek = seek
			var name_ = LinkButton.new()
			name_.text = seek.user
			name_.pressed.connect(playtak.accept_seek.bind(seek.id))
			s.controls.push_back(name_)
			var rules = Label.new()
			var rules_string = "%dx%d" % [seek.size, seek.size]
			if seek.komi != 0:
				var half_komi = roundi(seek.komi * 2)
				if half_komi % 2 == 0:
					rules_string += ", %d Komi" % roundi(seek.komi)
				else:
					rules_string += ", %.1f Komi" % seek.komi
			rules.text = rules_string
			s.controls.push_back(rules)
			var time = Label.new()
			var time_string = "%d+%d" % [seek.time, seek.inc]
			time.text = time_string
			s.controls.push_back(time)

			seeks.push_back(s)
			for c in s.controls:
				$MainBox/Seeks.add_child(c)
