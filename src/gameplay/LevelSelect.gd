extends Control

class_name LevelSelect

const ZONE_NAMES: Dictionary = {
	"z1": "Sunlit Shallows",
	"z2": "Kelp Forest Canyon",
	"z3": "Shipwreck Alley",
	"z4": "Volcanic Vent Fields",
	"z5": "Twilight Trench",
	"z6": "Crystal Caves",
}

const LEVEL_NAMES: Dictionary = {
	"z1": ["First Dive", "Spike Garden", "Jellyfish Patrol", "Sun Diver",
		   "Double Jelly", "Reef Cluster", "Combo Run", "Sunlit Finale"],
	"z2": ["Kelp Sprint", "Curtain Call", "Mine Field", "Canyon Run",
		   "Tunnel Vision", "Double Hazard", "Long Tunnel", "Kelp Mastery"],
	"z3": ["Wreck Intro", "Jet Stream", "Chain Swing", "Eel Alley",
		   "Hull Breach", "Dense Corridor", "Mixed Wreck", "Dual Eels"],
	"z4": ["Hot Start", "First Eruption", "Mine Burst", "Pressure Drop",
		   "Dual Hazard", "Volcanic Surge", "Heat Wave", "Eruption Finale"],
	"z5": ["Slow Descent", "Dark Passage", "Mirror Run", "Void Mirror",
		   "Full Chaos", "Max Range", "Precision Run", "Trench Master"],
	"z6": ["Shard Intro", "Shard Mirror", "Burst Shard", "Wall Shard",
		   "Dark Shard", "Peak Difficulty", "Triple Gauntlet", "Rainbow Run"],
}

const DIFFICULTY_LABELS: Dictionary = {"easy": "Easy", "normal": "Normal", "hard": "Hard"}
const DIFFICULTY_ORDER: Array = ["easy", "normal", "hard"]

var _profile: String = ""
var _selected_difficulty: String = "normal"
var _diff_btns: Dictionary = {}  # difficulty -> Button
var _level_container: VBoxContainer = null


func _ready() -> void:
	_profile = SaveSystem.get_active_profile_id()
	_selected_difficulty = GameManager.active_difficulty
	var zone_id: String = GameManager.current_zone_id
	$ZoneTitle.text = ZONE_NAMES.get(zone_id, zone_id.to_upper()) as String
	$BackButton.pressed.connect(func() -> void: GameManager.go_to_zone_select())
	_build_difficulty_row(zone_id)
	_build_level_list(zone_id)


func _build_difficulty_row(zone_id: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size = Vector2(0.0, 80.0)

	for diff: String in DIFFICULTY_ORDER:
		var btn: Button = Button.new()
		btn.text = DIFFICULTY_LABELS[diff] as String
		btn.custom_minimum_size = Vector2(260.0, 76.0)
		btn.add_theme_font_size_override("font_size", 28)
		var d: String = diff  # capture
		btn.pressed.connect(func() -> void: _on_difficulty_selected(d, zone_id))
		_diff_btns[diff] = btn
		row.add_child(btn)

	$LevelContainer.get_parent().add_child(row)
	$LevelContainer.get_parent().move_child(row, $LevelContainer.get_index())
	_level_container = $LevelContainer
	_refresh_difficulty_row(zone_id)


func _refresh_difficulty_row(zone_id: String) -> void:
	for diff: String in DIFFICULTY_ORDER:
		var btn: Button = _diff_btns[diff] as Button
		var locked: bool = _is_difficulty_locked(zone_id, diff)
		btn.disabled = locked
		if diff == _selected_difficulty:
			btn.modulate = Color(0.3, 1.0, 0.5)
		elif locked:
			btn.modulate = Color(0.5, 0.5, 0.5)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)


func _is_difficulty_locked(zone_id: String, difficulty: String) -> bool:
	if difficulty == "easy":
		return false
	var prev_diff: String = "easy" if difficulty == "normal" else "normal"
	# Unlock difficulty if any level in this zone has cleared the previous difficulty.
	for i: int in range(1, 9):
		var level_id: String = "%s-l%d" % [zone_id, i]
		if SaveSystem.is_difficulty_cleared(_profile, level_id, prev_diff):
			return false
	return true


func _on_difficulty_selected(difficulty: String, zone_id: String) -> void:
	_selected_difficulty = difficulty
	GameManager.active_difficulty = difficulty
	_refresh_difficulty_row(zone_id)
	_rebuild_level_list(zone_id)


func _rebuild_level_list(zone_id: String) -> void:
	if _level_container == null:
		return
	for c: Node in _level_container.get_children():
		c.queue_free()
	await get_tree().process_frame
	_build_level_list(zone_id)


func _build_level_list(zone_id: String) -> void:
	var container: VBoxContainer = $LevelContainer
	var results: Dictionary = SaveSystem.get_all_level_results(_profile)
	var names: Array = LEVEL_NAMES.get(zone_id, []) as Array

	for i: int in range(8):
		var level_id: String = "%s-l%d" % [zone_id, i + 1]
		var level_name: String = names[i] as String if i < names.size() else "Level %d" % (i + 1)
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 88)

		var level_exists: bool = FileAccess.file_exists("res://assets/levels/%s.brl" % level_id)
		if not level_exists:
			btn.text = "L%d  %s  [soon]" % [i + 1, level_name]
			btn.disabled = true
		else:
			var entry: Dictionary = results.get(level_id, {}) as Dictionary
			var stars: int = SaveSystem.get_difficulty_stars(_profile, level_id, _selected_difficulty)
			var best_pct: float = float(entry.get("best_progress_pct", 0.0))
			var best_score: int = int(entry.get("best_score", 0))
			var pct_text: String = ""
			if stars > 0:
				pct_text = "  best 100%"
			elif best_pct > 0.0:
				pct_text = "  best %.0f%%" % best_pct
			var score_text: String = ""
			if best_score > 0:
				score_text = "  %d pts" % best_score
			var ghost_marker: String = ""
			if not GhostLibrary.load_ghost(_profile, level_id, "personal_best").is_empty():
				ghost_marker = " ★"
			var diff_badge: String = _diff_badge(stars)
			btn.text = "L%d  %s  %s%s%s%s" % [i + 1, level_name, diff_badge, pct_text, score_text, ghost_marker]
			var lid: String = level_id
			btn.pressed.connect(func() -> void: GameManager.start_level(lid))

		container.add_child(btn)


func _diff_badge(stars: int) -> String:
	match stars:
		3: return "[★★★]"
		2: return "[★★ ]"
		1: return "[★  ]"
		_: return "[   ]"
