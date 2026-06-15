extends Control

class_name ResultsScreen

const LEVELS_PER_ZONE: int = 8


func _ready() -> void:
	var score: int = GameManager.last_score
	var stars: int = GameManager.last_stars

	$Center/VBox/StarsLabel.text = _stars_text(stars)
	$Center/VBox/ScoreLabel.text = "Score: %d" % score
	$Center/VBox/BestScoreLabel.text = _best_score_text(score)

	var coins: int = GameManager.last_coins_earned
	$Center/VBox/CoinsLabel.text = "+%d coins" % coins
	$Center/VBox/CoinsLabel.visible = coins > 0

	_show_ghost_delta(score)
	_show_rule_card_results()
	_show_copilot_contribution()
	_setup_next_level_button()

	$Center/VBox/RetryButton.pressed.connect(_on_retry_pressed)
	$Center/VBox/LevelsButton.pressed.connect(_on_levels_pressed)
	$Center/VBox/MenuButton.pressed.connect(_on_menu_pressed)


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
	var btn: Button = $Center/VBox/NextLevelButton
	var current_id: String = GameManager.current_level_id
	# User-created levels have no campaign "next level".
	if current_id.begins_with("user://"):
		btn.visible = false
		return
	var next_id: String = _next_level_id(current_id)
	if next_id.is_empty():
		btn.disabled = true
		btn.text = "ZONE COMPLETE!"
	else:
		btn.disabled = false
		btn.pressed.connect(func() -> void: GameManager.start_level(next_id))


func _next_level_id(level_id: String) -> String:
	# Space Bubble levels: space/sb_l1 → space/sb_l2, etc.
	if level_id.begins_with("space/sb_l"):
		var num_str: String = level_id.substr("space/sb_l".length())
		if not num_str.is_valid_int():
			return ""
		var num: int = num_str.to_int()
		if num >= LEVELS_PER_ZONE:
			return ""
		var next_id: String = "space/sb_l%d" % (num + 1)
		return next_id if FileAccess.file_exists("res://assets/levels/%s.brl" % next_id) else ""
	# Standard levels: z1-l1 → z1-l2, etc.
	var parts: PackedStringArray = level_id.split("-")
	if parts.size() != 2:
		return ""
	var zone_part: String = parts[0]
	var level_part: String = parts[1]
	if not level_part.begins_with("l"):
		return ""
	var level_num_str: String = level_part.substr(1)
	if not level_num_str.is_valid_int():
		return ""
	var level_num: int = level_num_str.to_int()
	if level_num >= LEVELS_PER_ZONE:
		return ""
	var next_id: String = "%s-l%d" % [zone_part, level_num + 1]
	if not FileAccess.file_exists("res://assets/levels/%s.brl" % next_id):
		return ""
	return next_id


func _on_retry_pressed() -> void:
	GameManager.start_level(GameManager.current_level_id)


func _on_levels_pressed() -> void:
	var level_id: String = GameManager.current_level_id
	var zone_id: String = "sb" if level_id.begins_with("space/") else level_id.split("-")[0]
	GameManager.go_to_level_select(zone_id)


func _show_ghost_delta(score: int) -> void:
	var label: Label = $Center/VBox/GhostDeltaLabel
	var ghost_score: int = GhostLibrary.last_ghost_score
	if ghost_score < 0:
		label.visible = false
		return
	var delta: int = score - ghost_score
	label.visible = true
	if delta > 0:
		label.text = "Beat the ghost by %d!" % delta
		label.modulate = Color(0.3, 1.0, 0.4, 1)
	elif delta < 0:
		label.text = "Ghost beat you by %d" % (-delta)
		label.modulate = Color(0.4, 0.8, 1.0, 1)
	else:
		label.text = "Tied the ghost!"
		label.modulate = Color(1, 1, 0.5, 1)


func _show_rule_card_results() -> void:
	var container: VBoxContainer = $Center/VBox/RuleCardResults
	var results: Array = RuleCardSystem.last_results
	if results.is_empty():
		container.visible = false
		return
	for entry: Variant in results:
		var d: Dictionary = entry as Dictionary
		var card_id: String = str(d.get("card_id", ""))
		var passed: bool = bool(d.get("passed", false))
		var lbl: Label = Label.new()
		lbl.text = ("%s  ✓" if passed else "%s  ✗") % card_id.replace("_", " ").capitalize()
		lbl.modulate = Color(0.3, 1.0, 0.4) if passed else Color(1.0, 0.4, 0.4)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(lbl)


func _show_copilot_contribution() -> void:
	var contrib: Dictionary = GameManager.last_copilot_contribution
	if contrib.is_empty():
		return
	var activations: int = int(contrib.get("power_activations", 0))
	if activations == 0:
		return
	var lbl: Label = Label.new()
	lbl.text = "Player B: %d power%s activated" % [activations, "s" if activations != 1 else ""]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate = Color(0.6, 0.9, 1.0)
	$Center/VBox/RuleCardResults.add_child(lbl)


func _on_menu_pressed() -> void:
	GameManager.go_to_menu()
