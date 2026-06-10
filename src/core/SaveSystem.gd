# Autoload node that manages local family profiles and per-profile level progress persistence.
extends Node

const SAVE_VERSION: int = 2

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
		_write_json(progress_path, _fresh_v2_profile(profile_id))

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


func _fresh_v2_profile(profile_id: String) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"profile_id": profile_id,
		"total_stars": 0,
		"coins": 0,
		"levels": {},
		"characters": {"default_fish": true},
		"cosmetics": {"owned": [], "equipped": {"trail": "", "ring": "", "palette": ""}},
		"achievements": {},
		"settings": {
			"timing_offset_ms": 0.0,
			"reduced_motion": false,
			"wide_timing_windows": false,
			"text_scale": 1.0,
			"colorblind_judgements": false,
			"volume_master": 1.0,
			"volume_music": 1.0,
			"volume_sfx": 1.0,
		}
	}


func _migrate(data: Dictionary) -> Dictionary:
	var ver: int = int(data.get("version", 1))
	if ver >= SAVE_VERSION:
		return data

	# Write a backup before migrating.
	var profile_id: String = str(data.get("profile_id", "player1"))
	var bak_path: String = "user://profiles/%s/progress.json.bak" % profile_id
	_write_json(bak_path, data)

	# v1 → v2: add economy, achievement, cosmetics, per-level new fields, new settings.
	var fresh: Dictionary = _fresh_v2_profile(profile_id)

	# Carry over existing fields.
	fresh["total_stars"] = int(data.get("total_stars", 0))
	fresh["coins"] = int(data.get("coins", 0))
	fresh["characters"] = data.get("characters", {"default_fish": true}) as Dictionary

	# Carry over settings, merging new keys over old.
	var old_settings: Dictionary = data.get("settings", {}) as Dictionary
	var new_settings: Dictionary = fresh["settings"] as Dictionary
	for k: String in old_settings.keys():
		new_settings[k] = old_settings[k]
	fresh["settings"] = new_settings

	# Carry over per-level data, adding new per-level fields where absent.
	var old_levels: Dictionary = data.get("levels", {}) as Dictionary
	var new_levels: Dictionary = {}
	for lid: String in old_levels.keys():
		var old_entry: Dictionary = old_levels[lid] as Dictionary
		var new_entry: Dictionary = {
			"best_score": int(old_entry.get("best_score", 0)),
			"best_stars": int(old_entry.get("best_stars", 0)),
			"attempts": int(old_entry.get("attempts", 1)),
			"best_progress_pct": float(old_entry.get("best_progress_pct", 100.0)),
			"treasure_coins": old_entry.get("treasure_coins", [false, false, false]) as Array,
			"practice_best_pct": float(old_entry.get("practice_best_pct", 0.0)),
		}
		new_levels[lid] = new_entry
	fresh["levels"] = new_levels
	fresh["version"] = SAVE_VERSION

	return fresh


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
	return _migrate(parsed as Dictionary)


func save_progress(profile_id: String, data: Dictionary) -> void:
	var progress_path: String = "user://profiles/%s/progress.json" % profile_id
	_write_json(progress_path, data)


func update_level_result(profile_id: String, level_id: String, score: int, stars: int) -> void:
	var data: Dictionary = load_progress(profile_id)
	if data.is_empty():
		ensure_profile(profile_id)
		data = load_progress(profile_id)

	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var existing: Dictionary = _ensure_level_entry(levels, level_id)
	var existing_score: int = int(existing.get("best_score", 0))

	if score > existing_score:
		existing["best_score"] = score
		existing["best_stars"] = stars
		existing["best_progress_pct"] = 100.0
	levels[level_id] = existing
	data["levels"] = levels
	# Recalculate total_stars across all level records.
	var total: int = 0
	for entry: Variant in levels.values():
		total += int((entry as Dictionary).get("best_stars", 0))
	data["total_stars"] = total
	save_progress(profile_id, data)


## Record that a run attempt started (called on run_failed or run_completed).
func record_attempt(profile_id: String, level_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if data.is_empty():
		ensure_profile(profile_id)
		data = load_progress(profile_id)
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var entry: Dictionary = _ensure_level_entry(levels, level_id)
	entry["attempts"] = int(entry.get("attempts", 0)) + 1
	levels[level_id] = entry
	data["levels"] = levels
	save_progress(profile_id, data)


## Record the furthest progress reached this run (0.0–100.0 percent of level).
func record_progress_pct(profile_id: String, level_id: String, pct: float) -> void:
	var data: Dictionary = load_progress(profile_id)
	if data.is_empty():
		ensure_profile(profile_id)
		data = load_progress(profile_id)
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var entry: Dictionary = _ensure_level_entry(levels, level_id)
	var best: float = float(entry.get("best_progress_pct", 0.0))
	if pct > best:
		entry["best_progress_pct"] = pct
		levels[level_id] = entry
		data["levels"] = levels
		save_progress(profile_id, data)


func get_best_stars(profile_id: String, level_id: String) -> int:
	var data: Dictionary = load_progress(profile_id)
	return int(((data.get("levels", {}) as Dictionary).get(level_id, {}) as Dictionary).get("best_stars", 0))


func get_best_progress_pct(profile_id: String, level_id: String) -> float:
	var data: Dictionary = load_progress(profile_id)
	return float(((data.get("levels", {}) as Dictionary).get(level_id, {}) as Dictionary).get("best_progress_pct", 0.0))


func get_attempts(profile_id: String, level_id: String) -> int:
	var data: Dictionary = load_progress(profile_id)
	return int(((data.get("levels", {}) as Dictionary).get(level_id, {}) as Dictionary).get("attempts", 0))


func get_total_stars(profile_id: String) -> int:
	var data: Dictionary = load_progress(profile_id)
	return int(data.get("total_stars", 0))


func is_level_cleared(profile_id: String, level_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	return (data.get("levels", {}) as Dictionary).has(level_id)


func get_all_level_results(profile_id: String) -> Dictionary:
	var data: Dictionary = load_progress(profile_id)
	return data.get("levels", {}) as Dictionary


func get_setting(profile_id: String, key: String, default: Variant) -> Variant:
	var data: Dictionary = load_progress(profile_id)
	return (data.get("settings", {}) as Dictionary).get(key, default)


func set_setting(profile_id: String, key: String, value: Variant) -> void:
	var data: Dictionary = load_progress(profile_id)
	if data.is_empty():
		ensure_profile(profile_id)
		data = load_progress(profile_id)
	var settings: Dictionary = data.get("settings", {}) as Dictionary
	settings[key] = value
	data["settings"] = settings
	save_progress(profile_id, data)


func _ensure_level_entry(levels: Dictionary, level_id: String) -> Dictionary:
	if levels.has(level_id):
		return levels[level_id] as Dictionary
	return {
		"best_score": 0,
		"best_stars": 0,
		"attempts": 0,
		"best_progress_pct": 0.0,
		"treasure_coins": [false, false, false],
		"practice_best_pct": 0.0,
	}


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
