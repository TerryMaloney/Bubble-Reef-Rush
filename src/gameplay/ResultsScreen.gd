extends Control

class_name ResultsScreen

const LEVELS_PER_ZONE: int = 8


func _ready() -> void:
	var score: int = GameManager.last_score
	var stars: int = GameManager.last_stars

	$StarsLabel.text = _stars_text(stars)
	$ScoreLabel.text = "Score: %d" % score
	$BestScoreLabel.text = _best_score_text(score)

	_setup_next_level_button()

	$RetryButton.pressed.connect(_on_retry_pressed)
	$LevelsButton.pressed.connect(_on_levels_pressed)
	$MenuButton.pressed.connect(_on_menu_pressed)


func _stars_text(stars: int) -> String:
	match stars:
		3: return "* * *"
		2: return "* *"
		1: return "*"
		_: return "- - -"


func _best_score_text(current_score: int) -> String:
	if GameManager.last_prev_best_score == 0 or current_score > GameManager.last_prev_best_score:
		return "NEW BEST!"
	return "Best: %d" % GameManager.last_prev_best_score


func _setup_next_level_button() -> void:
	var btn: Button = $NextLevelButton
	var next_id: String = _next_level_id(GameManager.current_level_id)
	if next_id.is_empty():
		btn.disabled = true
		btn.text = "ZONE COMPLETE!"
	else:
		btn.disabled = false
		btn.pressed.connect(func() -> void: GameManager.start_level(next_id))


func _next_level_id(level_id: String) -> String:
	# level_id format: "z<zone>-l<index>" e.g. "z1-l1"
	var parts: PackedStringArray = level_id.split("-")
	if parts.size() != 2:
		return ""
	var zone_part: String = parts[0]  # "z1"
	var level_part: String = parts[1]  # "l1"
	if not level_part.begins_with("l"):
		return ""
	var level_num_str: String = level_part.substr(1)
	if not level_num_str.is_valid_int():
		return ""
	var level_num: int = level_num_str.to_int()
	if level_num >= LEVELS_PER_ZONE:
		return ""
	return "%s-l%d" % [zone_part, level_num + 1]


func _on_retry_pressed() -> void:
	GameManager.start_level(GameManager.current_level_id)


func _on_levels_pressed() -> void:
	var zone_id: String = GameManager.current_level_id.split("-")[0]
	GameManager.go_to_level_select(zone_id)


func _on_menu_pressed() -> void:
	GameManager.go_to_menu()
