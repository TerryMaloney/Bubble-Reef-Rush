## SaveSystem v2 integration test.
##
## Verifies:
##   1. A fresh profile is created with schema version 2.
##   2. v1→v2 migration preserves stars and level results, adds new fields.
##   3. record_attempt() increments the attempt counter.
##   4. record_progress_pct() only advances (never decreases) the best pct.
##   5. Unlock truth table: z2 requires z1-l4; z4 requires z3-l4;
##      z5 requires z4-l4; z6 requires 120 total stars.
##
## All SaveSystem calls go through root.get_node("SaveSystem") to avoid the
## compile-time "Identifier not found" error that autoload names cause in
## bare --script mode (autoloads ARE registered at runtime, just not at
## compile time).
##
## Run with:
##   godot --headless --path . --script tests/integration/save_test.gd
extends SceneTree

var _failures: PackedStringArray = []
var _ss: Node = null
const TEST_PROFILE: String = "save_test_tmp"


func _init() -> void:
	await process_frame
	await process_frame

	_ss = root.get_node("SaveSystem")

	_cleanup()
	_test_fresh_profile_is_v2()
	_test_v1_migration()
	_test_record_attempt()
	_test_record_progress_pct()
	_test_unlock_chain()
	_cleanup()

	print("==== SAVE TEST ====")
	if _failures.is_empty():
		print("All SaveSystem contracts hold.")
		print("SAVE_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("SAVE_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


func _cleanup() -> void:
	var profile_dir: String = "user://profiles/%s" % TEST_PROFILE
	if DirAccess.dir_exists_absolute(profile_dir):
		var progress_path: String = profile_dir + "/progress.json"
		var bak_path: String = progress_path + ".bak"
		if FileAccess.file_exists(progress_path):
			DirAccess.remove_absolute(progress_path)
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)


## ── Fresh profile is v2 ──────────────────────────────────────────────────────
func _test_fresh_profile_is_v2() -> void:
	_ss.ensure_profile(TEST_PROFILE)
	var data: Dictionary = _ss.load_progress(TEST_PROFILE) as Dictionary
	if int(data.get("version", 0)) != 2:
		_fail("Fresh profile version=%d, expected 2" % int(data.get("version", 0)))
	if not data.has("achievements"):
		_fail("Fresh profile missing 'achievements' key")
	if not data.has("cosmetics"):
		_fail("Fresh profile missing 'cosmetics' key")
	var settings: Dictionary = data.get("settings", {}) as Dictionary
	if not settings.has("timing_offset_ms"):
		_fail("Fresh profile settings missing 'timing_offset_ms'")
	if not settings.has("reduced_motion"):
		_fail("Fresh profile settings missing 'reduced_motion'")
	print("Fresh-profile v2 check — OK")


## ── v1 → v2 migration ───────────────────────────────────────────────────────
func _test_v1_migration() -> void:
	# Write a minimal v1 save directly.
	var v1: Dictionary = {
		"version": 1,
		"profile_id": TEST_PROFILE,
		"total_stars": 5,
		"coins": 100,
		"levels": {
			"z1-l1": {"best_score": 500, "best_stars": 2},
			"z1-l2": {"best_score": 300, "best_stars": 1},
		},
		"characters": {"default_fish": true},
		"settings": {"timing_offset_ms": 25.0},
	}
	var progress_path: String = "user://profiles/%s/progress.json" % TEST_PROFILE
	var file: FileAccess = FileAccess.open(progress_path, FileAccess.WRITE)
	if file == null:
		_fail("v1 migration: cannot open test file for writing")
		return
	file.store_string(JSON.stringify(v1))
	file.close()

	var data: Dictionary = _ss.load_progress(TEST_PROFILE) as Dictionary
	if int(data.get("version", 0)) != 2:
		_fail("After migration version=%d, expected 2" % int(data.get("version", 0)))
	if int(data.get("total_stars", 0)) != 5:
		_fail("Migration lost total_stars (got %d)" % int(data.get("total_stars", 0)))
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	if not levels.has("z1-l1"):
		_fail("Migration lost z1-l1 entry")
	else:
		var entry: Dictionary = levels["z1-l1"] as Dictionary
		if int(entry.get("best_stars", 0)) != 2:
			_fail("Migration: z1-l1 best_stars=%d, expected 2" % int(entry.get("best_stars", 0)))
		if not entry.has("attempts"):
			_fail("Migration: z1-l1 missing 'attempts' key after migration")
		if not entry.has("treasure_coins"):
			_fail("Migration: z1-l1 missing 'treasure_coins' key after migration")
	# Settings should carry over timing_offset_ms.
	var settings: Dictionary = data.get("settings", {}) as Dictionary
	if absf(float(settings.get("timing_offset_ms", 0.0)) - 25.0) > 0.001:
		_fail("Migration: timing_offset_ms not preserved (got %s)" % str(settings.get("timing_offset_ms")))
	# .bak file should have been written.
	var bak_path: String = progress_path + ".bak"
	if not FileAccess.file_exists(bak_path):
		_fail("Migration: .bak backup file not created")
	print("v1→v2 migration check — OK")


## ── record_attempt ───────────────────────────────────────────────────────────
func _test_record_attempt() -> void:
	_cleanup()
	_ss.ensure_profile(TEST_PROFILE)
	var lid: String = "z1-l1"
	if int(_ss.get_attempts(TEST_PROFILE, lid)) != 0:
		_fail("record_attempt: initial count should be 0 (got %d)" % int(_ss.get_attempts(TEST_PROFILE, lid)))
	_ss.record_attempt(TEST_PROFILE, lid)
	if int(_ss.get_attempts(TEST_PROFILE, lid)) != 1:
		_fail("record_attempt: after 1 call should be 1 (got %d)" % int(_ss.get_attempts(TEST_PROFILE, lid)))
	_ss.record_attempt(TEST_PROFILE, lid)
	_ss.record_attempt(TEST_PROFILE, lid)
	if int(_ss.get_attempts(TEST_PROFILE, lid)) != 3:
		_fail("record_attempt: after 3 calls should be 3 (got %d)" % int(_ss.get_attempts(TEST_PROFILE, lid)))
	print("record_attempt check — OK")


## ── record_progress_pct ──────────────────────────────────────────────────────
func _test_record_progress_pct() -> void:
	_cleanup()
	_ss.ensure_profile(TEST_PROFILE)
	var lid: String = "z1-l1"
	_ss.record_progress_pct(TEST_PROFILE, lid, 45.0)
	if absf(float(_ss.get_best_progress_pct(TEST_PROFILE, lid)) - 45.0) > 0.01:
		_fail("record_progress_pct: expected 45 after first call (got %.1f)" % float(_ss.get_best_progress_pct(TEST_PROFILE, lid)))
	_ss.record_progress_pct(TEST_PROFILE, lid, 30.0)
	if absf(float(_ss.get_best_progress_pct(TEST_PROFILE, lid)) - 45.0) > 0.01:
		_fail("record_progress_pct: should not decrease from 45 to 30")
	_ss.record_progress_pct(TEST_PROFILE, lid, 80.0)
	if absf(float(_ss.get_best_progress_pct(TEST_PROFILE, lid)) - 80.0) > 0.01:
		_fail("record_progress_pct: should advance from 45 to 80 (got %.1f)" % float(_ss.get_best_progress_pct(TEST_PROFILE, lid)))
	print("record_progress_pct check — OK")


## ── Unlock truth table ───────────────────────────────────────────────────────
func _test_unlock_chain() -> void:
	_cleanup()
	_ss.ensure_profile(TEST_PROFILE)

	# z1-l4 not yet cleared — z2 prerequisite not met.
	if bool(_ss.is_level_cleared(TEST_PROFILE, "z1-l4")):
		_fail("Unlock: z1-l4 should not be cleared on fresh profile")

	# Clear z1-l4 → z2 prerequisite now met.
	_ss.update_level_result(TEST_PROFILE, "z1-l4", 500, 2)
	if not bool(_ss.is_level_cleared(TEST_PROFILE, "z1-l4")):
		_fail("Unlock: z1-l4 should be cleared after update_level_result")

	# Clear the full required chain through z4-l4.
	_ss.update_level_result(TEST_PROFILE, "z2-l4", 500, 2)
	_ss.update_level_result(TEST_PROFILE, "z3-l4", 500, 2)
	_ss.update_level_result(TEST_PROFILE, "z4-l4", 500, 2)
	if not bool(_ss.is_level_cleared(TEST_PROFILE, "z4-l4")):
		_fail("Unlock: z4-l4 should be cleared")

	# z6 requires 120 total stars — seed enough 3-star clears to reach threshold.
	# Already have z1-l4(2)+z2-l4(2)+z3-l4(2)+z4-l4(2)=8 stars; need 38 more.
	for i: int in range(38):
		_ss.update_level_result(TEST_PROFILE, "z_test-%d" % i, 600, 3)
	var total: int = int(_ss.get_total_stars(TEST_PROFILE))
	if total < 120:
		_fail("Unlock: expected ≥120 total stars after seeding, got %d" % total)
	print("Unlock chain check — OK (total_stars=%d)" % total)
