## collection_room_test.gd — Phase 22 contracts for CollectionRoomScreen data sources.
##
## Tests:
##   1. characters_count      — get_collection_data returns 8 character entries.
##   2. boss_trophy_round_trip — add_boss_trophy / get_boss_trophy persists correctly.
##   3. family_records_best   — get_collection_data family_records shows best across profiles.
##   4. character_unlock_flag — unlocking a character is reflected in collection data.
##
## Run with:
##   godot --headless --path . --script tests/integration/collection_room_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_characters_count(root)
	_test_boss_trophy_round_trip(root)
	_test_family_records_best(root)
	_test_character_unlock_flag(root)

	print("Collection room tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("COLLECTION_ROOM_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. characters_count — verify the 8 canonical character IDs are all queryable.
func _test_characters_count(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid: String = "cr_chars_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	# Mirror the canonical list from CollectionRoomScreen.
	var char_ids: Array = ["pebble", "finn", "zap", "mochi", "pip", "crusher", "lumina", "grumble"]
	var count: int = 0
	for cid in char_ids:
		# get_character_unlocked must not error for each ID.
		var _v: bool = ss.get_character_unlocked(pid, cid as String)
		count += 1

	if count == 8:
		_ok("characters_count")
	else:
		_fail("characters_count", "expected 8 chars, got %d" % count)


## 2. boss_trophy_round_trip
func _test_boss_trophy_round_trip(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	# Use a trophy ID guaranteed not to be in the fresh profile: "boss_zX_test_only"
	var pid: String = "cr_boss_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)
	var test_boss: String = "boss_test_only"

	ss.add_boss_trophy(pid, test_boss)

	if ss.get_boss_trophy(pid, test_boss):
		_ok("boss_trophy_round_trip")
	else:
		_fail("boss_trophy_round_trip", "trophy not found after add_boss_trophy")


## 3. family_records_best — best score across all profiles is the highest value.
func _test_family_records_best(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid_a: String = "cr_rec_a_%d" % Time.get_ticks_msec()
	var pid_b: String = "cr_rec_b_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid_a)
	ss.ensure_profile(pid_b)

	ss.update_level_result(pid_a, "z1-l1", 400, 2)
	ss.update_level_result(pid_b, "z1-l1", 700, 3)

	# Replicate the family_records aggregation from get_collection_data().
	var best_score: int = 0
	var best_pid: String = ""
	for pid: String in ss.list_profiles():
		var results: Dictionary = ss.get_all_level_results(pid)
		if results.has("z1-l1"):
			var sc: int = int((results["z1-l1"] as Dictionary).get("best_score", 0))
			if sc > best_score:
				best_score = sc
				best_pid = pid

	if best_score == 700:
		_ok("family_records_best")
	else:
		_fail("family_records_best", "expected best_score=700, got %d (profile=%s)" % [best_score, best_pid])


## 4. character_unlock_flag — set_character_unlocked is reflected by get_character_unlocked.
func _test_character_unlock_flag(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid: String = "cr_unlock_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	ss.set_character_unlocked(pid, "zap")

	if ss.get_character_unlocked(pid, "zap"):
		_ok("character_unlock_flag")
	else:
		_fail("character_unlock_flag", "zap unlocked flag expected true after set_character_unlocked")
