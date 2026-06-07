## Smoke test runner. Execute with: godot --headless --script tests/smoke/run_smoke_tests.gd
extends SceneTree

func _init() -> void:
	await process_frame

	# Check autoloads are present
	assert(root.has_node("GameManager"), "GameManager autoload missing")
	assert(root.has_node("EventBus"), "EventBus autoload missing")
	assert(root.has_node("SaveSystem"), "SaveSystem autoload missing")
	assert(root.has_node("BeatConductor"), "BeatConductor autoload missing")

	# Check level file loads
	var level_path := "res://assets/levels/z1-l1.brl"
	assert(FileAccess.file_exists(level_path), "z1-l1.brl level file missing")

	var file := FileAccess.open(level_path, FileAccess.READ)
	assert(file != null, "Cannot open z1-l1.brl")
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	assert(err == OK, "z1-l1.brl is not valid JSON")

	var data: Variant = json.get_data()
	assert(data is Dictionary, "z1-l1.brl root must be object")
	assert((data as Dictionary).has("metadata"), "z1-l1.brl missing metadata")
	assert((data as Dictionary).has("beat_map"), "z1-l1.brl missing beat_map")

	# SaveSystem basic check
	var save_sys = root.get_node("SaveSystem")
	var profile_id: String = save_sys.get_active_profile_id()
	assert(not profile_id.is_empty(), "SaveSystem returned empty profile id")

	print("SMOKE_OK")
	quit(0)
