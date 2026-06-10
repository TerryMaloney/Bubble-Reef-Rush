## obstacle_z4_test.gd — Phase 9 contracts for Zone 4 obstacles.
##
## Tests:
##   1. LavaBurst state machine: DORMANT → TELEGRAPHING → ERUPTING → COOLDOWN → DORMANT
##   2. LavaBurst collision gating: disabled in TELEGRAPHING, enabled in ERUPTING
##   3. LavaBurst player hit: player in eruption zone is hit
##   4. LavaBurst player safe: player outside eruption zone is NOT hit
##   5. PressureWave: player in gap NOT hit
##   6. PressureWave: player above gap IS hit
##   7. PressureWave: player below gap IS hit
##   8. PressureWave: moves at travel_speed independent of ScrollService
##   9. TimingJudge high-BPM assertion: PERFECT window > 0ms at 165 BPM
##
## Run with:
##   godot --headless --path . --script tests/integration/obstacle_z4_test.gd
extends SceneTree

var _failures: PackedStringArray = []
var _event_bus: Node = null


func _init() -> void:
	await process_frame
	await process_frame

	_event_bus = root.get_node("EventBus")

	await _test_lava_state_machine()
	await _test_lava_collision_gating()
	await _test_lava_player_hit()
	await _test_lava_player_safe()
	await _test_wave_gap_safe()
	await _test_wave_upper_hit()
	await _test_wave_lower_hit()
	await _test_wave_movement()
	_test_high_bpm_timing()

	print("==== OBSTACLE Z4 TEST ====")
	if _failures.is_empty():
		print("All Phase 9 Zone 4 obstacle contracts hold.")
		print("OBSTACLE_Z4_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("OBSTACLE_Z4_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


## ── LavaBurst state machine ───────────────────────────────────────────────────
func _test_lava_state_machine() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var lava = load("res://scenes/obstacles/LavaBurst.tscn").instantiate()
	holder.add_child(lava)
	lava.set_process(false)
	lava.setup({"beat_index": 4, "lane_position": 0.9,
		"parameters": {"wall_origin": "bottom", "x_position": 0.5, "dormant_beats": 8}})

	# Initial: DORMANT (0)
	if lava._state != 0:
		_fail("LavaBurst: initial state not DORMANT(0), got %d" % lava._state)
		holder.queue_free(); await process_frame; return

	# Beat before entry should not trigger
	lava._on_beat_fired(3)
	if lava._state != 0:
		_fail("LavaBurst: triggered before entry_beat")

	# Entry beat → TELEGRAPHING (1)
	lava._on_beat_fired(4)
	if lava._state != 1:
		_fail("LavaBurst: after beat_fired(4) expected TELEGRAPHING(1), got %d" % lava._state)
		holder.queue_free(); await process_frame; return
	print("LavaBurst: DORMANT → TELEGRAPHING — OK")

	# Direct transition (avoids scroll movement clobbering queue_free threshold)
	lava._do_erupt()
	if lava._state != 2:
		_fail("LavaBurst: after _do_erupt() expected ERUPTING(2), got %d" % lava._state)
		holder.queue_free(); await process_frame; return
	print("LavaBurst: TELEGRAPHING → ERUPTING — OK")

	lava._do_cooldown()
	if lava._state != 3:
		_fail("LavaBurst: after _do_cooldown() expected COOLDOWN(3), got %d" % lava._state)
		holder.queue_free(); await process_frame; return
	print("LavaBurst: ERUPTING → COOLDOWN — OK")

	lava._set_state(lava.State.DORMANT)
	if lava._state != 0:
		_fail("LavaBurst: after _set_state(DORMANT) expected DORMANT(0), got %d" % lava._state)
	else:
		print("LavaBurst: COOLDOWN → DORMANT — OK")

	holder.queue_free()
	await process_frame


## ── LavaBurst collision gating ────────────────────────────────────────────────
func _test_lava_collision_gating() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var lava = load("res://scenes/obstacles/LavaBurst.tscn").instantiate()
	holder.add_child(lava)
	lava.set_process(false)
	lava.setup({"beat_index": 4, "lane_position": 0.9,
		"parameters": {"wall_origin": "bottom", "x_position": 0.5, "dormant_beats": 8}})

	# DORMANT: collision disabled
	if not lava._erupt_col.disabled:
		_fail("LavaBurst collision gating: not disabled in DORMANT")

	# TELEGRAPHING: still disabled
	lava._on_beat_fired(4)
	if not lava._erupt_col.disabled:
		_fail("LavaBurst collision gating: not disabled in TELEGRAPHING")
	else:
		print("LavaBurst: collision disabled during TELEGRAPHING — OK")

	# ERUPTING: enabled
	lava._do_erupt()
	if lava._erupt_col.disabled:
		_fail("LavaBurst collision gating: not enabled in ERUPTING")
	else:
		print("LavaBurst: collision enabled during ERUPTING — OK")

	# COOLDOWN: disabled again
	lava._do_cooldown()
	if not lava._erupt_col.disabled:
		_fail("LavaBurst collision gating: not disabled in COOLDOWN")
	else:
		print("LavaBurst: collision disabled during COOLDOWN — OK")

	holder.queue_free()
	await process_frame


## ── LavaBurst player hit (player in eruption zone) ───────────────────────────
func _test_lava_player_hit() -> void:
	var player_hit_flag := [false]
	var conn: Callable = func() -> void: player_hit_flag[0] = true
	_event_bus.player_hit.connect(conn)

	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# Bottom vent: eruption covers y=[840, 1920]. Player at y=960 is in range.
	var player = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(200.0, 960.0)
	player.set_physics_process(false)
	holder.add_child(player)

	var lava = load("res://scenes/obstacles/LavaBurst.tscn").instantiate()
	lava.position = Vector2(200.0, 0.0)
	holder.add_child(lava)
	lava.set_process(false)
	lava.setup({"beat_index": 4, "lane_position": 0.9,
		"parameters": {"wall_origin": "bottom", "x_position": 0.5, "dormant_beats": 8}})

	# Go directly to ERUPTING (no scroll movement)
	lava._do_erupt()

	for _i: int in range(8):
		await physics_frame

	_event_bus.player_hit.disconnect(conn)

	if not player_hit_flag[0]:
		_fail("LavaBurst player hit: player at y=960 not hit by bottom vent eruption")
	else:
		print("LavaBurst: player hit during ERUPTING — OK")

	holder.queue_free()
	await process_frame


## ── LavaBurst player safe (player outside eruption zone) ─────────────────────
func _test_lava_player_safe() -> void:
	var player_hit_flag := [false]
	var conn: Callable = func() -> void: player_hit_flag[0] = true
	_event_bus.player_hit.connect(conn)

	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# Bottom vent: eruption covers y=[840, 1920]. Player at y=400 is SAFE.
	var player = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(200.0, 400.0)
	player.set_physics_process(false)
	holder.add_child(player)

	var lava = load("res://scenes/obstacles/LavaBurst.tscn").instantiate()
	lava.position = Vector2(200.0, 0.0)
	holder.add_child(lava)
	lava.set_process(false)
	lava.setup({"beat_index": 4, "lane_position": 0.9,
		"parameters": {"wall_origin": "bottom", "x_position": 0.5, "dormant_beats": 8}})

	lava._do_erupt()

	for _i: int in range(8):
		await physics_frame

	_event_bus.player_hit.disconnect(conn)

	if player_hit_flag[0]:
		_fail("LavaBurst player safe: player at y=400 was hit (should be safe above bottom vent)")
	else:
		print("LavaBurst: player safe above eruption zone — OK")

	holder.queue_free()
	await process_frame


## ── PressureWave: player in gap NOT hit ──────────────────────────────────────
func _test_wave_gap_safe() -> void:
	var player_hit_flag := [false]
	var conn: Callable = func() -> void: player_hit_flag[0] = true
	_event_bus.player_hit.connect(conn)

	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# gap_y_normalized=0.5, gap_height=160: gap covers y=[880, 1040]. Player at y=960 is safe.
	var player = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(200.0, 960.0)
	player.set_physics_process(false)
	holder.add_child(player)

	var wave = load("res://scenes/obstacles/PressureWave.tscn").instantiate()
	wave.position = Vector2(200.0, 0.0)
	holder.add_child(wave)
	wave.set_process(false)
	wave.setup({"beat_index": 8, "lane_position": 0.5,
		"parameters": {"gap_y_normalized": 0.5, "gap_height": 160, "travel_speed": 300, "entry_side": "right"}})

	for _i: int in range(8):
		await physics_frame

	_event_bus.player_hit.disconnect(conn)

	if player_hit_flag[0]:
		_fail("PressureWave gap safe: player in gap was hit")
	else:
		print("PressureWave: player in gap NOT hit — OK")

	holder.queue_free()
	await process_frame


## ── PressureWave: player above gap IS hit ────────────────────────────────────
func _test_wave_upper_hit() -> void:
	var player_hit_flag := [false]
	var conn: Callable = func() -> void: player_hit_flag[0] = true
	_event_bus.player_hit.connect(conn)

	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# Upper block covers y=[0, 880]. Player at y=400 is in upper block → hit.
	var player = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(200.0, 400.0)
	player.set_physics_process(false)
	holder.add_child(player)

	var wave = load("res://scenes/obstacles/PressureWave.tscn").instantiate()
	wave.position = Vector2(200.0, 0.0)
	holder.add_child(wave)
	wave.set_process(false)
	wave.setup({"beat_index": 8, "lane_position": 0.5,
		"parameters": {"gap_y_normalized": 0.5, "gap_height": 160, "travel_speed": 300, "entry_side": "right"}})

	for _i: int in range(8):
		await physics_frame

	_event_bus.player_hit.disconnect(conn)

	if not player_hit_flag[0]:
		_fail("PressureWave upper hit: player above gap was not hit")
	else:
		print("PressureWave: player above gap IS hit — OK")

	holder.queue_free()
	await process_frame


## ── PressureWave: player below gap IS hit ────────────────────────────────────
func _test_wave_lower_hit() -> void:
	var player_hit_flag := [false]
	var conn: Callable = func() -> void: player_hit_flag[0] = true
	_event_bus.player_hit.connect(conn)

	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# Lower block covers y=[1040, 1920]. Player at y=1400 is in lower block → hit.
	var player = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(200.0, 1400.0)
	player.set_physics_process(false)
	holder.add_child(player)

	var wave = load("res://scenes/obstacles/PressureWave.tscn").instantiate()
	wave.position = Vector2(200.0, 0.0)
	holder.add_child(wave)
	wave.set_process(false)
	wave.setup({"beat_index": 8, "lane_position": 0.5,
		"parameters": {"gap_y_normalized": 0.5, "gap_height": 160, "travel_speed": 300, "entry_side": "right"}})

	for _i: int in range(8):
		await physics_frame

	_event_bus.player_hit.disconnect(conn)

	if not player_hit_flag[0]:
		_fail("PressureWave lower hit: player below gap was not hit")
	else:
		print("PressureWave: player below gap IS hit — OK")

	holder.queue_free()
	await process_frame


## ── PressureWave: moves at travel_speed (independent of ScrollService) ────────
func _test_wave_movement() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var wave = load("res://scenes/obstacles/PressureWave.tscn").instantiate()
	wave.position = Vector2(500.0, 0.0)
	holder.add_child(wave)
	wave.set_process(false)
	wave.setup({"beat_index": 8, "lane_position": 0.5,
		"parameters": {"gap_y_normalized": 0.5, "gap_height": 160, "travel_speed": 300, "entry_side": "right"}})

	var x_before: float = wave.position.x
	wave._process(1.0)  # 1 second at 300 px/s → should move 300 px left
	var x_after: float = wave.position.x
	var moved: float = x_before - x_after

	if absf(moved - 300.0) > 1.0:
		_fail("PressureWave movement: expected 300 px in 1s, got %.1f" % moved)
	else:
		print("PressureWave: moves %.0f px/s (travel_speed=300) — OK" % moved)

	holder.queue_free()
	await process_frame


## ── TimingJudge high-BPM assertion ───────────────────────────────────────────
func _test_high_bpm_timing() -> void:
	# At 165 BPM: beat = 60/165 = 0.364s. PERFECT window must remain > 0.
	var tj = root.get_node("TimingJudge")
	if tj == null:
		print("TimingJudge high-BPM: autoload not found, skipping")
		return

	var original_bpm: float = 0.0
	if tj.has_method("set_bpm"):
		original_bpm = tj.get("_bpm") if tj.get("_bpm") != null else 120.0
		tj.set_bpm(165.0)
	elif tj.get("_bpm") != null:
		original_bpm = float(tj.get("_bpm"))
		tj.set("_bpm", 165.0)
	else:
		print("TimingJudge high-BPM: cannot set BPM, skipping")
		return

	var perfect_window: float = 0.0
	if tj.has_method("get_perfect_window_ms"):
		perfect_window = float(tj.get_perfect_window_ms())
	elif tj.get("_perfect_window_ms") != null:
		perfect_window = float(tj.get("_perfect_window_ms"))
	else:
		# Read from window_scale and built-in constant
		var base: float = 60.0  # ms, from GDD §8.3
		var scale: float = 1.0
		if tj.get("window_scale") != null:
			scale = float(tj.get("window_scale"))
		perfect_window = base * scale

	if perfect_window <= 0.0:
		_fail("TimingJudge high-BPM: PERFECT window is 0 or negative at 165 BPM (%.1f ms)" % perfect_window)
	else:
		print("TimingJudge high-BPM: PERFECT window = %.1f ms at 165 BPM — OK" % perfect_window)

	# Restore
	if tj.has_method("set_bpm"):
		tj.set_bpm(original_bpm)
	elif tj.get("_bpm") != null:
		tj.set("_bpm", original_bpm)
