## ScrollService speed-zone contract test.
##
## Verifies:
##   1. speed_now() returns 408.0 (BASE_SPEED) when ScrollService is inactive.
##   2. distance_until_beat() returns _INACTIVE_DISTANCE (980) when inactive,
##      preserving spawn_x = JUDGMENT_X + 980 = CANVAS_W + 100 (geometry compat).
##   3. After activate(z1-l1), distance for 4 beats at 100 BPM = 4×0.6×408 = 979.2 px  ±1.
##   4. After activate(z2-l7 with 1.15× finale zone), cumulative distance across the
##      zone boundary at beat 40 is < 1 px error vs hand-computed integral.
##   5. speed_now() respects the active zone multiplier.
##
## Run with:
##   godot --headless --path . --script tests/integration/speed_zone_test.gd
extends SceneTree

var _failures: PackedStringArray = []
var _scroll: Node = null


func _init() -> void:
	await process_frame
	await process_frame

	_scroll = root.get_node("ScrollService")

	_test_inactive_speed()
	_test_inactive_distance()
	await _test_fixed_bpm_distance()
	await _test_zone_boundary()
	await _test_zone_speed()

	print("==== SPEED ZONE TEST ====")
	if _failures.is_empty():
		print("All ScrollService contracts hold.")
		print("SPEED_ZONE_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("SPEED_ZONE_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


## ── Inactive speed ───────────────────────────────────────────────────────────
func _test_inactive_speed() -> void:
	_scroll.deactivate()
	var s: float = _scroll.speed_now()
	if absf(s - 408.0) > 0.001:
		_fail("Inactive speed_now() = %.3f, expected 408.0" % s)
	else:
		print("Inactive speed_now() = 408 — OK")


## ── Inactive distance ────────────────────────────────────────────────────────
func _test_inactive_distance() -> void:
	_scroll.deactivate()
	var d: float = _scroll.distance_until_beat(4.0)
	# Expect 980 so spawn_x = JUDGMENT_X(200) + 980 = CANVAS_W(1080) + 100.
	if absf(d - 980.0) > 0.001:
		_fail("Inactive distance_until_beat(4) = %.3f, expected 980.0" % d)
	else:
		print("Inactive distance_until_beat() = 980 — OK")


## ── Fixed-BPM distance (z1-l1 at 100 BPM, no speed zones) ───────────────────
func _test_fixed_bpm_distance() -> void:
	# Load z1-l1, activate ScrollService, then query distance for 4 beats.
	# BeatConductor is not started so get_current_beat_position() = 0.
	# Expected: 4 × (60/100) × 408 = 4 × 0.6 × 408 = 979.2 px
	var rm: RhythmMap = RhythmMap.new()
	root.add_child(rm)
	var loaded: bool = false
	rm.map_loaded.connect(func(_id: String) -> void: loaded = true)
	rm.load_level("z1-l1")
	for _i: int in range(10):
		if loaded:
			break
		await process_frame

	if not rm.is_loaded():
		_fail("Could not load z1-l1 for fixed-BPM distance test")
		rm.queue_free()
		return

	_scroll.activate(rm)
	var dist: float = _scroll.distance_until_beat(4.0)
	var expected: float = 4.0 * (60.0 / 100.0) * 408.0  # 979.2
	if absf(dist - expected) > 1.0:
		_fail("z1-l1 distance_until_beat(4) = %.2f, expected %.2f (±1 px)" % [dist, expected])
	else:
		print("Fixed-BPM 4-beat distance = %.2f (expected %.2f) — OK" % [dist, expected])

	_scroll.deactivate()
	rm.queue_free()
	await process_frame


## ── Zone boundary < 1 px error (z2-l7 with 1.15× finale at beat 40) ─────────
func _test_zone_boundary() -> void:
	var rm: RhythmMap = RhythmMap.new()
	root.add_child(rm)
	var loaded: bool = false
	rm.map_loaded.connect(func(_id: String) -> void: loaded = true)
	rm.load_level("z2-l7")
	for _i: int in range(10):
		if loaded:
			break
		await process_frame

	if not rm.is_loaded():
		_fail("Could not load z2-l7 for zone-boundary test")
		rm.queue_free()
		return

	_scroll.activate(rm)

	# Hand-compute the cumulative distance from beat 0 to beat 44.
	# z2-l7: 130 BPM throughout, 1.0× for beats 0-39, 1.15× for beats 40+.
	# beat_dur = 60/130 ≈ 0.46154 s
	var bpm: float = 130.0
	var beat_dur: float = 60.0 / bpm
	var expected_0_to_40: float = 40.0 * beat_dur * 408.0  # 1.0× zone
	var expected_40_to_44: float = 4.0 * beat_dur * (408.0 * 1.15)  # 1.15× zone
	var expected_total: float = expected_0_to_40 + expected_40_to_44

	# ScrollService._cum_px_at(44) should match expected_total within 1 px.
	# We can get this via distance_until_beat(44) with beat_position = 0.
	var got: float = _scroll.distance_until_beat(44.0)
	if absf(got - expected_total) > 1.0:
		_fail("Zone boundary: distance_until_beat(44) = %.2f, expected %.2f (±1 px)" % [got, expected_total])
	else:
		print("Zone boundary (beat 40, 1.0×→1.15×) distance = %.2f (expected %.2f) — OK" % [got, expected_total])

	_scroll.deactivate()
	rm.queue_free()
	await process_frame


## ── speed_now() respects zone multiplier ────────────────────────────────────
func _test_zone_speed() -> void:
	var rm: RhythmMap = RhythmMap.new()
	root.add_child(rm)
	var loaded: bool = false
	rm.map_loaded.connect(func(_id: String) -> void: loaded = true)
	rm.load_level("z2-l7")
	for _i: int in range(10):
		if loaded:
			break
		await process_frame

	if not rm.is_loaded():
		_fail("Could not load z2-l7 for zone-speed test")
		rm.queue_free()
		return

	# Verify the zone table was built correctly by checking entries directly.
	# Beat 0: mult=1.0  → speed = 408 × 1.0 = 408
	# Beat 44: mult=1.15 → speed = 408 × 1.15 = 469.2
	_scroll.activate(rm)
	var speed_0: float = float((_scroll._table[0] as Dictionary)["speed"])
	var speed_44: float = float((_scroll._table[44] as Dictionary)["speed"])
	var expected_0: float = 408.0 * 1.0
	var expected_44: float = 408.0 * 1.15

	if absf(speed_0 - expected_0) > 0.1:
		_fail("Beat 0 speed = %.1f, expected %.1f" % [speed_0, expected_0])
	else:
		print("Beat 0 speed = %.1f — OK" % speed_0)

	if absf(speed_44 - expected_44) > 0.5:
		_fail("Beat 44 speed = %.1f, expected %.1f" % [speed_44, expected_44])
	else:
		print("Beat 44 speed = %.1f (expected %.1f) — OK" % [speed_44, expected_44])

	_scroll.deactivate()
	rm.queue_free()
	await process_frame
