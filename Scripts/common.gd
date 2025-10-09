class_name Common

const StoneCounts = {
	4: { "flats": 15, "caps": 0 },
	5: { "flats": 21, "caps": 1 },
	6: { "flats": 30, "caps": 1 },
	7: { "flats": 40, "caps": 2 },
	8: { "flats": 50, "caps": 2 }
}

static func format_mins(secs: int) -> String:
	if secs % 60 == 0:
		return str(secs / 60)
	else:
		return "%d:%02d" % [secs / 60, secs % 60]

static func format_secs(secs: int) -> String:
	if secs < 60:
		return str(secs)
	else:
		return "%d:%02d" % [secs / 60, secs % 60]

class ClockSettings:
	var time: int
	var increment: int
	var extra_time_move: int
	var extra_time: int
	
	func _init(t: int, i: int, etm: int = 0, et: int = 0):
		time = t
		increment = i
		extra_time_move = etm
		extra_time = et
	
	func format() -> String:
		var s := Common.format_mins(time)
		if increment > 0:
			s += "+%s" % Common.format_secs(increment)
		if extra_time > 0:
			s += " | %d/+%s" % [extra_time_move, Common.format_mins(extra_time)]
		return s

class GameRules:
	var size: int
	var flats: int
	var caps: int
	var half_komi: int

	func _init(s: int, hk: int = 4, fs: int = -1, cs: int = -1):
		size = s
		half_komi = hk
		flats = fs if fs >= 0 else StoneCounts[s].flats
		caps = cs if cs >= 0 else StoneCounts[s].caps
	
	func format() -> String:
		var s := "%dx%d" % [size, size]
		if half_komi > 0:
			if (half_komi & 1) == 0:
				s += ", Komi %d" % (half_komi / 2)
			else:
				s += ", Komi %.1f" % (half_komi * 0.5)
		if flats != Common.StoneCounts[size].flats || caps != Common.StoneCounts[size].caps:
			s += " [%d/%d]" % [flats, caps] 
		return s
