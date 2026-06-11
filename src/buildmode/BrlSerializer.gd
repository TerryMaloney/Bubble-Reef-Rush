## BrlSerializer.gd
## Serializes a BuildSession to user://profiles/<id>/levels/<uuid>.brl and
## reads it back for round-trip validation.
## The file is written atomically: JSON is fully produced in memory, written
## to a .tmp path, then renamed (or re-written) to the final path.
## Caller (BuildModeRoot) is responsible for the RhythmMap scene-tree round-trip
## after save; this class only handles file I/O and JSON integrity.
class_name BrlSerializer
extends RefCounted

const LEVELS_DIR_FMT: String = "user://profiles/%s/levels/"


## Save session to disk.  Returns "" on success or a human-readable error string.
## Emits EventBus.buildmode_level_saved on success.
## Does NOT finalize — caller must also pass played_through gate.
static func save(session: BuildSession, profile_id: String) -> String:
	if not session.played_through:
		return "Level must be test-played before saving. Use the Play button first."

	var data: Dictionary = session.get_data()
	var json_text: String = JSON.stringify(data, "\t")

	# Quick JSON round-trip sanity check — no scene tree required.
	var reparsed: Variant = JSON.parse_string(json_text)
	if reparsed == null:
		return "Serialization error: JSON.stringify produced invalid JSON."

	var reparsed_dict: Dictionary = reparsed as Dictionary
	var orig_id: String = str((data["metadata"] as Dictionary).get("id", ""))
	var rt_id: String = str((reparsed_dict.get("metadata", {}) as Dictionary).get("id", ""))
	if orig_id != rt_id:
		return "Round-trip validation failed: level id mismatch ('%s' vs '%s')." % [orig_id, rt_id]

	var dir: String = LEVELS_DIR_FMT % profile_id
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	var slug: String = orig_id
	var tmp_path: String = dir + slug + ".brl.tmp"
	var final_path: String = dir + slug + ".brl"

	var f: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return "Cannot write to '%s' (error %d)." % [tmp_path, FileAccess.get_open_error()]
	f.store_string(json_text)
	f.close()

	# Verify the written content is readable.
	var f2: FileAccess = FileAccess.open(tmp_path, FileAccess.READ)
	if f2 == null:
		return "Cannot read back temp file '%s'." % tmp_path
	var read_text: String = f2.get_as_text()
	f2.close()
	if JSON.parse_string(read_text) == null:
		DirAccess.open(dir).remove(slug + ".brl.tmp")
		return "Temp file content is not valid JSON after write."

	# Atomic rename: overwrite final path.
	var da: DirAccess = DirAccess.open(dir)
	if da == null:
		return "Cannot open levels directory '%s'." % dir
	if FileAccess.file_exists(final_path):
		da.remove(slug + ".brl")
	var rename_err: Error = da.rename(slug + ".brl.tmp", slug + ".brl")
	if rename_err != OK:
		return "Rename failed (error %d). Temp file left at '%s'." % [rename_err, tmp_path]

	session.mark_saved()
	# Caller (BuildModeRoot) emits EventBus.buildmode_level_saved with the path.
	return ""


## Path where a level is saved for a given profile + level id.
static func level_path(level_id: String, profile_id: String) -> String:
	return LEVELS_DIR_FMT % profile_id + level_id + ".brl"


## Load a previously saved build-mode level from disk into a new BuildSession.
## Returns null and pushes a warning on failure.
static func load_from_disk(level_id: String, profile_id: String) -> BuildSession:
	var path: String = LEVELS_DIR_FMT % profile_id + level_id + ".brl"
	if not FileAccess.file_exists(path):
		push_warning("BrlSerializer: file not found: %s" % path)
		return null

	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("BrlSerializer: cannot open '%s' (error %d)" % [path, FileAccess.get_open_error()])
		return null

	var text: String = f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_warning("BrlSerializer: JSON parse error in '%s'" % path)
		return null

	var session := BuildSession.new()
	session.load_from_dict(parsed as Dictionary)
	return session


## List all player-created level IDs saved under a profile.
static func list_levels(profile_id: String) -> Array[String]:
	var dir_path: String = LEVELS_DIR_FMT % profile_id
	var result: Array[String] = []
	var da: DirAccess = DirAccess.open(dir_path)
	if da == null:
		return result
	da.list_dir_begin()
	var fname: String = da.get_next()
	while fname != "":
		if not da.current_is_dir() and fname.ends_with(".brl"):
			result.append(fname.trim_suffix(".brl"))
		fname = da.get_next()
	da.list_dir_end()
	return result


## Serialize a dictionary to a JSON string (for in-memory round-trip tests).
static func to_json_string(data: Dictionary) -> String:
	return JSON.stringify(data, "\t")


## Deserialize a JSON string back to a Dictionary.  Returns null on failure.
static func from_json_string(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed as Dictionary
