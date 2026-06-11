## Accessibility.gd
## Autoload singleton. Single read point for all accessibility and settings values,
## backed by SaveSystem so callers don't need to know the save schema.
##
## Also owns volume application so any code that changes a setting can call
## apply_volumes() and the AudioServer state stays in sync.
extends Node


func _ready() -> void:
	apply_volumes()


# ---------------------------------------------------------------------------
# Setting readers
# ---------------------------------------------------------------------------

func timing_offset_ms() -> float:
	return float(SaveSystem.get_setting(SaveSystem.get_active_profile_id(), "timing_offset_ms", 0.0))


func wide_timing_windows() -> bool:
	return bool(SaveSystem.get_setting(SaveSystem.get_active_profile_id(), "wide_timing_windows", false))


func reduced_motion() -> bool:
	return bool(SaveSystem.get_setting(SaveSystem.get_active_profile_id(), "reduced_motion", false))


func text_scale() -> float:
	return float(SaveSystem.get_setting(SaveSystem.get_active_profile_id(), "text_scale", 1.0))


func colorblind_judgements() -> bool:
	return bool(SaveSystem.get_setting(SaveSystem.get_active_profile_id(), "colorblind_judgements", false))


func volume_master() -> float:
	return clampf(float(SaveSystem.get_setting(SaveSystem.get_active_profile_id(), "volume_master", 1.0)), 0.0, 1.0)


func volume_music() -> float:
	return clampf(float(SaveSystem.get_setting(SaveSystem.get_active_profile_id(), "volume_music", 1.0)), 0.0, 1.0)


func volume_sfx() -> float:
	return clampf(float(SaveSystem.get_setting(SaveSystem.get_active_profile_id(), "volume_sfx", 1.0)), 0.0, 1.0)


# ---------------------------------------------------------------------------
# Setting writers (convenience wrappers around SaveSystem.set_setting)
# ---------------------------------------------------------------------------

func set_timing_offset_ms(value: float) -> void:
	SaveSystem.set_setting(SaveSystem.get_active_profile_id(), "timing_offset_ms", value)
	BeatConductor.user_latency_offset_ms = value


func set_wide_timing_windows(value: bool) -> void:
	SaveSystem.set_setting(SaveSystem.get_active_profile_id(), "wide_timing_windows", value)


func set_reduced_motion(value: bool) -> void:
	SaveSystem.set_setting(SaveSystem.get_active_profile_id(), "reduced_motion", value)


func set_text_scale(value: float) -> void:
	SaveSystem.set_setting(SaveSystem.get_active_profile_id(), "text_scale", value)
	_apply_text_scale(value)


func _apply_text_scale(value: float) -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	if loop != null:
		loop.root.content_scale_factor = clampf(value, 0.5, 2.0)


func set_colorblind_judgements(value: bool) -> void:
	SaveSystem.set_setting(SaveSystem.get_active_profile_id(), "colorblind_judgements", value)


func set_volume(bus: String, value: float) -> void:
	SaveSystem.set_setting(SaveSystem.get_active_profile_id(), "volume_" + bus, clampf(value, 0.0, 1.0))
	apply_volumes()


func apply_volumes() -> void:
	var master_db: float = linear_to_db(volume_master()) if volume_master() > 0.0 else -80.0
	var music_db: float = linear_to_db(volume_music()) if volume_music() > 0.0 else -80.0
	var sfx_db: float = linear_to_db(volume_sfx()) if volume_sfx() > 0.0 else -80.0
	var master_idx: int = AudioServer.get_bus_index("Master")
	var music_idx: int = AudioServer.get_bus_index("Music")
	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, master_db)
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, music_db)
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, sfx_db)
