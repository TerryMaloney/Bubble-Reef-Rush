## BuildModeRoot.gd
## Hub scene for the Build Mode editor.  Wires BuildSession, BrlSerializer,
## PlayabilityValidator, DifficultyTagger, TimelineView, PalettePanel,
## PropertiesPanel, and PlaybackBar together.
extends Node2D

class_name BuildModeRoot

# ── Child node refs ───────────────────────────────────────────────────────────
@onready var _timeline: TimelineView = $MainArea/TimelineView
@onready var _palette: PalettePanel = $MainArea/PalettePanel
@onready var _props: PropertiesPanel = $BottomPanel/PropertiesPanel
@onready var _playback: PlaybackBar = $BottomPanel/PlaybackBar
@onready var _name_edit: LineEdit = $TopBar/HBox/NameEdit
@onready var _bpm_spin: SpinBox = $TopBar/HBox/BpmSpin
@onready var _zone_opt: OptionButton = $TopBar/HBox/ZoneOpt
@onready var _save_btn: Button = $TopBar/HBox/SaveBtn
@onready var _validate_label: Label = $TopBar/HBox/ValidateLabel
@onready var _diff_label: Label = $TopBar/HBox/DiffLabel
@onready var _back_btn: Button = $TopBar/HBox/BackBtn
@onready var _undo_btn: Button = $TopBar/HBox/UndoBtn
@onready var _redo_btn: Button = $TopBar/HBox/RedoBtn
@onready var _delete_btn: Button = $BottomPanel/PropertiesPanel/DeleteBtn

# ── State ─────────────────────────────────────────────────────────────────────
var _session: BuildSession = null
var _profile_id: String = "player1"
var _validation_errors: Array[String] = []

## When true: next run_completed marks the session as played_through.
var _awaiting_playtest: bool = false

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
const MAX_UNDO: int = 30


func _ready() -> void:
	add_to_group("build_mode_root")
	_profile_id = SaveSystem.get_active_profile_id()
	var progress: Dictionary = SaveSystem.load_progress(_profile_id)
	var total_stars: int = int(progress.get("total_stars", 0))
	var highest_zone: int = _highest_cleared_zone(progress)

	_palette.refresh_palette(highest_zone)
	_palette.obstacle_type_selected.connect(_on_obstacle_type_selected)
	_timeline.obstacle_placed.connect(_on_obstacle_placed)
	_timeline.obstacle_selected.connect(_on_obstacle_selected)
	_timeline.obstacle_deselected.connect(_on_obstacle_deselected)
	if _props != null:
		_props.property_changed.connect(_on_property_changed)
	if _playback != null:
		_playback.timeline = _timeline

	_save_btn.pressed.connect(_on_save_pressed)
	_name_edit.text_changed.connect(_on_name_changed)
	_bpm_spin.value_changed.connect(_on_bpm_changed)
	_zone_opt.item_selected.connect(_on_zone_changed)
	_back_btn.pressed.connect(_on_back_pressed)
	_undo_btn.pressed.connect(_on_undo_pressed)
	_redo_btn.pressed.connect(_on_redo_pressed)
	if _delete_btn != null:
		_delete_btn.pressed.connect(_on_delete_selected)

	_timeline.delete_requested.connect(_on_delete_obstacle)

	for i: int in range(1, 7):
		_zone_opt.add_item("Zone %d" % i, i)

	EventBus.run_completed.connect(_on_run_completed)

	# Restore session stashed before test-play, or start fresh.
	if GameManager.pending_build_session != null:
		_session = GameManager.pending_build_session as BuildSession
		GameManager.pending_build_session = null
		_apply_session_to_ui()
	else:
		_new_session()


## Called from GameManager or "New Level" button.
func _new_session() -> void:
	_session = BuildSession.new()
	_session.create_new(_profile_id, 1)
	_apply_session_to_ui()


func get_session() -> BuildSession:
	return _session


func set_awaiting_playtest(val: bool) -> void:
	_awaiting_playtest = val


## Load an existing player level by ID.
func load_session(level_id: String) -> void:
	var loaded: BuildSession = BrlSerializer.load_from_disk(level_id, _profile_id)
	if loaded == null:
		push_warning("BuildModeRoot: failed to load level '%s'" % level_id)
		return
	_session = loaded
	_apply_session_to_ui()


func _apply_session_to_ui() -> void:
	if _session == null:
		return
	var meta: Dictionary = _session.get_data().get("metadata", {}) as Dictionary
	_name_edit.text = str(meta.get("name", "My Level"))
	_bpm_spin.value = float(meta.get("bpm", 120.0))
	var zone: int = int(meta.get("zone", 1))
	_zone_opt.selected = zone - 1
	_timeline.session = _session
	_timeline.refresh()
	if _playback != null:
		_playback.level_id = str(meta.get("id", ""))
	_validate_and_tag()


# ── UI event handlers ─────────────────────────────────────────────────────────

func _on_obstacle_type_selected(otype: String) -> void:
	if _timeline != null:
		_timeline.active_type = otype


func _on_obstacle_placed(beat_index: float, lane_y_normalized: float) -> void:
	if _session == null or _timeline.active_type.is_empty():
		return
	_push_undo_snapshot()
	var entry: Dictionary = {
		"beat_index": beat_index,
		"lane_position": lane_y_normalized,
		"obstacle_type": _timeline.active_type,
		"parameters": _default_params(_timeline.active_type)
	}
	_session.add_beat_entry(entry)
	_timeline.refresh()
	_validate_and_tag()


func _on_obstacle_selected(index: int) -> void:
	if _session == null:
		return
	var beat_map: Array = (_session.get_data().get("beat_map", []) as Array)
	if index < beat_map.size():
		if _props != null:
			_props.show_entry(index, beat_map[index] as Dictionary)


func _on_obstacle_deselected() -> void:
	if _props != null:
		_props.clear()


func _on_property_changed(beat_map_index: int, key: String, value: Variant) -> void:
	if _session == null:
		return
	var beat_map: Array = (_session.get_data().get("beat_map", []) as Array)
	if beat_map_index < beat_map.size():
		_push_undo_snapshot()
		var entry: Dictionary = (beat_map[beat_map_index] as Dictionary).duplicate(true)
		var params: Dictionary = entry.get("parameters", {}) as Dictionary
		params[key] = value
		entry["parameters"] = params
		_session.update_beat_entry(beat_map_index, entry)
		_validate_and_tag()


func _on_name_changed(new_name: String) -> void:
	if _session != null:
		_session.set_metadata("name", new_name)
	_validate_and_tag()


func _on_bpm_changed(value: float) -> void:
	if _session != null:
		_session.set_metadata("bpm", value)
	_validate_and_tag()


func _on_zone_changed(idx: int) -> void:
	if _session != null:
		_session.set_metadata("zone", idx + 1)
		_palette.refresh_palette(_highest_cleared_zone(SaveSystem.load_progress(_profile_id)))
	_validate_and_tag()


func _on_save_pressed() -> void:
	if _session == null:
		return
	if not _session.played_through:
		_validate_label.text = "Test-play the level before saving."
		_validate_label.modulate = Color(1.0, 0.6, 0.1)
		return
	if not _validation_errors.is_empty():
		_validate_label.text = "Fix %d error(s) before saving." % _validation_errors.size()
		_validate_label.modulate = Color(1.0, 0.2, 0.2)
		return
	var err: String = BrlSerializer.save(_session, _profile_id)
	if err.is_empty():
		EventBus.buildmode_level_saved.emit(BrlSerializer.level_path(str(_session.get_metadata("id")), _profile_id))
		_validate_label.text = "Saved!"
		_validate_label.modulate = Color(0.3, 1.0, 0.3)

		# RhythmMap round-trip: load saved file back through RhythmMap for full validation.
		var level_id: String = str(_session.get_metadata("id"))
		var saved_path: String = "user://profiles/%s/levels/%s.brl" % [_profile_id, level_id]
		var rm: RhythmMap = RhythmMap.new()
		add_child(rm)
		rm.map_loaded.connect(func(_id: String) -> void:
			rm.queue_free()
			_validate_label.text += " ✓ Round-trip OK"
		)
		rm.map_load_failed.connect(func(reason: String) -> void:
			rm.queue_free()
			_validate_label.text = "Save OK but round-trip failed: " + reason
			_validate_label.modulate = Color(1.0, 0.5, 0.1)
		)
		rm.load_level(saved_path)
	else:
		_validate_label.text = err
		_validate_label.modulate = Color(1.0, 0.2, 0.2)


func _on_run_completed(_level_id: String, _score: int, _stars: int) -> void:
	if _awaiting_playtest:
		_awaiting_playtest = false
		_session.mark_played_through()
		_validate_label.text = "Played through — ready to save."
		_validate_label.modulate = Color(0.5, 1.0, 0.5)


# ── Back / Undo / Redo / Delete ───────────────────────────────────────────────

func _on_back_pressed() -> void:
	GameManager.go_to_menu()


func _push_undo_snapshot() -> void:
	if _session == null:
		return
	_undo_stack.push_back(_session.get_data().duplicate(true))
	if _undo_stack.size() > MAX_UNDO:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_undo_btn.disabled = false
	_redo_btn.disabled = true


func _on_undo_pressed() -> void:
	if _undo_stack.is_empty() or _session == null:
		return
	_redo_stack.push_back(_session.get_data().duplicate(true))
	var snap: Dictionary = _undo_stack.pop_back()
	_session.load_from_dict(snap)
	_apply_session_to_ui()
	_undo_btn.disabled = _undo_stack.is_empty()
	_redo_btn.disabled = false


func _on_redo_pressed() -> void:
	if _redo_stack.is_empty() or _session == null:
		return
	_undo_stack.push_back(_session.get_data().duplicate(true))
	var snap: Dictionary = _redo_stack.pop_back()
	_session.load_from_dict(snap)
	_apply_session_to_ui()
	_undo_btn.disabled = false
	_redo_btn.disabled = _redo_stack.is_empty()


func _on_delete_selected() -> void:
	if _session == null or _timeline.selected_index < 0:
		return
	_on_delete_obstacle(_timeline.selected_index)


func _on_delete_obstacle(index: int) -> void:
	if _session == null:
		return
	var beat_map: Array = (_session.get_data().get("beat_map", []) as Array)
	if index < 0 or index >= beat_map.size():
		return
	_push_undo_snapshot()
	_session.remove_beat_entry(index)
	_timeline.selected_index = -1
	if _props != null:
		_props.clear()
	_timeline.refresh()
	_validate_and_tag()


# ── Validation + tagging ──────────────────────────────────────────────────────

func _validate_and_tag() -> void:
	if _session == null:
		return
	_validation_errors = PlayabilityValidator.validate(_session.get_data())
	if _validation_errors.is_empty():
		_validate_label.text = "Valid"
		_validate_label.modulate = Color(0.5, 1.0, 0.5)
	else:
		_validate_label.text = "%d error(s)" % _validation_errors.size()
		_validate_label.modulate = Color(1.0, 0.3, 0.3)

	var tag: String = DifficultyTagger.compute_tag(_session.get_data())
	_diff_label.text = tag


# ── Helpers ───────────────────────────────────────────────────────────────────

func _default_params(otype: String) -> Dictionary:
	var result: Dictionary = {}
	for pdef: Dictionary in ObstacleParamSchema.params_for(otype):
		result[str(pdef.get("key", ""))] = pdef.get("default")
	return result


func _highest_cleared_zone(progress: Dictionary) -> int:
	var levels: Dictionary = progress.get("levels", {}) as Dictionary
	var highest: int = 0
	for level_id: String in levels.keys():
		if level_id.begins_with("z") and "-" in level_id:
			var parts: Array = level_id.split("-")
			if parts.size() >= 1:
				var z: int = int(str(parts[0]).trim_prefix("z"))
				if z > highest:
					highest = z
	return highest
