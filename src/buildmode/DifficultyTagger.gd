## DifficultyTagger.gd
## Computes an auto-difficulty tag from a .brl Dictionary using the GDD §6.4 formula:
##
##   score = (avg_obstacles_per_measure × 2)
##         + (max_speed_multiplier × 1.5)
##         + (obstacle_type_diversity × 1)
##         + (BPM / 30)
##
##   score → tag:  4–8 = Beginner, 9–14 = Intermediate, 15–22 = Advanced, 23+ = Expert
##
## Override-down-only: creators may lower their tag but not raise it.
class_name DifficultyTagger
extends RefCounted

## Numeric difficulty ranks for range comparisons.
enum Rank { BEGINNER = 1, INTERMEDIATE = 2, ADVANCED = 3, EXPERT = 4 }


## Compute and return the auto-difficulty tag string for a level Dictionary.
static func compute_tag(data: Dictionary) -> String:
	var score: float = _compute_score(data)
	return _score_to_tag(score)


## Compute the raw numeric difficulty score.
static func compute_score(data: Dictionary) -> float:
	return _compute_score(data)


## Apply creator override (override-down-only).
## Returns the override tag if it is ≤ the computed rank; otherwise returns computed tag.
static func apply_override(computed_tag: String, override_tag: String) -> String:
	var computed_rank: int = _tag_rank(computed_tag)
	var override_rank: int = _tag_rank(override_tag)
	if override_rank <= computed_rank:
		return override_tag
	return computed_tag


## True if the proposed tag is a valid override (i.e. ≤ computed difficulty).
static func is_valid_override(computed_tag: String, proposed: String) -> bool:
	return _tag_rank(proposed) <= _tag_rank(computed_tag)


## Human-readable list of all tag strings in ascending difficulty order.
static func all_tags() -> Array[String]:
	return ["Beginner", "Intermediate", "Advanced", "Expert"]


# ── Private helpers ───────────────────────────────────────────────────────────

static func _compute_score(data: Dictionary) -> float:
	var meta: Dictionary = data.get("metadata", {}) as Dictionary
	var bpm: float = float(meta.get("bpm", 110.0))
	var beat_map: Array = data.get("beat_map", []) as Array
	var speed_zones: Array = data.get("speed_zones", []) as Array

	# Count obstacles by 4-beat measure.
	var measure_counts: Dictionary = {}
	var total_beats_used: int = 0
	for entry: Variant in beat_map:
		var e: Dictionary = entry as Dictionary
		var beat_idx: float = float(e.get("beat_index", 0))
		var measure: int = int(beat_idx / 4.0)
		measure_counts[measure] = int(measure_counts.get(measure, 0)) + 1
		total_beats_used = maxi(total_beats_used, int(beat_idx) + 1)

	var num_measures: int = maxi(1, int(ceil(float(total_beats_used) / 4.0)))
	var total_obstacles: int = 0
	for v: Variant in measure_counts.values():
		total_obstacles += int(v)
	var avg_per_measure: float = float(total_obstacles) / float(num_measures)

	# Max speed multiplier across all speed zones.
	var max_mult: float = 1.0
	for zone: Variant in speed_zones:
		var z: Dictionary = zone as Dictionary
		var m: float = float(z.get("speed_multiplier", 1.0))
		if m > max_mult:
			max_mult = m

	# Obstacle type diversity.
	var types: Dictionary = {}
	for entry: Variant in beat_map:
		var otype: String = str((entry as Dictionary).get("obstacle_type", ""))
		if not otype.is_empty():
			types[otype] = true
	var diversity: int = types.size()

	var score: float = (avg_per_measure * 2.0) + (max_mult * 1.5) + float(diversity) + (bpm / 30.0)
	return score


static func _score_to_tag(score: float) -> String:
	if score < 9.0:
		return "Beginner"
	elif score < 15.0:
		return "Intermediate"
	elif score < 23.0:
		return "Advanced"
	else:
		return "Expert"


static func _tag_rank(tag: String) -> int:
	match tag:
		"Beginner":    return Rank.BEGINNER
		"Intermediate": return Rank.INTERMEDIATE
		"Advanced":    return Rank.ADVANCED
		"Expert":      return Rank.EXPERT
		_:             return Rank.BEGINNER
