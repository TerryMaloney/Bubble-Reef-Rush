extends SceneTree

# Ghost system integration test — 5 contracts.
# Contract 1: record_stores_events      — GhostRecorder stores events with beat positions
# Contract 2: ghost_library_roundtrip   — save + load returns identical data
# Contract 3: ghost_saved_signal        — GhostLibrary.save_ghost emits ghost_saved signal
# Contract 4: ghost_player_no_collision — GhostPlayer is not in any collision layer
# Contract 5: family_champion_picks_best — get_family_champion returns highest-score ghost

const RECORDER_GD := "res://src/gameplay/GhostRecorder.gd"
const GHOST_PLAYER_GD := "res://src/gameplay/GhostPlayer.gd"

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()
	# All autoloads (EventBus, GhostLibrary, BeatConductor) are already loaded
	# by Godot from project.godot — just reference them by name via root.get_node().

	await _test_record_stores_events(root)
	await _test_ghost_library_roundtrip(root)
	await _test_ghost_saved_signal(root)
	await _test_ghost_player_no_collision(root)
	await _test_family_champion_picks_best(root)

	print("Ghost tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("GHOST_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  — " + detail if detail != "" else ""))
	_fail_count += 1


# ── Contract 1 ────────────────────────────────────────────────────────────────

func _test_record_stores_events(root: Node) -> void:
	var rec: Node = load(RECORDER_GD).new()
	root.add_child(rec)

	rec.start()
	# Simulate 3 recorded events.
	rec.record_event("dive_start")
	rec.record_event("dive_end")
	rec.record_event("dive_start")

	var data: Dictionary = rec.get_ghost_data("z1-l1", "1.0")
	var inputs: Array = data.get("inputs", [])
	if inputs.size() == 3:
		_ok("record_stores_events: count == 3")
	else:
		_fail("record_stores_events", "expected 3, got %d" % inputs.size())

	var first: Dictionary = inputs[0] as Dictionary
	if first.has("beat") and first.has("event") and first["event"] == "dive_start":
		_ok("record_stores_events: event schema has beat + event keys")
	else:
		_fail("record_stores_events: bad event schema: %s" % str(first))

	rec.queue_free()
	await process_frame


# ── Contract 2 ────────────────────────────────────────────────────────────────

func _test_ghost_library_roundtrip(root: Node) -> void:
	var lib: Node = root.get_node("GhostLibrary")
	var ghost_data: Dictionary = {
		"schema_ver": 1,
		"level_id": "z1-l1",
		"game_version": "1.0",
		"final_score": 420,
		"inputs": [{"beat": 0.0, "event": "dive_start"}, {"beat": 0.5, "event": "dive_end"}]
	}
	var profile := "test_profile_ghost"
	lib.save_ghost(profile, "z1-l1", "personal_best", ghost_data)
	var loaded: Dictionary = lib.load_ghost(profile, "z1-l1", "personal_best")

	if loaded.get("final_score", 0) == 420:
		_ok("ghost_library_roundtrip: score survives round-trip")
	else:
		_fail("ghost_library_roundtrip: score mismatch: %s" % str(loaded))

	var in_inputs: Array = loaded.get("inputs", [])
	if in_inputs.size() == 2:
		_ok("ghost_library_roundtrip: inputs array preserved")
	else:
		_fail("ghost_library_roundtrip: inputs size wrong: %d" % in_inputs.size())

	await process_frame


# ── Contract 3 ────────────────────────────────────────────────────────────────

func _test_ghost_saved_signal(root: Node) -> void:
	var lib: Node = root.get_node("GhostLibrary")
	var eb: Node = root.get_node("EventBus")
	# Use an Array so the lambda captures a reference type (avoids bool copy issues).
	var fired: Array = []
	eb.ghost_saved.connect(func(_lid: String, _gt: String) -> void: fired.append(1))

	lib.save_ghost("test_signal_profile", "z2-l2", "personal_best",
		{"schema_ver": 1, "level_id": "z2-l2", "game_version": "1.0",
		 "final_score": 300, "inputs": []})

	await process_frame
	await process_frame
	if fired.size() > 0:
		_ok("ghost_saved_signal: EventBus.ghost_saved emitted")
	else:
		_fail("ghost_saved_signal: signal not fired")

	await process_frame


# ── Contract 4 ────────────────────────────────────────────────────────────────

func _test_ghost_player_no_collision(root: Node) -> void:
	var gp: Node2D = load(GHOST_PLAYER_GD).new()
	root.add_child(gp)
	gp.setup({
		"schema_ver": 1, "level_id": "z1-l1", "game_version": "1.0",
		"final_score": 100,
		"inputs": [{"beat": 1.0, "event": "dive_start"}, {"beat": 1.5, "event": "dive_end"}]
	})

	# GhostPlayer must NOT be a CollisionObject — it is purely visual.
	if not (gp is CollisionObject2D):
		_ok("ghost_player_no_collision: GhostPlayer is not a CollisionObject2D")
	else:
		_fail("ghost_player_no_collision: GhostPlayer is a CollisionObject2D — it will block hits")

	gp.queue_free()
	await process_frame


# ── Contract 5 ────────────────────────────────────────────────────────────────

func _test_family_champion_picks_best(root: Node) -> void:
	var lib: Node = root.get_node("GhostLibrary")

	# Write two profiles with different scores for the same level.
	lib.save_ghost("family_a", "z3-l3", "personal_best",
		{"schema_ver": 1, "level_id": "z3-l3", "game_version": "1.0",
		 "final_score": 550, "inputs": []})
	lib.save_ghost("family_b", "z3-l3", "personal_best",
		{"schema_ver": 1, "level_id": "z3-l3", "game_version": "1.0",
		 "final_score": 720, "inputs": []})

	var champion: Dictionary = lib.get_family_champion("z3-l3")
	if champion.get("final_score", 0) == 720:
		_ok("family_champion_picks_best: returns highest-score ghost")
	else:
		_fail("family_champion_picks_best: wrong champion score: %d" % champion.get("final_score", -1))

	await process_frame
