## GhostLibrary — autoload that persists and retrieves ghost run data.
##
## Ghost files live at:  user://profiles/<profile_id>/ghosts/<level_id>_<type>.json
## Ghost types:
##   "personal_best"   — best score for the active profile
##   "family_champion" — best score across all profiles (computed by get_family_champion)
##   "imported"        — from a Challenge Capsule (Phase 17)
##
## Ghost data schema (produced by GhostRecorder.get_ghost_data()):
##   {schema_ver: 1, level_id, game_version, final_score, inputs: [{beat, event}]}
##
## Emits EventBus.ghost_saved(level_id, ghost_type) on every successful save.
extends Node

const GHOST_SUBDIR: String = "ghosts"


## Save ghost_data for a profile. Overwrites existing ghost of the same type.
func save_ghost(profile_id: String, level_id: String, ghost_type: String, ghost_data: Dictionary) -> void:
	var dir_path: String = _ghost_dir(profile_id)
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path: String = _ghost_path(profile_id, level_id, ghost_type)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("GhostLibrary: cannot write to '%s' (err %d)" % [path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(ghost_data))
	file.close()
	EventBus.ghost_saved.emit(level_id, ghost_type)


## Load and return ghost data. Returns empty dict if no ghost exists or on parse error.
func load_ghost(profile_id: String, level_id: String, ghost_type: String) -> Dictionary:
	var path: String = _ghost_path(profile_id, level_id, ghost_type)
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


## Return all ghost types available for a level in a given profile.
func list_ghosts(profile_id: String, level_id: String) -> Array[String]:
	var result: Array[String] = []
	var dir_path: String = _ghost_dir(profile_id)
	if not DirAccess.dir_exists_absolute(dir_path):
		return result
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return result
	var prefix: String = _safe_id(level_id) + "_"
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.begins_with(prefix) and fname.ends_with(".json"):
			var ghost_type: String = fname.substr(prefix.length(), fname.length() - prefix.length() - 5)
			result.append(ghost_type)
		fname = dir.get_next()
	dir.list_dir_end()
	return result


## Scan all profiles and return the ghost data with the highest final_score
## for this level. Returns empty dict if no ghosts found for this level.
func get_family_champion(level_id: String) -> Dictionary:
	var best_data: Dictionary = {}
	var best_score: int = -1
	var profiles_dir: String = "user://profiles"
	if not DirAccess.dir_exists_absolute(profiles_dir):
		return {}
	var dir: DirAccess = DirAccess.open(profiles_dir)
	if dir == null:
		return {}
	dir.list_dir_begin()
	var profile_id: String = dir.get_next()
	while profile_id != "":
		if dir.current_is_dir() and not profile_id.begins_with("."):
			var ghost: Dictionary = load_ghost(profile_id, level_id, "personal_best")
			if not ghost.is_empty():
				var score: int = int(ghost.get("final_score", 0))
				if score > best_score:
					best_score = score
					best_data = ghost.duplicate()
		profile_id = dir.get_next()
	dir.list_dir_end()
	return best_data


# ── Private helpers ────────────────────────────────────────────────────────────

func _ghost_dir(profile_id: String) -> String:
	return "user://profiles/%s/%s" % [profile_id, GHOST_SUBDIR]


func _ghost_path(profile_id: String, level_id: String, ghost_type: String) -> String:
	return "%s/%s_%s.json" % [_ghost_dir(profile_id), _safe_id(level_id), ghost_type]


## Replace filesystem-unsafe characters (e.g. "/") with underscores.
func _safe_id(level_id: String) -> String:
	return level_id.replace("/", "_").replace(":", "_")
