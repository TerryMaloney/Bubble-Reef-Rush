## Obstacle contract test: KelpCurtain + BubbleMine.
##
## Four cases:
##   1. Player placed inside a kelp blade    → player_hit fires (collision works)
##   2. Player placed at gap centre          → player_hit does NOT fire (gap is clear)
##   3. Player within BubbleMine arm_radius  → mine enters WARNING state
##   4. Player placed on BubbleMine centre   → player_hit fires (detonation works)
##
## Run with:
##   godot --headless --path . --script tests/integration/obstacle_test.gd
extends SceneTree

var _player_hit: bool = false

## Synthetic screen height used when building KelpCurtain blades at known positions.
## Gap centre at 500 gives blades above: y=350,170,−10 and below: y=650,830,1010.
const SCREEN_H: float = 1000.0
const GAP_CENTER_Y: float = 500.0
## y=350 is the centre of the first blade above the gap (blade spans 260..440 px).
const BLADE_HIT_Y: float = 350.0


func _init() -> void:
	await process_frame

	var event_bus: Node = root.get_node("EventBus")
	event_bus.player_hit.connect(func() -> void: _player_hit = true)

	var kelp_blade_ok: bool  = await _test_kelp_blade_hit()
	_player_hit = false
	var kelp_gap_ok: bool    = await _test_kelp_gap_no_hit()
	_player_hit = false
	var mine_warning_ok: bool = await _test_mine_warning()
	_player_hit = false
	var mine_hit_ok: bool    = await _test_mine_hit()

	print("==== OBSTACLE TEST ====")
	print("KelpCurtain blade  → player_hit fires:  %s" % kelp_blade_ok)
	print("KelpCurtain gap    → no hit fires:      %s" % kelp_gap_ok)
	print("BubbleMine WARNING → enters WARNING:    %s" % mine_warning_ok)
	print("BubbleMine contact → player_hit fires:  %s" % mine_hit_ok)
	print("=======================")

	if kelp_blade_ok and kelp_gap_ok and mine_warning_ok and mine_hit_ok:
		print("OBSTACLE_OK")
		quit(0)
	else:
		print("OBSTACLE_FAIL")
		quit(1)


## Player placed at the centre of the first blade above the gap should receive on_hit.
func _test_kelp_blade_hit() -> bool:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# Untyped on purpose: a KelpCurtain annotation makes that script a
	# compile-time dependency of this one, and its BeatConductor autoload
	# reference cannot resolve while the --script main is being compiled.
	var kc = load("res://scenes/obstacles/KelpCurtain.tscn").instantiate()
	kc.position = Vector2.ZERO
	holder.add_child(kc)
	kc.set_process(false)  # keep it from scrolling during the test
	# Build blades at known positions (bypass setup() to avoid viewport-size dependency).
	kc._build_blades(GAP_CENTER_Y, SCREEN_H)

	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(0.0, BLADE_HIT_Y)
	player.set_physics_process(false)
	holder.add_child(player)

	for _i: int in range(5):
		await physics_frame

	holder.queue_free()
	await process_frame
	return _player_hit


## Player placed at the gap centre must NOT collide with any blade.
## Gap is 440..560 px; player capsule at y=500 spans ~452..548 — entirely inside gap.
func _test_kelp_gap_no_hit() -> bool:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var kc = load("res://scenes/obstacles/KelpCurtain.tscn").instantiate()
	kc.position = Vector2.ZERO
	holder.add_child(kc)
	kc.set_process(false)
	kc._build_blades(GAP_CENTER_Y, SCREEN_H)

	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(0.0, GAP_CENTER_Y)
	player.set_physics_process(false)
	holder.add_child(player)

	for _i: int in range(5):
		await physics_frame

	holder.queue_free()
	await process_frame
	return not _player_hit  # pass = no hit


## Player within arm_radius (but not touching the mine body) → WARNING state.
## Mine at (400,400), player at (400,530): distance=130 < arm_radius=160 → WARNING.
## Collision shapes don't overlap (130 > mine_r56 + capsule_r20 = 76) → no body_entered.
func _test_mine_warning() -> bool:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# Add player first so mine._ready() finds it immediately.
	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(400.0, 530.0)
	player.set_physics_process(false)
	holder.add_child(player)

	var mine: BubbleMine = load("res://scenes/obstacles/BubbleMine.tscn").instantiate() as BubbleMine
	mine.position = Vector2(400.0, 400.0)
	mine.arm_radius = 160.0
	holder.add_child(mine)
	# Let _process run naturally (distance check happens in _process, not physics).

	for _i: int in range(4):
		await process_frame

	var in_warning: bool = (mine._state == BubbleMine.State.WARNING)
	mine.set_process(false)  # stop before queue_free to prevent any deferred scrolling

	holder.queue_free()
	await process_frame
	return in_warning


## Player placed exactly on the mine → body_entered fires → on_hit() → player_hit.
func _test_mine_hit() -> bool:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(400.0, 400.0)
	player.set_physics_process(false)
	holder.add_child(player)

	var mine: BubbleMine = load("res://scenes/obstacles/BubbleMine.tscn").instantiate() as BubbleMine
	mine.position = Vector2(400.0, 400.0)
	mine.set_process(false)  # prevent scrolling while waiting for physics
	holder.add_child(mine)

	for _i: int in range(5):
		await physics_frame

	holder.queue_free()
	await process_frame
	return _player_hit
