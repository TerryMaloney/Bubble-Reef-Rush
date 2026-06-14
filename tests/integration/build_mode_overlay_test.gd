## build_mode_overlay_test.gd
## Verifies PlayabilityValidator.compute_band_trace() returns correct geometry
## for the Build Mode autoshadow overlay, and that validate_all_difficulties()
## passes all three difficulties for the official Zone 1 levels.
##
## Run with:
##   godot --headless --path . --script tests/integration/build_mode_overlay_test.gd
extends SceneTree

var _failures: PackedStringArray = []


func _init() -> void:
	await process_frame
	await process_frame

	_test_band_trace_basic()
	_test_band_trace_empty_on_no_obstacles()
	_test_band_trace_narrows_on_hard()
	_test_z1_levels_all_diff_pass()

	print("==== BUILD MODE OVERLAY TEST ====")
	if _failures.is_empty():
		print("All build-mode overlay contracts hold.")
		print("BUILD_MODE_OVERLAY_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("BUILD_MODE_OVERLAY_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


func _load_level(level_id: String) -> Dictionary:
	var path: String = "res://assets/levels/%s.brl" % level_id
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed as Dictionary


func _test_band_trace_basic() -> void:
	var data: Dictionary = _make_level([
		{"beat_index": 4.0, "lane_position": 0.5, "obstacle_type": "pressure_wall",
			"parameters": {"intensity": 0.5, "gap_y_normalized": 0.5}},
	])
	var trace: Array[Dictionary] = PlayabilityValidator.compute_band_trace(data, "Normal")
	if trace.is_empty():
		_fail("compute_band_trace basic: got empty trace for level with one gate")
		return
	var entry: Dictionary = trace[0] as Dictionary
	if not entry.has("beat") or not entry.has("lo") or not entry.has("hi"):
		_fail("compute_band_trace basic: trace entry missing beat/lo/hi keys")
		return
	var lo: float = float(entry.get("lo", 0.0))
	var hi: float = float(entry.get("hi", 0.0))
	if lo >= hi:
		_fail("compute_band_trace basic: lo (%.0f) >= hi (%.0f)" % [lo, hi])
		return
	if lo < 60.0 or hi > 1860.0:
		_fail("compute_band_trace basic: band [%.0f,%.0f] out of canvas bounds [60,1860]" % [lo, hi])
		return
	print("  PASS: compute_band_trace basic — beat=%.1f lo=%.0f hi=%.0f" % [
			float(entry.get("beat", 0)), lo, hi])


func _test_band_trace_empty_on_no_obstacles() -> void:
	var data: Dictionary = _make_level([])
	var trace: Array[Dictionary] = PlayabilityValidator.compute_band_trace(data, "Normal")
	if not trace.is_empty():
		_fail("compute_band_trace empty: expected empty trace for level with no gates, got %d entries" % trace.size())
	else:
		print("  PASS: compute_band_trace empty level → empty trace")


func _test_band_trace_narrows_on_hard() -> void:
	# Same gate at Normal vs Hard — Hard should give a smaller (narrower) band.
	var data: Dictionary = _make_level([
		{"beat_index": 4.0, "lane_position": 0.5, "obstacle_type": "pressure_wall",
			"parameters": {"intensity": 0.5, "gap_y_normalized": 0.5}},
	])
	var normal_trace: Array[Dictionary] = PlayabilityValidator.compute_band_trace(data, "Normal")
	var hard_trace: Array[Dictionary] = PlayabilityValidator.compute_band_trace(data, "Hard")
	if normal_trace.is_empty() or hard_trace.is_empty():
		_fail("compute_band_trace difficulty: got empty trace")
		return
	var n_entry: Dictionary = normal_trace[0] as Dictionary
	var h_entry: Dictionary = hard_trace[0] as Dictionary
	var n_size: float = float(n_entry.get("hi", 0)) - float(n_entry.get("lo", 0))
	var h_size: float = float(h_entry.get("hi", 0)) - float(h_entry.get("lo", 0))
	if h_size >= n_size:
		_fail("compute_band_trace Hard should be narrower than Normal: Hard=%.0f Normal=%.0f" % [h_size, n_size])
	else:
		print("  PASS: Hard band (%.0fpx) narrower than Normal (%.0fpx)" % [h_size, n_size])


func _test_z1_levels_all_diff_pass() -> void:
	for level_id: String in ["z1-l1", "z1-l2", "z1-l3"]:
		var data: Dictionary = _load_level(level_id)
		if data.is_empty():
			print("  SKIP: %s not found" % level_id)
			continue
		var all_errors: Dictionary = PlayabilityValidator.validate_all_difficulties(data)
		var any_fail: bool = false
		for diff: String in ["Easy", "Normal", "Hard"]:
			var errs: Array = all_errors.get(diff, []) as Array
			if not errs.is_empty():
				_fail("%s [%s]: %s" % [level_id, diff, str(errs)])
				any_fail = true
		if not any_fail:
			print("  PASS: %s all 3 difficulties — no errors" % level_id)


func _make_level(beat_entries: Array) -> Dictionary:
	return {
		"schema_version": "1.1",
		"metadata": {
			"id": "a1b2c3d4-e5f6-4789-8abc-def012345678",
			"name": "Test Level",
			"zone": 1,
			"bpm": 100.0,
			"bpm_variable": false,
			"difficulty": 1,
			"author": "test",
			"created_at": "2026-01-01T00:00:00",
			"is_official": false,
			"total_beats": 16
		},
		"music": {
			"filename": "placeholder.wav",
			"loop": true,
			"loop_start_beat": 0,
			"preview_start_beat": 0,
			"preview_duration_beats": 8,
			"beat_offset_ms": 0.0,
			"volume_db": 0.0
		},
		"beat_map": beat_entries.duplicate(true),
		"collectibles": [],
		"speed_zones": [],
		"background": {
			"asset_key": "bg_zone_1",
			"parallax_layers": [],
			"color_override": "",
			"shader_key": "",
			"particle_key": ""
		},
		"unlock_requirements": {
			"required_zone_clear": null,
			"required_level_id": null,
			"min_total_stars": 0
		},
		"par_score": {
			"one_star": 100,
			"two_star": 500,
			"three_star": 1000,
			"max_possible": 1500
		}
	}
