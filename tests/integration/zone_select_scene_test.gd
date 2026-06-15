## zone_select_scene_test.gd — verifies the Zone Select and Level Select polish:
## tall readable zone cards with BPM info, and level buttons showing names.
##
## Run with:
##   godot --headless --path . --script tests/integration/zone_select_scene_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	await process_frame
	await _test_zone_cards()
	await _test_level_buttons()
	print("Zone select scene tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("ZONE_SELECT_SCENE_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. Zone cards (6 ocean + 1 space bubble = 7 total), ≥200px tall, 36px font, first shows BPM.
func _test_zone_cards() -> void:
	var packed: PackedScene = load("res://scenes/gameplay/ZoneSelect.tscn") as PackedScene
	if packed == null:
		_fail("zone_cards", "ZoneSelect.tscn failed to load")
		return
	var screen: Control = packed.instantiate() as Control
	root.add_child(screen)
	await process_frame
	var container: Node = screen.get_node("ZoneContainer")
	if container.get_child_count() != 7:
		_fail("zone_cards", "expected 7 zone cards, got %d" % container.get_child_count())
		screen.queue_free()
		return
	var first: Button = container.get_child(0) as Button
	if first == null:
		_fail("zone_cards", "first zone card is not a Button")
		screen.queue_free()
		return
	if first.custom_minimum_size.y < 200:
		_fail("zone_cards", "zone card height %.0f < 200" % first.custom_minimum_size.y)
		screen.queue_free()
		return
	if first.get_theme_font_size("font_size") != 36:
		_fail("zone_cards", "zone card font_size is %d, expected 36" % first.get_theme_font_size("font_size"))
		screen.queue_free()
		return
	if not first.text.contains("BPM"):
		_fail("zone_cards", "first zone card text '%s' has no BPM info" % first.text)
		screen.queue_free()
		return
	_ok("zone_cards")
	screen.queue_free()


## 2. Level Select renders 8 buttons with human-readable level names.
func _test_level_buttons() -> void:
	var gm: Node = root.get_node("GameManager")
	gm.current_zone_id = "z1"
	var packed: PackedScene = load("res://scenes/gameplay/LevelSelect.tscn") as PackedScene
	if packed == null:
		_fail("level_buttons", "LevelSelect.tscn failed to load")
		return
	var screen: Control = packed.instantiate() as Control
	root.add_child(screen)
	await process_frame
	var container: Node = screen.get_node("LevelContainer")
	if container.get_child_count() != 8:
		_fail("level_buttons", "expected 8 level buttons, got %d" % container.get_child_count())
		screen.queue_free()
		return
	var first: Button = container.get_child(0) as Button
	if not first.text.contains("First Dive"):
		_fail("level_buttons", "first button text '%s' missing level name" % first.text)
		screen.queue_free()
		return
	_ok("level_buttons")
	screen.queue_free()
