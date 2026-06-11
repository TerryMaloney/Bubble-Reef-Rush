## ResonanceController integration test — Phase 15.
##
## Contracts:
##   1. charge_accumulates:       5 collectibles fill 1 charge; power_charged(1.0) emits.
##   2. partial_pearl_progress:   each pearl emits power_charged with increasing pct.
##   3. fire_consumes_charge:     fire() returns true and decrements charge.
##   4. disabled_blocks_fire:     mode="disabled" → fire() always returns false.
##   5. perfect_at_zero_beat:     with BeatConductor stopped (pos=0.0), is_perfect=true.
##   6. echo_shield_absorbs:      fire echo_shield → has_echo_shield=true; consume=true.
##   7. shield_depletes:          second consume_shield() returns false.
##   8. reset_clears_state:       reset() zeroes charges and emits power_charged(0.0).
##
## All game-class references are load()-ed at runtime (not statically typed) because
## their scripts reference autoloads not resolvable at --script compile time.
##
## Run with:
##   godot --headless --path . --script tests/integration/resonance_test.gd
extends SceneTree

const RC_GD: String = "res://src/gameplay/ResonanceController.gd"

var _failures: PackedStringArray = []
var _eb: Node = null


func _init() -> void:
	await process_frame
	await process_frame

	_eb = root.get_node("EventBus")

	await _test_charge_accumulates()
	await _test_partial_pearl_progress()
	await _test_fire_consumes_charge()
	await _test_disabled_blocks_fire()
	await _test_perfect_at_zero_beat()
	await _test_echo_shield_absorbs()
	await _test_shield_depletes()
	await _test_reset_clears_state()

	print("==== RESONANCE TEST ====")
	if _failures.is_empty():
		print("All ResonanceController contracts hold.")
		print("RESONANCE_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("RESONANCE_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


func _make_rc(mode: String = "allowed", max_ch: int = 1, power: String = "bubble_burst") -> Node:
	var rc: Node = load(RC_GD).new()
	root.add_child(rc)
	rc.setup(mode, max_ch, power)
	return rc


func _emit_pearls(n: int) -> void:
	for _i: int in range(n):
		_eb.collectible_taken.emit(10)


## ── 1. charge_accumulates ────────────────────────────────────────────────────
func _test_charge_accumulates() -> void:
	var rc: Node = _make_rc()
	await process_frame

	# 4 pearls → no charge yet
	_emit_pearls(4)
	if int(rc.get_charges()) != 0:
		_fail("charge_accumulates: 4 pearls should not complete a charge (got %d)" % rc.get_charges())

	# capture the pct emitted on the 5th pearl
	var captured: Array = [-1.0]
	var _h: Callable = func(p: float) -> void: captured[0] = p
	_eb.power_charged.connect(_h)
	_emit_pearls(1)
	_eb.power_charged.disconnect(_h)

	if int(rc.get_charges()) != 1:
		_fail("charge_accumulates: 5 pearls should yield 1 charge (got %d)" % rc.get_charges())
	if float(captured[0]) < 0.99:
		_fail("charge_accumulates: power_charged should emit ≥1.0 on full charge (got %.2f)" % float(captured[0]))

	rc.queue_free()
	await process_frame
	print("charge_accumulates — OK")


## ── 2. partial_pearl_progress ────────────────────────────────────────────────
func _test_partial_pearl_progress() -> void:
	var rc: Node = _make_rc()
	await process_frame

	var pcts: Array = []
	var _h: Callable = func(p: float) -> void: pcts.append(p)
	_eb.power_charged.connect(_h)
	_emit_pearls(3)
	_eb.power_charged.disconnect(_h)

	if pcts.size() < 3:
		_fail("partial_pearl_progress: expected ≥3 power_charged emissions for 3 pearls (got %d)" % pcts.size())
	else:
		var prev: float = -0.001
		for v in pcts:
			if float(v) < prev - 0.001:
				_fail("partial_pearl_progress: pct decreased (%.3f → %.3f)" % [prev, float(v)])
			prev = float(v)
		if float(pcts[pcts.size() - 1]) < 0.55:
			_fail("partial_pearl_progress: 3/5 pearls should give pct ≥ 0.55 (got %.2f)" % float(pcts[pcts.size() - 1]))

	rc.queue_free()
	await process_frame
	print("partial_pearl_progress — OK")


## ── 3. fire_consumes_charge ──────────────────────────────────────────────────
func _test_fire_consumes_charge() -> void:
	var rc: Node = _make_rc()
	await process_frame
	_emit_pearls(5)

	if not rc.can_fire():
		_fail("fire_consumes_charge: can_fire() should be true after 5 pearls")

	var fired: bool = rc.fire()
	if not fired:
		_fail("fire_consumes_charge: fire() should return true when charged")
	if int(rc.get_charges()) != 0:
		_fail("fire_consumes_charge: charges should be 0 after firing (got %d)" % rc.get_charges())
	if rc.can_fire():
		_fail("fire_consumes_charge: can_fire() should be false after consuming charge")

	rc.queue_free()
	await process_frame
	print("fire_consumes_charge — OK")


## ── 4. disabled_blocks_fire ──────────────────────────────────────────────────
func _test_disabled_blocks_fire() -> void:
	var rc: Node = _make_rc("disabled")
	await process_frame
	_emit_pearls(10)

	if rc.can_fire():
		_fail("disabled_blocks_fire: can_fire() must be false in disabled mode")
	var fired: bool = rc.fire()
	if fired:
		_fail("disabled_blocks_fire: fire() must return false in disabled mode")

	rc.queue_free()
	await process_frame
	print("disabled_blocks_fire — OK")


## ── 5. perfect_at_zero_beat ──────────────────────────────────────────────────
func _test_perfect_at_zero_beat() -> void:
	# BeatConductor not running → get_current_beat_position() returns 0.0.
	# fmod(0.0, 1.0) = 0.0 < PERFECT_BEAT_WINDOW (0.12) → is_perfect must be true.
	var rc: Node = _make_rc()
	await process_frame
	_emit_pearls(5)

	var type_got: Array = [""]
	var perfect_got: Array = [false]
	var _h: Callable = func(t: String, p: bool) -> void:
		type_got[0] = t
		perfect_got[0] = p
	_eb.power_activated.connect(_h, CONNECT_ONE_SHOT)
	rc.fire()

	if type_got[0] != "bubble_burst":
		_fail("perfect_at_zero_beat: expected power type 'bubble_burst' (got '%s')" % type_got[0])
	if not bool(perfect_got[0]):
		_fail("perfect_at_zero_beat: beat_pos=0.0 is inside PERFECT window, is_perfect must be true")

	rc.queue_free()
	await process_frame
	print("perfect_at_zero_beat — OK")


## ── 6. echo_shield_absorbs ───────────────────────────────────────────────────
func _test_echo_shield_absorbs() -> void:
	var rc: Node = _make_rc("allowed", 1, "echo_shield")
	await process_frame
	_emit_pearls(5)
	rc.fire()

	if not rc.has_echo_shield():
		_fail("echo_shield_absorbs: has_echo_shield() should be true after firing echo_shield")

	var absorbed: bool = rc.consume_shield()
	if not absorbed:
		_fail("echo_shield_absorbs: consume_shield() should return true on first call")
	if rc.has_echo_shield():
		_fail("echo_shield_absorbs: has_echo_shield() should be false after consuming")

	rc.queue_free()
	await process_frame
	print("echo_shield_absorbs — OK")


## ── 7. shield_depletes ───────────────────────────────────────────────────────
func _test_shield_depletes() -> void:
	var rc: Node = _make_rc("allowed", 1, "echo_shield")
	await process_frame
	_emit_pearls(5)
	rc.fire()
	rc.consume_shield()  # depletes

	var second: bool = rc.consume_shield()
	if second:
		_fail("shield_depletes: second consume_shield() must return false")

	rc.queue_free()
	await process_frame
	print("shield_depletes — OK")


## ── 8. reset_clears_state ────────────────────────────────────────────────────
func _test_reset_clears_state() -> void:
	var rc: Node = _make_rc()
	await process_frame
	_emit_pearls(5)

	var captured: Array = [-1.0]
	var _h: Callable = func(p: float) -> void: captured[0] = p
	_eb.power_charged.connect(_h, CONNECT_ONE_SHOT)
	rc.reset()

	if int(rc.get_charges()) != 0:
		_fail("reset_clears_state: charges should be 0 after reset (got %d)" % rc.get_charges())
	if absf(float(captured[0])) > 0.01:
		_fail("reset_clears_state: power_charged(0.0) should fire on reset (got %.2f)" % float(captured[0]))

	rc.queue_free()
	await process_frame
	print("reset_clears_state — OK")
