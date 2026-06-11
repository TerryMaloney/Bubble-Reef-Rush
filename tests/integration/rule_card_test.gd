extends SceneTree

# RuleCardSystem integration test — 7 contracts.
# Contract 1: max_misses_passes       — "no_miss" with misses=0 → passed
# Contract 2: max_misses_fails        — "no_miss" with misses=2 → failed
# Contract 3: collect_all_passes      — "collect_all_pearls" with full collection → passed
# Contract 4: no_powers_fails         — "no_powers" with powers_fired=1 → failed
# Contract 5: race_ghost_passes       — "beat_my_score" score > ghost_score → passed
# Contract 6: signal_emitted          — rule_card_result signal fires with correct args
# Contract 7: evaluate_run_result     — all_passed=false when any card fails

const RULE_CARD_GD := "res://src/core/RuleCardSystem.gd"

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()
	var rcs: Node = root.get_node("RuleCardSystem")

	_test_max_misses_passes(rcs)
	_test_max_misses_fails(rcs)
	_test_collect_all_passes(rcs)
	_test_no_powers_fails(rcs)
	_test_race_ghost_passes(rcs)
	_test_signal_emitted(rcs, root)
	_test_evaluate_run_result(rcs)

	print("RuleCard tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("RULE_CARD_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


# ── Contract 1 ────────────────────────────────────────────────────────────────

func _test_max_misses_passes(rcs: Node) -> void:
	rcs.active_rules.clear()
	rcs.active_rules.append("no_miss")
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"misses": 0})
	if result.get("passed", false):
		_ok("max_misses_passes: no_miss passes with 0 misses")
	else:
		_fail("max_misses_passes", "expected passed=true")
	rcs.active_rules.clear()


# ── Contract 2 ────────────────────────────────────────────────────────────────

func _test_max_misses_fails(rcs: Node) -> void:
	rcs.active_rules.clear()
	rcs.active_rules.append("no_miss")
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"misses": 2})
	if not result.get("passed", true):
		_ok("max_misses_fails: no_miss fails with 2 misses")
	else:
		_fail("max_misses_fails", "expected passed=false")
	rcs.active_rules.clear()


# ── Contract 3 ────────────────────────────────────────────────────────────────

func _test_collect_all_passes(rcs: Node) -> void:
	rcs.active_rules.clear()
	rcs.active_rules.append("collect_all_pearls")
	var result: Dictionary = rcs.evaluate_run("z1-l1",
		{"total_pearls": 10, "pearls_collected": 10})
	if result.get("passed", false):
		_ok("collect_all_passes: all 10 pearls collected")
	else:
		_fail("collect_all_passes", "expected passed=true")
	rcs.active_rules.clear()


# ── Contract 4 ────────────────────────────────────────────────────────────────

func _test_no_powers_fails(rcs: Node) -> void:
	rcs.active_rules.clear()
	rcs.active_rules.append("no_powers")
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"powers_fired": 1})
	if not result.get("passed", true):
		_ok("no_powers_fails: no_powers fails when power was used")
	else:
		_fail("no_powers_fails", "expected passed=false")
	rcs.active_rules.clear()


# ── Contract 5 ────────────────────────────────────────────────────────────────

func _test_race_ghost_passes(rcs: Node) -> void:
	rcs.active_rules.clear()
	rcs.active_rules.append("beat_my_score")
	var result: Dictionary = rcs.evaluate_run("z1-l1",
		{"score": 500, "ghost_score": 400})
	if result.get("passed", false):
		_ok("race_ghost_passes: score 500 beats ghost 400")
	else:
		_fail("race_ghost_passes", "expected passed=true")
	rcs.active_rules.clear()


# ── Contract 6 ────────────────────────────────────────────────────────────────

func _test_signal_emitted(rcs: Node, root: Node) -> void:
	rcs.active_rules.clear()
	rcs.active_rules.append("no_miss")

	var received: Array = []
	root.get_node("EventBus").rule_card_result.connect(
		func(card_id: String, passed: bool) -> void:
			received.append({"card_id": card_id, "passed": passed})
	)

	rcs.evaluate_run("z1-l1", {"misses": 0})

	if received.size() >= 1:
		_ok("signal_emitted: rule_card_result received")
	else:
		_fail("signal_emitted", "no signal received")

	if received.size() >= 1 and received[0].get("card_id", "") == "no_miss":
		_ok("signal_emitted: card_id is 'no_miss'")
	else:
		_fail("signal_emitted: wrong card_id", str(received))

	rcs.active_rules.clear()


# ── Contract 7 ────────────────────────────────────────────────────────────────

func _test_evaluate_run_result(rcs: Node) -> void:
	rcs.active_rules.clear()
	rcs.active_rules.append("no_miss")
	rcs.active_rules.append("no_powers")

	# misses=1 fails no_miss; powers_fired=0 passes no_powers
	var result: Dictionary = rcs.evaluate_run("z1-l1", {"misses": 1, "powers_fired": 0})
	if not result.get("passed", true):
		_ok("evaluate_run_result: all_passed=false when one card fails")
	else:
		_fail("evaluate_run_result", "expected passed=false")

	var results: Array = result.get("results", []) as Array
	if results.size() == 2:
		_ok("evaluate_run_result: results array has 2 entries")
	else:
		_fail("evaluate_run_result: wrong results count", str(results.size()))

	rcs.active_rules.clear()
