## buildmode_test.gd — Phase 12 contracts for Build Mode data layer.
##
## Tests:
##   1. BuildSession create_new: schema fields present, dirty=true, played_through=false
##   2. BuildSession mutations: add/remove entries, dirty propagates, played_through clears
##   3. BrlSerializer round-trip: JSON serialize → parse → deep-equal on key fields
##   4. PlayabilityValidator: valid level passes, impossible movement detected
##   5. PlayabilityValidator density cap: zone-1 level over 4/measure flagged
##   6. PlayabilityValidator overlap rule: two obstacles within 80 px at same beat flagged
##   7. DifficultyTagger: known score/tag table for Beginner/Intermediate/Advanced/Expert
##   8. DifficultyTagger override-down-only: lower allowed, higher rejected
##   9. Played-through gate: BrlSerializer rejects save without played_through
##  10. Contract: PlayabilityValidator agrees with check_movements.py on z1-l1.brl
##
## Run with:
##   godot --headless --path . --script tests/integration/buildmode_test.gd
extends SceneTree

var _failures: PackedStringArray = []


func _init() -> void:
	await process_frame
	await process_frame

	_test_session_create()
	_test_session_mutations()
	_test_brl_round_trip()
	_test_validator_valid()
	_test_validator_impossible_movement()
	_test_validator_density_cap()
	_test_validator_overlap()
	_test_tagger_table()
	_test_tagger_override()
	_test_played_through_gate()
	_test_contract_z1l1()

	print("==== BUILDMODE TEST ====")
	if _failures.is_empty():
		print("All Phase 12 build-mode contracts hold.")
		print("BUILDMODE_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("BUILDMODE_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


## ── 1. BuildSession create_new ────────────────────────────────────────────────
func _test_session_create() -> void:
	var s := BuildSession.new()
	s.create_new("tester", 1)

	var d := s.get_data()
	if not d.has("schema_version"):
		_fail("BuildSession create_new: missing schema_version")
	elif str(d["schema_version"]) != "1.1":
		_fail("BuildSession create_new: schema_version != '1.1', got '%s'" % d["schema_version"])

	if not d.has("beat_map") or not (d["beat_map"] is Array):
		_fail("BuildSession create_new: beat_map missing or not Array")

	if not s.dirty:
		_fail("BuildSession create_new: dirty should be true after create_new")

	if s.played_through:
		_fail("BuildSession create_new: played_through should be false after create_new")

	var level_id: String = str((d["metadata"] as Dictionary).get("id", ""))
	if level_id.is_empty():
		_fail("BuildSession create_new: metadata.id is empty")
	else:
		print("BuildSession create_new: id='%s', dirty=%s — OK" % [level_id, s.dirty])


## ── 2. BuildSession mutations ─────────────────────────────────────────────────
func _test_session_mutations() -> void:
	var s := BuildSession.new()
	s.create_new("tester", 1)
	s.mark_saved()
	s.mark_played_through()

	if s.dirty:
		_fail("BuildSession mutation: dirty should be false after mark_saved")
	if not s.played_through:
		_fail("BuildSession mutation: played_through should be true after mark_played_through")

	# add_beat_entry should set dirty and clear played_through.
	s.add_beat_entry({"beat_index": 4.0, "lane_position": 0.5, "obstacle_type": "coral_spike", "parameters": {}})

	if not s.dirty:
		_fail("BuildSession mutation: dirty should be true after add_beat_entry")
	if s.played_through:
		_fail("BuildSession mutation: played_through should clear after add_beat_entry")
	if s.beat_count() != 1:
		_fail("BuildSession mutation: beat_count should be 1 after add, got %d" % s.beat_count())

	s.remove_beat_entry(0)
	if s.beat_count() != 0:
		_fail("BuildSession mutation: beat_count should be 0 after remove, got %d" % s.beat_count())

	print("BuildSession mutations: dirty/played_through propagation — OK")


## ── 3. BrlSerializer round-trip ──────────────────────────────────────────────
func _test_brl_round_trip() -> void:
	var s := BuildSession.new()
	s.create_new("tester", 2)
	s.add_beat_entry({
		"beat_index": 4.0,
		"lane_position": 0.5,
		"obstacle_type": "kelp_curtain",
		"parameters": {"gap_y_normalized": 0.5, "gap_height": 240.0, "sway_enabled": true}
	})

	var d_orig: Dictionary = s.get_data()
	var json_str: String = BrlSerializer.to_json_string(d_orig)

	if json_str.is_empty():
		_fail("BrlSerializer round-trip: to_json_string returned empty string")
		return

	var d_rt: Dictionary = BrlSerializer.from_json_string(json_str)
	if d_rt.is_empty():
		_fail("BrlSerializer round-trip: from_json_string returned empty dict")
		return

	# Compare key structural fields.
	var orig_id: String = str((d_orig["metadata"] as Dictionary).get("id", "X"))
	var rt_id: String = str((d_rt.get("metadata", {}) as Dictionary).get("id", "Y"))
	if orig_id != rt_id:
		_fail("BrlSerializer round-trip: id mismatch '%s' vs '%s'" % [orig_id, rt_id])
		return

	var orig_beats: Array = d_orig["beat_map"] as Array
	var rt_beats: Array = (d_rt.get("beat_map", []) as Array)
	if orig_beats.size() != rt_beats.size():
		_fail("BrlSerializer round-trip: beat_map size mismatch %d vs %d" % [orig_beats.size(), rt_beats.size()])
		return

	var orig_type: String = str((orig_beats[0] as Dictionary).get("obstacle_type", ""))
	var rt_type: String = str((rt_beats[0] as Dictionary).get("obstacle_type", ""))
	if orig_type != rt_type:
		_fail("BrlSerializer round-trip: obstacle_type mismatch '%s' vs '%s'" % [orig_type, rt_type])
		return

	print("BrlSerializer round-trip: id + beat_map deep-equal — OK")


## ── 4. PlayabilityValidator: valid level passes ──────────────────────────────
func _test_validator_valid() -> void:
	var data: Dictionary = _make_simple_level(1, [
		{"beat_index": 4.0, "lane_position": 0.5, "obstacle_type": "pressure_wall",
			"parameters": {"intensity": 0.5, "gap_y_normalized": 0.5}},
		{"beat_index": 8.0, "lane_position": 0.5, "obstacle_type": "pressure_wall",
			"parameters": {"intensity": 0.5, "gap_y_normalized": 0.5}},
	])
	var errors: Array[String] = PlayabilityValidator.validate(data)
	if not errors.is_empty():
		_fail("PlayabilityValidator valid: expected no errors, got: %s" % str(errors))
	else:
		print("PlayabilityValidator valid level: no errors — OK")


## ── 5. PlayabilityValidator: impossible movement flagged ────────────────────
func _test_validator_impossible_movement() -> void:
	# At 120 BPM, 1 beat = 0.5s.  Max up in 0.5s = 700*0.5/1920 = 0.182 normalized.
	# Jump from 0.9 to 0.1 in 1 beat = delta -0.8 upward >> budget 0.125 → error.
	var data: Dictionary = _make_simple_level(1, [
		{"beat_index": 4.0, "lane_position": 0.9, "obstacle_type": "pressure_wall",
			"parameters": {"intensity": 0.5, "gap_y_normalized": 0.9}},
		{"beat_index": 5.0, "lane_position": 0.1, "obstacle_type": "pressure_wall",
			"parameters": {"intensity": 0.5, "gap_y_normalized": 0.1}},
	])
	var errors: Array[String] = PlayabilityValidator.validate(data)
	if errors.is_empty():
		_fail("PlayabilityValidator impossible movement: expected errors, got none")
	else:
		print("PlayabilityValidator impossible movement: %d error(s) detected — OK" % errors.size())


## ── 6. PlayabilityValidator: density cap ─────────────────────────────────────
func _test_validator_density_cap() -> void:
	# Zone 1 cap = 4 per measure (4 beats).  Put 5 in measure 0 (beats 0..3.9).
	var entries: Array[Dictionary] = []
	for i: int in range(5):
		entries.append({
			"beat_index": float(i) * 0.5,  # 0.0, 0.5, 1.0, 1.5, 2.0 — all in measure 0
			"lane_position": 0.5,
			"obstacle_type": "coral_spike",
			"parameters": {}
		})
	var data: Dictionary = _make_simple_level(1, entries)
	var errors: Array[String] = PlayabilityValidator.validate(data)
	var found_density: bool = false
	for e: String in errors:
		if "density cap" in e or "exceeds" in e:
			found_density = true
	if not found_density:
		_fail("PlayabilityValidator density cap: zone-1 over-cap not flagged. Errors: %s" % str(errors))
	else:
		print("PlayabilityValidator density cap: zone-1 over-cap detected — OK")


## ── 7. PlayabilityValidator: overlap rule ─────────────────────────────────────
func _test_validator_overlap() -> void:
	# Two obstacles at same beat, y positions 0.3 and 0.33 (63px apart — < 80px).
	var data: Dictionary = _make_simple_level(1, [
		{"beat_index": 4.0, "lane_position": 0.3, "obstacle_type": "coral_spike", "parameters": {}},
		{"beat_index": 4.0, "lane_position": 0.33, "obstacle_type": "coral_spike", "parameters": {}},
	])
	var errors: Array[String] = PlayabilityValidator.validate(data)
	var found_overlap: bool = false
	for e: String in errors:
		if "overlap" in e:
			found_overlap = true
	if not found_overlap:
		_fail("PlayabilityValidator overlap: 63px overlap not flagged. Errors: %s" % str(errors))
	else:
		print("PlayabilityValidator overlap: 63px same-beat overlap detected — OK")


## ── 8. DifficultyTagger: known score/tag table ───────────────────────────────
func _test_tagger_table() -> void:
	# BPM=120, 2 obstacles in 4 beats (avg 2/measure), no speed zones, 1 type.
	# score = (2×2) + (1.0×1.5) + (1×1) + (120/30) = 4+1.5+1+4 = 10.5 → Intermediate
	var data: Dictionary = _make_simple_level(1, [
		{"beat_index": 1.0, "lane_position": 0.3, "obstacle_type": "coral_spike", "parameters": {}},
		{"beat_index": 3.0, "lane_position": 0.7, "obstacle_type": "coral_spike", "parameters": {}},
	])
	(data["metadata"] as Dictionary)["bpm"] = 120.0
	var tag: String = DifficultyTagger.compute_tag(data)
	if tag != "Intermediate":
		_fail("DifficultyTagger table: expected Intermediate, got '%s' (score=%.1f)" % [tag, DifficultyTagger.compute_score(data)])
	else:
		print("DifficultyTagger: BPM=120 2-obstacle → Intermediate (score=%.1f) — OK" % DifficultyTagger.compute_score(data))

	# Beginner check: BPM=60, 0 obstacles, no zones, 0 types.
	# score = (0) + (1.5) + (0) + (60/30) = 3.5 → Beginner (< 9)
	var easy: Dictionary = _make_simple_level(1, [])
	(easy["metadata"] as Dictionary)["bpm"] = 60.0
	var easy_tag: String = DifficultyTagger.compute_tag(easy)
	if easy_tag != "Beginner":
		_fail("DifficultyTagger table: expected Beginner for empty level at 60 BPM, got '%s'" % easy_tag)
	else:
		print("DifficultyTagger: 60 BPM empty → Beginner — OK")

	# Expert check: BPM=180, 12 obstacles in 4 beats, 3 types, speed zone 1.5×.
	# score = (12×2) + (1.5×1.5) + (3) + (180/30) = 24+2.25+3+6 = 35.25 → Expert
	var expert_entries: Array[Dictionary] = []
	var expert_types: Array[String] = ["coral_spike", "kelp_curtain", "bubble_mine"]
	for i: int in range(12):
		expert_entries.append({
			"beat_index": float(i % 4),
			"lane_position": 0.5,
			"obstacle_type": expert_types[i % 3],
			"parameters": {}
		})
	var hard: Dictionary = _make_simple_level(6, expert_entries)
	(hard["metadata"] as Dictionary)["bpm"] = 180.0
	(hard["speed_zones"] as Array).append({"start_beat": 0.0, "end_beat": 16.0, "speed_multiplier": 1.5})
	var hard_tag: String = DifficultyTagger.compute_tag(hard)
	if hard_tag != "Expert":
		_fail("DifficultyTagger table: expected Expert for dense level, got '%s' (score=%.1f)" % [hard_tag, DifficultyTagger.compute_score(hard)])
	else:
		print("DifficultyTagger: dense BPM=180 → Expert (score=%.1f) — OK" % DifficultyTagger.compute_score(hard))


## ── 9. DifficultyTagger override-down-only ───────────────────────────────────
func _test_tagger_override() -> void:
	# Computed = Advanced (rank 3). Override to Intermediate (rank 2) → allowed.
	var result_lower: String = DifficultyTagger.apply_override("Advanced", "Intermediate")
	if result_lower != "Intermediate":
		_fail("DifficultyTagger override: down to Intermediate should be allowed, got '%s'" % result_lower)
	else:
		print("DifficultyTagger override: down to Intermediate allowed — OK")

	# Override to Expert (rank 4) → blocked, returns computed tag.
	var result_higher: String = DifficultyTagger.apply_override("Advanced", "Expert")
	if result_higher != "Advanced":
		_fail("DifficultyTagger override: up to Expert should be blocked (got '%s')" % result_higher)
	else:
		print("DifficultyTagger override: up to Expert blocked — OK")

	if DifficultyTagger.is_valid_override("Intermediate", "Beginner"):
		print("DifficultyTagger override: is_valid_override(down) = true — OK")
	else:
		_fail("DifficultyTagger override: is_valid_override(Intermediate, Beginner) should be true")

	if DifficultyTagger.is_valid_override("Intermediate", "Expert"):
		_fail("DifficultyTagger override: is_valid_override(Intermediate, Expert) should be false")
	else:
		print("DifficultyTagger override: is_valid_override(up) = false — OK")


## ── 10. Played-through gate ──────────────────────────────────────────────────
func _test_played_through_gate() -> void:
	var s := BuildSession.new()
	s.create_new("tester", 1)
	# played_through = false → save should reject.
	var err: String = BrlSerializer.save(s, "test_profile")
	if err.is_empty():
		_fail("Played-through gate: BrlSerializer.save should fail without played_through")
	else:
		print("Played-through gate: save rejected (msg: '%s') — OK" % err)

	# After marking played_through → save proceeds (or fails only on file I/O in headless).
	s.mark_played_through()
	var err2: String = BrlSerializer.save(s, "test_profile")
	# In headless mode user:// dir should be accessible. Accept either "" or an I/O error
	# (not the played_through error).
	var still_gated: bool = "test-play" in err2 or "played" in err2.to_lower()
	if still_gated:
		_fail("Played-through gate: save still rejected after mark_played_through: '%s'" % err2)
	else:
		print("Played-through gate: save proceeds after mark_played_through — OK (err='%s')" % err2)


## ── 11. Contract: validator agrees with check_movements.py on z1-l1 ──────────
func _test_contract_z1l1() -> void:
	# Load the official z1-l1 level (known-good, check_movements.py passes it).
	var path: String = "res://assets/levels/z1-l1.brl"
	if not FileAccess.file_exists(path):
		print("Contract z1-l1: file not found, skipping")
		return

	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		print("Contract z1-l1: cannot open file, skipping")
		return
	var text: String = f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		_fail("Contract z1-l1: JSON parse failed")
		return

	var errors: Array[String] = PlayabilityValidator.validate(parsed as Dictionary)
	if not errors.is_empty():
		_fail("Contract z1-l1: PlayabilityValidator found errors on known-good level: %s" % str(errors))
	else:
		print("Contract z1-l1: PlayabilityValidator agrees with check_movements.py (0 errors) — OK")


# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_simple_level(zone: int, beat_entries: Array) -> Dictionary:
	return {
		"schema_version": "1.1",
		"metadata": {
			"id": "a1b2c3d4-e5f6-4789-8abc-def012345678",
			"name": "Test Level",
			"zone": zone,
			"bpm": 120.0,
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
