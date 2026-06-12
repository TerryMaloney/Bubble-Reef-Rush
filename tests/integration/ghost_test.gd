## ghost_test.gd — Phase 16 contracts for GhostRecorder and GhostLibrary.
##
## Tests:
##   1. recorder_records_events    — start() + record_event x2 yields input_count=2.
##   2. recorder_empty_before_start — fresh recorder reports is_empty()==true.
##   3. ghost_data_roundtrip       — 3 recorded events survive get_ghost_data().
##   4. ghost_library_save_load    — save_ghost/load_ghost round-trips final_score.
##   5. ghost_signal_emitted       — ghost_saved fires when save_ghost() is called.
##
## Run with:
##   godot --headless --path . --script tests/integration/ghost_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	# Wait one frame so autoload _ready() has run (TransitionLayer overlay).
	await process_frame
	var root := get_root()

	_test_recorder_records_events(root)
	_test_recorder_empty_before_start(root)
	_test_ghost_data_roundtrip(root)
	_test_ghost_library_save_load(root)
	_test_ghost_signal_emitted(root)
	_test_ghost_delta_format()
	_test_show_ghost_cleared_on_menu(root)

	print("Ghost tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("GHOST_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. recorder_records_events
func _test_recorder_records_events(root: Node) -> void:
	var rec: Node = load("res://src/gameplay/GhostRecorder.gd").new()
	root.add_child(rec)
	rec.start()
	rec.record_event(4.0, "dive_start")
	rec.record_event(6.0, "dive_end")

	if rec.get_input_count() == 2:
		_ok("recorder_records_events")
	else:
		_fail("recorder_records_events", "expected 2 inputs, got %d" % rec.get_input_count())

	rec.queue_free()


## 2. recorder_empty_before_start
func _test_recorder_empty_before_start(root: Node) -> void:
	var rec: Node = load("res://src/gameplay/GhostRecorder.gd").new()
	root.add_child(rec)

	if rec.is_empty() == true:
		_ok("recorder_empty_before_start")
	else:
		_fail("recorder_empty_before_start", "fresh recorder should be empty")

	rec.queue_free()


## 3. ghost_data_roundtrip
func _test_ghost_data_roundtrip(root: Node) -> void:
	var rec: Node = load("res://src/gameplay/GhostRecorder.gd").new()
	root.add_child(rec)
	rec.start()
	rec.record_event(1.0, "dive_start")
	rec.record_event(2.0, "dive_end")
	rec.record_event(3.0, "dive_start")

	var data: Dictionary = rec.get_ghost_data("test_level", "1.0")
	var inputs: Array = data.get("inputs", [])
	var level_id: String = str(data.get("level_id", ""))

	if inputs.size() == 3 and level_id == "test_level":
		_ok("ghost_data_roundtrip")
	else:
		_fail("ghost_data_roundtrip",
			"inputs.size=%d (want 3), level_id=%s (want test_level)" % [inputs.size(), level_id])

	rec.queue_free()


## 4. ghost_library_save_load
func _test_ghost_library_save_load(root: Node) -> void:
	var gl: Node = root.get_node("GhostLibrary")
	var ss: Node = root.get_node("SaveSystem")

	var pid: String = "ghost_test_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	var ghost_data: Dictionary = {
		"level_id": "z1-l1",
		"game_version": "1.0",
		"level_hash": "",
		"final_score": 9876,
		"inputs": [],
		"recorded_at": "",
	}
	gl.save_ghost(pid, "z1-l1", "personal_best", ghost_data)
	var loaded: Dictionary = gl.load_ghost(pid, "z1-l1", "personal_best")
	var score: int = int(loaded.get("final_score", -1))

	if score == 9876:
		_ok("ghost_library_save_load")
	else:
		_fail("ghost_library_save_load", "expected final_score=9876, got %d" % score)


## 5. ghost_signal_emitted
func _test_ghost_signal_emitted(root: Node) -> void:
	var gl: Node = root.get_node("GhostLibrary")
	var ss: Node = root.get_node("SaveSystem")
	var eb: Node = root.get_node("EventBus")

	var pid: String = "ghost_sig_test_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	var received: Array = []
	eb.ghost_saved.connect(func(_level_id: String, _ghost_type: String) -> void:
		received.append(1)
	)

	var ghost_data: Dictionary = {
		"level_id": "z1-l2",
		"game_version": "1.0",
		"level_hash": "",
		"final_score": 100,
		"inputs": [],
		"recorded_at": "",
	}
	gl.save_ghost(pid, "z1-l2", "personal_best", ghost_data)

	if not received.is_empty():
		_ok("ghost_signal_emitted")
	else:
		_fail("ghost_signal_emitted", "ghost_saved signal was not received")


## 6. ghost_delta_format — pure pace/delta formatting used by the HUD label.
## Loaded at runtime (not via class_name) so autoload deps resolve in --script mode.
func _test_ghost_delta_format() -> void:
	var hud: GDScript = load("res://src/ui/HUDController.gd") as GDScript
	# On pace exactly: ghost 2000 at 50% → pace 1000; score 1000 → "+0".
	var cases: Array = [
		[1000, 2000, 50.0, "+0"],
		[1500, 2000, 50.0, "+500"],
		[400, 2000, 50.0, "-600"],
	]
	for c: Array in cases:
		var got: String = str(hud.format_ghost_delta(int(c[0]), int(c[1]), float(c[2])))
		if got != str(c[3]):
			_fail("ghost_delta_format", "expected '%s', got '%s'" % [c[3], got])
			return
	_ok("ghost_delta_format")


## 7. show_ghost_cleared_on_menu — returning to the menu stops ghost spawning.
func _test_show_ghost_cleared_on_menu(root: Node) -> void:
	var gm: Node = root.get_node("GameManager")
	gm.show_ghost = "family_champion"
	gm.go_to_menu()
	if str(gm.show_ghost) != "":
		_fail("show_ghost_cleared_on_menu", "show_ghost still '%s' after go_to_menu" % gm.show_ghost)
		return
	_ok("show_ghost_cleared_on_menu")
