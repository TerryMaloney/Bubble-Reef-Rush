## AchievementSystem — autoload that evaluates data-driven achievement and
## character-unlock rules against the player's save data.
## Rules are defined in assets/data/achievements.json.
extends Node

const ACHIEVEMENTS_PATH: String = "res://assets/data/achievements.json"
const LEVELS_PER_ZONE: int = 8

var _data: Dictionary = {}
var _session_max_combo: int = 0


func _ready() -> void:
	_load_data()
	EventBus.fever_started.connect(_on_fever_started)


func _load_data() -> void:
	if not ResourceLoader.exists(ACHIEVEMENTS_PATH):
		push_warning("AchievementSystem: achievements.json not found at " + ACHIEVEMENTS_PATH)
		return
	var file: FileAccess = FileAccess.open(ACHIEVEMENTS_PATH, FileAccess.READ)
	if file == null:
		push_error("AchievementSystem: Cannot open achievements.json")
		return
	var json: JSON = JSON.new()
	var err: Error = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("AchievementSystem: JSON parse error: " + json.get_error_message())
		return
	_data = json.data as Dictionary


## Evaluate all achievement and character rules after a run completes.
## Call AFTER SaveSystem.update_level_result() so level results are current.
func evaluate_run(profile_id: String, _level_id: String, _score: int, _stars: int) -> void:
	if _data.is_empty():
		return
	var all_results: Dictionary = SaveSystem.get_all_level_results(profile_id)

	for ach: Variant in (_data.get("achievements", []) as Array):
		var ach_dict: Dictionary = ach as Dictionary
		var id: String = str(ach_dict.get("id", ""))
		if id.is_empty() or SaveSystem.get_achievement(profile_id, id):
			continue
		if _evaluate_rule(ach_dict, profile_id, all_results):
			SaveSystem.set_achievement(profile_id, id)
			EventBus.achievement_unlocked.emit(id, str(ach_dict.get("name", id)))
			AchievementToast.show_achievement(str(ach_dict.get("name", id)), str(ach_dict.get("desc", "")))

	for char_def: Variant in (_data.get("characters", []) as Array):
		var char_dict: Dictionary = char_def as Dictionary
		var char_id: String = str(char_dict.get("id", ""))
		if char_id.is_empty() or char_id == "default_fish":
			continue
		if SaveSystem.get_character_unlocked(profile_id, char_id):
			continue
		if _evaluate_rule(char_dict, profile_id, all_results):
			SaveSystem.set_character_unlocked(profile_id, char_id)
			AchievementToast.show_achievement(str(char_dict.get("name", char_id)) + " Unlocked!", str(char_dict.get("desc", "")))


## Get all achievement definitions (for UI display).
func get_all_achievements() -> Array:
	return _data.get("achievements", []) as Array


## Get all character definitions (for roster UI).
func get_all_characters() -> Array:
	return _data.get("characters", []) as Array


## Check if a single rule passes for the given profile.
func check_rule(rule_def: Dictionary, profile_id: String) -> bool:
	var all_results: Dictionary = SaveSystem.get_all_level_results(profile_id)
	return _evaluate_rule(rule_def, profile_id, all_results)


func _evaluate_rule(rule_def: Dictionary, profile_id: String, all_results: Dictionary) -> bool:
	var rule: String = str(rule_def.get("rule", ""))
	match rule:
		"default":
			return true
		"zone_cleared":
			return _zone_cleared(str(rule_def.get("zone", "")), all_results)
		"three_star_zone":
			return _three_star_zone(str(rule_def.get("zone", "")), all_results)
		"stars_total":
			return SaveSystem.get_total_stars(profile_id) >= int(rule_def.get("threshold", 0))
		"levels_cleared":
			return _count_cleared(all_results) >= int(rule_def.get("threshold", 0))
		"combo_reached":
			return _session_max_combo >= int(rule_def.get("threshold", 0))
		"treasure_coins_total":
			return SaveSystem.count_treasure_coins(profile_id) >= int(rule_def.get("threshold", 0))
		"three_star_count":
			return _three_star_count_zone(str(rule_def.get("zone", "")), all_results) >= int(rule_def.get("threshold", 0))
	return false


func _zone_cleared(zone: String, all_results: Dictionary) -> bool:
	for i: int in range(1, LEVELS_PER_ZONE + 1):
		var lid: String = "%s-l%d" % [zone, i]
		if not all_results.has(lid):
			return false
		if int((all_results[lid] as Dictionary).get("best_stars", 0)) < 1:
			return false
	return true


func _three_star_zone(zone: String, all_results: Dictionary) -> bool:
	for i: int in range(1, LEVELS_PER_ZONE + 1):
		var lid: String = "%s-l%d" % [zone, i]
		if not all_results.has(lid):
			return false
		if int((all_results[lid] as Dictionary).get("best_stars", 0)) < 3:
			return false
	return true


func _three_star_count_zone(zone: String, all_results: Dictionary) -> int:
	var count: int = 0
	for i: int in range(1, LEVELS_PER_ZONE + 1):
		var lid: String = "%s-l%d" % [zone, i]
		if not all_results.has(lid):
			continue
		if int((all_results[lid] as Dictionary).get("best_stars", 0)) == 3:
			count += 1
	return count


func _count_cleared(all_results: Dictionary) -> int:
	var count: int = 0
	for level_data: Variant in all_results.values():
		if int((level_data as Dictionary).get("best_stars", 0)) >= 1:
			count += 1
	return count


func _on_fever_started() -> void:
	_session_max_combo = maxi(_session_max_combo, 30)
