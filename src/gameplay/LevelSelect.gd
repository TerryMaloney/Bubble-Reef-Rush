extends Control

class_name LevelSelect

const ZONE_NAMES: Dictionary = {
	"z1": "Sunlit Shallows",
	"z2": "Kelp Forest Canyon",
	"z3": "Shipwreck Alley",
	"z4": "Volcanic Vent Fields",
	"z5": "Twilight Trench",
	"z6": "Ancient Sunken Factory",
	"sb": "Space Bubble",
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
	"z6": ["Pipe Maze", "Mirror Tanks", "Steam Burst", "Pressure Valve",
		   "Dark Assembly", "Reactor Core", "Factory Gauntlet", "Systems Offline"],
	"sb": ["Gravity Ballet", "Nebula Drift", "Comet Trail", "Star Cluster",
		   "Void Sprint", "Plasma Wave", "Dark Matter", "Space Finale"],
}

const DIFFICULTY_LABELS: Dictionary = {"easy": "Easy", "normal": "Normal", "hard": "Hard"}
const DIFFICULTY_ORDER: Array = ["easy", "normal", "hard"]

var _profile: String = ""
var _selected_difficulty: String = "normal"
var _diff_btns: Dictionary = {}  # difficulty -> Button
var _level_container: VBoxContainer = null
var _selected_mutators: Array[String] = []
var _mutator_defs: Array = []


func _ready() -> void:
	_profile = SaveSystem.get_active_profile_id()
	_selected_difficulty = GameManager.active_difficulty
	var zone_id: String = GameManager.current_zone_id
	$ZoneTitle.text = ZONE_NAMES.get(zone_id, zone_id.to_upper()) as String
	$BackButton.pressed.connect(func() -> void: GameManager.go_to_zone_select())
	_build_difficulty_row(zone_id)
	_load_mutator_defs()
	_build_mutator_strip()
	_build_level_list(zone_id)


func _build_difficulty_row(zone_id: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size = Vector2(0.0, 80.0)

	for diff: String in DIFFICULTY_ORDER:
		var btn: Button = Button.new()
		btn.text = DIFFICULTY_LABELS[diff] as String
		btn.custom_minimum_size = Vector2(260.0, 88.0)
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
		# Space Bubble levels live in assets/levels/space/ with a different ID scheme.
		var level_id: String = "space/sb_l%d" % (i + 1) if zone_id == "sb" else "%s-l%d" % [zone_id, i + 1]
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
			btn.pressed.connect(func() -> void: _launch_level(lid))

		container.add_child(btn)


func _launch_level(level_id: String) -> void:
	MutatorSystem.active_mutators = _selected_mutators.duplicate()
	GameManager.start_level(level_id)


func _load_mutator_defs() -> void:
	var file: FileAccess = FileAccess.open("res://assets/data/mutators.json", FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Array:
		_mutator_defs = json.data as Array
	file.close()


func _build_mutator_strip() -> void:
	var unlocked: Array = []
	for d: Variant in _mutator_defs:
		var def: Dictionary = d as Dictionary
		var cond: String = str(def.get("unlock_condition", "default"))
		if _is_mutator_unlocked(cond):
			unlocked.append(def)
	if unlocked.is_empty():
		return
	var parent: Node = $LevelContainer.get_parent()
	var insert_idx: int = $LevelContainer.get_index()

	var strip_label: Label = Label.new()
	strip_label.text = "Challenges:"
	strip_label.add_theme_font_size_override("font_size", 24)
	strip_label.modulate = Color(0.7, 0.9, 1.0)
	parent.add_child(strip_label)
	parent.move_child(strip_label, insert_idx)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 80.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var strip: HBoxContainer = HBoxContainer.new()
	strip.add_theme_constant_override("separation", 12)
	scroll.add_child(strip)
	parent.add_child(scroll)
	parent.move_child(scroll, $LevelContainer.get_index())

	for def: Variant in unlocked:
		var d: Dictionary = def as Dictionary
		var mid: String = str(d.get("id", ""))
		var btn: Button = Button.new()
		btn.text = str(d.get("name", mid))
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0.0, 72.0)
		btn.add_theme_font_size_override("font_size", 22)
		btn.toggled.connect(func(on: bool) -> void: _on_mutator_toggled(mid, on))
		strip.add_child(btn)


func _is_mutator_unlocked(cond: String) -> bool:
	if cond == "default":
		return true
	if cond.begins_with("clear_"):
		var level_id: String = cond.substr("clear_".length()).replace("_l", "-l")
		return SaveSystem.is_level_cleared(_profile, level_id)
	return false


func _on_mutator_toggled(mutator_id: String, enabled: bool) -> void:
	if enabled:
		if mutator_id not in _selected_mutators:
			_selected_mutators.append(mutator_id)
	else:
		_selected_mutators.erase(mutator_id)


func _diff_badge(stars: int) -> String:
	match stars:
		3: return "[★★★]"
		2: return "[★★ ]"
		1: return "[★  ]"
		_: return "[   ]"
