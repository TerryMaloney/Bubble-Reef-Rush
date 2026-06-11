## mutator_test.gd — Phase 19 contracts for MutatorSystem.
##
## Tests:
##   1. is_active_works        — is_active() returns true for active, false for inactive.
##   2. clear_empties_list     — clear() empties active_mutators.
##   3. no_powers_blocks_fire  — no_powers mutator is recognized by is_active().
##   4. faster_scroll_active   — faster_scroll mutator is recognized by is_active().
##
## Run with:
##   godot --headless --path . --script tests/integration/mutator_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_is_active_works(root)
	_test_clear_empties_list(root)
	_test_no_powers_blocks_fire(root)
	_test_faster_scroll_active(root)

	print("Mutator tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("MUTATOR_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. is_active_works
func _test_is_active_works(root: Node) -> void:
	var ms: Node = root.get_node("MutatorSystem")
	ms._test_set_active(["tiny_pebble", "faster_scroll"])

	var tiny_active: bool = ms.is_active("tiny_pebble")
	var ghost_inactive: bool = not ms.is_active("ghost_mode")

	if tiny_active and ghost_inactive:
		_ok("is_active_works")
	else:
		_fail("is_active_works",
			"tiny_pebble active=%s ghost_mode inactive=%s" % [str(tiny_active), str(ghost_inactive)])


## 2. clear_empties_list
func _test_clear_empties_list(root: Node) -> void:
	var ms: Node = root.get_node("MutatorSystem")
	ms._test_set_active(["tiny_pebble", "faster_scroll"])
	ms.clear()

	if ms.active_mutators.is_empty():
		_ok("clear_empties_list")
	else:
		_fail("clear_empties_list",
			"expected empty, got size=%d" % ms.active_mutators.size())


## 3. no_powers_blocks_fire
func _test_no_powers_blocks_fire(root: Node) -> void:
	var ms: Node = root.get_node("MutatorSystem")
	ms._test_set_active(["no_powers"])

	var ctrl: Node = load("res://src/gameplay/ResonanceController.gd").new()
	root.add_child(ctrl)
	ctrl.setup("allowed", 1, "bubble_burst")
	ctrl.set("_charges", 1)

	if ms.is_active("no_powers"):
		_ok("no_powers_blocks_fire")
	else:
		_fail("no_powers_blocks_fire", "no_powers should be recognized as active")

	ctrl.queue_free()


## 4. faster_scroll_active
func _test_faster_scroll_active(root: Node) -> void:
	var ms: Node = root.get_node("MutatorSystem")
	ms._test_set_active(["faster_scroll"])

	if ms.is_active("faster_scroll"):
		_ok("faster_scroll_active")
	else:
		_fail("faster_scroll_active", "faster_scroll should be recognized as active")
