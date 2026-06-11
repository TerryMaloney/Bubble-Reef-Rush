## save_v3_test.gd — Save schema v3 migration and accessor tests.
## Uses root.get_node("SaveSystem") to avoid compile-time autoload resolution.
extends SceneTree

const PROFILE: String = "test_v3_profile"

var _failures: int = 0
var _ss: Node = null


func _init() -> void:
	await process_frame
	await process_frame
	_ss = root.get_node("SaveSystem")
	_run_all()
	print("==== SAVE V3 TEST ====")
	if _failures == 0:
		print("All SaveSystem v3 contracts hold.")
		print("SAVE_V3_OK")
		quit(0)
	else:
		print("SAVE_V3_FAIL (%d failures)" % _failures)
		quit(1)


func _run_all() -> void:
	_test_fresh_profile_is_v3()
	_test_v2_migrates_to_v3()
	_test_v2_data_preserved()
	_test_v3_defaults()
	_test_power_unlocked_accessors()
	_test_build_unlock_accessors()
	_test_blueprint_accessors()
	_test_workshop_rank()
	_test_secret_exit_accessors()
	_test_mutator_unlock_accessors()
	_test_rule_card_unlock_accessors()
	_test_radio_key_accessors()
	_test_world_station_accessors()


func _pass(name: String) -> void:
	print("  PASS: %s" % name)


func _fail(name: String, msg: String) -> void:
	_failures += 1
	print("  FAIL: %s — %s" % [name, msg])


func _cleanup() -> void:
	var dir: String = "user://profiles/%s/" % PROFILE
	for fname: String in ["progress.json", "progress.json.bak", "progress_v2.json.bak"]:
		var p: String = dir + fname
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	if DirAccess.dir_exists_absolute(dir):
		DirAccess.remove_absolute(dir)


func _write_raw(payload: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute("user://profiles/%s/" % PROFILE)
	var path: String = "user://profiles/%s/progress.json" % PROFILE
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(payload))
	f.close()


func _test_fresh_profile_is_v3() -> void:
	_cleanup()
	_ss.ensure_profile(PROFILE)
	var data: Dictionary = _ss.load_progress(PROFILE) as Dictionary
	if int(data.get("version", 0)) != 3:
		_fail("fresh profile is v3", "version=%d" % int(data.get("version", 0)))
	elif not data.has("powers_unlocked"):
		_fail("fresh profile has powers_unlocked", "key missing")
	elif not data.has("build_unlocks"):
		_fail("fresh profile has build_unlocks", "key missing")
	else:
		_pass("fresh profile is v3")
	_cleanup()


func _test_v2_migrates_to_v3() -> void:
	var v2: Dictionary = {
		"version": 2, "profile_id": PROFILE, "total_stars": 7, "coins": 50,
		"levels": {"z1-l1": {"best_score": 300, "best_stars": 2, "attempts": 3,
			"best_progress_pct": 100.0, "treasure_coins": [true, false, false],
			"practice_best_pct": 60.0}},
		"characters": {"default_fish": true, "zap": true},
		"cosmetics": {"owned": [], "equipped": {"trail": "", "ring": "", "palette": ""}},
		"achievements": {"first_blood": true},
		"settings": {"timing_offset_ms": 0.0, "reduced_motion": false,
			"wide_timing_windows": false, "text_scale": 1.0,
			"colorblind_judgements": false, "volume_master": 1.0,
			"volume_music": 1.0, "volume_sfx": 1.0}
	}
	_write_raw(v2)
	var data: Dictionary = _ss.load_progress(PROFILE) as Dictionary
	if int(data.get("version", 0)) != 3:
		_fail("v2 migrates to v3", "version=%d" % int(data.get("version", 0)))
	else:
		_pass("v2 migrates to v3")
	_cleanup()


func _test_v2_data_preserved() -> void:
	var v2: Dictionary = {
		"version": 2, "profile_id": PROFILE, "total_stars": 7, "coins": 50,
		"levels": {"z1-l1": {"best_score": 300, "best_stars": 2, "attempts": 3,
			"best_progress_pct": 100.0, "treasure_coins": [true, false, false],
			"practice_best_pct": 60.0}},
		"characters": {"default_fish": true, "zap": true},
		"cosmetics": {"owned": [], "equipped": {"trail": "", "ring": "", "palette": ""}},
		"achievements": {"first_blood": true},
		"settings": {"timing_offset_ms": 0.0, "reduced_motion": false,
			"wide_timing_windows": false, "text_scale": 1.0,
			"colorblind_judgements": false, "volume_master": 1.0,
			"volume_music": 1.0, "volume_sfx": 1.0}
	}
	_write_raw(v2)
	var data: Dictionary = _ss.load_progress(PROFILE) as Dictionary
	var ok: bool = true
	if int(data.get("total_stars", 0)) != 7:
		_fail("v2 total_stars preserved", "got %d" % int(data.get("total_stars", 0)))
		ok = false
	if int(data.get("coins", 0)) != 50:
		_fail("v2 coins preserved", "got %d" % int(data.get("coins", 0)))
		ok = false
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	if not levels.has("z1-l1"):
		_fail("v2 level data preserved", "z1-l1 missing")
		ok = false
	else:
		var l: Dictionary = levels["z1-l1"] as Dictionary
		if int(l.get("best_score", 0)) != 300:
			_fail("v2 level best_score preserved", "got %d" % int(l.get("best_score", 0)))
			ok = false
	if not bool((data.get("characters", {}) as Dictionary).get("zap", false)):
		_fail("v2 characters preserved", "zap missing")
		ok = false
	if not bool((data.get("achievements", {}) as Dictionary).get("first_blood", false)):
		_fail("v2 achievements preserved", "first_blood missing")
		ok = false
	if ok:
		_pass("v2 data preserved after migration")
	_cleanup()


func _test_v3_defaults() -> void:
	_ss.ensure_profile(PROFILE)
	var data: Dictionary = _ss.load_progress(PROFILE) as Dictionary
	var ok: bool = true
	if not bool((data.get("powers_unlocked", {}) as Dictionary).get("bubble_burst", false)):
		_fail("v3 default bubble_burst unlocked", "missing")
		ok = false
	var obs: Array = ((data.get("build_unlocks", {}) as Dictionary).get("obstacles", []) as Array)
	if not ("coral_spike" in obs):
		_fail("v3 default coral_spike in build_unlocks", "missing")
		ok = false
	if not ("ocean" in (data.get("world_stations_unlocked", []) as Array)):
		_fail("v3 default ocean station", "missing")
		ok = false
	if not ("tiny_pebble" in (data.get("mutators_unlocked", []) as Array)):
		_fail("v3 default tiny_pebble mutator", "missing")
		ok = false
	if not ("beat_my_score" in (data.get("rule_cards_unlocked", []) as Array)):
		_fail("v3 default beat_my_score rule card", "missing")
		ok = false
	if ok:
		_pass("v3 defaults correct")
	_cleanup()


func _test_power_unlocked_accessors() -> void:
	_ss.ensure_profile(PROFILE)
	var ok: bool = true
	if not _ss.get_power_unlocked(PROFILE, "bubble_burst"):
		_fail("get_power_unlocked bubble_burst default true", "returned false")
		ok = false
	if _ss.get_power_unlocked(PROFILE, "echo_shield"):
		_fail("get_power_unlocked echo_shield default false", "returned true")
		ok = false
	_ss.set_power_unlocked(PROFILE, "echo_shield")
	if not _ss.get_power_unlocked(PROFILE, "echo_shield"):
		_fail("set_power_unlocked persists", "still false")
		ok = false
	if _ss.get_equipped_power(PROFILE) != "bubble_burst":
		_fail("get_equipped_power default", "not bubble_burst")
		ok = false
	_ss.set_equipped_power(PROFILE, "echo_shield")
	if _ss.get_equipped_power(PROFILE) != "echo_shield":
		_fail("set_equipped_power persists", "not echo_shield")
		ok = false
	if ok:
		_pass("power unlocked accessors")
	_cleanup()


func _test_build_unlock_accessors() -> void:
	_ss.ensure_profile(PROFILE)
	var ok: bool = true
	if not _ss.has_build_unlock(PROFILE, "obstacles", "coral_spike"):
		_fail("has_build_unlock coral_spike default", "returned false")
		ok = false
	if _ss.has_build_unlock(PROFILE, "obstacles", "anchor_chain"):
		_fail("has_build_unlock anchor_chain default false", "returned true")
		ok = false
	_ss.add_build_unlock(PROFILE, "obstacles", "anchor_chain")
	if not _ss.has_build_unlock(PROFILE, "obstacles", "anchor_chain"):
		_fail("add_build_unlock persists", "still false")
		ok = false
	var obs: Array = _ss.get_build_unlocks(PROFILE, "obstacles")
	if not ("anchor_chain" in obs):
		_fail("get_build_unlocks contains anchor_chain", "missing")
		ok = false
	if ok:
		_pass("build unlock accessors")
	_cleanup()


func _test_blueprint_accessors() -> void:
	_ss.ensure_profile(PROFILE)
	var bps: Array = _ss.get_blueprints(PROFILE)
	if bps.size() != 0:
		_fail("blueprints default empty", "size=%d" % bps.size())
		_cleanup()
		return
	_ss.add_blueprint(PROFILE, "bubble_cannon")
	bps = _ss.get_blueprints(PROFILE)
	if not ("bubble_cannon" in bps):
		_fail("add_blueprint persists", "missing")
		_cleanup()
		return
	_ss.add_blueprint(PROFILE, "bubble_cannon")
	bps = _ss.get_blueprints(PROFILE)
	if bps.size() != 1:
		_fail("add_blueprint no duplicates", "size=%d" % bps.size())
		_cleanup()
		return
	_pass("blueprint accessors")
	_cleanup()


func _test_workshop_rank() -> void:
	_ss.ensure_profile(PROFILE)
	if _ss.get_workshop_rank(PROFILE) != 0:
		_fail("workshop_rank default 0", "got %d" % _ss.get_workshop_rank(PROFILE))
		_cleanup()
		return
	_ss.add_workshop_xp(PROFILE, 100)
	if _ss.get_workshop_rank(PROFILE) != 1:
		_fail("100xp = rank 1", "got %d" % _ss.get_workshop_rank(PROFILE))
		_cleanup()
		return
	_ss.add_workshop_xp(PROFILE, 200)
	if _ss.get_workshop_rank(PROFILE) != 2:
		_fail("300xp = rank 2", "got %d" % _ss.get_workshop_rank(PROFILE))
		_cleanup()
		return
	_pass("workshop rank progression")
	_cleanup()


func _test_secret_exit_accessors() -> void:
	_ss.ensure_profile(PROFILE)
	if _ss.get_secret_exit_found(PROFILE, "z1-l3", "exit_a"):
		_fail("secret exit default false", "returned true")
		_cleanup()
		return
	_ss.set_secret_exit_found(PROFILE, "z1-l3", "exit_a")
	if not _ss.get_secret_exit_found(PROFILE, "z1-l3", "exit_a"):
		_fail("set_secret_exit_found persists", "still false")
		_cleanup()
		return
	if _ss.get_secret_exit_found(PROFILE, "z1-l3", "exit_b"):
		_fail("different exit still false", "returned true")
		_cleanup()
		return
	_pass("secret exit accessors")
	_cleanup()


func _test_mutator_unlock_accessors() -> void:
	_ss.ensure_profile(PROFILE)
	if not _ss.get_mutator_unlocked(PROFILE, "tiny_pebble"):
		_fail("tiny_pebble default unlocked", "returned false")
		_cleanup()
		return
	if _ss.get_mutator_unlocked(PROFILE, "reverse_buoyancy"):
		_fail("reverse_buoyancy default locked", "returned true")
		_cleanup()
		return
	_ss.add_mutator_unlock(PROFILE, "reverse_buoyancy")
	if not _ss.get_mutator_unlocked(PROFILE, "reverse_buoyancy"):
		_fail("add_mutator_unlock persists", "still false")
		_cleanup()
		return
	_pass("mutator unlock accessors")
	_cleanup()


func _test_rule_card_unlock_accessors() -> void:
	_ss.ensure_profile(PROFILE)
	if not _ss.get_rule_card_unlocked(PROFILE, "beat_my_score"):
		_fail("beat_my_score default unlocked", "returned false")
		_cleanup()
		return
	if _ss.get_rule_card_unlocked(PROFILE, "race_ghost"):
		_fail("race_ghost default locked", "returned true")
		_cleanup()
		return
	_ss.add_rule_card_unlock(PROFILE, "race_ghost")
	if not _ss.get_rule_card_unlocked(PROFILE, "race_ghost"):
		_fail("add_rule_card_unlock persists", "still false")
		_cleanup()
		return
	_pass("rule card unlock accessors")
	_cleanup()


func _test_radio_key_accessors() -> void:
	_ss.ensure_profile(PROFILE)
	if _ss.has_radio_key(PROFILE, "space_key"):
		_fail("radio key default false", "returned true")
		_cleanup()
		return
	_ss.add_radio_key(PROFILE, "space_key")
	if not _ss.has_radio_key(PROFILE, "space_key"):
		_fail("add_radio_key persists", "still false")
		_cleanup()
		return
	_pass("radio key accessors")
	_cleanup()


func _test_world_station_accessors() -> void:
	_ss.ensure_profile(PROFILE)
	var stations: Array = _ss.get_world_stations_unlocked(PROFILE)
	if not ("ocean" in stations):
		_fail("ocean station default unlocked", "missing")
		_cleanup()
		return
	if "space_bubble" in stations:
		_fail("space_bubble default locked", "present")
		_cleanup()
		return
	_ss.unlock_world_station(PROFILE, "space_bubble")
	stations = _ss.get_world_stations_unlocked(PROFILE)
	if not ("space_bubble" in stations):
		_fail("unlock_world_station persists", "missing")
		_cleanup()
		return
	_pass("world station accessors")
	_cleanup()
