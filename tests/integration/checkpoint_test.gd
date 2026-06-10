## checkpoint_test.gd — Phase 6 contracts for practice mode + checkpoint seek.
##
## Tests:
##   1. BeatConductor seek-to-16: get_current_beat_position() ≈ 16 after start.
##   2. Variable-BPM: start_level_variable_bpm(null, timestamps, 8) works headless.
##   3. ObstacleSpawner start_beat: entries before beat 16 are excluded.
##   4. CollectibleSpawner start_beat: entries before beat 16 are excluded.
##   5. Spawn distance accuracy at seek point: beat 20 from beat 16 = 4 beats px.
##   6. Practice mode: run_failed does NOT call SaveSystem.record_attempt().
##   7. LevelLoader.restart_from_beat fires practice_respawned signal.
##
## All autoloads are accessed via root.get_node() because --script mode does not
## resolve autoload singletons as compile-time identifiers.
##
## Run with:
##   godot --headless --path . --script tests/integration/checkpoint_test.gd
extends SceneTree

const Z1L1: String = "z1-l1"

var _failures: PackedStringArray = []

## Autoload refs — resolved once in _init after two process_frame awaits.
var _conductor: Node = null
var _scroll: Node = null
var _event_bus: Node = null
var _save: Node = null
var _game_manager: Node = null


func _init() -> void:
	await process_frame
	await process_frame

	_conductor = root.get_node("BeatConductor")
	_scroll = root.get_node("ScrollService")
	_event_bus = root.get_node("EventBus")
	_save = root.get_node("SaveSystem")
	_game_manager = root.get_node("GameManager")

	await _test_fixed_bpm_seek()
	await _test_vbpm_seek_headless()
	await _test_spawner_start_beat()
	await _test_collectible_spawner_start_beat()
	await _test_spawn_distance_at_seek()
	await _test_practice_no_save_writes()
	await _test_restart_from_beat_signal()

	print("==== CHECKPOINT TEST ====")
	if _failures.is_empty():
		print("All Phase 6 checkpoint contracts hold.")
		print("CHECKPOINT_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("CHECKPOINT_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


## Helper: load a RhythmMap and wait for map_loaded.
func _load_map(level_id: String) -> Node:
	var map_node = load("res://src/rhythm/RhythmMap.gd").new()
	root.add_child(map_node)
	var loaded := [false]
	map_node.map_loaded.connect(func(_id: String) -> void: loaded[0] = true, CONNECT_ONE_SHOT)
	map_node.load_level(level_id)
	var t: int = 0
	while not loaded[0] and t < 80:
		await process_frame
		t += 1
	if not loaded[0]:
		push_error("_load_map: map never loaded for " + level_id)
	return map_node


## ── BeatConductor fixed-BPM seek ────────────────────────────────────────────
func _test_fixed_bpm_seek() -> void:
	_conductor.start_level(120.0, null, 16.0)
	await process_frame

	var pos: float = _conductor.get_current_beat_position()
	_conductor.stop_level()

	if absf(pos - 16.0) > 0.5:
		_fail("Fixed-BPM seek: beat_position = %.3f, expected ≈16.0" % pos)
	else:
		print("Fixed-BPM seek-to-16: beat_position = %.3f — OK" % pos)


## ── Variable-BPM seek headless (null stream, wall clock) ────────────────────
func _test_vbpm_seek_headless() -> void:
	# Build a simple 32-beat 120-BPM timestamp array (0.5 s/beat).
	var timestamps: Array[float] = []
	for i: int in range(32):
		timestamps.append(float(i) * 0.5)

	_conductor.start_level_variable_bpm(null, timestamps, 8.0)
	await process_frame

	var pos: float = _conductor.get_current_beat_position()
	_conductor.stop_level()

	if absf(pos - 8.0) > 1.0:
		_fail("Variable-BPM seek: beat_position = %.3f, expected ≈8.0" % pos)
	else:
		print("Variable-BPM seek-to-8 headless — OK (pos=%.3f)" % pos)


## ── ObstacleSpawner start_beat filtering ────────────────────────────────────
func _test_spawner_start_beat() -> void:
	var map_node = await _load_map(Z1L1)
	if not map_node.is_loaded():
		_fail("ObstacleSpawner start_beat: map never loaded")
		map_node.queue_free()
		return

	var spawner = load("res://src/gameplay/ObstacleSpawner.gd").new()
	root.add_child(spawner)
	await process_frame

	var raw: Dictionary = map_node.get_raw_data()
	var all_entries: Array = raw.get("beat_map", []) as Array
	var total_count: int = all_entries.size()
	var after_10_count: int = 0
	for entry: Variant in all_entries:
		if float((entry as Dictionary).get("beat_index", 0)) >= 10.0:
			after_10_count += 1

	spawner.setup(map_node, 10.0)
	var pending_count: int = spawner._pending.size()

	spawner.queue_free()
	map_node.queue_free()
	await process_frame

	if pending_count != after_10_count:
		_fail("ObstacleSpawner start_beat=10: pending=%d, expected %d (total=%d)" % [pending_count, after_10_count, total_count])
	else:
		print("ObstacleSpawner start_beat=10: %d/%d entries kept — OK" % [pending_count, total_count])


## ── CollectibleSpawner start_beat filtering ─────────────────────────────────
func _test_collectible_spawner_start_beat() -> void:
	var map_node = await _load_map(Z1L1)
	if not map_node.is_loaded():
		_fail("CollectibleSpawner start_beat: map never loaded")
		map_node.queue_free()
		return

	var spawner = load("res://src/gameplay/CollectibleSpawner.gd").new()
	root.add_child(spawner)
	await process_frame

	var raw: Dictionary = map_node.get_raw_data()
	var all_entries: Array = raw.get("collectibles", []) as Array
	var after_10_count: int = 0
	for entry: Variant in all_entries:
		if float((entry as Dictionary).get("beat_index", 0)) >= 10.0:
			after_10_count += 1

	spawner.setup(map_node, 10.0)
	var pending_count: int = spawner._pending.size()

	spawner.queue_free()
	map_node.queue_free()
	await process_frame

	if pending_count != after_10_count:
		_fail("CollectibleSpawner start_beat=10: pending=%d, expected %d" % [pending_count, after_10_count])
	else:
		print("CollectibleSpawner start_beat=10: %d collectibles kept — OK" % pending_count)


## ── Spawn distance accuracy at seek point ────────────────────────────────────
func _test_spawn_distance_at_seek() -> void:
	# z1-l1 is 100 BPM, beat_duration = 0.6s, speed = 408 px/s, no speed zones.
	# 4 beats from beat 16 to beat 20 = 4 × 0.6 × 408 = 979.2 px.
	# Tolerance ±15 px accounts for sub-frame elapsed time at measurement.
	var map_node = await _load_map(Z1L1)
	if not map_node.is_loaded():
		_fail("Spawn distance: map never loaded")
		map_node.queue_free()
		return

	_conductor.start_level(100.0, null, 16.0)
	_scroll.activate(map_node)
	await process_frame

	var dist: float = _scroll.distance_until_beat(20.0)
	var expected: float = 4.0 * (60.0 / 100.0) * 408.0  # 979.2

	_scroll.deactivate()
	_conductor.stop_level()
	map_node.queue_free()
	await process_frame

	if absf(dist - expected) > 15.0:
		_fail("Spawn distance beat-20 from beat-16: %.2f px, expected %.2f ±15" % [dist, expected])
	else:
		print("Spawn distance beat-20 from beat-16: %.2f px (expected %.2f) — OK" % [dist, expected])


## ── Practice mode: run_failed skips SaveSystem writes ───────────────────────
func _test_practice_no_save_writes() -> void:
	var profile: String = _save.get_active_profile_id()
	var attempts_before: int = _save.get_attempts(profile, Z1L1)

	_game_manager.is_practice_mode = true
	_event_bus.run_failed.emit(Z1L1, 0)
	await process_frame

	var attempts_after: int = _save.get_attempts(profile, Z1L1)
	_game_manager.is_practice_mode = false

	if attempts_after != attempts_before:
		_fail("Practice mode: SaveSystem.record_attempt called (was=%d, now=%d)" % [attempts_before, attempts_after])
	else:
		print("Practice mode: run_failed skips SaveSystem writes — OK")


## ── LevelLoader.restart_from_beat emits practice_respawned ──────────────────
func _test_restart_from_beat_signal() -> void:
	var map_node = await _load_map(Z1L1)
	if not map_node.is_loaded():
		_fail("restart_from_beat signal: map never loaded")
		map_node.queue_free()
		return

	var loader = load("res://src/core/LevelLoader.gd").new()
	root.add_child(loader)
	# Manually wire the loader's cached state (normally set by _on_map_loaded).
	loader.rhythm_map = map_node
	loader._bpm = 120.0
	loader._is_variable = false
	loader._music_stream = null
	loader._total_beats = 32
	loader._level_id_meta = Z1L1
	loader._result_emitted = false

	var spawner = load("res://src/gameplay/ObstacleSpawner.gd").new()
	root.add_child(spawner)
	loader.obstacle_spawner = spawner
	var cspawner = load("res://src/gameplay/CollectibleSpawner.gd").new()
	root.add_child(cspawner)
	loader.collectible_spawner = cspawner

	var respawn_caught := [false]
	_event_bus.practice_respawned.connect(func() -> void: respawn_caught[0] = true, CONNECT_ONE_SHOT)

	loader.restart_from_beat(8.0)
	await process_frame

	_conductor.stop_level()
	_scroll.deactivate()
	spawner.queue_free()
	cspawner.queue_free()
	loader.queue_free()
	map_node.queue_free()
	await process_frame

	if not respawn_caught[0]:
		_fail("restart_from_beat: practice_respawned signal not emitted")
	else:
		print("restart_from_beat emits practice_respawned — OK")
