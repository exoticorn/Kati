extends Control

enum Action {
	REQUEST_UNDO,
	REMOVE_UNDO,
	OFFER_DRAW,
	REMOVE_DRAW,
	RESIGN
}

signal send_action(action: Action)

var has_requested_undo := false
var has_offered_draw := false

func _on_undo_pressed() -> void:
	send_action.emit(Action.REMOVE_UNDO if has_requested_undo else Action.REQUEST_UNDO)
	has_requested_undo = !has_requested_undo

func _on_draw_pressed() -> void:
	send_action.emit(Action.REMOVE_DRAW if has_offered_draw else Action.OFFER_DRAW)
	has_offered_draw = !has_offered_draw

func _on_resign_pressed() -> void:
	if !$Resign.button_pressed:
		send_action.emit(Action.RESIGN)

func reset():
	$Undo.button_pressed = false
	$Resign.button_pressed = false
	has_requested_undo = false

func receive_action(action: Action):
	match action:
		Action.REQUEST_UNDO: $Undo.button_pressed = true
		Action.REMOVE_UNDO: $Undo.button_pressed = false
		Action.OFFER_DRAW: $Draw.button_pressed = true
		Action.REMOVE_DRAW: $Draw.button_pressed = false
