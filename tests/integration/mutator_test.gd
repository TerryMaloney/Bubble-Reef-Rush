extends SceneTree

# Mutator system integration test — 4 contracts.
# Contract 1: tiny_pebble_scales      — tiny_pebble sets player scale to (0.5, 0.5)
# Contract 2: reverse_buoyancy_flips  — reverse_buoyancy negates float_force and dive_force
# Contract 3: no_powers_blocks_fire   — no_powers sets power mode to "disabled"
# Contract 4: faster_scroll_increases — faster_scroll multiplies speed_now by 1.3

const MUTATOR_GD := "res://src/core/MutatorSystem.gd"
const PLAYER_GD := "res://src/gameplay/PlayerController.gd"
const RESONANCE_GD := "res://src/gameplay/ResonanceController.gd"

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()
	# MutatorSystem is already an autoload; get it via root.
	var ms: Node = root.get_node("MutatorSystem")

	_test_tiny_scales(ms, root)
	_test_reverse_buoyancy(ms, root)
	_test_no_powers_blocks_fire(ms, root)
	_test_faster_scroll(ms, root)

	print("Mutator tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("MUTATOR_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  — " + detail if detail != "" else ""))
	_fail_count += 1


# ── Minimal mock helpers ───────────────────────────────────────────────────────

func _make_mock_player(root: Node) -> Node2D:
	# Create a Node2D with an inline script that exposes the properties
	# MutatorSystem.apply() reads and writes.
	var script := GDScript.new()
	script.source_code = "extends Node2D\nvar float_force:float=480.0\nvar dive_force:float=1220.0\nvar drag:float=0.983\nvar diving:bool=false"
	var ok: int = script.reload()
	if ok != OK:
		push_error("mock_player script error: %d" % ok)
	var player := Node2D.new()
	player.set_script(script)
	root.add_child(player)
	return player


func _make_mock_scroll() -> Node:
	var script := GDScript.new()
	script.source_code = "extends Node\nvar speed_now:float=400.0"
	script.reload()
	var scroll := Node.new()
	scroll.set_script(script)
	return scroll


func _make_mock_root(root: Node, rc_node: Node = null) -> Node:
	var lr := Node.new()
	if rc_node != null:
		rc_node.name = "ResonanceController"
		lr.add_child(rc_node)
	root.add_child(lr)
	return lr


# ── Contract 1 ────────────────────────────────────────────────────────────────

func _test_tiny_scales(ms: Node, root: Node) -> void:
	ms.active_mutators.clear()
	ms.active_mutators.append("tiny_pebble")

	var player: Node2D = _make_mock_player(root)
	var scroll: Node = _make_mock_scroll()
	var level_root: Node = _make_mock_root(root)

	ms.apply(player, scroll, level_root)

	if player.scale.is_equal_approx(Vector2(0.5, 0.5)):
		_ok("tiny_pebble_scales: player scale == (0.5, 0.5)")
	else:
		_fail("tiny_pebble_scales", "scale = %s" % str(player.scale))

	player.queue_free()
	level_root.queue_free()
	ms.active_mutators.clear()


# ── Contract 2 ────────────────────────────────────────────────────────────────

func _test_reverse_buoyancy(ms: Node, root: Node) -> void:
	ms.active_mutators.clear()
	ms.active_mutators.append("reverse_buoyancy")

	var player: Node2D = _make_mock_player(root)
	var original_float: float = player.float_force
	var original_dive: float = player.dive_force

	var scroll: Node = _make_mock_scroll()
	var level_root: Node = _make_mock_root(root)

	ms.apply(player, scroll, level_root)

	var new_float: float = player.float_force
	var new_dive: float = player.dive_force

	if is_equal_approx(new_float, -original_float):
		_ok("reverse_buoyancy_flips: float_force negated (%g to %g)" % [original_float, new_float])
	else:
		_fail("reverse_buoyancy_flips: float_force not negated",
			"%g to %g" % [original_float, new_float])

	if is_equal_approx(new_dive, -original_dive):
		_ok("reverse_buoyancy_flips: dive_force negated (%g to %g)" % [original_dive, new_dive])
	else:
		_fail("reverse_buoyancy_flips: dive_force not negated",
			"%g to %g" % [original_dive, new_dive])

	player.queue_free()
	level_root.queue_free()
	ms.active_mutators.clear()


# ── Contract 3 ────────────────────────────────────────────────────────────────

func _test_no_powers_blocks_fire(ms: Node, root: Node) -> void:
	ms.active_mutators.clear()
	ms.active_mutators.append("no_powers")

	# Create a real ResonanceController and add it to the mock root.
	var rc: Node = load(RESONANCE_GD).new()
	rc.name = "ResonanceController"
	var player: Node2D = _make_mock_player(root)
	var scroll: Node = _make_mock_scroll()
	var level_root: Node = _make_mock_root(root, rc)  # already added to root inside _make_mock_root

	# Setup the RC first.
	rc.setup("allowed", 1, "bubble_burst")
	ms.apply(player, scroll, level_root)

	# After applying no_powers, RC should have mode "disabled" — fire() should not emit.
	var fired: Array = []
	root.get_node("EventBus").power_activated.connect(func(_pt, _ip) -> void: fired.append(1))
	# Give RC 5 pearls to fill the charge.
	for i: int in range(5):
		root.get_node("EventBus").collectible_taken.emit(1)

	rc.fire()

	# Signal fires synchronously, no need to await.
	if fired.is_empty():
		_ok("no_powers_blocks_fire: fire() blocked when mode=disabled")
	else:
		_fail("no_powers_blocks_fire: power fired despite no_powers mutator")

	player.queue_free()
	level_root.queue_free()
	ms.active_mutators.clear()


# ── Contract 4 ────────────────────────────────────────────────────────────────

func _test_faster_scroll(ms: Node, root: Node) -> void:
	ms.active_mutators.clear()
	ms.active_mutators.append("faster_scroll")

	var player: Node2D = _make_mock_player(root)
	var scroll: Node = _make_mock_scroll()
	var original_speed: float = scroll.speed_now
	var level_root: Node = _make_mock_root(root)

	ms.apply(player, scroll, level_root)

	var new_speed: float = scroll.speed_now
	var expected: float = original_speed * 1.3
	if is_equal_approx(new_speed, expected):
		_ok("faster_scroll_increases: speed_now x1.3 (%g to %g)" % [original_speed, new_speed])
	else:
		_fail("faster_scroll_increases: wrong speed", "%g expected %g" % [new_speed, expected])

	player.queue_free()
	level_root.queue_free()
	ms.active_mutators.clear()
