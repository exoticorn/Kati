extends PanelContainer

const PRESETS = {
	"Rapid 5x5": {
		"size": 5,
		"time": 12,
		"inc": 10,
	},
	"Rapid 6x6": {
		"size": 6,
		"time": 15,
		"inc": 10,
	},
	"Rapid 7x7": {
		"size": 7,
		"time": 20,
		"inc": 15
	},
	"Blitz 5x5": {
		"size": 5,
		"time": 5,
		"inc": 5,
	},
	"Blitz 6x6": {
		"size": 6,
		"time": 5,
		"inc": 5
	},
	"League Match": {
		"size": 6,
		"time": 15,
		"inc": 10,
		"extra_move": 35,
		"extra_time": 5,
		"tournament": true
	},
	"Beginner Tournament": {
		"size": 6,
		"time": 15,
		"inc": 10,
		"komi": 0,
		"tournament": true
	},
	"Intermediate Tournament": {
		"size": 6,
		"time": 15,
		"inc": 10,
		"tournament": true
	}
}

var _playtak: PlaytakInterface
var _has_seek := false

func setup(playtak: PlaytakInterface):
	_playtak = playtak
	playtak.players_changed.connect(_on_players_changed)

func _ready():
	for preset in PRESETS:
		%Preset.add_item(preset)

func _on_preset_item_selected(_index: int) -> void:
	update()

func _on_players_changed():
	update()

func update():
	%Message.text = ""
	if _has_seek:
		%Preset.disabled = true
		%Opponent.editable = false
		%Color.disabled = true
		%GameType.disabled = true
		%GameType.disabled = true
		%Size.disabled = true
		%Komi.disabled = true
		%Time.editable = false
		%Increment.editable = false
		%ExtraMove.editable = false
		%ExtraTime.editable = false
		%ConfirmButton.text = "Cancel Seek"
		%ConfirmButton.disabled = false
	else:
		%Preset.disabled = false
		%Opponent.editable = true
		%Color.disabled = false
		%GameType.disabled = false
		var preset_index = %Preset.selected
		var disabled = preset_index != 0
		%GameType.disabled = disabled
		%Size.disabled = disabled
		%Komi.disabled = disabled
		%Time.editable = !disabled
		%Increment.editable = !disabled
		%ExtraMove.editable = !disabled
		%ExtraTime.editable = !disabled
		if disabled:
			var preset: Dictionary = PRESETS[%Preset.get_item_text(preset_index)]
			%GameType.selected = 1 if preset.get("tournament", false) else 0
			%Size.selected = preset.size - 3
			%Komi.selected = roundi(preset.get("komi", 2) * 2)
			%Time.value = preset.time
			%Increment.value = preset.inc
			%ExtraMove.value = preset.get("extra_move", 0)
			%ExtraTime.value = preset.get("extra_time", 0)
		
		var is_valid = true
		var opponent: String = %Opponent.text
		if %GameType.selected == 1 && opponent.is_empty():
			set_error_message("A tournament game requires an opponent")
			is_valid = false
		elif !opponent.is_empty() && _playtak.online_players.find(opponent) < 0:
			set_warning_message("No online player with name '%s'" % opponent)
		%ConfirmButton.text = "Post Seek"
		%ConfirmButton.disabled = !is_valid

func set_error_message(msg):
	%Message.text = msg
	%Message.add_theme_color_override("font_color", Color.RED)

func set_warning_message(msg):
	%Message.text = msg
	%Message.add_theme_color_override("font_color", Color.YELLOW)

func _on_opponent_text_changed(_new_text: String) -> void:
	update()

func _on_confirm_button_pressed() -> void:
	var seek := PlaytakInterface.Seek.new()
	if _has_seek:
		seek.user = "0"
		seek.rules = Common.GameRules.new(0, 0, 0, 0)
		seek.clock = Common.ClockSettings.new(0, 0)
		seek.color = PlaytakInterface.ColorChoice.NONE
		seek.game_type = PlaytakInterface.GameType.RATED
	else:
		seek.user = %Opponent.text
		if seek.user.is_empty():
			seek.user = "0"
		seek.rules = Common.GameRules.new(%Size.selected + 3, %Komi.selected)
		seek.clock = Common.ClockSettings.new(%Time.value * 60, %Increment.value, %ExtraMove.value, %ExtraTime.value * 60)
		seek.color = %Color.selected
		seek.game_type = %GameType.selected
	_playtak.send_seek(seek)
	_has_seek = !_has_seek
	update()
