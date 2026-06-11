## SpecialLevelController — handles special level type behaviours.
## Created lazily by LevelRoot._on_run_started_special() when level_type != "standard".
## Connects to EventBus signals and manages trial completion and boss phase progression.
extends Node

var _level_type: String = "standard"
var _character_id: String = ""
var _boss_id: String = ""
var _trial_unlock_id: String = ""
var _current_boss_phase: int = 0
var _boss_phase_thresholds: Array = []


func setup(metadata: Dictionary) -> void:
	_level_type = str(metadata.get("level_type", "standard"))
	_character_id = str(metadata.get("character_id", ""))
	_boss_id = str(metadata.get("boss_id", ""))
	_trial_unlock_id = str(metadata.get("trial_unlock_id", ""))
	_current_boss_phase = 0
	_boss_phase_thresholds.clear()
	match _level_type:
		"character_trial", "creator_trial":
			EventBus.run_completed.connect(_on_run_completed_trial)
		"boss_chase":
			_load_boss_phases()
			BeatConductor.beat.connect(handle_beat)


func _on_run_completed_trial(level_id: String, _score: int, stars: int) -> void:
	if stars <= 0:
		return
	if _trial_unlock_id.is_empty():
		return
	EventBus.trial_completed.emit(level_id, _trial_unlock_id)
	if not _character_id.is_empty():
		var profile: String = SaveSystem.get_active_profile_id()
		SaveSystem.set_character_unlocked(profile, _character_id)


## Public — called by BeatConductor.beat signal and directly by tests.
func handle_beat(beat_index: float) -> void:
	if _boss_phase_thresholds.is_empty():
		return
	if _current_boss_phase >= _boss_phase_thresholds.size():
		return
	var threshold: float = float(_boss_phase_thresholds[_current_boss_phase])
	if beat_index >= threshold:
		_current_boss_phase += 1
		EventBus.boss_phase_changed.emit(_boss_id, _current_boss_phase)


func _load_boss_phases() -> void:
	if _boss_id.is_empty():
		return
	var script_path: String = "res://src/gameplay/bosses/%s.gd" % _boss_id
	if not ResourceLoader.exists(script_path):
		return
	var script: GDScript = load(script_path)
	if script == null:
		return
	var boss: RefCounted = script.new()
	if not boss.has_method("get_phases"):
		return
	var phases: Array = boss.get_phases()
	for phase: Variant in phases:
		if phase is Dictionary:
			var threshold: Variant = (phase as Dictionary).get("beat_threshold", 0.0)
			_boss_phase_thresholds.append(float(threshold))
