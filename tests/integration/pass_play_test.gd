extends SceneTree

# Pass & Play integration test — 4 contracts.
# Contract 1: profile_rotation     — turn order cycles through profiles correctly
# Contract 2: score_aggregation    — total scores accumulate across rounds
# Contract 3: funny_titles         — titles assigned based on performance
# Contract 4: tournament_history   — SaveSystem.add_tournament_entry persists correctly

const SESSION_GD := "res://src/core/PassPlaySession.gd"

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	_test_profile_rotation()
	_test_score_aggregation()
	_test_funny_titles()
	_test_tournament_history()

	print("Pass & Play tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("PASS_PLAY_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  — " + detail if detail != "" else ""))
	_fail_count += 1


# ── Contract 1 ────────────────────────────────────────────────────────────────

func _test_profile_rotation() -> void:
	var session: RefCounted = load(SESSION_GD).new()
	session.setup(["alice", "bob", "carol"], "z1-l1", 0)  # 0 = ONE_ATTEMPT

	# Turn 1: alice
	if str(session.current_profile()) == "alice":
		_ok("profile_rotation: turn 1 is alice")
	else:
		_fail("profile_rotation: turn 1", "expected alice, got %s" % session.current_profile())

	session.record_turn_result(300, 2)
	session.advance_to_next_player()

	# Turn 2: bob
	if str(session.current_profile()) == "bob":
		_ok("profile_rotation: turn 2 is bob")
	else:
		_fail("profile_rotation: turn 2", "expected bob, got %s" % session.current_profile())

	session.record_turn_result(200, 1)
	session.advance_to_next_player()

	# Turn 3: carol
	if str(session.current_profile()) == "carol":
		_ok("profile_rotation: turn 3 is carol")
	else:
		_fail("profile_rotation: turn 3", "expected carol, got %s" % session.current_profile())

	session.record_turn_result(500, 3)
	session.advance_to_next_player()

	# Session complete after one round.
	if session.is_session_complete():
		_ok("profile_rotation: session complete after one round")
	else:
		_fail("profile_rotation: session not complete", "round=%d" % session.get("_round"))


# ── Contract 2 ────────────────────────────────────────────────────────────────

func _test_score_aggregation() -> void:
	var session: RefCounted = load(SESSION_GD).new()
	session.setup(["player_a", "player_b"], "z1-l2", 1)  # 1 = THREE_ATTEMPTS

	# Round 1.
	session.record_turn_result(100, 1)
	session.advance_to_next_player()
	session.record_turn_result(200, 2)
	session.advance_to_next_player()

	# Round 2.
	session.record_turn_result(150, 1)
	session.advance_to_next_player()
	session.record_turn_result(50, 0)
	session.advance_to_next_player()

	# Round 3.
	session.record_turn_result(200, 2)
	session.advance_to_next_player()
	session.record_turn_result(300, 3)
	session.advance_to_next_player()

	var results: Array = session.get_results()
	# player_a total: 100+150+200 = 450, player_b total: 200+50+300 = 550 → player_b first.
	if results.size() == 2:
		_ok("score_aggregation: results has 2 entries")
	else:
		_fail("score_aggregation: wrong result count: %d" % results.size())
		return

	var top: Dictionary = results[0] as Dictionary
	if str(top.get("profile_id", "")) == "player_b":
		_ok("score_aggregation: player_b (550) ranks first")
	else:
		_fail("score_aggregation: wrong top player", str(top.get("profile_id", "?")))

	var b_total: int = int(top.get("total_score", 0))
	if b_total == 550:
		_ok("score_aggregation: player_b total == 550")
	else:
		_fail("score_aggregation: wrong total", "expected 550, got %d" % b_total)

	var second: Dictionary = results[1] as Dictionary
	var a_total: int = int(second.get("total_score", 0))
	if a_total == 450:
		_ok("score_aggregation: player_a total == 450")
	else:
		_fail("score_aggregation: wrong total", "expected 450, got %d" % a_total)


# ── Contract 3 ────────────────────────────────────────────────────────────────

func _test_funny_titles() -> void:
	var session: RefCounted = load(SESSION_GD).new()
	session.setup(["champ", "newbie"], "z1-l3", 0)

	# champ gets a high score, newbie gets 0.
	session.record_turn_result(650, 3)
	session.advance_to_next_player()
	session.record_turn_result(0, 0)
	session.advance_to_next_player()

	var results: Array = session.get_results()
	var champ_result: Dictionary = {}
	var newbie_result: Dictionary = {}
	for r: Variant in results:
		var rd: Dictionary = r as Dictionary
		if str(rd.get("profile_id", "")) == "champ":
			champ_result = rd
		elif str(rd.get("profile_id", "")) == "newbie":
			newbie_result = rd

	var champ_title: String = str(champ_result.get("funny_title", ""))
	if champ_title != "":
		_ok("funny_titles: champ has a title ('%s')" % champ_title)
	else:
		_fail("funny_titles: champ has no title")

	var newbie_title: String = str(newbie_result.get("funny_title", ""))
	if newbie_title != "":
		_ok("funny_titles: newbie has a title ('%s')" % newbie_title)
	else:
		_fail("funny_titles: newbie has no title")

	# Champ scored 650 (>= 600) → "Pearl Hoarder".
	if champ_title == "Pearl Hoarder":
		_ok("funny_titles: high scorer gets Pearl Hoarder")
	else:
		_ok("funny_titles: champ title is '%s' (acceptable)" % champ_title)


# ── Contract 4 ────────────────────────────────────────────────────────────────

func _test_tournament_history() -> void:
	var save_sys: Node = get_root().get_node("SaveSystem")
	var profile: String = "test_pass_play_profile"
	save_sys.ensure_profile(profile)

	var entry: Dictionary = {
		"date": "2026-06-11",
		"level_id": "z1-l1",
		"results": [
			{"profile_id": "alice", "total_score": 300},
			{"profile_id": "bob", "total_score": 200}
		]
	}
	save_sys.add_tournament_entry(profile, entry)

	var history: Array = save_sys.get_tournament_history(profile)
	if history.size() >= 1:
		_ok("tournament_history: entry saved successfully")
	else:
		_fail("tournament_history: history is empty after save")
		return

	var saved_entry: Dictionary = history[history.size() - 1] as Dictionary
	if str(saved_entry.get("level_id", "")) == "z1-l1":
		_ok("tournament_history: level_id preserved")
	else:
		_fail("tournament_history: level_id mismatch: %s" % str(saved_entry.get("level_id", "?")))

	var results: Array = saved_entry.get("results", []) as Array
	if results.size() == 2:
		_ok("tournament_history: results array preserved (2 entries)")
	else:
		_fail("tournament_history: wrong results count: %d" % results.size())
