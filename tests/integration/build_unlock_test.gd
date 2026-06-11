## build_unlock_test.gd — Phase 20 contracts for BuildUnlockRegistry.
##
## Tests:
##   1. z3_unlocks_anchor_chain  — z3 level completion unlocks anchor_chain.
##   2. z3_unlocks_eel_snap      — z3 level completion also unlocks eel_snap.
##   3. z1_no_z3_unlocks         — z1 level completion does not unlock anchor_chain.
##   4. zero_stars_no_unlock     — stars=0 does not unlock z3 items.
##   5. z4_unlocks_lava_burst    — z4 level with stars=2 unlocks lava_burst.
##
## Run with:
##   godot --headless --path . --script tests/integration/build_unlock_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_z3_unlocks_anchor_chain(root)
	_test_z3_unlocks_eel_snap(root)
	_test_z1_no_z3_unlocks(root)
	_test_zero_stars_no_unlock(root)
	_test_z4_unlocks_lava_burst(root)

	print("Build unlock tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("BUILD_UNLOCK_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. z3_unlocks_anchor_chain
func _test_z3_unlocks_anchor_chain(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var reg: Node = root.get_node("BuildUnlockRegistry")
	var pid: String = "bu_test_%d_1" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	reg.check_unlocks(pid, "z3-l1", 1)

	if ss.has_build_unlock(pid, "obstacles", "anchor_chain"):
		_ok("z3_unlocks_anchor_chain")
	else:
		_fail("z3_unlocks_anchor_chain", "anchor_chain should be unlocked after z3-l1 clear")


## 2. z3_unlocks_eel_snap
func _test_z3_unlocks_eel_snap(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var reg: Node = root.get_node("BuildUnlockRegistry")
	var pid: String = "bu_test_%d_2" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	reg.check_unlocks(pid, "z3-l1", 1)

	if ss.has_build_unlock(pid, "obstacles", "eel_snap"):
		_ok("z3_unlocks_eel_snap")
	else:
		_fail("z3_unlocks_eel_snap", "eel_snap should be unlocked after z3-l1 clear")


## 3. z1_no_z3_unlocks
func _test_z1_no_z3_unlocks(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var reg: Node = root.get_node("BuildUnlockRegistry")
	var pid: String = "bu_test_%d_3" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	reg.check_unlocks(pid, "z1-l1", 1)

	if not ss.has_build_unlock(pid, "obstacles", "anchor_chain"):
		_ok("z1_no_z3_unlocks")
	else:
		_fail("z1_no_z3_unlocks", "anchor_chain should NOT be unlocked from a z1 level")


## 4. zero_stars_no_unlock
func _test_zero_stars_no_unlock(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var reg: Node = root.get_node("BuildUnlockRegistry")
	var pid: String = "bu_test_%d_4" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	reg.check_unlocks(pid, "z3-l1", 0)

	if not ss.has_build_unlock(pid, "obstacles", "anchor_chain"):
		_ok("zero_stars_no_unlock")
	else:
		_fail("zero_stars_no_unlock", "anchor_chain should NOT be unlocked with stars=0")


## 5. z4_unlocks_lava_burst
func _test_z4_unlocks_lava_burst(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var reg: Node = root.get_node("BuildUnlockRegistry")
	var pid: String = "bu_test_%d_5" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	reg.check_unlocks(pid, "z4-l1", 2)

	if ss.has_build_unlock(pid, "obstacles", "lava_burst"):
		_ok("z4_unlocks_lava_burst")
	else:
		_fail("z4_unlocks_lava_burst", "lava_burst should be unlocked after z4-l1 with stars=2")
