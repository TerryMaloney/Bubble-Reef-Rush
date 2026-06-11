extends SceneTree

# SpecialLevelController integration test — 5 contracts.
# Contract 1: level_type_read      — setup() reads level_type from metadata
# Contract 2: trial_completed_pass — character_trial emits trial_completed on stars > 0
# Contract 3: trial_blocked_zero   — character_trial does NOT emit on stars = 0
# Contract 4: boss_phase_advances  — boss_chase emits boss_phase_changed at beat threshold
# Contract 5: character_unlocked   — character_trial saves character unlock on completion

const SPECIAL_GD := "res://src/gameplay/SpecialLevelController.gd"

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_level_type_read(root)
	_test_trial_completed_pass(root)
	_test_trial_blocked_zero(root)
	_test_boss_phase_advances(root)
	_test_character_unlocked(root)

	print("SpecialLevel tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("SPECIAL_LEVEL_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


func _make_controller(root: Node) -> Node:
	var ctrl: Node = load(SPECIAL_GD).new()
	root.add_child(ctrl)
	return ctrl


# -- Contract 1 ────────────────────────────────────────────────────────────────

func _test_level_type_read(root: Node) -> void:
	var ctrl: Node = _make_controller(root)
	ctrl.setup({"level_type": "creator_trial", "trial_unlock_id": "unlock_test"})

	if ctrl._level_type == "creator_trial":
		_ok("level_type_read: _level_type is 'creator_trial'")
	else:
		_fail("level_type_read", "got: " + str(ctrl._level_type))

	ctrl.queue_free()


# -- Contract 2 ────────────────────────────────────────────────────────────────

func _test_trial_completed_pass(root: Node) -> void:
	var ctrl: Node = _make_controller(root)
	ctrl.setup({"level_type": "character_trial", "character_id": "", "trial_unlock_id": "unlock_test_char"})

	var received: Array = []
	root.get_node("EventBus").trial_completed.connect(
		func(lid: String, unlock: String) -> void: received.append({"lid": lid, "unlock": unlock})
	)

	root.get_node("EventBus").run_completed.emit("ct_test", 300, 2)

	if received.size() >= 1:
		_ok("trial_completed_pass: trial_completed emitted on stars > 0")
	else:
		_fail("trial_completed_pass", "signal not received")

	var found_id: bool = false
	for item: Variant in received:
		if (item as Dictionary).get("unlock", "") == "unlock_test_char":
			found_id = true
	if found_id:
		_ok("trial_completed_pass: unlock_id is correct")
	else:
		_fail("trial_completed_pass: wrong unlock_id", str(received))

	ctrl.queue_free()


# -- Contract 3 ────────────────────────────────────────────────────────────────

func _test_trial_blocked_zero(root: Node) -> void:
	var ctrl: Node = _make_controller(root)
	ctrl.setup({"level_type": "creator_trial", "trial_unlock_id": "unlock_should_not_fire"})

	var received: Array = []
	root.get_node("EventBus").trial_completed.connect(
		func(_lid: String, _unlock: String) -> void: received.append(1)
	)

	root.get_node("EventBus").run_completed.emit("crtr_test", 0, 0)

	if received.is_empty():
		_ok("trial_blocked_zero: trial_completed NOT emitted at 0 stars")
	else:
		_fail("trial_blocked_zero", "signal fired unexpectedly")

	ctrl.queue_free()


# -- Contract 4 ────────────────────────────────────────────────────────────────

func _test_boss_phase_advances(root: Node) -> void:
	var ctrl: Node = _make_controller(root)
	# Manually set boss phases (skip boss script loading — set thresholds directly).
	ctrl._level_type = "boss_chase"
	ctrl._boss_id = "test_boss"
	ctrl._boss_phase_thresholds = [8.0, 16.0, 24.0]

	var phases_received: Array = []
	root.get_node("EventBus").boss_phase_changed.connect(
		func(bid: String, phase: int) -> void: phases_received.append({"bid": bid, "phase": phase})
	)

	ctrl.handle_beat(7.9)  # below threshold — no emit
	ctrl.handle_beat(8.0)  # at threshold — phase 1

	if phases_received.size() == 1:
		_ok("boss_phase_advances: phase changed at beat 8.0")
	else:
		_fail("boss_phase_advances: wrong emit count", str(phases_received.size()))

	if phases_received.size() >= 1 and phases_received[0].get("phase", -1) == 1:
		_ok("boss_phase_advances: phase == 1")
	else:
		_fail("boss_phase_advances: wrong phase value", str(phases_received))

	ctrl.handle_beat(16.0)  # phase 2
	if phases_received.size() == 2:
		_ok("boss_phase_advances: phase 2 reached at beat 16.0")
	else:
		_fail("boss_phase_advances: phase 2 not reached", str(phases_received))

	ctrl.queue_free()


# -- Contract 5 ────────────────────────────────────────────────────────────────

func _test_character_unlocked(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid: String = "sl_test_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)
	ss.set_active_profile(pid)

	var ctrl: Node = _make_controller(root)
	ctrl.setup({"level_type": "character_trial", "character_id": "zap", "trial_unlock_id": "unlock_zap"})

	root.get_node("EventBus").run_completed.emit("ct_zap", 200, 1)

	if ss.get_character_unlocked(pid, "zap"):
		_ok("character_unlocked: zap unlocked in SaveSystem after trial completion")
	else:
		_fail("character_unlocked", "zap not unlocked")

	ctrl.queue_free()
