## obstacle_z6_test.gd — Phase 11 contracts for Zone 6 obstacles.
##
## Tests:
##   1. CrystalShard velocity: entry_side=right + diagonal=down → vel.x < 0, vel.y > 0
##   2. CrystalShard velocity: entry_side=left  + diagonal=up   → vel.x > 0, vel.y < 0
##   3. CrystalShard top-wall bounce: vel.y flips positive when y ≤ 0
##   4. CrystalShard bottom-wall bounce: vel.y flips negative when y ≥ CANVAS_H
##   5. CrystalShard player hit: overlap with Player fires on_hit()
##   6. CrystalShard despawn: queue_free when x < -400
##   7. CrystalShard rotation direction: clockwise=+1.0, counter_clockwise=−1.0
##
## Run with:
##   godot --headless --path . --script tests/integration/obstacle_z6_test.gd
extends SceneTree

var _failures: PackedStringArray = []


func _init() -> void:
	await process_frame
	await process_frame

	await _test_crystal_velocity_right_down()
	await _test_crystal_velocity_left_up()
	await _test_crystal_top_bounce()
	await _test_crystal_bottom_bounce()
	await _test_crystal_player_hit()
	await _test_crystal_despawn()
	await _test_crystal_rotation()

	print("==== OBSTACLE Z6 TEST ====")
	if _failures.is_empty():
		print("All Phase 11 Zone 6 obstacle contracts hold.")
		print("OBSTACLE_Z6_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("OBSTACLE_Z6_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


## ── CrystalShard velocity: right + down ──────────────────────────────────────
func _test_crystal_velocity_right_down() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var shard = load("res://scenes/obstacles/CrystalShard.tscn").instantiate()
	holder.add_child(shard)
	shard.set_process(false)
	shard.setup({"beat_index": 2, "lane_position": 0.5,
		"parameters": {"lateral_speed": 400, "entry_side": "right",
			"diagonal_speed_initial": "down", "rotation_direction": "clockwise",
			"color_variant": "blue"}})

	if shard._vel.x >= 0.0:
		_fail("CrystalShard vel right+down: vel.x should be < 0, got %.1f" % shard._vel.x)
	elif shard._vel.y <= 0.0:
		_fail("CrystalShard vel right+down: vel.y should be > 0, got %.1f" % shard._vel.y)
	else:
		print("CrystalShard: right+down velocity (%.0f, %.0f) — OK" % [shard._vel.x, shard._vel.y])

	holder.queue_free()
	await process_frame


## ── CrystalShard velocity: left + up ─────────────────────────────────────────
func _test_crystal_velocity_left_up() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var shard = load("res://scenes/obstacles/CrystalShard.tscn").instantiate()
	holder.add_child(shard)
	shard.set_process(false)
	shard.setup({"beat_index": 2, "lane_position": 0.5,
		"parameters": {"lateral_speed": 600, "entry_side": "left",
			"diagonal_speed_initial": "up", "rotation_direction": "counter_clockwise",
			"color_variant": "purple"}})

	if shard._vel.x <= 0.0:
		_fail("CrystalShard vel left+up: vel.x should be > 0, got %.1f" % shard._vel.x)
	elif shard._vel.y >= 0.0:
		_fail("CrystalShard vel left+up: vel.y should be < 0, got %.1f" % shard._vel.y)
	else:
		print("CrystalShard: left+up velocity (%.0f, %.0f) — OK" % [shard._vel.x, shard._vel.y])

	holder.queue_free()
	await process_frame


## ── CrystalShard top-wall bounce ─────────────────────────────────────────────
func _test_crystal_top_bounce() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var shard = load("res://scenes/obstacles/CrystalShard.tscn").instantiate()
	holder.add_child(shard)
	shard.set_process(false)
	shard.setup({"beat_index": 2, "lane_position": 0.5,
		"parameters": {"lateral_speed": 400, "entry_side": "right",
			"diagonal_speed_initial": "down", "rotation_direction": "clockwise",
			"color_variant": "blue"}})

	# Place near top with upward velocity so the next _process step exits y < 0.
	shard.position = Vector2(540.0, 5.0)
	shard._vel = Vector2(-400.0, -200.0)
	shard._process(0.1)  # y → -15 → bounce: vel.y = absf(-200) = +200

	if shard._vel.y <= 0.0:
		_fail("CrystalShard top bounce: vel.y should be > 0 after bounce, got %.1f" % shard._vel.y)
	else:
		print("CrystalShard: top-wall bounce → vel.y=%.0f — OK" % shard._vel.y)

	holder.queue_free()
	await process_frame


## ── CrystalShard bottom-wall bounce ──────────────────────────────────────────
func _test_crystal_bottom_bounce() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var shard = load("res://scenes/obstacles/CrystalShard.tscn").instantiate()
	holder.add_child(shard)
	shard.set_process(false)
	shard.setup({"beat_index": 2, "lane_position": 0.5,
		"parameters": {"lateral_speed": 400, "entry_side": "right",
			"diagonal_speed_initial": "down", "rotation_direction": "clockwise",
			"color_variant": "blue"}})

	# Place near bottom with downward velocity so the next _process step exits y > 1920.
	shard.position = Vector2(540.0, 1915.0)
	shard._vel = Vector2(-400.0, 200.0)
	shard._process(0.1)  # y → 1935 → bounce: vel.y = -absf(200) = -200

	if shard._vel.y >= 0.0:
		_fail("CrystalShard bottom bounce: vel.y should be < 0 after bounce, got %.1f" % shard._vel.y)
	else:
		print("CrystalShard: bottom-wall bounce → vel.y=%.0f — OK" % shard._vel.y)

	holder.queue_free()
	await process_frame


## ── CrystalShard player hit ───────────────────────────────────────────────────
func _test_crystal_player_hit() -> void:
	var player_hit_flag := [false]
	var eb = root.get_node("EventBus")
	var conn: Callable = func() -> void: player_hit_flag[0] = true
	eb.player_hit.connect(conn)

	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(540.0, 960.0)
	player.set_physics_process(false)
	holder.add_child(player)

	var shard = load("res://scenes/obstacles/CrystalShard.tscn").instantiate()
	shard.position = Vector2(540.0, 960.0)
	holder.add_child(shard)
	shard.set_process(false)
	shard.setup({"beat_index": 2, "lane_position": 0.5,
		"parameters": {"lateral_speed": 400, "entry_side": "right",
			"diagonal_speed_initial": "down", "rotation_direction": "clockwise",
			"color_variant": "blue"}})

	for _i: int in range(8):
		await physics_frame

	eb.player_hit.disconnect(conn)

	if not player_hit_flag[0]:
		_fail("CrystalShard player hit: player not hit when overlapping")
	else:
		print("CrystalShard: player hit on overlap — OK")

	holder.queue_free()
	await process_frame


## ── CrystalShard despawn ──────────────────────────────────────────────────────
func _test_crystal_despawn() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var shard = load("res://scenes/obstacles/CrystalShard.tscn").instantiate()
	holder.add_child(shard)
	shard.set_process(false)
	shard.setup({"beat_index": 2, "lane_position": 0.5,
		"parameters": {"lateral_speed": 400, "entry_side": "right",
			"diagonal_speed_initial": "down", "rotation_direction": "clockwise",
			"color_variant": "blue"}})

	# Just inside the boundary; one step of -400 px/s × 0.1 s crosses x < -400.
	shard.position = Vector2(-380.0, 960.0)
	shard._vel = Vector2(-400.0, 0.0)
	shard._process(0.1)  # x → -420 < -400 → queue_free()

	if is_instance_valid(shard) and not shard.is_queued_for_deletion():
		_fail("CrystalShard despawn: not queued_for_deletion after x < -400")
	else:
		print("CrystalShard: queued_for_deletion after x < -400 — OK")

	holder.queue_free()
	await process_frame


## ── CrystalShard rotation direction ──────────────────────────────────────────
func _test_crystal_rotation() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var shard_cw = load("res://scenes/obstacles/CrystalShard.tscn").instantiate()
	holder.add_child(shard_cw)
	shard_cw.set_process(false)
	shard_cw.setup({"beat_index": 2, "lane_position": 0.5,
		"parameters": {"lateral_speed": 400, "entry_side": "right",
			"diagonal_speed_initial": "down", "rotation_direction": "clockwise",
			"color_variant": "teal"}})

	if absf(shard_cw._rotation_dir - 1.0) > 0.01:
		_fail("CrystalShard rotation: clockwise → _rotation_dir=1.0, got %.2f" % shard_cw._rotation_dir)
	else:
		print("CrystalShard: clockwise _rotation_dir=1.0 — OK")

	var shard_ccw = load("res://scenes/obstacles/CrystalShard.tscn").instantiate()
	holder.add_child(shard_ccw)
	shard_ccw.set_process(false)
	shard_ccw.setup({"beat_index": 2, "lane_position": 0.5,
		"parameters": {"lateral_speed": 400, "entry_side": "right",
			"diagonal_speed_initial": "down", "rotation_direction": "counter_clockwise",
			"color_variant": "pink"}})

	if absf(shard_ccw._rotation_dir + 1.0) > 0.01:
		_fail("CrystalShard rotation: counter_clockwise → _rotation_dir=-1.0, got %.2f" % shard_ccw._rotation_dir)
	else:
		print("CrystalShard: counter_clockwise _rotation_dir=-1.0 — OK")

	holder.queue_free()
	await process_frame
