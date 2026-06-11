## copilot_test.gd — Phase 24 contracts for CoPilotController.
##
## Tests:
##   1. trigger_increments     — trigger_power() increments contribution count.
##   2. reset_contribution     — reset_contribution() zeroes the count.
##   3. profile_b_stored       — get_profile_b() returns the configured profile.
##   4. null_resonance_safe    — trigger_power() with null resonance doesn't crash.
##   5. profiles_credited      — SaveSystem can record results for both profiles.
##
## Run with:
##   godot --headless --path . --script tests/integration/copilot_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_trigger_increments(root)
	_test_reset_contribution(root)
	_test_profile_b_stored(root)
	_test_null_resonance_safe(root)
	_test_profiles_credited(root)

	print("Co-pilot tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("COPILOT_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. trigger_increments
func _test_trigger_increments(_root: Node) -> void:
	var cp: Node = load("res://src/gameplay/CoPilotController.gd").new()
	cp.setup("bob", null)
	cp.trigger_power()
	cp.trigger_power()
	var c: Dictionary = cp.get_contribution()
	if int(c.get("power_activations", 0)) == 2:
		_ok("trigger_increments")
	else:
		_fail("trigger_increments", "expected 2, got %d" % int(c.get("power_activations", 0)))


## 2. reset_contribution
func _test_reset_contribution(_root: Node) -> void:
	var cp: Node = load("res://src/gameplay/CoPilotController.gd").new()
	cp.setup("bob", null)
	cp.trigger_power()
	cp.trigger_power()
	cp.reset_contribution()
	var c: Dictionary = cp.get_contribution()
	if int(c.get("power_activations", 0)) == 0:
		_ok("reset_contribution")
	else:
		_fail("reset_contribution", "expected 0 after reset, got %d" % int(c.get("power_activations", 0)))


## 3. profile_b_stored
func _test_profile_b_stored(_root: Node) -> void:
	var cp: Node = load("res://src/gameplay/CoPilotController.gd").new()
	cp.setup("alice", null)
	if cp.get_profile_b() == "alice":
		_ok("profile_b_stored")
	else:
		_fail("profile_b_stored", "expected 'alice', got '%s'" % cp.get_profile_b())


## 4. null_resonance_safe
func _test_null_resonance_safe(_root: Node) -> void:
	var cp: Node = load("res://src/gameplay/CoPilotController.gd").new()
	cp.setup("player2", null)
	cp.trigger_power()  # Must not crash.
	_ok("null_resonance_safe")


## 5. profiles_credited
func _test_profiles_credited(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid_a: String = "cp_a_%d" % Time.get_ticks_msec()
	var pid_b: String = "cp_b_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid_a)
	ss.ensure_profile(pid_b)

	ss.update_level_result(pid_a, "z1-l1", 600, 3)
	ss.update_level_result(pid_b, "z1-l1", 600, 3)

	var a_stars: int = ss.get_best_stars(pid_a, "z1-l1")
	var b_stars: int = ss.get_best_stars(pid_b, "z1-l1")

	if a_stars == 3 and b_stars == 3:
		_ok("profiles_credited")
	else:
		_fail("profiles_credited", "a_stars=%d b_stars=%d (want both 3)" % [a_stars, b_stars])
