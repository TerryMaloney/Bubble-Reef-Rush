## PassPlayScoreboardScreen — shows sorted final results after Pass & Play.
extends Control

class_name PassPlayScoreboardScreen

@onready var _title_label: Label = $Panel/VBox/TitleLabel
@onready var _results_container: VBoxContainer = $Panel/VBox/Results
@onready var _next_btn: Button = $Panel/VBox/NextButton
@onready var _play_again_btn: Button = $Panel/VBox/PlayAgainButton
@onready var _menu_btn: Button = $Panel/VBox/MenuButton

var _session: PassPlaySession = null


func _ready() -> void:
	if GameManager.pending_pass_play_session != null:
		var s: PassPlaySession = GameManager.pending_pass_play_session
		GameManager.pending_pass_play_session = null
		setup(s)


func setup(session: PassPlaySession) -> void:
	_session = session
	var any_won: bool = session.any_completed()
	_title_label.text = "Reef Results!" if any_won else "Wiped Out!"

	_next_btn.pressed.connect(_on_next_level)
	_play_again_btn.pressed.connect(_on_play_again)
	_menu_btn.pressed.connect(_on_menu)

	# Show "Next Level" only when someone finished; otherwise only "Try Again".
	if any_won:
		_next_btn.text = "Next Level! ▶"
		_next_btn.show()
		_play_again_btn.text = "Same Level"
	else:
		_next_btn.hide()
		_play_again_btn.text = "Try Again!"

	_populate_results()

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
		var completed: bool = bool(entry.get("completed", false))
		var row: Label = Label.new()
		var crown: String = ""
		if i == 0 and completed:
			crown = "👑 WINNER  "
		elif not completed:
			crown = "💀 "
		else:
			crown = ["🥇 ", "🥈 ", "🥉 ", "   "][mini(i, 3)]
		row.text = "%s%s — %d pts  [%s]" % [
			crown,
			str(entry.get("profile_id", "?")),
			int(entry.get("total_score", 0)),
			str(entry.get("funny_title", ""))
		]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 28)
		_results_container.add_child(row)


func _on_next_level() -> void:
	var next: String = _next_level_id(_session.level_id)
	if next.is_empty():
		# No next level — fall back to play again on same.
		_on_play_again()
		return
	var new_session: PassPlaySession = PassPlaySession.new()
	new_session.setup(_session.profiles, next, int(_session.mode))
	GameManager.start_pass_play(new_session)
	queue_free()


func _on_play_again() -> void:
	if _session != null:
		var new_session: PassPlaySession = PassPlaySession.new()
		new_session.setup(_session.profiles, _session.level_id, int(_session.mode))
		GameManager.start_pass_play(new_session)
	queue_free()


func _on_menu() -> void:
	queue_free()
	GameManager.go_to_menu()


static func _next_level_id(level_id: String) -> String:
	var parts: PackedStringArray = level_id.split("-")
	if parts.size() != 2:
		return ""
	var zone: int = int(parts[0].lstrip("z"))
	var lvl: int = int(parts[1].lstrip("l"))
	var candidate: String = "z%d-l%d" % [zone, lvl + 1]
	if FileAccess.file_exists("res://assets/levels/%s.brl" % candidate):
		return candidate
	candidate = "z%d-l1" % [zone + 1]
	if FileAccess.file_exists("res://assets/levels/%s.brl" % candidate):
		return candidate
	return ""
