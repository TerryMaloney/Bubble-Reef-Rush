## FeverController — scene-local node tracking fever mode (combo ≥ 30).
## During fever: +50 score per PERFECT/GOOD, pearls worth double their base value.
## Fever ends on MISS. Connect via LevelRoot.
extends Node

class_name FeverController

const FEVER_COMBO_THRESHOLD: int = 30
const FEVER_SCORE_BONUS: int = 50

var _fever: bool = false
var _combo: int = 0


func _ready() -> void:
	EventBus.beat_judged.connect(_on_beat_judged)
	EventBus.collectible_taken.connect(_on_collectible_taken)
	EventBus.run_started.connect(_reset)


func is_fever() -> bool:
	return _fever


## ── Private ──────────────────────────────────────────────────────────────────

func _on_beat_judged(result: int) -> void:
	match result:
		TimingJudge.TimingResult.PERFECT, TimingJudge.TimingResult.GOOD:
			_combo += 1
			if not _fever and _combo >= FEVER_COMBO_THRESHOLD:
				_fever = true
				EventBus.fever_started.emit()
				SFXManager.play_sfx("sfx/fever_start")
			if _fever:
				EventBus.score_bonus.emit(FEVER_SCORE_BONUS)
		TimingJudge.TimingResult.MISS:
			if _fever:
				_fever = false
				EventBus.fever_ended.emit()
				SFXManager.play_sfx("sfx/fever_end")
			_combo = 0


func _on_collectible_taken(value: int) -> void:
	if _fever:
		# Pearl is worth double during fever — emit a bonus equal to base value.
		EventBus.score_bonus.emit(value)


func _reset(_level_id: String = "") -> void:
	_fever = false
	_combo = 0
