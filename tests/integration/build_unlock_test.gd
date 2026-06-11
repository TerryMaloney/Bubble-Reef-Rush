extends SceneTree

# BuildUnlockRegistry integration test — 5 contracts.
# Contract 1: z3_unlocks_anchor_chain — clearing z3 level grants anchor_chain
# Contract 2: z3_unlocks_eel_snap     — clearing z3 level grants eel_snap
# Contract 3: z1_no_z3_unlocks        — clearing z1 level does not grant anchor_chain
# Contract 4: zero_stars_no_unlock    — stars=0 grants nothing
# Contract 5: z4_unlocks_lava_burst   — clearing z4 level grants lava_burst

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()
	var reg: Node = root.get_node("BuildUnlockRegistry")
	var ss: Node = root.get_node("SaveSystem")

	# Use isolated test profile IDs to avoid polluting real save data.
	var t: int = Time.get_ticks_msec()
	var pid_z3: String = "bu_test_z3_%d" % t
	var pid_z1: String = "bu_test_z1_%d" % (t + 1)
	var pid_zero: String = "bu_test_zero_%d" % (t + 2)
	var pid_z4: String = "bu_test_z4_%d" % (t + 3)

	# Ensure test profiles exist so SaveSystem can write to them.
	ss.ensure_profile(pid_z3)
	ss.ensure_profile(pid_z1)
	ss.ensure_profile(pid_zero)
	ss.ensure_profile(pid_z4)

	_test_z3_unlocks(reg, ss, pid_z3)
	_test_z1_no_z3_unlocks(reg, ss, pid_z1)
	_test_zero_stars(reg, ss, pid_zero)
	_test_z4_unlocks(reg, ss, pid_z4)

	print("BuildUnlock tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("BUILD_UNLOCK_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


# ── Contract 1 & 2 ────────────────────────────────────────────────────────────

func _test_z3_unlocks(reg: Node, ss: Node, pid: String) -> void:
	reg.check_unlocks(pid, "z3-l1", 2)

	if ss.has_build_unlock(pid, "obstacles", "anchor_chain"):
		_ok("z3_unlocks_anchor_chain: anchor_chain unlocked after z3 clear")
	else:
		_fail("z3_unlocks_anchor_chain", "anchor_chain not found in build_unlocks")

	if ss.has_build_unlock(pid, "obstacles", "eel_snap"):
		_ok("z3_unlocks_eel_snap: eel_snap unlocked after z3 clear")
	else:
		_fail("z3_unlocks_eel_snap", "eel_snap not found in build_unlocks")


# ── Contract 3 ────────────────────────────────────────────────────────────────

func _test_z1_no_z3_unlocks(reg: Node, ss: Node, pid: String) -> void:
	reg.check_unlocks(pid, "z1-l4", 3)

	if not ss.has_build_unlock(pid, "obstacles", "anchor_chain"):
		_ok("z1_no_z3_unlocks: z1 clear does not grant anchor_chain")
	else:
		_fail("z1_no_z3_unlocks", "anchor_chain was incorrectly granted")


# ── Contract 4 ────────────────────────────────────────────────────────────────

func _test_zero_stars(reg: Node, ss: Node, pid: String) -> void:
	reg.check_unlocks(pid, "z4-l1", 0)

	if not ss.has_build_unlock(pid, "obstacles", "lava_burst"):
		_ok("zero_stars_no_unlock: stars=0 grants no unlocks")
	else:
		_fail("zero_stars_no_unlock", "lava_burst incorrectly granted at 0 stars")


# ── Contract 5 ────────────────────────────────────────────────────────────────

func _test_z4_unlocks(reg: Node, ss: Node, pid: String) -> void:
	reg.check_unlocks(pid, "z4-l2", 1)

	if ss.has_build_unlock(pid, "obstacles", "lava_burst"):
		_ok("z4_unlocks_lava_burst: lava_burst unlocked after z4 clear")
	else:
		_fail("z4_unlocks_lava_burst", "lava_burst not found in build_unlocks")
