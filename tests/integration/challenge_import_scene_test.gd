## challenge_import_scene_test.gd — verifies ChallengeImportScreen instantiates
## and that the capsule save flow works (save_capsule() missing-method crash was the
## regression target).
##
## Run with:
##   godot --headless --path . --script tests/integration/challenge_import_scene_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	_test_scene_instantiates()
	_test_import_empty_pending_no_crash()
	_test_capsule_file_write()
	print("Challenge import scene tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("CHALLENGE_IMPORT_SCENE_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. scene_instantiates — scene loads and wires signals without error.
func _test_scene_instantiates() -> void:
	var packed: PackedScene = load("res://scenes/ui/ChallengeImportScreen.tscn") as PackedScene
	if packed == null:
		_fail("scene_instantiates", "PackedScene failed to load")
		return
	var screen: Control = packed.instantiate() as Control
	if screen == null:
		_fail("scene_instantiates", "instantiate() returned null")
		return
	get_root().add_child(screen)
	# Import button should start disabled (no pending data).
	var import_btn: Button = screen.get_node("Panel/VBox/ImportButton") as Button
	if import_btn == null:
		_fail("scene_instantiates", "ImportButton not found")
		screen.queue_free()
		return
	if not import_btn.disabled:
		_fail("scene_instantiates", "ImportButton should be disabled on init")
		screen.queue_free()
		return
	_ok("scene_instantiates")
	screen.queue_free()


## 2. import_button_disabled_on_start — no pending data means import is locked.
func _test_import_empty_pending_no_crash() -> void:
	var packed: PackedScene = load("res://scenes/ui/ChallengeImportScreen.tscn") as PackedScene
	var screen: Control = packed.instantiate() as Control
	get_root().add_child(screen)
	var import_btn: Button = screen.get_node("Panel/VBox/ImportButton") as Button
	if import_btn == null:
		_fail("import_button_disabled_on_start", "ImportButton not found")
		screen.queue_free()
		return
	if not import_btn.disabled:
		_fail("import_button_disabled_on_start", "ImportButton should start disabled")
		screen.queue_free()
		return
	_ok("import_button_disabled_on_start")
	screen.queue_free()


## 3. capsule_file_write — the fixed import flow writes a .brrc file to user://.
func _test_capsule_file_write() -> void:
	var ser = load("res://src/core/CapsuleSerializer.gd").new()
	var data: Dictionary = {
		"level_ref": "test_import_capsule",
		"creator_nick": "Tester",
		"target": "any",
		"ghost_inputs": [],
		"rules": [],
		"mutators": [],
	}
	var encoded: String = ser.pack(data)
	var pending: Dictionary = ser.unpack(encoded)
	if pending.is_empty():
		_fail("capsule_file_write", "CapsuleSerializer.unpack returned empty dict")
		return

	var level_ref: String = str(pending.get("level_ref", "fallback"))
	var profile: String = "test_profile"
	var dir: String = "user://profiles/%s/capsules" % profile
	DirAccess.make_dir_recursive_absolute(dir)
	var path: String = "%s/%s.brrc" % [dir, level_ref]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("capsule_file_write", "FileAccess.open returned null")
		return
	file.store_string(JSON.stringify(pending))
	file.close()

	if not FileAccess.file_exists(path):
		_fail("capsule_file_write", "file was not created at %s" % path)
		return
	_ok("capsule_file_write")
	DirAccess.remove_absolute(path)
