# Autoload node that manages local family profiles and per-profile level progress persistence.
extends Node


const PROFILE_INDEX_PATH: String = "user://profiles/index.cfg"
const LEVELS_DIR_TEMPLATE: String = "user://profiles/%s/levels/"


func _ready() -> void:
	ensure_profile(get_active_profile_id())


func ensure_profile(profile_id: String) -> void:
	var profile_dir: String = "user://profiles/%s/" % profile_id
	var levels_dir: String = LEVELS_DIR_TEMPLATE % profile_id
	var progress_path: String = profile_dir + "progress.json"

	if not DirAccess.dir_exists_absolute(profile_dir):
		DirAccess.make_dir_recursive_absolute(profile_dir)

	if not DirAccess.dir_exists_absolute(levels_dir):
		DirAccess.make_dir_recursive_absolute(levels_dir)

	if not FileAccess.file_exists(progress_path):
		var initial_progress: Dictionary = {
			"version": 1,
			"profile_id": profile_id,
			"total_stars": 0,
			"coins": 0,
			"levels": {},
			"characters": {"default_fish": true},
			"settings": {"timing_offset_ms": 0.0}
		}
		_write_json(progress_path, initial_progress)

	# Ensure this profile is registered in the index.
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PROFILE_INDEX_PATH)
	var profiles: Array = cfg.get_value("profiles", "list", [])
	if not (profile_id in profiles):
		profiles.append(profile_id)
		cfg.set_value("profiles", "list", profiles)
		cfg.save(PROFILE_INDEX_PATH)


func get_active_profile_id() -> String:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(PROFILE_INDEX_PATH)
	if err != OK:
		return "player1"
	var profile_id: String = cfg.get_value("active", "profile_id", "player1")
	if profile_id == "":
		return "player1"
	return profile_id


func set_active_profile(profile_id: String) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PROFILE_INDEX_PATH)
	cfg.set_value("active", "profile_id", profile_id)
	cfg.save(PROFILE_INDEX_PATH)
	EventBus.active_profile_changed.emit(profile_id)


func list_profiles() -> Array[String]:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(PROFILE_INDEX_PATH)
	if err != OK:
		return []
	var raw: Array = cfg.get_value("profiles", "list", [])
	var result: Array[String] = []
	for entry: Variant in raw:
		result.append(str(entry))
	return result


func load_progress(profile_id: String) -> Dictionary:
	var progress_path: String = "user://profiles/%s/progress.json" % profile_id
	if not FileAccess.file_exists(progress_path):
		return {}
	var file: FileAccess = FileAccess.open(progress_path, FileAccess.READ)
	if file == null:
		push_warning("SaveSystem: Could not open progress file for profile '%s'." % profile_id)
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_warning("SaveSystem: Failed to parse progress JSON for profile '%s'." % profile_id)
		return {}
	return parsed as Dictionary


func save_progress(profile_id: String, data: Dictionary) -> void:
	var progress_path: String = "user://profiles/%s/progress.json" % profile_id
	_write_json(progress_path, data)


func update_level_result(profile_id: String, level_id: String, score: int, stars: int) -> void:
	var data: Dictionary = load_progress(profile_id)
	if data.is_empty():
		ensure_profile(profile_id)
		data = load_progress(profile_id)

	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var existing: Dictionary = levels.get(level_id, {}) as Dictionary
	var existing_score: int = existing.get("best_score", 0) as int

	if score > existing_score:
		existing["best_score"] = score
		existing["best_stars"] = stars
		levels[level_id] = existing
		data["levels"] = levels
		# Recalculate total_stars across all level records.
		var total: int = 0
		for entry: Variant in levels.values():
			total += int((entry as Dictionary).get("best_stars", 0))
		data["total_stars"] = total
		save_progress(profile_id, data)


func _write_json(path: String, payload: Dictionary) -> void:
	var tmp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: Cannot open '%s' for writing." % tmp_path)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	# Atomic rename: remove destination then rename tmp into place.
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	DirAccess.rename_absolute(tmp_path, path)
