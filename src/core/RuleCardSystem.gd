## RuleCardSystem — autoload that evaluates active rule cards after a run.
## Active rule cards are set before a run begins via set_active_rules().
## evaluate_run() is called from GameManager/AchievementSystem after run_completed.
## Cards.json is loaded LAZILY on first evaluate_run() call — NOT in _ready() —
## because FileAccess fails silently for late autoloads during _ready() in headless mode.
extends Node

const CARDS_JSON: String = "res://assets/data/rule_cards.json"

var active_rules: Array[String] = []
var _cards_by_id: Dictionary = {}


func _ready() -> void:
	pass  # Lazy load on first use


func set_active_rules(cards: Array) -> void:
	active_rules.clear()
	for c: Variant in cards:
		active_rules.append(str(c))


func evaluate_run(level_id: String, run_data: Dictionary) -> Dictionary:
	if _cards_by_id.is_empty():
		_load_cards()
	var results: Array = []
	var all_passed: bool = true
	for card_id: String in active_rules:
		var passed: bool = _evaluate_rule(card_id, run_data)
		results.append({"card_id": card_id, "passed": passed})
		EventBus.rule_card_result.emit(card_id, passed)
		if not passed:
			all_passed = false
	return {"passed": all_passed, "results": results}


func _load_cards() -> void:
	var file: FileAccess = FileAccess.open(CARDS_JSON, FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	var err: Error = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return
	var data: Variant = json.data
	if not (data is Array):
		return
	for item: Variant in (data as Array):
		if item is Dictionary:
			var d: Dictionary = item as Dictionary
			var id: String = str(d.get("id", ""))
			if not id.is_empty():
				_cards_by_id[id] = d


func _evaluate_rule(card_id: String, run_data: Dictionary) -> bool:
	if not _cards_by_id.has(card_id):
		return true  # Unknown card: pass by default
	var card: Dictionary = _cards_by_id[card_id] as Dictionary
	var check_type: String = str(card.get("check_type", ""))
	var params: Dictionary = card.get("check_params", {}) as Dictionary
	match check_type:
		"max_misses":
			return int(run_data.get("misses", 0)) <= int(params.get("limit", 0))
		"collect_all_pearls":
			return bool(run_data.get("all_pearls_collected", false))
		"race_ghost":
			var score: int = int(run_data.get("score", 0))
			var ghost_score: int = int(run_data.get("ghost_score", 0))
			return score > ghost_score
		"treasure_hunt":
			return bool(run_data.get("all_treasures_collected", false))
		"no_powers":
			return int(run_data.get("powers_used", 0)) == 0
		"one_burst":
			return int(run_data.get("bubble_bursts_used", 0)) == 1
		"shield_only":
			return int(run_data.get("bubble_bursts_used", 0)) == 0
		"speed_run":
			return int(run_data.get("final_beat", 9999)) <= int(params.get("time_limit_beats", 32))
		"tiny_challenge":
			return bool(run_data.get("mutator_tiny_pebble_active", false))
		"reverse_buoyancy_challenge":
			return bool(run_data.get("mutator_reverse_buoyancy_active", false))
		"find_secret":
			return bool(run_data.get("secret_exit_found", false))
		"family_run":
			return bool(run_data.get("is_pass_play", false))
		"beat_score":
			return int(run_data.get("score", 0)) >= int(params.get("target", 0))
	return true


func get_card_def(card_id: String) -> Dictionary:
	if _cards_by_id.is_empty():
		_load_cards()
	return _cards_by_id.get(card_id, {}) as Dictionary
