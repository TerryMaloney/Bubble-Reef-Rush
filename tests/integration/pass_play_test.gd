## pass_play_test.gd — Phase 18 contracts for PassPlaySession.
##
## Tests:
##   1. profile_rotation         — get_current_profile() rotates after advance_turn().
##   2. score_aggregation        — submit_score stores best score per player.
##   3. funny_title_champion     — score >= 900 yields "Reef Champion".
##   4. funny_title_rookie       — score < 300 yields "Bubble Rookie".
##   5. session_ends_signal      — advance_turn() after all attempts emits pass_play_session_ended.
##
## Run with:
##   godot --headless --path . --script tests/integration/pass_play_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_profile_rotation(root)
	_test_score_aggregation(root)
	_test_funny_title_champion(root)
	_test_funny_title_rookie(root)
	_test_session_ends_signal(root)

	print("Pass-play tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("PASS_PLAY_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. profile_rotation
func _test_profile_rotation(_root: Node) -> void:
	var sess = load("res://src/core/PassPlaySession.gd").new()
	var profiles: Array[String] = ["alice", "bob"]
	sess.setup(profiles, "z1-l1", 1)

	var first: String = sess.get_current_profile()
	if first != "alice":
		_fail("profile_rotation", "expected alice first, got '%s'" % first)
		return

	var still_active: bool = sess.advance_turn()
	if not still_active:
		_fail("profile_rotation", "advance_turn should return true (bob still has 0 attempts)")
		return

	var second: String = sess.get_current_profile()
	if second != "bob":
		_fail("profile_rotation", "expected bob after advance, got '%s'" % second)
		return

	_ok("profile_rotation")


## 2. score_aggregation
func _test_score_aggregation(_root: Node) -> void:
	var sess = load("res://src/core/PassPlaySession.gd").new()
	var profiles: Array[String] = ["alice", "bob"]
	sess.setup(profiles, "z1-l1", 1)

	sess.submit_score("alice", 500)
	sess.submit_score("bob", 300)

	var scores: Dictionary = sess.get_scores()
	if int(scores.get("alice", 0)) != 500:
		_fail("score_aggregation", "alice score expected 500, got %d" % int(scores.get("alice", 0)))
		return

	_ok("score_aggregation")


## 3. funny_title_champion
func _test_funny_title_champion(_root: Node) -> void:
	var sess = load("res://src/core/PassPlaySession.gd").new()
	var profiles: Array[String] = ["alice"]
	sess.setup(profiles, "z1-l1", 1)

	# Set score directly via set() to bypass submit_score attempt counting.
	sess.set("_scores", {"alice": 950})

	var title: String = sess.funny_title("alice")
	if title != "Reef Champion":
		_fail("funny_title_champion", "expected 'Reef Champion', got '%s'" % title)
		return

	_ok("funny_title_champion")


## 4. funny_title_rookie
func _test_funny_title_rookie(_root: Node) -> void:
	var sess = load("res://src/core/PassPlaySession.gd").new()
	var profiles: Array[String] = ["alice"]
	sess.setup(profiles, "z1-l1", 1)

	sess.set("_scores", {"alice": 50})

	var title: String = sess.funny_title("alice")
	if title != "Bubble Rookie":
		_fail("funny_title_rookie", "expected 'Bubble Rookie', got '%s'" % title)
		return

	_ok("funny_title_rookie")


## 5. session_ends_signal
func _test_session_ends_signal(root: Node) -> void:
	var sess = load("res://src/core/PassPlaySession.gd").new()
	var profiles: Array[String] = ["alice"]
	sess.setup(profiles, "z1-l1", 1)

	sess.submit_score("alice", 200)

	var event_bus: Node = root.get_node("EventBus")
	var received: Array = []
	event_bus.pass_play_session_ended.connect(func(_results: Array) -> void:
		received.append(1)
	)

	# alice has 1 attempt used; advance_turn should detect all_done and emit signal.
	var still_active: bool = sess.advance_turn()
	if still_active:
		_fail("session_ends_signal", "advance_turn should return false when session ends")
		return
	if received.is_empty():
		_fail("session_ends_signal", "pass_play_session_ended signal was not received")
		return

	_ok("session_ends_signal")
