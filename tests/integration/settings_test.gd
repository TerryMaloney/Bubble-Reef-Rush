## Settings & Accessibility integration test.
##
## Verifies:
##   1. timing_offset_ms persists to SaveSystem and is read back by Accessibility.
##   2. Accessibility.set_timing_offset_ms() immediately updates BeatConductor.user_latency_offset_ms.
##   3. With wide_timing_windows=false, an input at 170ms offset is MISS.
##   4. With wide_timing_windows=true (window_scale=1.25), the same 170ms input is GOOD
##      because the GOOD outer half = 160*1.25 = 200ms > 170ms.
##
## All autoload references go through root.get_node() to avoid compile-time
## "Identifier not found" errors in bare --script mode.
##
## Run with:
##   godot --headless --path . --script tests/integration/settings_test.gd
extends SceneTree

var _failures: PackedStringArray = []
var _ss: Node = null
var _access: Node = null
var _conductor: Node = null
const TEST_PROFILE: String = "settings_test_tmp"


func _init() -> void:
	await process_frame
	await process_frame

	_ss = root.get_node("SaveSystem")
	_access = root.get_node("Accessibility")
	_conductor = root.get_node("BeatConductor")

	_cleanup()
	_ss.ensure_profile(TEST_PROFILE)

	_test_timing_offset_persists()
	await _test_wide_timing_windows()

	_cleanup()

	print("==== SETTINGS TEST ====")
	if _failures.is_empty():
		print("All settings contracts hold.")
		print("SETTINGS_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("SETTINGS_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


func _cleanup() -> void:
	var progress_path: String = "user://profiles/%s/progress.json" % TEST_PROFILE
	var bak_path: String = progress_path + ".bak"
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(progress_path)
	if FileAccess.file_exists(bak_path):
		DirAccess.remove_absolute(bak_path)


## ── Timing offset persists and immediately updates BeatConductor ────────────
func _test_timing_offset_persists() -> void:
	# Force SaveSystem to use the test profile.
	var real_profile: String = _ss.get_active_profile_id()
	_ss.set_setting(TEST_PROFILE, "timing_offset_ms", 42.0)

	# Verify the round-trip.
	var read_back: float = float(_ss.get_setting(TEST_PROFILE, "timing_offset_ms", 0.0))
	if absf(read_back - 42.0) > 0.001:
		_fail("timing_offset_ms round-trip: wrote 42.0, read back %.3f" % read_back)
		return

	# Now check BeatConductor is updated when we call Accessibility on the ACTIVE profile.
	_ss.set_setting(real_profile, "timing_offset_ms", 75.0)
	_access.set_timing_offset_ms(75.0)
	var bc_offset: float = float(_conductor.get("user_latency_offset_ms"))
	if absf(bc_offset - 75.0) > 0.001:
		_fail("BeatConductor.user_latency_offset_ms after set_timing_offset_ms: expected 75, got %.3f" % bc_offset)
	else:
		print("Timing offset persist check — OK (BeatConductor.user_latency_offset_ms=%.1f)" % bc_offset)

	# Restore.
	_access.set_timing_offset_ms(0.0)
	_ss.set_setting(real_profile, "timing_offset_ms", 0.0)


## ── Wide timing windows flip MISS → GOOD ────────────────────────────────────
## Directly inject _last_beat_time_ms so no signal timing is needed.
## Standard (window_scale=1.0): GOOD_OUTER = 160ms → 170ms is MISS.
## Wide (window_scale=1.25): GOOD_OUTER = 200ms → 170ms is GOOD.
func _test_wide_timing_windows() -> void:
	var judge_script: GDScript = load("res://src/rhythm/TimingJudge.gd") as GDScript
	if judge_script == null:
		_fail("Could not load TimingJudge.gd")
		return

	# Start conductor in wall-clock mode so get_bpm_at_beat() works.
	_conductor.start_level(110.0, null)
	await process_frame

	var judge: Node = judge_script.new()
	root.add_child(judge)
	await process_frame

	# Place the "last beat" at t=0.0ms and test with an input at 170ms.
	# offset = 170.0 - 0.0 = 170ms. No signal needed.
	judge.set("_last_beat_time_ms", 0.0)
	judge.set("_prev_beat_time_ms", -9999.0)

	# Standard windows (window_scale=1.0): GOOD_OUTER = 160ms → 170ms is MISS (enum=2).
	judge.set("window_scale", 1.0)
	var result_standard = judge.judge_input(170.0)
	if int(result_standard) != 2:
		_fail("Standard windows: 170ms input should be MISS/2 (got %d)" % int(result_standard))
	else:
		print("Standard window 170ms = MISS — OK")

	# Wide windows (window_scale=1.25): GOOD_OUTER = 160*1.25=200ms → 170ms is GOOD (enum=1).
	judge.reset()
	judge.set("_last_beat_time_ms", 0.0)
	judge.set("_prev_beat_time_ms", -9999.0)
	judge.set("window_scale", 1.25)
	var result_wide = judge.judge_input(170.0)
	if int(result_wide) != 1:
		_fail("Wide windows (1.25×): 170ms input should be GOOD/1 (got %d)" % int(result_wide))
	else:
		print("Wide window (1.25×) 170ms = GOOD — OK")

	_conductor.stop_level()
	judge.queue_free()
