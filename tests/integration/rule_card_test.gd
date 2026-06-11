## rule_card_test.gd — Phase 20 contracts for RuleCardSystem.
##
## Tests:
##   1. max_misses_passes           — no_miss rule passes when misses=0.
##   2. max_misses_fails            — no_miss rule fails when misses=2.
##   3. collect_all_passes          — collect_all_pearls passes when flag is true.
##   4. no_powers_fails             — no_powers rule fails when powers_used=1.
##   5. race_ghost_passes           — beat_my_score passes when score > ghost_score.
##   6. signal_emitted              — rule_card_result signal fires on evaluate_run.
##   7. signal_card_id              — received signal card_id matches "no_miss".
##   8. evaluate_run_result_all_passed — mixed rules yield passed=false when one fails.
##   9. evaluate_run_result_array   — two rules produce two entries in results.
##
## Run with:
##   godot --headless --path . --script tests/integration/rule_card_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_max_misses_passes(root)
	_test_max_misses_fails(root)
	_test_collect_all_passes(root)
	_test_no_powers_fails(root)
	_test_race_ghost_passes(root)
	_test_signal_emitted(root)
	_test_signal_card_id(root)
	_test_evaluate_run_result_all_passed(root)
	_test_evaluate_run_result_array(root)

	print("Rule card tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("RULE_CARD_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. max_misses_passes
func _test_max_misses_passes(root: Node) -> void:
	var rcs: Node = root.get_node("RuleCardSystem")
	rcs.set("_cards_by_id", {})
	rcs.set_active_rules(["no_miss"])
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"misses": 0, "score": 300})

	if result.get("passed", false) == true:
		_ok("max_misses_passes")
	else:
		_fail("max_misses_passes", "expected passed=true with misses=0")


## 2. max_misses_fails
func _test_max_misses_fails(root: Node) -> void:
	var rcs: Node = root.get_node("RuleCardSystem")
	rcs.set("_cards_by_id", {})
	rcs.set_active_rules(["no_miss"])
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"misses": 2, "score": 100})

	if result.get("passed", true) == false:
		_ok("max_misses_fails")
	else:
		_fail("max_misses_fails", "expected passed=false with misses=2")


## 3. collect_all_passes
func _test_collect_all_passes(root: Node) -> void:
	var rcs: Node = root.get_node("RuleCardSystem")
	rcs.set("_cards_by_id", {})
	rcs.set_active_rules(["collect_all_pearls"])
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"all_pearls_collected": true})

	if result.get("passed", false) == true:
		_ok("collect_all_passes")
	else:
		_fail("collect_all_passes", "expected passed=true with all_pearls_collected=true")


## 4. no_powers_fails
func _test_no_powers_fails(root: Node) -> void:
	var rcs: Node = root.get_node("RuleCardSystem")
	rcs.set("_cards_by_id", {})
	rcs.set_active_rules(["no_powers"])
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"powers_used": 1})

	if result.get("passed", true) == false:
		_ok("no_powers_fails")
	else:
		_fail("no_powers_fails", "expected passed=false with powers_used=1")


## 5. race_ghost_passes
func _test_race_ghost_passes(root: Node) -> void:
	var rcs: Node = root.get_node("RuleCardSystem")
	rcs.set("_cards_by_id", {})
	rcs.set_active_rules(["beat_my_score"])
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"score": 500, "ghost_score": 400})

	if result.get("passed", false) == true:
		_ok("race_ghost_passes")
	else:
		_fail("race_ghost_passes", "expected passed=true with score=500 > ghost_score=400")


## 6. signal_emitted
func _test_signal_emitted(root: Node) -> void:
	var rcs: Node = root.get_node("RuleCardSystem")
	var eb: Node = root.get_node("EventBus")
	rcs.set("_cards_by_id", {})
	rcs.set_active_rules(["no_miss"])

	var received: Array = []
	var cb_6: Callable = func(card_id: String, passed: bool) -> void:
		received.append({"card_id": card_id, "passed": passed})
	eb.rule_card_result.connect(cb_6)

	rcs.evaluate_run("z1-l1", {"misses": 0})

	eb.rule_card_result.disconnect(cb_6)

	if received.size() >= 1:
		_ok("signal_emitted")
	else:
		_fail("signal_emitted", "expected at least 1 signal emission, got %d" % received.size())


## 7. signal_card_id
func _test_signal_card_id(root: Node) -> void:
	var rcs: Node = root.get_node("RuleCardSystem")
	var eb: Node = root.get_node("EventBus")
	rcs.set("_cards_by_id", {})
	rcs.set_active_rules(["no_miss"])

	var received_ids: Array = []
	var cb_7: Callable = func(card_id: String, _passed: bool) -> void:
		received_ids.append(card_id)
	eb.rule_card_result.connect(cb_7)

	rcs.evaluate_run("z1-l1", {"misses": 0})

	eb.rule_card_result.disconnect(cb_7)

	if received_ids.size() >= 1 and received_ids[0] == "no_miss":
		_ok("signal_card_id")
	else:
		var got: String = str(received_ids)
		_fail("signal_card_id", "expected [no_miss], got " + got)


## 8. evaluate_run_result_all_passed
func _test_evaluate_run_result_all_passed(root: Node) -> void:
	var rcs: Node = root.get_node("RuleCardSystem")
	rcs.set("_cards_by_id", {})
	# no_miss passes with misses=0; no_powers fails with powers_used=1
	rcs.set_active_rules(["no_miss", "no_powers"])
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"misses": 0, "powers_used": 1})

	if result.get("passed", true) == false:
		_ok("evaluate_run_result_all_passed")
	else:
		_fail("evaluate_run_result_all_passed", "expected passed=false when one rule fails")


## 9. evaluate_run_result_array
func _test_evaluate_run_result_array(root: Node) -> void:
	var rcs: Node = root.get_node("RuleCardSystem")
	rcs.set("_cards_by_id", {})
	rcs.set_active_rules(["no_miss", "collect_all_pearls"])
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"misses": 0, "all_pearls_collected": true})

	var results_arr: Array = result.get("results", [])
	if results_arr.size() == 2:
		_ok("evaluate_run_result_array")
	else:
		_fail("evaluate_run_result_array", "expected 2 entries, got %d" % results_arr.size())
