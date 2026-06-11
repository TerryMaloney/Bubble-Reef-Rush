## reef_radio_test.gd — Phase 25 contracts for Reef Radio architecture.
##
## Tests:
##   1. worlds_json_parses     — worlds.json loads and has exactly 2 stations.
##   2. ocean_station_unlocked — ocean station is unlocked by default.
##   3. space_station_locked   — space_bubble station requires radio key.
##   4. space_station_unlocks  — add_radio_key(space_key) makes space_bubble available.
##   5. party_modes_count      — PartyHubScreen.get_modes() returns 5 party modes.
##
## Run with:
##   godot --headless --path . --script tests/integration/reef_radio_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_worlds_json_parses(root)
	_test_ocean_station_unlocked(root)
	_test_space_station_locked(root)
	_test_space_station_unlocks(root)
	_test_party_modes_count(root)

	print("Reef Radio tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("REEF_RADIO_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


func _load_worlds() -> Array:
	var file: FileAccess = FileAccess.open("res://assets/data/worlds.json", FileAccess.READ)
	if file == null:
		return []
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return []
	var data: Variant = json.data
	if not (data is Dictionary):
		return []
	return (data as Dictionary).get("stations", []) as Array


## 1. worlds_json_parses
func _test_worlds_json_parses(_root: Node) -> void:
	var stations: Array = _load_worlds()
	if stations.size() == 2:
		_ok("worlds_json_parses")
	else:
		_fail("worlds_json_parses", "expected 2 stations, got %d" % stations.size())


## 2. ocean_station_unlocked
func _test_ocean_station_unlocked(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid: String = "rr_ocean_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	var stations: Array = _load_worlds()
	var ocean_dict: Dictionary = {}
	for s: Variant in stations:
		if str((s as Dictionary).get("id", "")) == "ocean":
			ocean_dict = s as Dictionary
			break

	if ocean_dict.is_empty():
		_fail("ocean_station_unlocked", "ocean station not found in worlds.json")
		return

	var ws = load("res://src/core/WorldStation.gd").new()
	ws.from_dict(ocean_dict)
	if ws.is_unlocked_for(pid):
		_ok("ocean_station_unlocked")
	else:
		_fail("ocean_station_unlocked", "ocean should be unlocked by default")


## 3. space_station_locked
func _test_space_station_locked(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid: String = "rr_space_lock_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	var stations: Array = _load_worlds()
	var space_dict: Dictionary = {}
	for s: Variant in stations:
		if str((s as Dictionary).get("id", "")) == "space_bubble":
			space_dict = s as Dictionary
			break

	if space_dict.is_empty():
		_fail("space_station_locked", "space_bubble station not found in worlds.json")
		return

	var ws = load("res://src/core/WorldStation.gd").new()
	ws.from_dict(space_dict)
	if not ws.is_unlocked_for(pid):
		_ok("space_station_locked")
	else:
		_fail("space_station_locked", "space_bubble should be locked without radio key")


## 4. space_station_unlocks
func _test_space_station_unlocks(root: Node) -> void:
	var ss: Node = root.get_node("SaveSystem")
	var pid: String = "rr_space_unlock_%d" % Time.get_ticks_msec()
	ss.ensure_profile(pid)

	ss.add_radio_key(pid, "space_key")

	var stations: Array = _load_worlds()
	var space_dict: Dictionary = {}
	for s: Variant in stations:
		if str((s as Dictionary).get("id", "")) == "space_bubble":
			space_dict = s as Dictionary
			break

	var ws = load("res://src/core/WorldStation.gd").new()
	ws.from_dict(space_dict)
	if ws.is_unlocked_for(pid):
		_ok("space_station_unlocks")
	else:
		_fail("space_station_unlocks", "space_bubble should unlock after adding space_key")


## 5. party_modes_count
func _test_party_modes_count(_root: Node) -> void:
	var hub = load("res://src/ui/PartyHubScreen.gd").new()
	var modes: Array[Dictionary] = hub.get_modes()
	if modes.size() == 5:
		_ok("party_modes_count")
	else:
		_fail("party_modes_count", "expected 5 modes, got %d" % modes.size())
