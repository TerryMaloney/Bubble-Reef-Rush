## Tests for difficulty modes: DifficultyModifier parameter tweaks,
## SaveSystem per-difficulty star tracking, and unlock gating.
##
## Uses root.get_node() for autoloads (compile-time "Identifier not found" workaround
## in --script mode — same pattern as save_test.gd).
extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _ss: Node = null


func _init() -> void:
	await process_frame
	_ss = root.get_node("SaveSystem")
	# Clean up any lingering profiles from previous test runs.
	for old: String in ["test_diff_player", "test_legacy_diff", "test_cleared_diff",
			"diff_test_stars_abc", "diff_test_legacy_abc", "diff_test_cleared_abc"]:
		if _ss.call("list_profiles").has(old):
			_ss.delete_profile(old)

	_test_modifier_normal_passthrough()
	_test_modifier_easy_widens_gate()
	_test_modifier_hard_narrows_gate()
	_test_modifier_easy_eel_dormant()
	_test_modifier_hard_eel_dormant_clamped()
	_test_save_difficulty_stars()
	_test_legacy_best_stars_as_normal()
	_test_is_difficulty_cleared()

	print("Difficulty tests: %d passed, %d failed" % [_passed, _failed])
	print("DIFFICULTY_OK")
	quit(0 if _failed == 0 else 1)


func _test_modifier_normal_passthrough() -> void:
	var params: Dictionary = {"intensity": 0.5, "gap_height": 240.0}
	var out: Dictionary = DifficultyModifier.apply(params, "pressure_wall", "normal")
	_check(out["intensity"] == 0.5, "normal: intensity unchanged")
	_check(out["gap_height"] == 240.0, "normal: gap_height unchanged")


func _test_modifier_easy_widens_gate() -> void:
	var params: Dictionary = {"intensity": 0.5}
	var out: Dictionary = DifficultyModifier.apply(params, "pressure_wall", "easy")
	_check(float(out["intensity"]) < 0.5, "easy: intensity lowered (wider gap)")


func _test_modifier_hard_narrows_gate() -> void:
	var params: Dictionary = {"intensity": 0.5}
	var out: Dictionary = DifficultyModifier.apply(params, "pressure_wall", "hard")
	_check(float(out["intensity"]) > 0.5, "hard: intensity raised (narrower gap)")


func _test_modifier_easy_eel_dormant() -> void:
	var params: Dictionary = {"dormant_beats": 4}
	var out: Dictionary = DifficultyModifier.apply(params, "eel_snap", "easy")
	_check(int(out["dormant_beats"]) == 6, "easy: dormant_beats 4→6")


func _test_modifier_hard_eel_dormant_clamped() -> void:
	var params: Dictionary = {"dormant_beats": 2}
	var out: Dictionary = DifficultyModifier.apply(params, "eel_snap", "hard")
	_check(int(out["dormant_beats"]) == 2, "hard: dormant_beats 2 clamped at floor")


func _test_save_difficulty_stars() -> void:
	var pid: String = "diff_test_stars_abc"
	_ss.ensure_profile(pid)
	_ss.update_difficulty_stars(pid, "z1-l1", "easy", 3)
	_check(_ss.get_difficulty_stars(pid, "z1-l1", "easy") == 3, "easy stars stored")
	_check(_ss.get_difficulty_stars(pid, "z1-l1", "hard") == 0, "hard stars 0 initially")
	_ss.update_difficulty_stars(pid, "z1-l1", "normal", 2)
	_check(_ss.get_best_stars(pid, "z1-l1") == 3, "best_stars is max across difficulties")
	_ss.delete_profile(pid)


func _test_legacy_best_stars_as_normal() -> void:
	var pid: String = "diff_test_legacy_abc"
	_ss.ensure_profile(pid)
	_ss.update_level_result(pid, "z1-l1", 1000, 2)
	_check(_ss.get_difficulty_stars(pid, "z1-l1", "normal") == 2, "legacy best_stars maps to normal")
	_check(_ss.get_difficulty_stars(pid, "z1-l1", "easy") == 0, "legacy: easy is 0")
	_ss.delete_profile(pid)


func _test_is_difficulty_cleared() -> void:
	var pid: String = "diff_test_cleared_abc"
	_ss.ensure_profile(pid)
	_check(not _ss.is_difficulty_cleared(pid, "z1-l1", "easy"), "not cleared initially")
	_ss.update_difficulty_stars(pid, "z1-l1", "easy", 1)
	_check(_ss.is_difficulty_cleared(pid, "z1-l1", "easy"), "cleared after 1 star")
	_check(not _ss.is_difficulty_cleared(pid, "z1-l1", "normal"), "normal still locked")
	_ss.delete_profile(pid)


func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: " + label)
	else:
		_failed += 1
		push_error("  FAIL: " + label)
		print("  FAIL: " + label)
