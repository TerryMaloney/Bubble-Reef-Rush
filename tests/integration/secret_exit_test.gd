## secret_exit_test.gd — Phase 22 contracts for SecretExit + SaveSystem persistence.
##
## Tests:
##   1. save_persistence     — set_secret_exit_found then get_secret_exit_found returns true.
##   2. dedup                — calling set_secret_exit_found twice is idempotent.
##   3. signal_emitted       — EventBus.secret_exit_found fires on set.
##   4. profile_isolation    — exit found on profile A is not found on profile B.
##   5. obstacle_activate    — SecretExit.activate() persists and sets is_activated().
##
## Run with:
##   godot --headless --path . --script tests/integration/secret_exit_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_save_persistence(root)
	_test_dedup(root)
	_test_signal_emitted(root)
	_test_profile_isolation(root)
	_test_obstacle_activate(root)

	print("Secret exit tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("SECRET_EXIT_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. save_persistence
func _test_save_persistence(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid: String = "se_persist_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	ss.set_secret_exit_found(pid, "z1-l1", "z1_hidden_grotto")
	var found: bool = ss.get_secret_exit_found(pid, "z1-l1", "z1_hidden_grotto")
	if found:
		_ok("save_persistence")
	else:
		_fail("save_persistence", "expected true after set_secret_exit_found")


## 2. dedup
func _test_dedup(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid: String = "se_dedup_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	ss.set_secret_exit_found(pid, "z1-l1", "z1_hidden_grotto")
	ss.set_secret_exit_found(pid, "z1-l1", "z1_hidden_grotto")
	var found: bool = ss.get_secret_exit_found(pid, "z1-l1", "z1_hidden_grotto")
	if found:
		_ok("dedup")
	else:
		_fail("dedup", "expected true after double set")


## 3. signal_emitted
func _test_signal_emitted(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var eb: Node = root.get_node("EventBus")
	var pid: String = "se_sig_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	var received: Array = []
	eb.secret_exit_found.connect(func(_lid: String, _eid: String) -> void:
		received.append(1)
	)

	ss.set_secret_exit_found(pid, "z2-l1", "z2_sunken_chest")

	if not received.is_empty():
		_ok("signal_emitted")
	else:
		_fail("signal_emitted", "EventBus.secret_exit_found was not emitted")


## 4. profile_isolation
func _test_profile_isolation(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid_a: String = "se_iso_a_%d" % Time.get_ticks_msec()
	var pid_b: String = "se_iso_b_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid_a)
	ss.ensure_profile(pid_b)

	ss.set_secret_exit_found(pid_a, "z3-l1", "z3_volcanic_vent")

	var a_found: bool = ss.get_secret_exit_found(pid_a, "z3-l1", "z3_volcanic_vent")
	var b_found: bool = ss.get_secret_exit_found(pid_b, "z3-l1", "z3_volcanic_vent")

	if a_found and not b_found:
		_ok("profile_isolation")
	else:
		_fail("profile_isolation", "a=%s b=%s (want a=true b=false)" % [str(a_found), str(b_found)])


## 5. obstacle_activate
func _test_obstacle_activate(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid: String = "se_obs_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	var exit_node = load("res://src/gameplay/obstacles/SecretExit.gd").new()
	# Fake a setup entry.
	exit_node.setup({"parameters": {"exit_id": "test_exit"}})

	if exit_node.is_activated():
		_fail("obstacle_activate", "should not be activated before activate()")
		return

	exit_node.activate(pid, "z1-l1")

	if not exit_node.is_activated():
		_fail("obstacle_activate", "is_activated() should be true after activate()")
		return

	var found: bool = ss.get_secret_exit_found(pid, "z1-l1", "test_exit")
	if found:
		_ok("obstacle_activate")
	else:
		_fail("obstacle_activate", "save not persisted after activate()")
