## PassPlayNextPlayerScreen — full-screen handoff between players.
## Shows who's up next, their name, and the previous player's result.
extends Control

class_name PassPlayNextPlayerScreen

@onready var _player_label: Label = $Panel/VBox/PlayerLabel
@onready var _result_label: Label = $Panel/VBox/ResultLabel
@onready var _start_btn: Button = $Panel/VBox/StartButton

var _on_start: Callable


func setup(next_profile: String, prev_profile: String, prev_score: int, callback: Callable) -> void:
	_on_start = callback
	_player_label.text = "Next up:\n%s" % next_profile
	if prev_profile.is_empty():
		_result_label.text = "Good luck!"
	else:
		_result_label.text = "%s scored %d — your turn!" % [prev_profile, prev_score]
	_start_btn.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	if _on_start.is_valid():
		_on_start.call()
	queue_free()
