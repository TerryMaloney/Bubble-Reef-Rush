## Headless playtest harness for Bubble Reef Rush.
## Loads the real LevelRoot scene, simulates one-touch input over several
## seconds of physics frames, and reports what actually happened: beats fired,
## obstacles spawned, collisions, pearls collected, player movement.
##
## Run with:
##   godot --headless --path . --script tests/integration/playtest.gd
##
## Exit code 0 = core loop verified, 1 = a hard assertion failed.
extends SceneTree

# How long to simulate, in real milliseconds.
const SIM_DURATION_MS: int = 7000

# Counters populated by signal handlers.
var _beats_fired: int = 0
var _obstacles_spawned_seen: int = 0
var _run_started: bool = false
var _player_hit: bool = false
var _collectibles_taken: int = 0
var _run_failed: bool = false
var _bottom_spikes_seen: bool = false


func _init() -> void:
	# Boot needs a couple of frames so autoloads are ready.
	await process_frame
	await process_frame

	var game_manager: Node = root.get_node("GameManager")
	var event_bus: Node = root.get_node("EventBus")
	var beat_conductor: Node = root.get_node("BeatConductor")

	# Tell GameManager which level LevelRoot should load on _ready.
	game_manager.current_level_id = "z1-l1"

	# Wire up observation signals before instancing the level.
	beat_conductor.beat_fired.connect(func(_i: int) -> void: _beats_fired += 1)
	event_bus.run_started.connect(func(_id: String) -> void: _run_started = true)
	event_bus.player_hit.connect(func() -> void: _player_hit = true)
	event_bus.collectible_taken.connect(func(_v: int) -> void: _collectibles_taken += 1)
	event_bus.run_failed.connect(func(_id: String, _s: int) -> void: _run_failed = true)

	# Instance the real gameplay scene.
	var level_scene: PackedScene = load("res://scenes/gameplay/LevelRoot.tscn")
	_hard_assert(level_scene != null, "LevelRoot.tscn failed to load")
	var level: Node = level_scene.instantiate()
	root.add_child(level)

	# Let _ready chains run (LevelLoader loads the .brl, conductor starts).
	await process_frame
	await physics_frame

	# Verify the scene graph wired up.
	var player: Node = level.get_node_or_null("Player")
	_hard_assert(player != null, "Player node missing from LevelRoot")
	_hard_assert(player.get_node_or_null("BeatVisualizer") != null, "BeatVisualizer child missing")
	_hard_assert(player.get_node_or_null("TimingJudge") != null, "TimingJudge child missing")
	_hard_assert(_run_started, "run_started never fired — level did not load")

	var start_y: float = player.global_position.y
	var min_y: float = start_y
	var max_y: float = start_y

	# Simulate gameplay: pulse the swim_dive action roughly every ~0.5s, and
	# advance physics frames so PlayerController, spawners, and obstacles run.
	var start_ms: int = Time.get_ticks_msec()
	var frame: int = 0
	while Time.get_ticks_msec() - start_ms < SIM_DURATION_MS:
		# Press for ~12 frames, release for ~18, repeating — mimics tap-and-hold.
		var phase: int = frame % 30
		if phase == 0:
			_press_dive(true)
		elif phase == 12:
			_press_dive(false)

		await physics_frame
		frame += 1

		# Track how far the fish travelled and how many obstacles are live.
		if is_instance_valid(player):
			var y: float = player.global_position.y
			min_y = minf(min_y, y)
			max_y = maxf(max_y, y)
		_obstacles_spawned_seen = maxi(_obstacles_spawned_seen, _count_obstacles(level))

		# Check whether any bottom-attachment spike is live this frame.
		if not _bottom_spikes_seen:
			_bottom_spikes_seen = _has_bottom_spike(level)

	_press_dive(false)

	# ---- Report ----
	print("==== PLAYTEST REPORT ====")
	print("Frames simulated: %d" % frame)
	print("run_started fired: %s" % _run_started)
	print("Beats fired: %d" % _beats_fired)
	print("Obstacles seen on screen (peak): %d" % _obstacles_spawned_seen)
	print("Bottom spike ever seen: %s" % _bottom_spikes_seen)
	print("Collectibles taken: %d" % _collectibles_taken)
	print("Player hit fired: %s" % _player_hit)
	print("run_failed fired: %s" % _run_failed)
	print("Player Y range: %.1f .. %.1f (start %.1f)" % [min_y, max_y, start_y])
	print("=========================")

	# ---- Difficulty director trace (untyped so this entry script keeps no
	# compile-time dependency on the director class) ----
	var director: Variant = level.get_node_or_null("DifficultyDirector")
	if director != null:
		print("Director assist at end: %.2f" % director.get_assist())
		# Sample the authored sawtooth vs effective intensity at a few beats so
		# the curve shape is visible in the log.
		print("Intensity sample (authored 0.6):")
		for b: int in [4, 14, 16, 22, 28]:
			print("  beat %2d -> effective %.2f" % [b, director.effective_intensity(0.6, b)])

	# ---- Core-loop assertions ----
	_hard_assert(_beats_fired >= 4, "Beat clock not firing (got %d beats)" % _beats_fired)
	_hard_assert(_obstacles_spawned_seen >= 1, "No gates/obstacles ever spawned")
	_hard_assert(_bottom_spikes_seen, "No bottom-attachment spike ever seen — gate bottom half broken")
	_hard_assert(absf(max_y - min_y) > 20.0, "Player never moved vertically — input/physics dead")

	print("PLAYTEST_OK")
	quit(0)


func _count_obstacles(level: Node) -> int:
	var n: int = 0
	for child: Node in level.get_children():
		if child is Area2D:
			n += 1
	return n


## Returns true if any live Area2D child has a CollisionShape2D offset to negative Y,
## which is the signature of a bottom-attachment CoralSpike (pointing upward from wall).
func _has_bottom_spike(level: Node) -> bool:
	for child: Node in level.get_children():
		if child is Area2D:
			var coll: Node = child.get_node_or_null("CollisionShape2D")
			if coll != null and (coll as CollisionShape2D).position.y < -10.0:
				return true
	return false


func _press_dive(pressed: bool) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = "swim_dive"
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _hard_assert(cond: bool, msg: String) -> void:
	if not cond:
		push_error("PLAYTEST FAIL: " + msg)
		print("PLAYTEST FAIL: " + msg)
		quit(1)
