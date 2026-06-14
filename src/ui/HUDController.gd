# Scene-local CanvasLayer node displaying score, combo, timing judgement feedback, and beat pulse.
extends Node

class_name HUDController

@export var score_label: Label
@export var combo_label: Label
@export var judgment_label: Label
@export var retry_button: Button
@export var progress_bar: ProgressBar
@export var attempt_label: Label
@export var drop_cp_button: Button
@export var resonance_bar: ProgressBar
@export var power_button: Button
@export var ghost_intro_label: Label
@export var ghost_delta_label: Label
@export var difficulty_badge: Label

var score: int = 0

var _combo: int = 0
var _judgment_tween: Tween = null
var _beat_tween: Tween = null

## Latest run progress (0–100), shown as "You made it X%" on death.
var _last_pct: float = 0.0
var _death_label: Label = null

## Timing judge reference — must be set by LevelRoot after instantiating the judge.
var timing_judge: TimingJudge = null


func _ready() -> void:
	EventBus.collectible_taken.connect(_on_collectible_taken)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_progress.connect(_on_run_progress)
	EventBus.run_failed.connect(_on_run_failed_hud)
	EventBus.score_bonus.connect(_on_score_bonus)
	EventBus.fever_started.connect(_on_fever_started)
	EventBus.fever_ended.connect(_on_fever_ended)
	EventBus.practice_checkpoint_saved.connect(_on_checkpoint_saved)
	BeatConductor.beat_fired.connect(_on_beat_fired)
	EventBus.power_charged.connect(_on_power_charged)
	EventBus.power_cooldown_started.connect(_on_power_cooldown_started)
	EventBus.hazard_warning.connect(_on_hazard_warning)

	if retry_button != null:
		retry_button.pressed.connect(_on_retry_pressed)
		retry_button.hide()
		_make_death_label()

	# Power button starts disabled — enabled only when fully charged.
	if power_button != null:
		power_button.disabled = true

	if drop_cp_button != null:
		drop_cp_button.visible = GameManager.is_practice_mode


## Call this from LevelRoot once the TimingJudge child is ready.
func connect_timing_judge(judge: TimingJudge) -> void:
	timing_judge = judge
	timing_judge.input_judged.connect(_on_input_judged)
	timing_judge.combo_updated.connect(_on_combo_updated)


# ---------------------------------------------------------------------------
# EventBus handlers
# ---------------------------------------------------------------------------

func _on_run_started(level_id: String) -> void:
	score = 0
	_combo = 0
	_update_score_label()
	_update_combo_label()
	if judgment_label != null:
		judgment_label.text = ""
	if retry_button != null:
		retry_button.hide()
	if _death_label != null:
		_death_label.visible = false
	_last_pct = 0.0
	if progress_bar != null:
		progress_bar.value = 0.0
	if ghost_delta_label != null:
		ghost_delta_label.visible = false
	if difficulty_badge != null:
		var diff: String = str(GameManager.active_difficulty)
		difficulty_badge.text = diff.to_upper()
		match diff:
			"easy": difficulty_badge.modulate = Color(0.2, 0.9, 1.0)
			"hard": difficulty_badge.modulate = Color(1.0, 0.4, 0.1)
			_: difficulty_badge.modulate = Color.WHITE
		difficulty_badge.show()
	# Show total attempts for this level so far (this run will be recorded on fail/complete).
	if attempt_label != null:
		var profile: String = SaveSystem.get_active_profile_id()
		var attempts: int = SaveSystem.get_attempts(profile, level_id)
		attempt_label.text = "Attempt %d" % (attempts + 1)


func _on_run_progress(_level_id: String, pct: float) -> void:
	_last_pct = pct
	if progress_bar != null:
		progress_bar.value = pct
	if ghost_delta_label != null and GhostLibrary.last_ghost_score >= 0:
		var delta: int = score - _ghost_pace(GhostLibrary.last_ghost_score, pct)
		ghost_delta_label.text = format_ghost_delta(score, GhostLibrary.last_ghost_score, pct)
		ghost_delta_label.modulate = Color(0.3, 1.0, 0.5) if delta >= 0 else Color(1.0, 0.45, 0.45)
		ghost_delta_label.visible = true


## Ghost score scaled to current progress — the pace the player must beat.
static func _ghost_pace(ghost_score: int, pct: float) -> int:
	return int(ghost_score * clampf(pct, 0.0, 100.0) / 100.0)


## Pure helper so headless tests can verify the delta formatting.
static func format_ghost_delta(current_score: int, ghost_score: int, pct: float) -> String:
	var delta: int = current_score - _ghost_pace(ghost_score, pct)
	return "+%d" % delta if delta >= 0 else "%d" % delta


## Shows "Racing: <ghost name> — <score>" for a few seconds at run start.
func show_ghost_intro(ghost_type: String, ghost_score: int) -> void:
	if ghost_intro_label == null:
		return
	var score_text: String = "" if ghost_score < 0 else " — %d" % ghost_score
	ghost_intro_label.text = "Racing: %s%s" % [_ghost_display_name(ghost_type), score_text]
	ghost_intro_label.visible = true
	ghost_intro_label.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(ghost_intro_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: ghost_intro_label.visible = false)


static func _ghost_display_name(ghost_type: String) -> String:
	match ghost_type:
		"personal_best":
			return "Personal Best"
		"family_champion":
			return "Family Champion"
		"imported":
			return "Imported Challenge"
		_:
			return ghost_type.capitalize()


func _on_run_failed_hud(_level_id: String, _score: int) -> void:
	if GameManager.is_practice_mode:
		return  # practice respawn; no retry button
	if retry_button != null:
		retry_button.show()
	if _death_label != null:
		_death_label.text = "You made it %d%%!" % int(roundf(_last_pct))
		_death_label.visible = true


## Build the "You made it X%" banner shown on death, above the retry button.
func _make_death_label() -> void:
	var parent: Node = retry_button.get_parent()
	if parent == null:
		return
	_death_label = Label.new()
	_death_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_death_label.anchor_left = 0.5
	_death_label.anchor_right = 0.5
	_death_label.offset_left = -360.0
	_death_label.offset_right = 360.0
	_death_label.offset_top = 560.0
	_death_label.offset_bottom = 660.0
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.add_theme_font_size_override("font_size", 64)
	_death_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	_death_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_death_label.add_theme_constant_override("outline_size", 8)
	_death_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_label.visible = false
	parent.add_child(_death_label)


## Restore score after a practice checkpoint respawn.
func set_score(new_score: int) -> void:
	score = new_score
	_update_score_label()


func _on_checkpoint_saved() -> void:
	_flash_judgment("CP SAVED", Color(0.2, 0.9, 0.4))


func _on_collectible_taken(value: int) -> void:
	score += value
	_update_score_label()


# ---------------------------------------------------------------------------
# TimingJudge signal handlers
# ---------------------------------------------------------------------------

func _on_input_judged(result: TimingJudge.TimingResult, _offset_ms: float, _beat_index: int) -> void:
	var combo_mult: int = _combo_multiplier(_combo)
	var colorblind: bool = Accessibility.colorblind_judgements()

	match result:
		TimingJudge.TimingResult.PERFECT:
			score += 100 * combo_mult
			_flash_judgment("◆ PERFECT" if colorblind else "PERFECT", Color(1.0, 0.85, 0.0))
		TimingJudge.TimingResult.GOOD:
			score += 60 * combo_mult
			_flash_judgment("● GOOD" if colorblind else "GOOD", Color(0.2, 0.6, 1.0))
		TimingJudge.TimingResult.MISS:
			pass  # no text — with no audio cue, a MISS label is just noise

	EventBus.beat_judged.emit(int(result))
	_update_score_label()


func _on_combo_updated(count: int) -> void:
	_combo = count
	_update_combo_label()


func _on_score_bonus(amount: int) -> void:
	score += amount
	_update_score_label()


func _on_fever_started() -> void:
	if combo_label != null:
		combo_label.modulate = Color(1.0, 0.8, 0.0)


func _on_fever_ended() -> void:
	if combo_label != null:
		combo_label.modulate = Color.WHITE


# ---------------------------------------------------------------------------
# BeatConductor signal handlers
# ---------------------------------------------------------------------------

func _on_beat_fired(_beat_index: int) -> void:
	if score_label == null:
		return
	# Subtle scale pulse on the score label to reinforce the beat.
	if _beat_tween != null:
		_beat_tween.kill()
	_beat_tween = create_tween()
	_beat_tween.tween_property(score_label, "scale", Vector2(1.08, 1.08), 0.05)
	_beat_tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)


# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------

func _update_score_label() -> void:
	if score_label != null:
		score_label.text = str(score)


func _update_combo_label() -> void:
	if combo_label == null:
		return
	if _combo >= 10:
		combo_label.show()
		combo_label.text = "×%d  %d" % [_combo_multiplier(_combo), _combo]
	else:
		combo_label.hide()


func _on_hazard_warning(text: String) -> void:
	_flash_judgment(text, Color(1.0, 0.65, 0.0), 2.0)


func _flash_judgment(text: String, color: Color, duration: float = 0.4) -> void:
	if judgment_label == null:
		return
	judgment_label.text = text
	judgment_label.modulate = color
	judgment_label.show()

	if _judgment_tween != null:
		_judgment_tween.kill()
	_judgment_tween = create_tween()
	_judgment_tween.tween_interval(duration)
	_judgment_tween.tween_callback(func() -> void: judgment_label.text = "")


func _combo_multiplier(combo: int) -> int:
	if combo >= 80:
		return 5
	elif combo >= 40:
		return 4
	elif combo >= 20:
		return 3
	elif combo >= 10:
		return 2
	else:
		return 1


func _on_retry_pressed() -> void:
	EventBus.retry_requested.emit()


func update_power_button_mode(mode: String) -> void:
	if power_button == null:
		return
	power_button.visible = (mode != "disabled")


func _on_power_charged(pct: float) -> void:
	if resonance_bar != null:
		resonance_bar.value = pct * 100.0
	if power_button != null:
		power_button.disabled = (pct < 1.0)


func _on_power_cooldown_started() -> void:
	if power_button != null:
		power_button.disabled = true

