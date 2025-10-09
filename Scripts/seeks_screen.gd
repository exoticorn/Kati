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
			rules.text = seek.rules.format()
			s.controls.push_back(rules)
			var time = Label.new()
			time.text = seek.clock.format()
			s.controls.push_back(time)

			seeks.push_back(s)
			for c in s.controls:
				$MainBox/Seeks.add_child(c)
