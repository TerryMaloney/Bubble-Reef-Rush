## Scene-local "Reef Director" — dynamic difficulty adjustment for one run.
##
## Implements the DDA layer described in docs/design/difficulty_design.md.
## It NEVER changes the music or scroll speed (the chart stays beat-locked);
## it only produces an *effective intensity* 0..1 that the ObstacleSpawner maps
## to gap size and density.
##
## Two opposing pressures keep the player in their flow channel:
##   - assist  : rises on death (gaps widen, gates thin) — practice-mode mercy.
##   - push    : rises on a strong combo (gaps tighten) — pressure for experts.
## effective = clamp(authored + push - assist, floor, ceil)
##
## Deaths carry across instant-retries via GameManager.consecutive_deaths, so a
## player who is genuinely stuck sees the level ease without a separate mode.
extends Node

class_name DifficultyDirector

## How much one death widens things (added to assist).
@export var assist_per_death: float = 0.16
## Assist bleeds off slowly as the player survives, per beat.
@export var assist_decay_per_beat: float = 0.012
## Hard cap so the level still resembles its authored shape.
@export var assist_max: float = 0.55
## Each full 10-combo adds this much push.
@export var push_per_combo_tier: float = 0.05
@export var push_max: float = 0.25
## Effective intensity is always clamped to this band.
@export var intensity_floor: float = 0.05
@export var intensity_ceil: float = 1.0
## The opening of every run is guaranteed gentle (early-win rule).
@export var early_win_beats: int = 8

var _assist: float = 0.0
var _push: float = 0.0


func _ready() -> void:
	EventBus.player_hit.connect(_on_player_hit)
	BeatConductor.beat_fired.connect(_on_beat_fired)


## Seed the starting assist from deaths carried across instant-retries.
## Called by LevelRoot, which owns the GameManager reference — keeps this node
## decoupled from autoloads and unit-testable in isolation.
func seed_from_deaths(deaths: int) -> void:
	_assist = minf(float(deaths) * assist_per_death, assist_max)


## Returns the effective intensity for an obstacle authored at `authored`
## intensity, due at `beat_index`. Used by ObstacleSpawner to size the gate.
func effective_intensity(authored: float, beat_index: int) -> float:
	if beat_index < early_win_beats:
		# Guaranteed gentle opening regardless of authored value or push.
		return minf(authored, intensity_floor + 0.05)
	return clampf(authored + _push - _assist, intensity_floor, intensity_ceil)


## Hook for the player's TimingJudge combo signal (wired by LevelRoot).
func on_combo_updated(combo: int) -> void:
	var tier: int = combo / 10
	_push = minf(float(tier) * push_per_combo_tier, push_max)


func get_assist() -> float:
	return _assist


func get_push() -> float:
	return _push


func _on_player_hit() -> void:
	_assist = minf(_assist + assist_per_death, assist_max)
	# A death breaks the combo, so drop the expert pressure too.
	_push = 0.0


func _on_beat_fired(_beat_index: int) -> void:
	_assist = maxf(0.0, _assist - assist_decay_per_beat)
