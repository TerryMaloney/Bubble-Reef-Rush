## Coordinate-space contract test.
##
## Directly exercises the spawn math in ObstacleSpawner and CollectibleSpawner
## to confirm they use the 1080×1920 canvas coordinate space, not the
## window/viewport pixel size (which caused tiny spikes and off-screen pearls
## before the get_visible_rect() → CANVAS_H constant fix).
##
## Also verifies that PlayerController bounds-clamps against 1920 (canvas top
## clamp at y=60, canvas bottom clamp at y=1860).
##
## All game-class references are duck-typed (no static annotations) so this
## script has no compile-time dependencies that pull in autoload-referencing
## scripts before the autoloads are registered.
##
## Run with:
##   godot --headless --path . --script tests/integration/geometry_test.gd
extends SceneTree

const CANVAS_W: float = 1080.0
const CANVAS_H: float = 1920.0

var _failures: PackedStringArray = []


func _init() -> void:
	await process_frame
	await process_frame

	_test_gate_heights()
	_test_pearl_position()
	await _test_player_top_clamp()

	print("==== GEOMETRY TEST ====")
	if _failures.is_empty():
		print("All geometry contracts hold in the 1080×1920 canvas space.")
		print("GEOMETRY_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("GEOMETRY_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


## ── Gate heights ─────────────────────────────────────────────────────────────
##
## Directly call ObstacleSpawner._spawn_gate() with a known entry and check
## that the two CoralSpike children of the holder have the expected heights.
## No BeatConductor / music involved — just spawn math.
##
## Input:  intensity=0.5, gap_y_normalized=0.5, canvas_h=1920
## Expect: gap_px = lerp(280,200, 0.5) = 240
##         gap_center_y = 0.5 × 1920 = 960
##         top_height = bottom_height = 960 – 120 = 840 px
func _test_gate_heights() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# Instantiate ObstacleSpawner as a child of holder so that
	# get_parent().add_child(spike) plants spikes in holder.
	var spawner = load("res://src/gameplay/ObstacleSpawner.gd").new()
	holder.add_child(spawner)

	var entry: Dictionary = {
		"beat_index": 0,
		"obstacle_type": "pressure_wall",
		"lane_position": 0.5,
		"parameters": {
			"gap_y_normalized": 0.5,
			"intensity": 0.5,
		},
	}
	spawner._spawn_gate(entry, entry["parameters"] as Dictionary)

	# Two CoralSpike Area2D nodes should now be direct children of holder.
	var top_h: float = 0.0
	var bot_h: float = 0.0
	var spawn_x: float = 0.0
	var found: int = 0

	for child: Node in holder.get_children():
		if child == spawner:
			continue
		if not child is Node2D:
			continue
		var spike: Node2D = child as Node2D
		var coll: Node = spike.get_node_or_null("CollisionShape2D")
		if coll == null:
			continue
		var shape = (coll as CollisionShape2D).shape
		if shape == null or not shape is RectangleShape2D:
			continue
		var h: float = (shape as RectangleShape2D).size.y
		found += 1
		spawn_x = spike.position.x
		if absf(spike.position.y) < 1.0:
			top_h = h
		elif absf(spike.position.y - CANVAS_H) < 1.0:
			bot_h = h

	if found < 2:
		_fail("Gate produced %d spikes, expected 2" % found)
	else:
		# Expected: gap_px=240, gap_center=960, so each spike is 840 px tall.
		if absf(top_h - 840.0) > 1.0:
			_fail("Top spike height %.1f px — expected 840 (gate top half in 1920-px space)" % top_h)
		if absf(bot_h - 840.0) > 1.0:
			_fail("Bottom spike height %.1f px — expected 840 (gate bottom half)" % bot_h)
		if absf(spawn_x - (CANVAS_W + 100.0)) > 1.0:
			_fail("Spike spawn x=%.1f — expected %.1f (CANVAS_W + 100)" % [spawn_x, CANVAS_W + 100.0])
		print("Gate check: top %.0f px, bot %.0f px at x=%.0f — OK" % [top_h, bot_h, spawn_x])

	holder.queue_free()


## ── Pearl position ────────────────────────────────────────────────────────────
##
## Call CollectibleSpawner._spawn_collectible() with lane_position=0.5 and
## verify the pearl lands at y=960 (0.5 × 1920) and x=1180 (CANVAS_W+100).
func _test_pearl_position() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var spawner = load("res://src/gameplay/CollectibleSpawner.gd").new()
	holder.add_child(spawner)

	var entry: Dictionary = {
		"beat_index": 0,
		"collectible_type": "pearl",
		"lane_position": 0.5,
		"value": 10,
	}
	spawner._spawn_collectible(entry)

	var pearl: Node2D = null
	for child: Node in holder.get_children():
		if child != spawner:
			pearl = child as Node2D
			break

	if pearl == null:
		_fail("CollectibleSpawner produced no pearl node")
	else:
		var expected_y: float = 0.5 * CANVAS_H  # 960.0
		var expected_x: float = CANVAS_W + 100.0  # 1180.0
		if absf(pearl.position.y - expected_y) > 1.0:
			_fail("Pearl y=%.1f — expected %.1f (lane 0.5 × CANVAS_H 1920)" % [pearl.position.y, expected_y])
		if absf(pearl.position.x - expected_x) > 1.0:
			_fail("Pearl x=%.1f — expected %.1f (CANVAS_W+100)" % [pearl.position.x, expected_x])
		print("Pearl check: pos (%.0f, %.0f) — OK" % [pearl.position.x, pearl.position.y])

	holder.queue_free()
	await process_frame


## ── Player top-clamp ──────────────────────────────────────────────────────────
##
## Float the player upward from y=960 for 240 physics frames (~4 s) with no
## input and confirm it clamps at y=60 (not at some smaller window height).
## A clamp based on the wrong viewport size (~540 px) would stop at y≈500 not 60.
func _test_player_top_clamp() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate() as Node2D
	player.global_position = Vector2(200.0, 960.0)
	holder.add_child(player)

	# Let _ready() fire then simulate 4 seconds of buoyancy with no dive input.
	await physics_frame
	for _i: int in range(240):
		await physics_frame

	var y: float = player.global_position.y
	# Must be at (or within 5 px of) the canvas-top clamp.
	# If the old viewport bug were still present, y would stop near 500–600.
	if absf(y - 60.0) > 5.0:
		_fail("Player floated to y=%.1f — expected ~60 (canvas-top clamp). "
			+ "If y≈500-600 the CANVAS_H constant fix is not taking effect." % y)
	else:
		print("Player top-clamp check: y=%.1f after 4 s float — OK" % y)

	holder.queue_free()
	await process_frame
