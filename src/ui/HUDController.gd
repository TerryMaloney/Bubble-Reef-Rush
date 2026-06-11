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

var score: int = 0

var _combo: int = 0
var _judgment_tween: Tween = null
var _beat_tween: Tween = null

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

	if retry_button != null:
		retry_button.pressed.connect(_on_retry_pressed)
		retry_button.hide()

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
	if progress_bar != null:
		progress_bar.value = 0.0
	# Show total attempts for this level so far (this run will be recorded on fail/complete).
	if attempt_label != null:
		var profile: String = SaveSystem.get_active_profile_id()
		var attempts: int = SaveSystem.get_attempts(profile, level_id)
		attempt_label.text = "Attempt %d" % (attempts + 1)


func _on_run_progress(_level_id: String, pct: float) -> void:
	if progress_bar != null:
		progress_bar.value = pct


func _on_run_failed_hud(_level_id: String, _score: int) -> void:
	if GameManager.is_practice_mode:
		return  # practice respawn; no retry button
	if retry_button != null:
		retry_button.show()


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


func _flash_judgment(text: String, color: Color) -> void:
	if judgment_label == null:
		return
	judgment_label.text = text
	judgment_label.modulate = color
	judgment_label.show()

	if _judgment_tween != null:
		_judgment_tween.kill()
	_judgment_tween = create_tween()
	_judgment_tween.tween_interval(0.4)
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

