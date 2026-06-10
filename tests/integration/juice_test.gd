## juice_test.gd — Phase 5 contracts for FeverController, JuiceDirector, NearMissDetector.
##
## Tests:
##   1. Fever activates at combo 30, suppresses before threshold.
##   2. Fever ends (fever_ended signal) on first MISS after threshold.
##   3. Score bonus fires +50 per PERFECT during fever.
##   4. Engine.time_scale is restored to 1.0 after JuiceDirector tree_exiting.
##   5. NearMissDetector: near_miss fires when area exits ring while player alive.
##   6. NearMissDetector: no near_miss after player_hit (player dead).
##   7. Reduced-motion: JuiceDirector does NOT modify Engine.time_scale.
##
## All game-class references are load()-ed at runtime (not statically typed)
## because their scripts reference autoloads which are not resolvable in --script
## compile time.
##
## TimingResult enum values: PERFECT=0, GOOD=1, MISS=2
##
## Run with:
##   godot --headless --path . --script tests/integration/juice_test.gd
extends SceneTree

const FEVER_GD: String = "res://src/gameplay/FeverController.gd"
const JUICE_GD: String = "res://src/gameplay/JuiceDirector.gd"
const NMD_GD: String   = "res://src/gameplay/NearMissDetector.gd"
## TimingResult: PERFECT=0, GOOD=1, MISS=2
const PERFECT: int = 0
const GOOD: int = 1
const MISS: int = 2

var _failures: PackedStringArray = []


func _init() -> void:
	await process_frame
	await process_frame

	await _test_fever_activates()
	await _test_fever_ends_on_miss()
	await _test_fever_score_bonus()
	await _test_time_scale_restored()
	await _test_near_miss_fires()
	await _test_no_near_miss_on_hit()
	await _test_reduced_motion_suppresses_time_scale()

	print("==== JUICE TEST ====")
	if _failures.is_empty():
		print("All Phase 5 juice contracts hold.")
		print("JUICE_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("JUICE_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


## ── Fever activates at combo 30 ──────────────────────────────────────────────
func _test_fever_activates() -> void:
	var fc = load(FEVER_GD).new()
	root.add_child(fc)
	await process_frame

	var event_bus: Node = root.get_node("EventBus")
	var fever_caught := [false]
	event_bus.fever_started.connect(func() -> void: fever_caught[0] = true, CONNECT_ONE_SHOT)

	for _i: int in range(29):
		event_bus.beat_judged.emit(PERFECT)
	if fc.is_fever():
		_fail("Fever triggered before combo 30")

	event_bus.beat_judged.emit(PERFECT)
	if not fc.is_fever():
		_fail("Fever NOT active after combo 30")
	if not fever_caught[0]:
		_fail("fever_started signal not emitted at combo 30")
	else:
		print("Fever activates at combo 30 — OK")

	fc.queue_free()
	await process_frame


## ── Fever ends on MISS ───────────────────────────────────────────────────────
func _test_fever_ends_on_miss() -> void:
	var fc = load(FEVER_GD).new()
	root.add_child(fc)
	await process_frame

	var event_bus: Node = root.get_node("EventBus")
	var fever_ended_caught := [false]
	event_bus.fever_ended.connect(func() -> void: fever_ended_caught[0] = true, CONNECT_ONE_SHOT)

	for _i: int in range(30):
		event_bus.beat_judged.emit(PERFECT)

	if not fc.is_fever():
		_fail("Precondition: fever not active before MISS test")
		fc.queue_free()
		return

	event_bus.beat_judged.emit(MISS)
	if fc.is_fever():
		_fail("Fever still active after MISS")
	if not fever_ended_caught[0]:
		_fail("fever_ended signal not emitted on MISS")
	else:
		print("Fever ends on MISS — OK")

	fc.queue_free()
	await process_frame


## ── Fever score bonus fires during fever ────────────────────────────────────
func _test_fever_score_bonus() -> void:
	var fc = load(FEVER_GD).new()
	root.add_child(fc)
	await process_frame

	var event_bus: Node = root.get_node("EventBus")
	var bonus_total := [0]
	var conn: Callable = func(amount: int) -> void: bonus_total[0] += amount
	event_bus.score_bonus.connect(conn)

	for _i: int in range(30):
		event_bus.beat_judged.emit(PERFECT)

	# 3 more PERFECTs during fever → 3 × 50 = 150 bonus.
	bonus_total[0] = 0
	for _i: int in range(3):
		event_bus.beat_judged.emit(PERFECT)

	event_bus.score_bonus.disconnect(conn)

	if bonus_total[0] != 150:
		_fail("Fever score bonus = %d, expected 150 (3 × 50)" % bonus_total[0])
	else:
		print("Fever score bonus 3×50 = 150 — OK")

	fc.queue_free()
	await process_frame


## ── Engine.time_scale restored via tree_exiting guard ───────────────────────
func _test_time_scale_restored() -> void:
	Engine.time_scale = 0.3
	var holder: Node = Node.new()
	root.add_child(holder)
	var jd = load(JUICE_GD).new()
	holder.add_child(jd)
	await process_frame

	holder.queue_free()
	await process_frame

	if absf(Engine.time_scale - 1.0) > 0.001:
		_fail("Engine.time_scale = %.3f after JuiceDirector exit, expected 1.0" % Engine.time_scale)
	else:
		print("time_scale restored to 1.0 on tree_exiting — OK")
	Engine.time_scale = 1.0


## ── NearMissDetector fires near_miss on area exit while alive ────────────────
func _test_near_miss_fires() -> void:
	var nmd = load(NMD_GD).new()
	root.add_child(nmd)
	var event_bus: Node = root.get_node("EventBus")

	var near_miss_count := [0]
	var conn: Callable = func() -> void: near_miss_count[0] += 1
	event_bus.near_miss.connect(conn)

	var fake_area: Area2D = Area2D.new()
	root.add_child(fake_area)
	nmd._on_area_entered(fake_area)
	nmd._on_area_exited(fake_area)

	event_bus.near_miss.disconnect(conn)
	fake_area.queue_free()
	nmd.queue_free()
	await process_frame

	if near_miss_count[0] != 1:
		_fail("near_miss fired %d times, expected 1" % near_miss_count[0])
	else:
		print("near_miss fires on area exit while alive — OK")


## ── NearMissDetector does NOT fire near_miss after player_hit ────────────────
func _test_no_near_miss_on_hit() -> void:
	var nmd = load(NMD_GD).new()
	root.add_child(nmd)
	var event_bus: Node = root.get_node("EventBus")

	var near_miss_count := [0]
	var conn: Callable = func() -> void: near_miss_count[0] += 1
	event_bus.near_miss.connect(conn)

	var fake_area: Area2D = Area2D.new()
	root.add_child(fake_area)
	nmd._on_area_entered(fake_area)
	nmd._on_player_hit()
	nmd._on_area_exited(fake_area)

	event_bus.near_miss.disconnect(conn)
	fake_area.queue_free()
	nmd.queue_free()
	await process_frame

	if near_miss_count[0] != 0:
		_fail("near_miss fired after player_hit (should be suppressed), count=%d" % near_miss_count[0])
	else:
		print("near_miss suppressed after player_hit — OK")


## ── Reduced motion suppresses JuiceDirector time_scale changes ──────────────
func _test_reduced_motion_suppresses_time_scale() -> void:
	var acc: Node = root.get_node("Accessibility")
	acc.set_reduced_motion(true)

	var holder: Node = Node.new()
	root.add_child(holder)
	var jd = load(JUICE_GD).new()
	holder.add_child(jd)
	await process_frame

	jd._on_player_hit()
	await process_frame

	var ts: float = Engine.time_scale
	holder.queue_free()
	await process_frame

	acc.set_reduced_motion(false)
	Engine.time_scale = 1.0

	if absf(ts - 1.0) > 0.001:
		_fail("Reduced-motion: time_scale = %.3f after player_hit, expected 1.0" % ts)
	else:
		print("Reduced-motion suppresses time_scale changes — OK")
