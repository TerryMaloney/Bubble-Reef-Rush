## theme_test.gd — verifies the global UI theme resource exists, is registered
## as the project theme, and carries the kid-readable font/style baseline.
##
## Run with:
##   godot --headless --path . --script tests/integration/theme_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	_test_theme_resource()
	_test_project_setting()
	print("Theme tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("THEME_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


func _test_theme_resource() -> void:
	var theme: Theme = load("res://assets/theme/theme.tres") as Theme
	if theme == null:
		_fail("theme_resource", "theme.tres failed to load as Theme")
		return
	if theme.default_font_size != 30:
		_fail("theme_resource", "default_font_size is %d, expected 30" % theme.default_font_size)
		return
	if theme.get_font_size("font_size", "Button") != 34:
		_fail("theme_resource", "Button font_size is %d, expected 34" % theme.get_font_size("font_size", "Button"))
		return
	var normal: StyleBoxFlat = theme.get_stylebox("normal", "Button") as StyleBoxFlat
	if normal == null:
		_fail("theme_resource", "Button normal stylebox is not StyleBoxFlat")
		return
	if normal.corner_radius_top_left != 12:
		_fail("theme_resource", "Button corner radius is %d, expected 12" % normal.corner_radius_top_left)
		return
	if not normal.bg_color.is_equal_approx(Color(0.102, 0.29, 0.431, 1.0)):
		_fail("theme_resource", "Button normal bg_color is %s" % str(normal.bg_color))
		return
	var panel: StyleBoxFlat = theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	if panel == null:
		_fail("theme_resource", "PanelContainer panel stylebox is not StyleBoxFlat")
		return
	_ok("theme_resource")


func _test_project_setting() -> void:
	var custom: String = str(ProjectSettings.get_setting("gui/theme/custom", ""))
	if custom != "res://assets/theme/theme.tres":
		_fail("project_setting", "gui/theme/custom is '%s'" % custom)
		return
	_ok("project_setting")
