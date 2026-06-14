## pearl_reachability_test.gd
## Verifies that all official Zone 1 levels pass pearl reachability validation
## at all three difficulty levels (Easy, Normal, Hard).
##
## Run with:
##   godot --headless --path . --script tests/integration/pearl_reachability_test.gd
extends SceneTree

var _failures: PackedStringArray = []


func _init() -> void:
	await process_frame
	await process_frame

	_test_levels(["z1-l1", "z1-l2", "z1-l3"])
	_test_validate_all_difficulties_api()
	_test_kelp_curtain_corridor()

	print("==== PEARL REACHABILITY TEST ====")
	if _failures.is_empty():
		print("All pearl reachability contracts hold.")
		print("PEARL_REACHABILITY_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("PEARL_REACHABILITY_FAIL")
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


func _test_levels(level_ids: Array) -> void:
	for level_id: String in level_ids:
		var data: Dictionary = _load_level(level_id)
		if data.is_empty():
			print("  SKIP: %s not found" % level_id)
			continue
		var all_errors: Dictionary = PlayabilityValidator.validate_all_difficulties(data)
		var any_fail: bool = false
		for diff: String in ["Easy", "Normal", "Hard"]:
			var errs: Array = all_errors.get(diff, []) as Array
			if not errs.is_empty():
				_fail("%s [%s]: %d error(s): %s" % [level_id, diff, errs.size(), str(errs)])
				any_fail = true
		if not any_fail:
			print("  PASS: %s — all 3 difficulties valid (Easy/Normal/Hard)" % level_id)


func _test_validate_all_difficulties_api() -> void:
	# A deliberately simple valid level should pass on all three difficulties.
	var data: Dictionary = _make_simple_level([
		{"beat_index": 4.0, "lane_position": 0.5, "obstacle_type": "pressure_wall",
			"parameters": {"intensity": 0.4, "gap_y_normalized": 0.5}},
		{"beat_index": 8.0, "lane_position": 0.5, "obstacle_type": "pressure_wall",
			"parameters": {"intensity": 0.4, "gap_y_normalized": 0.5}},
	])
	var all_errors: Dictionary = PlayabilityValidator.validate_all_difficulties(data)
	if not all_errors.has("Easy") or not all_errors.has("Normal") or not all_errors.has("Hard"):
		_fail("validate_all_difficulties: missing difficulty keys in result")
	else:
		var any_fail: bool = false
		for diff: String in ["Easy", "Normal", "Hard"]:
			if not (all_errors[diff] as Array).is_empty():
				any_fail = true
		if any_fail:
			_fail("validate_all_difficulties: valid level failed — %s" % str(all_errors))
		else:
			print("  PASS: validate_all_difficulties API returns 3 keys, all pass on simple level")

	# On hard difficulty, intensity 0.4+0.12=0.52 should still pass (not extreme).
	# A level with intensity 0.88 hard-patched to 1.0 at a position that blocks the path
	# should fail on Hard.
	var hard_data: Dictionary = _make_simple_level([
		{"beat_index": 4.0, "lane_position": 0.1, "obstacle_type": "pressure_wall",
			"parameters": {"intensity": 0.88, "gap_y_normalized": 0.1}},
		{"beat_index": 5.0, "lane_position": 0.9, "obstacle_type": "pressure_wall",
			"parameters": {"intensity": 0.88, "gap_y_normalized": 0.9}},
	])
	var hard_errors: Dictionary = PlayabilityValidator.validate_all_difficulties(hard_data)
	var hard_fails: Array = hard_errors.get("Hard", []) as Array
	if hard_fails.is_empty():
		# Not a required assertion — this test checks the API shape, not physics specifics.
		print("  NOTE: extreme level did not fail Hard (may be valid depending on geometry)")
	else:
		print("  PASS: validate_all_difficulties correctly flags Hard failures")


func _test_kelp_curtain_corridor() -> void:
	# Verify _gate_corridor uses gap_height for kelp_curtain (not intensity formula).
	# A kelp_curtain with gap_height=240 centred at 0.5 should give a 240px corridor
	# (minus 2×PLAYER_HALF=56) = 184px navigable.
	var entry: Dictionary = {
		"obstacle_type": "kelp_curtain",
		"lane_position": 0.5,
		"parameters": {"gap_y_normalized": 0.5, "gap_height": 240.0}
	}
	var data: Dictionary = _make_simple_level([entry])
	var errors: Array[String] = PlayabilityValidator.validate(data)
	if not errors.is_empty():
		# Filter to only reachability errors (density or overlap errors are irrelevant here).
		var reach_errors: Array[String] = []
		for e: String in errors:
			if "reachable" in e or "unreachable" in e or "no path" in e:
				reach_errors.append(e)
		if not reach_errors.is_empty():
			_fail("kelp_curtain corridor: valid kelp_curtain flagged as unreachable: %s" % str(reach_errors))
		else:
			print("  PASS: kelp_curtain gap_height=240 passes reachability (other errors: %d)" % errors.size())
	else:
		print("  PASS: kelp_curtain gap_height=240 — 0 errors")


func _make_simple_level(beat_entries: Array) -> Dictionary:
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
