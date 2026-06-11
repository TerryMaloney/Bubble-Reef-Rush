# Autoload that manages active rule cards for a run and evaluates them post-run.
extends Node

const CARDS_JSON: String = "res://assets/data/rule_cards.json"

var active_rules: Array[String] = []
var _cards_by_id: Dictionary = {}


func _ready() -> void:
	_load_cards()


func _load_cards() -> void:
	var file: FileAccess = FileAccess.open(CARDS_JSON, FileAccess.READ)
	if file == null:
		push_warning("RuleCardSystem: rule_cards.json not found at " + CARDS_JSON)
		return
	var json: JSON = JSON.new()
	var text: String = file.get_as_text()
	file.close()
	var err: Error = json.parse(text)
	if err != OK:
		push_error("RuleCardSystem: JSON parse error: " + json.get_error_message())
		return
	var arr: Variant = json.data
	if not (arr is Array):
		push_error("RuleCardSystem: rule_cards.json root is not an Array")
		return
	for item: Variant in (arr as Array):
		if item is Dictionary:
			var d: Dictionary = item as Dictionary
			_cards_by_id[str(d.get("id", ""))] = d


## Set the rule cards that must be satisfied this run.
func set_active_rules(cards: Array) -> void:
	active_rules.clear()
	for c: Variant in cards:
		active_rules.append(str(c))


## Evaluate all active rules against run_data. Emits rule_card_result per card.
## run_data keys: misses, total_pearls, pearls_collected, total_treasures,
## treasures_collected, powers_fired, shield_only, score, ghost_score,
## attempts, active_mutators (Array), secret_found, family_relay_complete.
func evaluate_run(_level_id: String, run_data: Dictionary) -> Dictionary:
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


## Check whether a specific rule card is currently active.
func is_active(card_id: String) -> bool:
	return card_id in active_rules


func _evaluate_rule(card_id: String, run_data: Dictionary) -> bool:
	var card: Dictionary = _cards_by_id.get(card_id, {})
	if card.is_empty():
		return true
	var params: Dictionary = card.get("check_params", {}) as Dictionary
	match str(card.get("check_type", "")):
		"max_misses":
			var limit: int = int(params.get("limit", 0))
			return int(run_data.get("misses", 0)) <= limit
		"collect_all_pearls":
			var total: int = int(run_data.get("total_pearls", 0))
			if total == 0:
				return true
			return int(run_data.get("pearls_collected", 0)) >= total
		"treasure_hunt":
			var total: int = int(run_data.get("total_treasures", 0))
			if total == 0:
				return true
			return int(run_data.get("treasures_collected", 0)) >= total
		"no_powers":
			return int(run_data.get("powers_fired", 0)) == 0
		"one_bubble_burst":
			return int(run_data.get("powers_fired", 0)) <= 1
		"shield_only":
			return bool(run_data.get("shield_only", false))
		"race_ghost":
			return int(run_data.get("score", 0)) > int(run_data.get("ghost_score", 0))
		"beat_score":
			var threshold: int = int(params.get("threshold", 0))
			return int(run_data.get("score", 0)) >= threshold
		"max_attempts":
			var limit: int = int(params.get("limit", 1))
			return int(run_data.get("attempts", 1)) <= limit
		"tiny_character":
			var mutators: Array = run_data.get("active_mutators", []) as Array
			return "tiny_pebble" in mutators
		"reverse_buoyancy":
			var mutators: Array = run_data.get("active_mutators", []) as Array
			return "reverse_buoyancy" in mutators
		"find_secret":
			return bool(run_data.get("secret_found", false))
		"family_relay":
			return bool(run_data.get("family_relay_complete", false))
		_:
			return true
