## resonance_test.gd — Phase 15 contracts for ResonanceController.
##
## Tests:
##   1. charge_accumulates     — 5 collectibles at value=10 yields 1 charge.
##   2. charge_pct_emitted     — power_charged signal fires on collectible intake.
##   3. fire_decrements_charge — fire() reduces charges by 1.
##   4. disabled_mode_blocks_fire — mode "disabled" prevents can_fire().
##   5. echo_shield_absorbs_hit — fire() with echo_shield sets shield; consume clears it.
##
## Run with:
##   godot --headless --path . --script tests/integration/resonance_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_charge_accumulates(root)
	_test_charge_pct_emitted(root)
	_test_fire_decrements_charge(root)
	_test_disabled_mode_blocks_fire(root)
	_test_echo_shield_absorbs_hit(root)

	print("Resonance tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("RESONANCE_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. charge_accumulates
func _test_charge_accumulates(root: Node) -> void:
	var ctrl: Node = load("res://src/gameplay/ResonanceController.gd").new()
	root.add_child(ctrl)
	ctrl.setup("allowed", 1, "bubble_burst")

	var eb: Node = root.get_node("EventBus")
	for i in range(5):
		eb.collectible_taken.emit(10)

	if ctrl.get_charges() == 1:
		_ok("charge_accumulates")
	else:
		_fail("charge_accumulates", "expected charges=1, got %d" % ctrl.get_charges())

	ctrl.queue_free()


## 2. charge_pct_emitted
func _test_charge_pct_emitted(root: Node) -> void:
	var ctrl: Node = load("res://src/gameplay/ResonanceController.gd").new()
	root.add_child(ctrl)
	ctrl.setup("allowed", 1, "bubble_burst")

	var eb: Node = root.get_node("EventBus")
	var received_pcts: Array = []
	eb.power_charged.connect(func(pct: float) -> void:
		received_pcts.append(pct)
	)

	eb.collectible_taken.emit(10)
	eb.collectible_taken.emit(10)

	if received_pcts.size() >= 2:
		_ok("charge_pct_emitted")
	else:
		_fail("charge_pct_emitted", "expected >=2 pct emissions, got %d" % received_pcts.size())

	ctrl.queue_free()


## 3. fire_decrements_charge
func _test_fire_decrements_charge(root: Node) -> void:
	var ctrl: Node = load("res://src/gameplay/ResonanceController.gd").new()
	root.add_child(ctrl)
	ctrl.setup("allowed", 1, "bubble_burst")
	ctrl.set("_charges", 1)
	ctrl.fire()

	if ctrl.get_charges() == 0:
		_ok("fire_decrements_charge")
	else:
		_fail("fire_decrements_charge", "expected charges=0 after fire, got %d" % ctrl.get_charges())

	ctrl.queue_free()


## 4. disabled_mode_blocks_fire
func _test_disabled_mode_blocks_fire(root: Node) -> void:
	var ctrl: Node = load("res://src/gameplay/ResonanceController.gd").new()
	root.add_child(ctrl)
	ctrl.setup("disabled", 1, "bubble_burst")

	var eb: Node = root.get_node("EventBus")
	for i in range(10):
		eb.collectible_taken.emit(10)

	if ctrl.can_fire() == false:
		_ok("disabled_mode_blocks_fire")
	else:
		_fail("disabled_mode_blocks_fire", "can_fire() should be false in disabled mode")

	ctrl.queue_free()


## 5. echo_shield_absorbs_hit
func _test_echo_shield_absorbs_hit(root: Node) -> void:
	var ctrl: Node = load("res://src/gameplay/ResonanceController.gd").new()
	root.add_child(ctrl)
	ctrl.setup("allowed", 1, "echo_shield")
	ctrl.set("_charges", 1)
	ctrl.fire()

	if not ctrl.has_echo_shield():
		_fail("echo_shield_absorbs_hit", "shield should be active after fire()")
		ctrl.queue_free()
		return

	ctrl.consume_shield()

	if ctrl.has_echo_shield() == false:
		_ok("echo_shield_absorbs_hit")
	else:
		_fail("echo_shield_absorbs_hit", "shield should be inactive after consume_shield()")

	ctrl.queue_free()
