## BeatVisualizer.gd
## Node2D that renders the beat pulse ring around the player character.
##
## Attach this as a child of the player node. It connects to BeatConductor
## automatically and drives its own animation without external ticking.
##
## The ring is drawn with draw_circle() / draw_arc() in _draw() — no shader,
## no extra Sprite2D asset required, though the color and scale are fully
## configurable via exported variables for artist iteration.

class_name BeatVisualizer
extends Node2D

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## Base ring color when no timing result is applied.
@export var base_color: Color = Color(1.0, 1.0, 1.0, 0.85)

## Maximum scale multiplier the ring reaches at the peak of its pulse.
@export var pulse_scale_max: float = 1.5

## Seconds for the full pulse animation (expand + fade).
@export var pulse_duration_sec: float = 0.1

## Ring stroke width in pixels.
@export var ring_width: float = 6.0

## Ring radius in pixels at full scale. The visible ring spans from
## (ring_radius - ring_width/2) to (ring_radius + ring_width/2).
@export var ring_radius: float = 48.0

## Minimum scale at the start of each pulse animation.
@export var pulse_scale_min: float = 0.2

# ---------------------------------------------------------------------------
# Timing-quality colors (match GDD visual cue reference)
# ---------------------------------------------------------------------------

## Gold for PERFECT hits.
const COLOR_PERFECT: Color = Color(1.0, 0.85, 0.0, 1.0)

## Blue for GOOD hits.
const COLOR_GOOD: Color = Color(0.2, 0.6, 1.0, 1.0)

## Gray for MISS hits.
const COLOR_MISS: Color = Color(0.5, 0.5, 0.5, 0.7)

# ---------------------------------------------------------------------------
# Internal animation state
# ---------------------------------------------------------------------------

## Current animated scale of the ring (driven by _pulse_timer).
var _current_scale: float = pulse_scale_min

## Current animated alpha of the ring (fades toward 0 over the pulse).
var _current_alpha: float = 0.0

## Elapsed time within the current pulse animation (seconds).
var _pulse_timer: float = 0.0

## True while a pulse animation is playing.
var _pulsing: bool = false

## Current ring draw color (changes on timing judgements).
var _current_color: Color = Color.WHITE

# ---------------------------------------------------------------------------
# Node lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_current_color = base_color
	BeatConductor.beat_fired.connect(_on_beat_fired)


func _exit_tree() -> void:
	if BeatConductor.beat_fired.is_connected(_on_beat_fired):
		BeatConductor.beat_fired.disconnect(_on_beat_fired)


func _process(delta: float) -> void:
	if not _pulsing:
		return

	_pulse_timer += delta
	var t: float = clampf(_pulse_timer / pulse_duration_sec, 0.0, 1.0)

	# Scale: ease-out from pulse_scale_min to pulse_scale_max.
	_current_scale = lerpf(pulse_scale_min, pulse_scale_max, _ease_out_quad(t))

	# Alpha: hold full opacity for the first half then fade to zero.
	if t < 0.5:
		_current_alpha = lerpf(0.0, 1.0, t * 2.0)
	else:
		_current_alpha = lerpf(1.0, 0.0, (t - 0.5) * 2.0)

	if t >= 1.0:
		_pulsing = false
		_current_alpha = 0.0

	queue_redraw()


func _draw() -> void:
	if _current_alpha <= 0.001:
		return

	var draw_color: Color = _current_color
	draw_color.a = _current_alpha

	var radius: float = ring_radius * _current_scale
	var half_width: float = ring_width * 0.5

	# Draw as a ring by layering two arcs: outer arc minus inner arc approach
	# using draw_arc() which Godot 4 provides natively.
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		64,          # point count — smooth enough at this scale
		draw_color,
		ring_width * _current_scale,
		true         # antialiased
	)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Change the ring color to reflect the last timing judgement.
## Call this immediately after TimingJudge.input_judged fires.
func set_timing_quality(result: TimingJudge.TimingResult) -> void:
	match result:
		TimingJudge.TimingResult.PERFECT:
			_current_color = COLOR_PERFECT
		TimingJudge.TimingResult.GOOD:
			_current_color = COLOR_GOOD
		TimingJudge.TimingResult.MISS:
			_current_color = COLOR_MISS

	# Trigger a fresh pulse burst on every timing result so the player gets
	# immediate visual feedback timed to their input.
	_trigger_pulse()


## Reset the ring to the base color (call at level start / restart).
func reset_color() -> void:
	_current_color = base_color

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _on_beat_fired(_beat_index: int) -> void:
	# Always pulse on beat regardless of whether a timing result was set.
	# The color reflects the last judgement result until the next beat.
	if not _pulsing:
		_current_color = base_color
	_trigger_pulse()


func _trigger_pulse() -> void:
	_pulse_timer = 0.0
	_current_scale = pulse_scale_min
	_current_alpha = 0.0
	_pulsing = true
	queue_redraw()


## Quadratic ease-out curve: fast at start, decelerates toward t=1.
func _ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)
