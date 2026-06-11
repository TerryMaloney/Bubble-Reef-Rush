## DailyDiveScreen — displays today's three Daily Dive levels and saves results.
## get_today_levels() is deterministic: same output for the whole calendar day.
extends Control

class_name DailyDiveScreen

var _today_levels: Array[String] = []


func _ready() -> void:
	$Panel/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Panel/VBox/CloseButton.pressed.connect(func() -> void: queue_free())
	_populate_ui()


func _populate_ui() -> void:
	var date: String = Time.get_date_string_from_system()
	$Panel/VBox/DateLabel.text = date

	_today_levels = get_today_levels()
	var profile: String = SaveSystem.get_active_profile_id()
	var history: Dictionary = SaveSystem.get_daily_dive_history(profile)

	var labels: Array[Label] = [
		$Panel/VBox/LevelsContainer/Level1Row/Level1Id as Label,
		$Panel/VBox/LevelsContainer/Level2Row/Level2Id as Label,
		$Panel/VBox/LevelsContainer/Level3Row/Level3Id as Label,
	]
	var score_labels: Array[Label] = [
		$Panel/VBox/LevelsContainer/Level1Row/Level1Score as Label,
		$Panel/VBox/LevelsContainer/Level2Row/Level2Score as Label,
		$Panel/VBox/LevelsContainer/Level3Row/Level3Score as Label,
	]

	for i: int in range(_today_levels.size()):
		labels[i].text = _today_levels[i]
		var best: int = int((history.get(_today_levels[i], {}) as Dictionary).get("best_score", 0))
		score_labels[i].text = "Best: %d" % best if best > 0 else ""


func _on_start_pressed() -> void:
	if _today_levels.is_empty():
		return
	GameManager.start_level(_today_levels[0])
	queue_free()


func get_today_levels() -> Array[String]:
	var date: String = Time.get_date_string_from_system()
	var seed: int = DeterministicSeed.date_seed(date)
	return DeterministicSeed.pick_levels(seed, 3, [1, 6])


func complete_dive(profile_id: String, score: int) -> void:
	var date: String = Time.get_date_string_from_system()
	SaveSystem.set_daily_dive_result(profile_id, date, score)
	EventBus.daily_dive_completed.emit(date, score)
