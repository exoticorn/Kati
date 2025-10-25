extends PanelContainer

const GameRules = Common.GameRules
const ClockSettings = Common.ClockSettings

func setup(rules: GameRules, clock: ClockSettings):
	var text = ""
	if rules.half_komi > 0:
		text = "Komi %s | " % Common.format_komi(rules.half_komi)
	$Label.text = text + clock.format()
