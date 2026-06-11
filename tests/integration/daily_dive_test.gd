## daily_dive_test.gd — Phase 23 contracts for DailyDiveScreen + SaveSystem.daily_dive.
##
## Tests:
##   1. determinism        — get_today_levels returns same list on two consecutive calls.
##   2. result_count       — get_today_levels always returns exactly 3 levels.
##   3. history_saved      — set_daily_dive_result persisted via get_daily_dive_history.
##   4. signal_emitted     — daily_dive_completed fires on complete_dive().
##
## Run with:
##   godot --headless --path . --script tests/integration/daily_dive_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_determinism()
	_test_result_count()
	_test_history_saved(root)
	_test_signal_emitted(root)

	print("Daily dive tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("DAILY_DIVE_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. determinism
func _test_determinism() -> void:
	var screen = load("res://src/ui/DailyDiveScreen.gd").new()
	var list_a: Array[String] = screen.get_today_levels()
	var list_b: Array[String] = screen.get_today_levels()
	if list_a == list_b:
		_ok("determinism")
	else:
		_fail("determinism", "two calls returned different level lists")


## 2. result_count
func _test_result_count() -> void:
	var screen = load("res://src/ui/DailyDiveScreen.gd").new()
	var levels: Array[String] = screen.get_today_levels()
	if levels.size() == 3:
		_ok("result_count")
	else:
		_fail("result_count", "expected 3 levels, got %d" % levels.size())


## 3. history_saved
func _test_history_saved(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid: String = "dd_hist_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	var date: String = "2026-06-11"
	ss.set_daily_dive_result(pid, date, 1500)
	var history: Dictionary = ss.get_daily_dive_history(pid)

	if history.has(date) and int(history[date]) == 1500:
		_ok("history_saved")
	else:
		_fail("history_saved", "expected score 1500 for date '%s', got %s" % [date, str(history.get(date, "missing"))])


## 4. signal_emitted
func _test_signal_emitted(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var eb: Node = root.get_node("EventBus")
	var pid: String = "dd_sig_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	var received: Array = []
	eb.daily_dive_completed.connect(func(_date: String, _score: int) -> void:
		received.append(1)
	)

	var screen = load("res://src/ui/DailyDiveScreen.gd").new()
	screen.complete_dive(pid, 800)

	if not received.is_empty():
		_ok("signal_emitted")
	else:
		_fail("signal_emitted", "daily_dive_completed was not emitted")
