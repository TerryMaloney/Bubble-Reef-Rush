## GhostLibrary — autoload that persists and retrieves ghost run data.
## Stores ghosts at user://profiles/<profile_id>/ghosts/<level_id>_<type>.json
## Types: "personal_best", "family_champion", "imported"
extends Node

## Score of the ghost loaded for the current run; -1 if no ghost was shown.
## Set by LevelRoot when spawning a GhostPlayer; read by ResultsScreen.
var last_ghost_score: int = -1


func _ghost_path(profile_id: String, level_id: String, ghost_type: String) -> String:
	var safe_level: String = level_id.replace("/", "_").replace("\\", "_")
	return "user://profiles/%s/ghosts/%s_%s.json" % [profile_id, safe_level, ghost_type]


func save_ghost(profile_id: String, level_id: String, ghost_type: String, data: Dictionary) -> void:
	var dir_path: String = "user://profiles/%s/ghosts" % profile_id
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path: String = _ghost_path(profile_id, level_id, ghost_type)
	var tmp: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	DirAccess.rename_absolute(tmp, path)
	EventBus.ghost_saved.emit(level_id, ghost_type)


func load_ghost(profile_id: String, level_id: String, ghost_type: String) -> Dictionary:
	var path: String = _ghost_path(profile_id, level_id, ghost_type)
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return {}
	var result: Variant = json.data
	if result is Dictionary:
		return result as Dictionary
	return {}


func list_ghosts(profile_id: String, level_id: String) -> Array[String]:
	var types: Array[String] = ["personal_best", "family_champion", "imported"]
	var found: Array[String] = []
	for t: String in types:
		if FileAccess.file_exists(_ghost_path(profile_id, level_id, t)):
			found.append(t)
	return found


func get_family_champion(level_id: String) -> Dictionary:
	var profiles: Array[String] = SaveSystem.list_profiles()
	var best_score: int = -1
	var best_data: Dictionary = {}
	for pid: String in profiles:
		var data: Dictionary = load_ghost(pid, level_id, "personal_best")
		if data.is_empty():
			continue
		var score: int = int(data.get("final_score", -1))
		if score > best_score:
			best_score = score
			best_data = data
	return best_data
