## obstacle_z3_test.gd — Phase 8 contracts for Zone 3 obstacles.
##
## Tests:
##   1. CurrentJet state machine: IDLE → TELEGRAPHING → FIRING → COOLDOWN → IDLE
##   2. CurrentJet collision gating: disabled in TELEGRAPHING, enabled in FIRING
##   3. CurrentJet player hit: player at jet lane_y is hit during FIRING
##   4. AnchorChain apex: on_apex signal fires as angular velocity crosses threshold
##   5. AnchorChain collision shapes present after setup
##   6. EelSnap state machine: DORMANT → TELEGRAPH → STRIKE → RETRACT → DORMANT
##   7. EelSnap collision gating: disabled in TELEGRAPH, enabled in STRIKE
##   8. EelSnap player hit: player at eel lane_y is hit during STRIKE
##
## Run with:
##   godot --headless --path . --script tests/integration/obstacle_z3_test.gd
extends SceneTree

var _failures: PackedStringArray = []
var _event_bus: Node = null


func _init() -> void:
	await process_frame
	await process_frame

	_event_bus = root.get_node("EventBus")

	await _test_jet_state_machine()
	await _test_jet_collision_gating()
	await _test_jet_player_hit()
	await _test_chain_apex()
	await _test_chain_segments()
	await _test_eel_state_machine()
	await _test_eel_collision_gating()
	await _test_eel_player_hit()

	print("==== OBSTACLE Z3 TEST ====")
	if _failures.is_empty():
		print("All Phase 8 Zone 3 obstacle contracts hold.")
		print("OBSTACLE_Z3_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("OBSTACLE_Z3_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


## ── CurrentJet state machine ─────────────────────────────────────────────────
func _test_jet_state_machine() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# Untyped — CurrentJet.gd references BeatConductor/ScrollService which are
	# autoloads, not resolvable at compile time in --script mode.
	var jet = load("res://scenes/obstacles/CurrentJet.tscn").instantiate()
	holder.add_child(jet)
	jet.set_process(false)
	jet.setup({"beat_index": 4, "lane_position": 0.5,
		"parameters": {"cycle_beats": 2, "origin_wall": "left"}})

	# Initial state should be IDLE (0).
	if jet._state != 0:
		_fail("CurrentJet: initial state not IDLE (got %d)" % jet._state)
		holder.queue_free()
		await process_frame
		return

	# Trigger first cycle via beat signal handler.
	jet._on_beat_fired(4)
	if jet._state != 1:
		_fail("CurrentJet: after beat_fired(4) expected TELEGRAPHING(1), got %d" % jet._state)
		holder.queue_free()
		await process_frame
		return
	print("CurrentJet: IDLE → TELEGRAPHING — OK")

	# Advance past TELEGRAPH_DUR (0.5 s).
	jet._process(0.6)
	if jet._state != 2:
		_fail("CurrentJet: after 0.6 s expected FIRING(2), got %d" % jet._state)
		holder.queue_free()
		await process_frame
		return
	print("CurrentJet: TELEGRAPHING → FIRING — OK")

	# Advance past FIRE_DUR (0.4 s).
	jet._process(0.5)
	if jet._state != 3:
		_fail("CurrentJet: after firing expected COOLDOWN(3), got %d" % jet._state)
		holder.queue_free()
		await process_frame
		return
	print("CurrentJet: FIRING → COOLDOWN — OK")

	# Advance past COOLDOWN_DUR (0.3 s).
	jet._process(0.4)
	if jet._state != 0:
		_fail("CurrentJet: after cooldown expected IDLE(0), got %d" % jet._state)
	else:
		print("CurrentJet: COOLDOWN → IDLE — OK")

	holder.queue_free()
	await process_frame


## ── CurrentJet collision gating ──────────────────────────────────────────────
func _test_jet_collision_gating() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var jet = load("res://scenes/obstacles/CurrentJet.tscn").instantiate()
	holder.add_child(jet)
	jet.set_process(false)
	jet.setup({"beat_index": 4, "lane_position": 0.5,
		"parameters": {"cycle_beats": 2, "origin_wall": "left"}})

	# IDLE: collision must be disabled.
	if not jet._stream_col.disabled:
		_fail("CurrentJet collision gating: collision not disabled in IDLE")

	# TELEGRAPHING: still disabled.
	jet._on_beat_fired(4)
	if not jet._stream_col.disabled:
		_fail("CurrentJet collision gating: collision not disabled in TELEGRAPHING")
	else:
		print("CurrentJet: collision disabled during TELEGRAPHING — OK")

	# FIRING: must be enabled.
	jet._process(0.6)
	if jet._stream_col.disabled:
		_fail("CurrentJet collision gating: collision not enabled in FIRING")
	else:
		print("CurrentJet: collision enabled during FIRING — OK")

	# COOLDOWN: disabled again.
	jet._process(0.5)
	if not jet._stream_col.disabled:
		_fail("CurrentJet collision gating: collision not disabled in COOLDOWN")
	else:
		print("CurrentJet: collision disabled during COOLDOWN — OK")

	holder.queue_free()
	await process_frame


## ── CurrentJet player hit ─────────────────────────────────────────────────────
func _test_jet_player_hit() -> void:
	var player_hit_flag := [false]
	var conn: Callable = func() -> void: player_hit_flag[0] = true
	_event_bus.player_hit.connect(conn)

	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(200.0, 960.0)
	player.set_physics_process(false)
	holder.add_child(player)

	var jet = load("res://scenes/obstacles/CurrentJet.tscn").instantiate()
	jet.position = Vector2(200.0, 960.0)
	holder.add_child(jet)
	jet.set_process(false)
	jet.setup({"beat_index": 4, "lane_position": 0.5,
		"parameters": {"cycle_beats": 2, "origin_wall": "left"}})

	# Advance to FIRING.
	jet._on_beat_fired(4)
	jet._process(0.6)

	for _i: int in range(8):
		await physics_frame

	_event_bus.player_hit.disconnect(conn)

	if not player_hit_flag[0]:
		_fail("CurrentJet player hit: player not hit during FIRING")
	else:
		print("CurrentJet: player hit during FIRING — OK")

	holder.queue_free()
	await process_frame


## ── AnchorChain apex detection ────────────────────────────────────────────────
func _test_chain_apex() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var ac = load("res://scenes/obstacles/AnchorChain.tscn").instantiate()
	holder.add_child(ac)
	ac.setup({"beat_index": 8, "lane_position": 0.0,
		"parameters": {"max_angle_degrees": 35, "pendulum_frequency": 0.5, "chain_length": 500}})
	ac.set_process(false)

	var apex_fired := [false]
	ac.on_apex.connect(func() -> void: apex_fired[0] = true)

	# Run 110 frames of 0.005 s (total 0.55 s).  First apex at t ≈ 0.5 s.
	for _i: int in range(110):
		ac._process(0.005)

	if not apex_fired[0]:
		_fail("AnchorChain apex: on_apex not fired within 0.55 s (freq=0.5 Hz)")
	else:
		print("AnchorChain: on_apex fired at pendulum apex — OK")

	holder.queue_free()
	await process_frame


## ── AnchorChain collision shapes present ─────────────────────────────────────
func _test_chain_segments() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var ac = load("res://scenes/obstacles/AnchorChain.tscn").instantiate()
	holder.add_child(ac)
	ac.setup({"beat_index": 8, "lane_position": 0.0,
		"parameters": {"max_angle_degrees": 35, "pendulum_frequency": 0.5, "chain_length": 500}})

	# 6 chain segments + 1 anchor = 7 children with collision shapes.
	var seg_count: int = ac._segments.size()
	if seg_count != 7:
		_fail("AnchorChain segments: expected 7, got %d" % seg_count)
	else:
		print("AnchorChain: %d collision segments (6 links + anchor) — OK" % seg_count)

	holder.queue_free()
	await process_frame


## ── EelSnap state machine ─────────────────────────────────────────────────────
func _test_eel_state_machine() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var eel = load("res://scenes/obstacles/EelSnap.tscn").instantiate()
	holder.add_child(eel)
	eel.set_process(false)
	eel.setup({"beat_index": 8, "lane_position": 0.5,
		"parameters": {"origin_wall": "left", "strike_length": 300, "dormant_beats": 4}})

	if eel._state != 0:
		_fail("EelSnap: initial state not DORMANT(0), got %d" % eel._state)
		holder.queue_free()
		await process_frame
		return

	# Beat before entry_beat should NOT trigger.
	eel._on_beat_fired(7)
	if eel._state != 0:
		_fail("EelSnap: triggered on beat before entry_beat")

	# Entry beat triggers TELEGRAPH.
	eel._on_beat_fired(8)
	if eel._state != 1:
		_fail("EelSnap: after beat_fired(8) expected TELEGRAPH(1), got %d" % eel._state)
		holder.queue_free()
		await process_frame
		return
	print("EelSnap: DORMANT → TELEGRAPH — OK")

	# Advance past TELEGRAPH_DUR (0.5 s) → STRIKE.
	eel._process(0.6)
	if eel._state != 2:
		_fail("EelSnap: after 0.6 s expected STRIKE(2), got %d" % eel._state)
		holder.queue_free()
		await process_frame
		return
	print("EelSnap: TELEGRAPH → STRIKE — OK")

	# Advance past STRIKE_DUR (0.15 s) → RETRACT.
	eel._process(0.2)
	if eel._state != 3:
		_fail("EelSnap: after strike expected RETRACT(3), got %d" % eel._state)
		holder.queue_free()
		await process_frame
		return
	print("EelSnap: STRIKE → RETRACT — OK")

	# Advance past RETRACT_DUR (0.3 s) → DORMANT.
	eel._process(0.4)
	if eel._state != 0:
		_fail("EelSnap: after retract expected DORMANT(0), got %d" % eel._state)
	else:
		print("EelSnap: RETRACT → DORMANT — OK")

	holder.queue_free()
	await process_frame


## ── EelSnap collision gating ─────────────────────────────────────────────────
func _test_eel_collision_gating() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var eel = load("res://scenes/obstacles/EelSnap.tscn").instantiate()
	holder.add_child(eel)
	eel.set_process(false)
	eel.setup({"beat_index": 8, "lane_position": 0.5,
		"parameters": {"origin_wall": "left", "strike_length": 300, "dormant_beats": 4}})

	# DORMANT: disabled.
	if not eel._strike_col.disabled:
		_fail("EelSnap collision gating: not disabled in DORMANT")

	# TELEGRAPH: still disabled.
	eel._on_beat_fired(8)
	if not eel._strike_col.disabled:
		_fail("EelSnap collision gating: not disabled in TELEGRAPH")
	else:
		print("EelSnap: collision disabled during TELEGRAPH — OK")

	# STRIKE: enabled.
	eel._process(0.6)
	if eel._strike_col.disabled:
		_fail("EelSnap collision gating: not enabled in STRIKE")
	else:
		print("EelSnap: collision enabled during STRIKE — OK")

	# RETRACT: disabled.
	eel._process(0.2)
	if not eel._strike_col.disabled:
		_fail("EelSnap collision gating: not disabled in RETRACT")
	else:
		print("EelSnap: collision disabled during RETRACT — OK")

	holder.queue_free()
	await process_frame


## ── EelSnap player hit ───────────────────────────────────────────────────────
func _test_eel_player_hit() -> void:
	var player_hit_flag := [false]
	var conn: Callable = func() -> void: player_hit_flag[0] = true
	_event_bus.player_hit.connect(conn)

	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# Player at (200, 960) — within eel strike zone [0..300] × [930..990].
	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	player.global_position = Vector2(200.0, 960.0)
	player.set_physics_process(false)
	holder.add_child(player)

	# Eel at (0, 960) with left wall: strike area at (150, 960), covers [0..300].
	var eel = load("res://scenes/obstacles/EelSnap.tscn").instantiate()
	eel.position = Vector2(0.0, 960.0)
	holder.add_child(eel)
	eel.set_process(false)
	eel.setup({"beat_index": 8, "lane_position": 0.5,
		"parameters": {"origin_wall": "left", "strike_length": 300, "dormant_beats": 4}})

	# Advance directly to STRIKE without triggering scroll movement.
	eel._do_strike()

	for _i: int in range(8):
		await physics_frame

	_event_bus.player_hit.disconnect(conn)

	if not player_hit_flag[0]:
		_fail("EelSnap player hit: player not hit during STRIKE")
	else:
		print("EelSnap: player hit during STRIKE — OK")

	holder.queue_free()
	await process_frame
