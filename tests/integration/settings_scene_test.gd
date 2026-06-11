## settings_scene_test.gd — instantiates SettingsScreen.tscn headlessly and
## verifies key node paths exist and the text-scale setting round-trips.
##
## Run with:
##   godot --headless --path . --script tests/integration/settings_scene_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()
	var save_sys: Node = root.get_node("SaveSystem")
	var accessibility: Node = root.get_node("Accessibility")

	# Ensure the default profile exists so SettingsScreen can read settings.
	save_sys.ensure_profile(save_sys.get_active_profile_id())

	# Load and instantiate the scene.
	var packed = load("res://scenes/gameplay/SettingsScreen.tscn")
	if packed == null:
		print("  FAIL: SettingsScreen.tscn not found")
		_fail_count += 1
		_finish()
		return

	var screen: Control = packed.instantiate() as Control
	root.add_child(screen)

	_check_node(screen, "Layout/VBox/BackButton", "BackButton path")
	_check_node(screen, "Layout/VBox/LatencySection/LatencyRow/LatencySlider", "LatencySlider path")
	_check_node(screen, "Layout/VBox/LatencySection/LatencyRow/LatencyValueLabel", "LatencyValueLabel path")
	_check_node(screen, "Layout/VBox/VolumesSection/MasterRow/MasterSlider", "MasterSlider path")
	_check_node(screen, "Layout/VBox/VolumesSection/MusicRow/MusicSlider", "MusicSlider path")
	_check_node(screen, "Layout/VBox/VolumesSection/SfxRow/SfxSlider", "SfxSlider path")
	_check_node(screen, "Layout/VBox/WideBeatSection/WideTimingToggle", "WideTimingToggle path")
	_check_node(screen, "Layout/VBox/MotionSection/ReducedMotionToggle", "ReducedMotionToggle path")
	_check_node(screen, "Layout/VBox/ColorblindSection/ColorblindToggle", "ColorblindToggle path")
	_check_node(screen, "Layout/VBox/TextScaleSection/TextScaleButtons/Scale80Button", "Scale80Button path")
	_check_node(screen, "Layout/VBox/TextScaleSection/TextScaleButtons/Scale100Button", "Scale100Button path")
	_check_node(screen, "Layout/VBox/TextScaleSection/TextScaleButtons/Scale120Button", "Scale120Button path")

	# Verify text scale round-trip.
	accessibility.set_text_scale(1.2)
	var stored: float = accessibility.text_scale()
	if absf(stored - 1.2) < 0.001:
		_ok("text_scale round-trip stores 1.2")
	else:
		_fail("text_scale round-trip", "expected 1.2, got %f" % stored)

	accessibility.set_text_scale(1.0)  # restore

	screen.queue_free()
	_finish()


func _check_node(screen: Control, path: String, label: String) -> void:
	if screen.has_node(path):
		_ok(label)
	else:
		_fail(label, "node '%s' not found in scene" % path)


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


func _finish() -> void:
	print("Settings scene tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("SETTINGS_SCENE_OK")
	quit()
