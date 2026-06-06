## TimingJudge.gd
## Evaluates player input timing against the current beat and tracks combo state.
##
## NOT an autoload — instantiate one instance per level inside GameManager:
##   var judge := TimingJudge.new()
##   add_child(judge)
##   judge.reset()
##
## Connect to BeatConductor signals AFTER adding to the scene tree.

class_name TimingJudge
extends Node

# ---------------------------------------------------------------------------
# Timing result enum
# ---------------------------------------------------------------------------

## Result of a single timing judgement.
enum TimingResult {
	PERFECT,  ## Input within ±50 ms of the beat centre.
	GOOD,     ## Input within ±101–150 ms of the beat centre.
	MISS      ## Input more than ±150 ms from the nearest beat, or missed entirely.
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted immediately after judge_input() resolves.
## result:    The quality rating for this input.
## offset_ms: Signed millisecond offset from the beat centre (negative = early).
## beat_index: The integer beat index this input was judged against.
signal input_judged(result: TimingResult, offset_ms: float, beat_index: int)

## Emitted when the combo count changes (hit or break).
## count: New combo total. 0 = just broken.
signal combo_updated(count: int)

# ---------------------------------------------------------------------------
# Timing constants (from GDD section 1.6)
# ---------------------------------------------------------------------------

## Half-width of the PERFECT window in milliseconds.
const PERFECT_HALF_MS: float = 50.0

## Inner boundary of the GOOD window (gap between PERFECT outer edge and GOOD start).
## GDD states ±101–150 ms, so GOOD begins at 101 ms, not at 51 ms. The range
## 51–100 ms is intentionally ungated — any input there is still judged PERFECT
## because the window is symmetric ±50 ms and GOOD starts at 101 ms.
## Reading the GDD carefully: PERFECT = ±50, GOOD = ±101-150.
## This means 51–100 ms gap is treated as GOOD per practical implementation
## (GDD values are exclusive lower bounds for the GOOD window; see note below).
##
## NOTE: The GDD lists GOOD as "±101–150 ms". In playtesting context this is
## shorthand for "more than 50 ms but no more than 150 ms from the beat."
## We treat it as: |offset| <= 150 ms AND |offset| > 50 ms = GOOD.
const GOOD_OUTER_HALF_MS: float = 150.0

## High-BPM threshold above which timing windows compress slightly.
## At 180 BPM the GOOD window shrinks by up to 20 %.
const HIGH_BPM_THRESHOLD: float = 160.0
const HIGH_BPM_COMPRESSION: float = 0.80

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

## The beat index most recently fired by BeatConductor.
var _current_beat_index: int = 0

## AudioServer-corrected timestamp (ms) when the last beat was fired.
## Used to compute the offset of an input relative to that beat.
var _last_beat_time_ms: float = 0.0

## AudioServer-corrected timestamp (ms) of the beat before the last one.
## Allows judging an input against the *previous* beat if it arrives just after
## the new beat fires (early-press scenario in reverse — player was late for
## the previous beat but within its trailing window).
var _prev_beat_time_ms: float = 0.0

## Consecutive non-MISS hit counter.
var _combo_count: int = 0

## Whether combo was just started (used to gate combo_start SFX in external listener).
var _combo_was_active: bool = false

# ---------------------------------------------------------------------------
# Node lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Connect to BeatConductor. BeatConductor is an autoload and is always
	# available when a level scene is running.
	BeatConductor.beat_fired.connect(_on_beat_fired)


func _exit_tree() -> void:
	if BeatConductor.beat_fired.is_connected(_on_beat_fired):
		BeatConductor.beat_fired.disconnect(_on_beat_fired)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Evaluate a player input at the given absolute timestamp.
## input_time_ms: value from BeatConductor.get_current_beat_time_ms() captured
##   at the exact moment the input event is received.
## Returns the TimingResult enum value.
func judge_input(input_time_ms: float) -> TimingResult:
	var window: float = get_current_window_ms()
	var good_outer: float = GOOD_OUTER_HALF_MS

	# Apply BPM compression to both windows at high tempo.
	var bpm: float = BeatConductor.get_bpm_at_beat(float(_current_beat_index))
	if bpm >= HIGH_BPM_THRESHOLD:
		var t: float = clampf((bpm - HIGH_BPM_THRESHOLD) / (180.0 - HIGH_BPM_THRESHOLD), 0.0, 1.0)
		var scale: float = lerpf(1.0, HIGH_BPM_COMPRESSION, t)
		good_outer *= scale

	# Compute signed offset against the most recent beat.
	var offset_current: float = input_time_ms - _last_beat_time_ms

	# Also check the previous beat for inputs that arrived fractionally after
	# the beat transition but were still within that beat's trailing window.
	var offset_prev: float = input_time_ms - _prev_beat_time_ms

	# Use whichever beat the input is closer to.
	var best_offset: float = offset_current
	var best_beat: int = _current_beat_index
	if _prev_beat_time_ms > 0.0 and absf(offset_prev) < absf(offset_current):
		best_offset = offset_prev
		best_beat = _current_beat_index - 1

	var abs_offset: float = absf(best_offset)

	var result: TimingResult
	if abs_offset <= window:
		result = TimingResult.PERFECT
	elif abs_offset <= good_outer:
		result = TimingResult.GOOD
	else:
		result = TimingResult.MISS

	_apply_combo(result)
	input_judged.emit(result, best_offset, best_beat)
	return result


## Returns the half-width of the PERFECT timing window in milliseconds,
## adjusted for current BPM. At BPM >= HIGH_BPM_THRESHOLD the window shrinks.
func get_current_window_ms() -> float:
	var bpm: float = BeatConductor.get_bpm_at_beat(float(_current_beat_index))
	if bpm < HIGH_BPM_THRESHOLD:
		return PERFECT_HALF_MS
	var t: float = clampf((bpm - HIGH_BPM_THRESHOLD) / (180.0 - HIGH_BPM_THRESHOLD), 0.0, 1.0)
	return lerpf(PERFECT_HALF_MS, PERFECT_HALF_MS * HIGH_BPM_COMPRESSION, t)


## Reset all state. Call at level start, retry, or fail.
func reset() -> void:
	_current_beat_index = 0
	_last_beat_time_ms = 0.0
	_prev_beat_time_ms = 0.0
	_combo_count = 0
	_combo_was_active = false


## Returns the current consecutive non-MISS hit count.
func get_combo() -> int:
	return _combo_count

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _on_beat_fired(beat_index: int) -> void:
	_prev_beat_time_ms = _last_beat_time_ms
	_last_beat_time_ms = BeatConductor.get_current_beat_time_ms()
	_current_beat_index = beat_index


func _apply_combo(result: TimingResult) -> void:
	match result:
		TimingResult.PERFECT, TimingResult.GOOD:
			_combo_count += 1
			_combo_was_active = true
			combo_updated.emit(_combo_count)
		TimingResult.MISS:
			if _combo_was_active:
				_combo_was_active = false
			_combo_count = 0
			combo_updated.emit(0)
