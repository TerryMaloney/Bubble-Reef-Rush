## PassPlayNextPlayerScreen — full-screen handoff between players.
## Shows who's up next, their name, and the previous player's result.
## Works as a full scene (loaded via TransitionLayer) reading state from GameManager.
extends Control

class_name PassPlayNextPlayerScreen

@onready var _player_label: Label = $Panel/VBox/PlayerLabel
@onready var _result_label: Label = $Panel/VBox/ResultLabel
@onready var _start_btn: Button = $Panel/VBox/StartButton

var _on_start: Callable


func _ready() -> void:
	var session: PassPlaySession = GameManager.active_pass_play_session
	if session != null:
		_player_label.text = "Next up:\n%s" % session.get_current_profile()
		var prev: String = GameManager.pp_prev_profile
		if prev.is_empty():
			_result_label.text = "Good luck!"
		else:
			_result_label.text = "%s scored %d — your turn!" % [prev, GameManager.pp_prev_score]
	_start_btn.pressed.connect(_on_start_pressed)


## Legacy setup() for when the screen is used as an overlay.
func setup(next_profile: String, prev_profile: String, prev_score: int, callback: Callable) -> void:
	_on_start = callback
	_player_label.text = "Next up:\n%s" % next_profile
	if prev_profile.is_empty():
		_result_label.text = "Good luck!"
	else:
		_result_label.text = "%s scored %d — your turn!" % [prev_profile, prev_score]


func _on_start_pressed() -> void:
	if _on_start.is_valid():
		_on_start.call()
	elif GameManager.active_pass_play_session != null:
		# Switch active profile to the next player before starting the level.
		SaveSystem.set_active_profile(GameManager.active_pass_play_session.get_current_profile())
		GameManager.start_level(GameManager.active_pass_play_session.level_id)
	else:
		GameManager.go_to_menu()
	queue_free()
