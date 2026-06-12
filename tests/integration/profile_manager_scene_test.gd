## profile_manager_scene_test.gd — verifies the ProfileManagerScreen delete flow,
## SaveSystem.delete_profile guards, and that overlay screens fully dim the
## scene behind them (Background ColorRect present).
##
## Run with:
##   godot --headless --path . --script tests/integration/profile_manager_scene_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	await process_frame
	await _test_scene_has_delete_buttons()
	_test_delete_profile_roundtrip()
	_test_delete_last_profile_guarded()
	_test_overlay_backgrounds()
	print("Profile manager scene tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("PROFILE_MANAGER_SCENE_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


func _save_system() -> Node:
	return root.get_node("SaveSystem")


## 1. Scene instantiates and every profile row carries a delete button.
func _test_scene_has_delete_buttons() -> void:
	_save_system().ensure_profile("player1")
	var packed: PackedScene = load("res://scenes/ui/ProfileManagerScreen.tscn") as PackedScene
	if packed == null:
		_fail("scene_has_delete_buttons", "PackedScene failed to load")
		return
	var screen: Control = packed.instantiate() as Control
	root.add_child(screen)
	await process_frame
	var rows: Array[Node] = screen.get_node("Panel/VBox/ProfileList").get_children()
	if rows.is_empty():
		_fail("scene_has_delete_buttons", "no profile rows rendered")
		screen.queue_free()
		return
	for row: Node in rows:
		var buttons: int = 0
		for child: Node in row.get_children():
			if child is Button:
				buttons += 1
		if buttons < 2:
			_fail("scene_has_delete_buttons", "row '%s' has %d buttons, expected Play-as + delete" % [row.name, buttons])
			screen.queue_free()
			return
	_ok("scene_has_delete_buttons")
	screen.queue_free()


## 2. delete_profile removes the profile from the index and wipes its directory.
func _test_delete_profile_roundtrip() -> void:
	var save: Node = _save_system()
	save.ensure_profile("test_del_a")
	save.ensure_profile("test_del_b")
	if not bool(save.delete_profile("test_del_b")):
		_fail("delete_profile_roundtrip", "delete_profile returned false")
		return
	if "test_del_b" in save.list_profiles():
		_fail("delete_profile_roundtrip", "profile still listed after delete")
		return
	if DirAccess.dir_exists_absolute("user://profiles/test_del_b/"):
		_fail("delete_profile_roundtrip", "profile directory still exists after delete")
		return
	if bool(save.delete_profile("test_del_b")):
		_fail("delete_profile_roundtrip", "deleting an unknown profile should return false")
		return
	_ok("delete_profile_roundtrip")
	save.delete_profile("test_del_a")


## 3. The last remaining profile cannot be deleted.
func _test_delete_last_profile_guarded() -> void:
	var save: Node = _save_system()
	# Temporarily shrink the index to a single profile, then restore it.
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load("user://profiles/index.cfg")
	var original: Array = cfg.get_value("profiles", "list", [])
	var original_active: String = str(cfg.get_value("active", "profile_id", "player1"))
	cfg.set_value("profiles", "list", ["only_one"])
	cfg.save("user://profiles/index.cfg")

	var blocked: bool = not bool(save.delete_profile("only_one"))

	cfg.set_value("profiles", "list", original)
	cfg.set_value("active", "profile_id", original_active)
	cfg.save("user://profiles/index.cfg")

	if not blocked:
		_fail("delete_last_profile_guarded", "delete_profile deleted the last profile")
		return
	_ok("delete_last_profile_guarded")


## 4. Overlay screens dim the scene behind them with a full-anchor Background.
func _test_overlay_backgrounds() -> void:
	var scenes: Array[String] = [
		"res://scenes/ui/ReefRivalsScreen.tscn",
		"res://scenes/ui/PassPlaySetupScreen.tscn",
		"res://scenes/ui/ChallengeImportScreen.tscn",
		"res://scenes/ui/ChallengeExportScreen.tscn",
		"res://scenes/ui/ProfileManagerScreen.tscn",
	]
	for path: String in scenes:
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			_fail("overlay_backgrounds", "%s failed to load" % path)
			return
		var screen: Control = packed.instantiate() as Control
		var bg: ColorRect = screen.get_node_or_null("Background") as ColorRect
		if bg == null:
			_fail("overlay_backgrounds", "%s has no Background ColorRect" % path)
			screen.free()
			return
		if bg.anchor_right != 1.0 or bg.anchor_bottom != 1.0:
			_fail("overlay_backgrounds", "%s Background is not full-anchor" % path)
			screen.free()
			return
		screen.free()
	_ok("overlay_backgrounds")
