## BuildModeRoot.gd
## Hub scene for the Build Mode editor.  Wires BuildSession, BrlSerializer,
## PlayabilityValidator, DifficultyTagger, TimelineView, PalettePanel,
## PropertiesPanel, and PlaybackBar together.
extends Node2D

class_name BuildModeRoot

# ── Child node refs ───────────────────────────────────────────────────────────
@onready var _timeline: TimelineView = $MainArea/TimelineView
@onready var _palette: PalettePanel = $PaletteStrip/PalettePanel
@onready var _props: PropertiesPanel = $BottomPanel/PropertiesPanel
@onready var _playback: PlaybackBar = $BottomPanel/PlaybackBar
@onready var _name_edit: LineEdit = $TopBar/HBox/NameEdit
@onready var _bpm_spin: SpinBox = $TopBar/HBox/BpmSpin
@onready var _zone_opt: OptionButton = $TopBar/HBox/ZoneOpt
@onready var _save_btn: Button = $TopBar/HBox/SaveBtn
@onready var _validate_label: Button = $PaletteStrip/ValidateLabel
@onready var _diff_label: Label = $PaletteStrip/DiffLabel
@onready var _back_btn: Button = $TopBar/HBox/BackBtn
@onready var _undo_btn: Button = $TopBar/HBox/UndoBtn
@onready var _redo_btn: Button = $TopBar/HBox/RedoBtn
@onready var _delete_btn: Button = $BottomPanel/PropertiesPanel/DeleteBtn

# ── State ─────────────────────────────────────────────────────────────────────
var _session: BuildSession = null
var _profile_id: String = "player1"
var _validation_errors: Array[String] = []
var _all_diff_errors: Dictionary = {}
var _preview_difficulty: String = "Normal"
var _preview_diff_btn: Button = null

## When true: next run_completed marks the session as played_through.
var _awaiting_playtest: bool = false

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
const MAX_UNDO: int = 30

var _errors_popup: Panel = null
var _rank_label: Label = null

const RANK_NAMES: Array[String] = ["Drifter", "Builder", "Architect", "Master Maker"]


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
	_timeline.obstacle_moved.connect(_on_obstacle_moved)
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
	_validate_label.pressed.connect(_on_validate_label_pressed)
	_build_errors_popup()

	# Preview-difficulty cycle button — built in code so no tscn edit needed.
	_preview_diff_btn = Button.new()
	_preview_diff_btn.text = "▶ Normal"
	_preview_diff_btn.add_theme_font_size_override("font_size", 22)
	$PaletteStrip.add_child(_preview_diff_btn)
	_preview_diff_btn.pressed.connect(_on_preview_diff_cycled)

	# Maker rank badge — shows workshop progression without any scene change.
	_rank_label = Label.new()
	_rank_label.add_theme_font_size_override("font_size", 20)
	_rank_label.modulate = Color(0.7, 0.9, 1.0)
	$PaletteStrip.add_child(_rank_label)
	_refresh_rank_label()

	for i: int in range(1, 7):
		_zone_opt.add_item("World %d" % i, i)

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
	# For kelp_curtain, the gap center should start at the tap position, not the schema default.
	if _timeline.active_type == "kelp_curtain":
		(entry["parameters"] as Dictionary)["gap_y_normalized"] = lane_y_normalized
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


func _on_obstacle_moved(index: int, new_beat: float, new_lane: float) -> void:
	if _session == null:
		return
	var beat_map: Array = (_session.get_data().get("beat_map", []) as Array)
	if index < 0 or index >= beat_map.size():
		return
	_push_undo_snapshot()
	var entry: Dictionary = (beat_map[index] as Dictionary).duplicate(true)
	entry["beat_index"] = new_beat
	entry["lane_position"] = new_lane
	# Dragging a kelp_curtain moves the gap center with it.
	if str(entry.get("obstacle_type", "")) == "kelp_curtain":
		var p: Dictionary = entry.get("parameters", {}) as Dictionary
		p["gap_y_normalized"] = new_lane
		entry["parameters"] = p
	_session.update_beat_entry(index, entry)
	_timeline.selected_index = index
	_timeline.refresh()
	_validate_and_tag()


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
		# Moving the gap position slider also repositions the obstacle icon on the timeline.
		if key == "gap_y_normalized" and str(entry.get("obstacle_type", "")) == "kelp_curtain":
			entry["lane_position"] = float(value)
		_session.update_beat_entry(beat_map_index, entry)
		# Redraw so gap size / position / height changes show live in the editor.
		_timeline.selected_index = beat_map_index
		_timeline.refresh()
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
		_validate_label.text = "Try your level first!"
		_validate_label.modulate = Color(1.0, 0.6, 0.1)
		return
	var any_fail: bool = false
	for diff: String in _all_diff_errors.keys():
		if not (_all_diff_errors[diff] as Array).is_empty():
			any_fail = true
	if any_fail:
		_validate_label.text = "Fix the problems first!"
		_validate_label.modulate = Color(1.0, 0.2, 0.2)
		return
	var err: String = BrlSerializer.save(_session, _profile_id)
	if err.is_empty():
		EventBus.buildmode_level_saved.emit(BrlSerializer.level_path(str(_session.get_metadata("id")), _profile_id))
		_validate_label.text = "Level Saved!"
		_validate_label.modulate = Color(0.3, 1.0, 0.3)
		SaveSystem.add_workshop_xp(_profile_id, 5)
		_refresh_rank_label()

		# RhythmMap round-trip: verify saved file loads correctly.
		var level_id: String = str(_session.get_metadata("id"))
		var saved_path: String = "user://profiles/%s/levels/%s.brl" % [_profile_id, level_id]
		var rm: RhythmMap = RhythmMap.new()
		add_child(rm)
		rm.map_loaded.connect(func(_id: String) -> void:
			rm.queue_free()
		)
		rm.map_load_failed.connect(func(reason: String) -> void:
			rm.queue_free()
			_validate_label.text = "Oops! Could not save: " + reason
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
		_validate_label.text = "Great job! Ready to save!"
		_validate_label.modulate = Color(0.5, 1.0, 0.5)
		SaveSystem.add_workshop_xp(_profile_id, 10)
		_refresh_rank_label()


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
	_all_diff_errors = PlayabilityValidator.validate_all_difficulties(_session.get_data())

	# Populate _validation_errors from the current preview difficulty for popup.
	_validation_errors.clear()
	for e: Variant in (_all_diff_errors.get(_preview_difficulty, []) as Array):
		_validation_errors.append(str(e))

	# Build E/N/H status string for the validate button.
	var any_fail: bool = false
	var parts: Array[String] = []
	for diff: String in ["Easy", "Normal", "Hard"]:
		var errs: Array = _all_diff_errors.get(diff, []) as Array
		if errs.is_empty():
			parts.append("%s:✓" % diff.left(1))
		else:
			parts.append("%s:%d✗" % [diff.left(1), errs.size()])
			any_fail = true
	_validate_label.text = "  ".join(parts) + "  ▼"
	_validate_label.modulate = Color(0.5, 1.0, 0.5) if not any_fail else Color(1.0, 0.3, 0.3)

	# Keep popup in sync if it's open.
	if _errors_popup != null and _errors_popup.visible:
		_refresh_errors_popup()

	# Update timeline autoshadow for the selected preview difficulty.
	var trace: Array[Dictionary] = PlayabilityValidator.compute_band_trace(
			_session.get_data(), _preview_difficulty)
	_timeline.set_band_trace(trace)

	var tag: String = DifficultyTagger.compute_tag(_session.get_data())
	_diff_label.text = "Difficulty: %s" % tag


func _on_preview_diff_cycled() -> void:
	match _preview_difficulty:
		"Normal": _preview_difficulty = "Hard"
		"Hard": _preview_difficulty = "Easy"
		_: _preview_difficulty = "Normal"
	if _preview_diff_btn != null:
		_preview_diff_btn.text = "▶ %s" % _preview_difficulty
	_validate_and_tag()


func _build_errors_popup() -> void:
	_errors_popup = Panel.new()
	_errors_popup.visible = false
	_errors_popup.z_index = 10
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.18, 0.97)
	style.border_color = Color(1.0, 0.3, 0.3, 0.9)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_errors_popup.add_theme_stylebox_override("panel", style)
	_errors_popup.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_errors_popup.size = Vector2(900.0, 600.0)
	_errors_popup.position = Vector2(90.0, 660.0)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_errors_popup.add_child(vbox)

	var title: Label = Label.new()
	title.name = "Title"
	title.text = "Level Problems (%s)" % _preview_difficulty
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color(1.0, 0.4, 0.4)
	vbox.add_child(title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.name = "List"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var close_btn: Button = Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.custom_minimum_size = Vector2(0.0, 72.0)
	close_btn.pressed.connect(func() -> void: _errors_popup.visible = false)
	vbox.add_child(close_btn)

	add_child(_errors_popup)


func _refresh_errors_popup() -> void:
	if _errors_popup == null:
		return
	var title_lbl: Label = _errors_popup.get_node_or_null("VBoxContainer/Title") as Label
	if title_lbl != null:
		title_lbl.text = "Level Problems (%s)" % _preview_difficulty
	var list: VBoxContainer = _errors_popup.get_node_or_null("VBoxContainer/Scroll/List") as VBoxContainer
	if list == null:
		return
	for c: Node in list.get_children():
		c.queue_free()
	if _validation_errors.is_empty():
		var ok: Label = Label.new()
		ok.text = "No problems — level looks good!"
		ok.add_theme_font_size_override("font_size", 26)
		ok.modulate = Color(0.5, 1.0, 0.5)
		list.add_child(ok)
	else:
		for i: int in range(_validation_errors.size()):
			var lbl: Label = Label.new()
			lbl.text = "• " + _validation_errors[i]
			lbl.add_theme_font_size_override("font_size", 24)
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			list.add_child(lbl)


func _on_validate_label_pressed() -> void:
	if _errors_popup == null:
		return
	_refresh_errors_popup()
	_errors_popup.visible = not _errors_popup.visible


# ── Helpers ───────────────────────────────────────────────────────────────────

func _default_params(otype: String) -> Dictionary:
	var result: Dictionary = {}
	for pdef: Dictionary in ObstacleParamSchema.params_for(otype):
		result[str(pdef.get("key", ""))] = pdef.get("default")
	return result


func _refresh_rank_label() -> void:
	if _rank_label == null:
		return
	var rank: int = SaveSystem.get_workshop_rank(_profile_id)
	var xp: int = int(SaveSystem.load_progress(_profile_id).get("workshop_xp", 0))
	_rank_label.text = "✦ Maker: %s (%d XP)" % [RANK_NAMES[clampi(rank, 0, 3)], xp]


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
