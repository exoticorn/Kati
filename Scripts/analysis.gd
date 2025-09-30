extends PanelContainer

var move_count: int = 0

func set_info(info: EngineInterface.MoveInfo):
	$Box/Move.text = info.move.to_ptn()
	var score = ""
	if info.score_is_winrate:
		score = "%d%%" % roundi(info.score * 100)
	else:
		score = "%.2f" % info.score
	$Box/Score.text = "%s | %d/%d" % [score, info.depth, info.seldepth]
	var pv = []
	for move in info.pv:
		pv.push_back(move.to_ptn())
	$Box/PV.text = " ".join(pv)
