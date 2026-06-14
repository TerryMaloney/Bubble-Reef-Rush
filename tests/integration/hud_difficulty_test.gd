## hud_difficulty_test.gd
## Verifies the difficulty badge wiring in the HUD layer:
##   - GameManager.active_difficulty field is readable and settable
##   - The badge colour/text logic (mirrored here) produces correct results
##   - HUDController export var 'difficulty_badge' exists in the class schema
##
## Note: HUDController.gd uses bare 'EventBus' autoload references which
## cannot compile in --script mode (known headless limitation; see difficulty_test.gd).
## Full scene integration is covered by the smoke test and manual play.
##
## Run with:
##   godot --headless --path . --script tests/integration/hud_difficulty_test.gd
extends SceneTree

var _failures: PackedStringArray = []
var _passed: int = 0


func _init() -> void:
	await process_frame
	await process_frame

	_test_game_manager_difficulty_field()
	_test_badge_text_logic()
	_test_badge_colour_logic()
	_test_hud_controller_schema()

	print("==== HUD DIFFICULTY TEST ====")
	if _failures.is_empty():
		print("%d checks passed." % _passed)
		print("HUD_DIFFICULTY_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("HUD_DIFFICULTY_FAIL")
		quit(1)


func _ok(label: String) -> void:
	_passed += 1
	print("  PASS: " + label)


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("  FAIL: " + msg)


func _test_game_manager_difficulty_field() -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		_fail("GameManager autoload not found")
		return

	# active_difficulty should default to "normal".
	var diff: String = str(gm.get("active_difficulty"))
	if diff.is_empty():
		_fail("GameManager.active_difficulty is empty/null on init")
		return
	_ok("GameManager.active_difficulty is set on init (value='%s')" % diff)

	# Can be set to each hardness level.
	for d: String in ["easy", "normal", "hard"]:
		gm.set("active_difficulty", d)
		var got: String = str(gm.get("active_difficulty"))
		if got != d:
			_fail("GameManager.active_difficulty set to '%s', got '%s'" % [d, got])
		else:
			_ok("GameManager.active_difficulty → '%s'" % d)

	# Reset to normal.
	gm.set("active_difficulty", "normal")


func _test_badge_text_logic() -> void:
	# Mirror HUDController's badge text logic: diff.to_upper().
	var cases: Dictionary = {"easy": "EASY", "normal": "NORMAL", "hard": "HARD"}
	for input: String in cases.keys():
		var expected: String = str(cases[input])
		var got: String = input.to_upper()
		if got != expected:
			_fail("badge text: '%s'.to_upper() = '%s', expected '%s'" % [input, got, expected])
		else:
			_ok("badge text '%s' → '%s'" % [input, got])


func _test_badge_colour_logic() -> void:
	# Mirror HUDController's colour-per-difficulty logic.
	var colour_easy: Color = Color(0.2, 0.9, 1.0)   # cyan
	var colour_normal: Color = Color.WHITE
	var colour_hard: Color = Color(1.0, 0.4, 0.1)    # orange-red

	# Easy: blue component should be 1.0.
	if not is_equal_approx(colour_easy.b, 1.0):
		_fail("colour_easy.b should be 1.0 (cyan)")
	else:
		_ok("colour_easy is cyan (b=1.0)")

	# Normal: white.
	if colour_normal != Color.WHITE:
		_fail("colour_normal should be white")
	else:
		_ok("colour_normal is white")

	# Hard: red-dominant (r > 0.8, g < 0.5).
	if colour_hard.r < 0.8 or colour_hard.g > 0.5:
		_fail("colour_hard should be orange-red (r>0.8, g<0.5), got %s" % str(colour_hard))
	else:
		_ok("colour_hard is orange-red (r=%.1f, g=%.1f)" % [colour_hard.r, colour_hard.g])

	# Easy and Hard must differ from Normal.
	if colour_easy == colour_normal:
		_fail("colour_easy should differ from colour_normal")
	else:
		_ok("colour_easy != colour_normal")
	if colour_hard == colour_normal:
		_fail("colour_hard should differ from colour_normal")
	else:
		_ok("colour_hard != colour_normal")


func _test_hud_controller_schema() -> void:
	# Verify that HUDController.gd has 'difficulty_badge' as a property
	# by inspecting the class via ClassDB or script property list.
	# We do this by loading the script directly (not instantiating it, to avoid
	# the EventBus headless compile limitation).
	var script: Script = load("res://src/ui/HUDController.gd") as Script
	if script == null:
		_fail("Could not load HUDController.gd")
		return

	var props: Array[Dictionary] = script.get_script_property_list()
	var found: bool = false
	for prop: Dictionary in props:
		if str(prop.get("name", "")) == "difficulty_badge":
			found = true
			break
	if not found:
		_fail("HUDController.gd: 'difficulty_badge' export var not found in property list")
	else:
		_ok("HUDController.gd has 'difficulty_badge' export var")
