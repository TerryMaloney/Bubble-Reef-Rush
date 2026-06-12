## collection_room_scene_test.gd — verifies CollectionRoomScreen.tscn instantiates
## without SCRIPT ERROR (the escaped-space node path crash was the regression target).
##
## Run with:
##   godot --headless --path . --script tests/integration/collection_room_scene_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	_test_scene_instantiates()
	_test_boss_trophies_path()
	print("Collection room scene tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("COLLECTION_ROOM_SCENE_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. scene_instantiates — load + add to tree triggers _ready()/_populate_ui() without crash.
func _test_scene_instantiates() -> void:
	var packed: PackedScene = load("res://scenes/ui/CollectionRoomScreen.tscn") as PackedScene
	if packed == null:
		_fail("scene_instantiates", "PackedScene failed to load")
		return
	var screen: Control = packed.instantiate() as Control
	if screen == null:
		_fail("scene_instantiates", "instantiate() returned null")
		return
	get_root().add_child(screen)
	_ok("scene_instantiates")
	screen.queue_free()


## 2. boss_trophies_path — the space-in-name node is reachable via get_node().
func _test_boss_trophies_path() -> void:
	var packed: PackedScene = load("res://scenes/ui/CollectionRoomScreen.tscn") as PackedScene
	var screen: Control = packed.instantiate() as Control
	get_root().add_child(screen)
	if not screen.has_node("TabContainer/Boss Trophies/TrophyGrid"):
		_fail("boss_trophies_path", "TrophyGrid not found — node path is broken")
		screen.queue_free()
		return
	_ok("boss_trophies_path")
	screen.queue_free()
