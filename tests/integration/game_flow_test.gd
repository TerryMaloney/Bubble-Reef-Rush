## Integration test for the complete game loop:
##   load level → fire all beats manually → run_completed → GameManager stores results
##
## Emits beats directly on BeatConductor rather than waiting for real-time wall-clock,
## so the test completes in milliseconds instead of ~19 seconds.
##
## Run with:
##   godot --headless --path . --script tests/integration/game_flow_test.gd
##
## Exit code 0 = game loop verified, 1 = assertion failed.
extends SceneTree

var _run_completed: bool = false
var _completed_level_id: String = ""
var _completed_score: int = -1
var _completed_stars: int = -1


func _init() -> void:
	await process_frame
	await process_frame

	var game_manager: Node = root.get_node("GameManager")
	var event_bus: Node = root.get_node("EventBus")
	var beat_conductor: Node = root.get_node("BeatConductor")

	game_manager.current_level_id = "z1-l1"

	event_bus.run_completed.connect(
		func(level_id: String, score: int, stars: int) -> void:
			_run_completed = true
			_completed_level_id = level_id
			_completed_score = score
			_completed_stars = stars
	)

	var level_scene: PackedScene = load("res://scenes/gameplay/LevelRoot.tscn")
	_hard_assert(level_scene != null, "LevelRoot.tscn failed to load")
	var level: Node = level_scene.instantiate()
	root.add_child(level)

	# Let _ready chains run: LevelLoader loads .brl, _check_level_end connects to beat_fired.
	await process_frame
	await physics_frame

	var level_loader: Node = level.get_node_or_null("LevelLoader")
	_hard_assert(level_loader != null, "LevelLoader node missing from LevelRoot")
	_hard_assert(level.get_node_or_null("Player") != null, "Player node missing from LevelRoot")

	# Fire all 32 beats manually — bypasses real-time wall clock.
	# Beat 31 is total_beats-1 and will trigger level_ended → run_completed.
	for i: int in range(32):
		beat_conductor.beat_fired.emit(i)

	# Let deferred scene change (change_scene_to_file → ResultsScreen) process.
	await process_frame

	# ---- Assertions ----
	_hard_assert(_run_completed, "run_completed never fired after all 32 beats")
	_hard_assert(_completed_level_id == "z1-l1", "run_completed fired with wrong level_id: '%s'" % _completed_level_id)
	_hard_assert(_completed_score >= 0, "run_completed score was negative: %d" % _completed_score)
	_hard_assert(_completed_stars >= 0, "run_completed stars was negative: %d" % _completed_stars)
	_hard_assert(game_manager.get("last_score") == _completed_score,
		"GameManager.last_score (%d) != emitted score (%d)" % [game_manager.get("last_score"), _completed_score])
	_hard_assert(game_manager.get("last_stars") == _completed_stars,
		"GameManager.last_stars (%d) != emitted stars (%d)" % [game_manager.get("last_stars"), _completed_stars])

	print("==== GAME FLOW TEST ====")
	print("run_completed fired: %s" % _run_completed)
	print("level_id: %s" % _completed_level_id)
	print("score: %d  stars: %d" % [_completed_score, _completed_stars])
	print("GameManager.last_score: %d  last_stars: %d" % [game_manager.get("last_score"), game_manager.get("last_stars")])
	print("========================")
	print("GAME_FLOW_OK")
	quit(0)


func _hard_assert(cond: bool, msg: String) -> void:
	if not cond:
		push_error("GAME_FLOW FAIL: " + msg)
		print("GAME_FLOW FAIL: " + msg)
		quit(1)
