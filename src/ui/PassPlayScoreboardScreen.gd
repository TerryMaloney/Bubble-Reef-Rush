## PassPlayScoreboardScreen — shows sorted final results after Pass & Play.
extends Control

class_name PassPlayScoreboardScreen

@onready var _title_label: Label = $Panel/VBox/TitleLabel
@onready var _results_container: VBoxContainer = $Panel/VBox/Results
@onready var _play_again_btn: Button = $Panel/VBox/PlayAgainButton
@onready var _menu_btn: Button = $Panel/VBox/MenuButton

var _session: PassPlaySession = null


func _ready() -> void:
	# When loaded via TransitionLayer, GameManager deposits the session here.
	if GameManager.pending_pass_play_session != null:
		var s: PassPlaySession = GameManager.pending_pass_play_session
		GameManager.pending_pass_play_session = null
		setup(s)


func setup(session: PassPlaySession) -> void:
	_session = session
	_title_label.text = "Reef Results!"
	if not _play_again_btn.pressed.is_connected(_on_play_again):
		_play_again_btn.pressed.connect(_on_play_again)
	if not _menu_btn.pressed.is_connected(_on_menu):
		_menu_btn.pressed.connect(_on_menu)
	_populate_results()

	# Save tournament history.
	var profile: String = SaveSystem.get_active_profile_id()
	var tournament_entry: Dictionary = {
		"date": Time.get_date_string_from_system(),
		"level_id": session.level_id,
		"results": session.get_results()
	}
	SaveSystem.add_tournament_entry(profile, tournament_entry)


func _populate_results() -> void:
	for child: Node in _results_container.get_children():
		child.queue_free()
	var results: Array[Dictionary] = _session.get_results()
	for i: int in range(results.size()):
		var entry: Dictionary = results[i]
		var row: Label = Label.new()
		var medal: String = ["🥇 ", "🥈 ", "🥉 ", "   "][mini(i, 3)]
		row.text = "%s%s — %d pts  [%s]" % [
			medal,
			str(entry.get("profile_id", "?")),
			int(entry.get("total_score", 0)),
			str(entry.get("funny_title", ""))
		]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_results_container.add_child(row)


func _on_play_again() -> void:
	if _session != null:
		var new_session: PassPlaySession = PassPlaySession.new()
		new_session.setup(_session.profiles, _session.level_id, int(_session.mode))
		GameManager.start_pass_play(new_session)
	queue_free()


func _on_menu() -> void:
	queue_free()
	GameManager.go_to_menu()
