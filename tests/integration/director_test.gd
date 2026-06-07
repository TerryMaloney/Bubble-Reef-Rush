## Unit test for DifficultyDirector — verifies the assist/push/early-win math
## that keeps players in the flow channel.
##
## The director script is loaded at RUNTIME (not as a compile-time type) and
## accessed via untyped/dynamic vars, so this entry script has no compile-time
## dependency on autoloads — which a bare `godot --script` run registers only
## after startup compilation.
##
## Run with:
##   godot --headless --path . --script tests/integration/director_test.gd
extends SceneTree

var _failures: int = 0
var _DirectorScript: GDScript = null


func _init() -> void:
	await process_frame
	_DirectorScript = load("res://src/gameplay/DifficultyDirector.gd")

	# --- Case 1: fresh director returns authored intensity mid-level ---
	var d: Variant = _make()
	_check("authored passthrough", absf(d.effective_intensity(0.5, 20) - 0.5) < 0.001)

	# --- Case 2: early-win opening is forced gentle ---
	_check("early-win gentle", d.effective_intensity(0.9, 4) <= d.intensity_floor + 0.05 + 0.001)

	# --- Case 3: a death raises assist and lowers effective intensity ---
	root.get_node("EventBus").player_hit.emit()
	await process_frame
	_check("death raises assist", d.get_assist() > 0.0)
	_check("death lowers intensity", d.effective_intensity(0.6, 20) < 0.6)
	_free(d)

	# --- Case 4: combo raises push above authored ---
	var d2: Variant = _make()
	d2.on_combo_updated(20)  # two combo tiers
	_check("combo raises push", d2.get_push() > 0.0)
	_check("push raises intensity", d2.effective_intensity(0.5, 20) > 0.5)
	_free(d2)

	# --- Case 5: deaths carry across retries (seeded by LevelRoot) ---
	var d3: Variant = _make()
	d3.seed_from_deaths(3)
	_check("carried deaths seed assist", d3.get_assist() > 0.0)
	_free(d3)

	# --- Case 6: effective intensity never leaves the clamp band ---
	var d4: Variant = _make()
	_check("clamped ceil", d4.effective_intensity(5.0, 20) <= d4.intensity_ceil + 0.001)
	_check("clamped floor", d4.effective_intensity(-5.0, 20) >= d4.intensity_floor - 0.001)
	_free(d4)

	print("==== DIRECTOR TEST ====")
	if _failures == 0:
		print("DIRECTOR_OK")
		quit(0)
	else:
		print("DIRECTOR_FAIL (%d failures)" % _failures)
		quit(1)


func _make() -> Variant:
	var d: Variant = _DirectorScript.new()
	root.add_child(d)
	return d


func _free(d: Variant) -> void:
	d.queue_free()


func _check(test_name: String, cond: bool) -> void:
	if cond:
		print("  PASS: %s" % test_name)
	else:
		print("  FAIL: %s" % test_name)
		_failures += 1
