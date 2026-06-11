## BuildSession.gd
## RefCounted data model for a single in-progress Build Mode level.
## Wraps the schema-1.1 Dictionary and tracks dirty + played_through state.
## Any mutation that changes beat_map or metadata clears played_through so the
## creator must re-test before finalizing (GDD §6.5).
class_name BuildSession
extends RefCounted

var dirty: bool = false
var played_through: bool = false

var _data: Dictionary = {}


## Create a brand-new level using sane defaults.
func create_new(author: String = "player", zone: int = 1) -> void:
	_data = {
		"schema_version": "1.1",
		"metadata": {
			"id": _generate_uuid(),
			"name": "My Level",
			"zone": zone,
			"bpm": 120.0,
			"bpm_variable": false,
			"difficulty": 1,
			"author": author,
			"created_at": Time.get_datetime_string_from_system(),
			"is_official": false,
			"total_beats": 16
		},
		"music": {
			"filename": "zone_%d_theme.wav" % zone,
			"loop": true,
			"loop_start_beat": 0,
			"preview_start_beat": 0,
			"preview_duration_beats": 8,
			"beat_offset_ms": 0.0,
			"volume_db": 0.0
		},
		"beat_map": [],
		"speed_zones": [],
		"background": {
			"asset_key": "bg_zone_%d" % zone,
			"parallax_layers": [],
			"color_override": "",
			"shader_key": "",
			"particle_key": ""
		},
		"unlock_requirements": {
			"required_zone_clear": null,
			"required_level_id": null,
			"min_total_stars": 0
		},
		"par_score": {
			"one_star": 100,
			"two_star": 500,
			"three_star": 1000,
			"max_possible": 1500
		}
	}
	dirty = true
	played_through = false


## Load from an existing Dictionary (e.g. loaded from disk).
## Clears dirty so the session starts clean after a load.
func load_from_dict(d: Dictionary) -> void:
	_data = d.duplicate(true)
	dirty = false
	played_through = false


## Returns the full schema-1.1 Dictionary.
func get_data() -> Dictionary:
	return _data


## Read a top-level metadata field.
func get_metadata(key: String, default: Variant = null) -> Variant:
	return (_data.get("metadata", {}) as Dictionary).get(key, default)


## Write a top-level metadata field.  Any edit clears played_through.
func set_metadata(key: String, value: Variant) -> void:
	(_data["metadata"] as Dictionary)[key] = value
	dirty = true
	played_through = false


## Append an entry to beat_map.  Any edit clears played_through.
func add_beat_entry(entry: Dictionary) -> void:
	(_data["beat_map"] as Array).append(entry)
	dirty = true
	played_through = false


## Remove the beat_map entry at the given index.
func remove_beat_entry(index: int) -> void:
	(_data["beat_map"] as Array).remove_at(index)
	dirty = true
	played_through = false


## Replace the beat_map entry at index with an updated version.
func update_beat_entry(index: int, entry: Dictionary) -> void:
	(_data["beat_map"] as Array)[index] = entry
	dirty = true
	played_through = false


## Called by BuildModeRoot when the creator completes a test-play.
func mark_played_through() -> void:
	played_through = true


## Called by BrlSerializer after a successful save.
func mark_saved() -> void:
	dirty = false


## How many beats are in the beat_map (useful for UI).
func beat_count() -> int:
	return (_data.get("beat_map", []) as Array).size()


# ── Level Tennis ──────────────────────────────────────────────────────────────

## When true, beats owned by other profiles are read-only.
var lock_previous_sections: bool = false

var _sections: Array = []  # Array of {start_beat, end_beat, owner}


func add_tennis_section(owner: String, start_beat: int, beats: int) -> void:
	_sections.append({
		"start_beat": start_beat,
		"end_beat": start_beat + beats,
		"owner": owner,
	})
	dirty = true
	played_through = false


## Returns the owner string for the section containing beat, or "" if none.
func get_section_owner(beat: float) -> String:
	for s: Variant in _sections:
		var sd: Dictionary = s as Dictionary
		if float(sd.get("start_beat", 0)) <= beat and beat < float(sd.get("end_beat", 0)):
			return str(sd.get("owner", ""))
	return ""


## Returns true when lock_previous_sections is on and beat belongs to a different owner.
func is_beat_locked_for(owner: String, beat: float) -> bool:
	if not lock_previous_sections:
		return false
	var beat_owner: String = get_section_owner(beat)
	if beat_owner.is_empty():
		return false
	return beat_owner != owner


func get_tennis_sections() -> Array:
	return _sections.duplicate()


## Returns unique contributor profile IDs, in order of first appearance.
func get_contributors() -> Array[String]:
	var seen: Array[String] = []
	for s: Variant in _sections:
		var o: String = str((s as Dictionary).get("owner", ""))
		if not o.is_empty() and not seen.has(o):
			seen.append(o)
	return seen


## Generate a UUID v4 for player-created level IDs.
static func _generate_uuid() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var b := PackedByteArray()
	b.resize(16)
	for i: int in range(16):
		b[i] = rng.randi_range(0, 255)
	# Version 4 and variant bits per RFC 4122.
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	var h: String = b.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		h.substr(0, 8),
		h.substr(8, 4),
		h.substr(12, 4),
		h.substr(16, 4),
		h.substr(20, 12)
	]
