## PlayabilityValidator.gd
## GDScript port of tools/check_movements.py plus GDD §6.3 density caps
## and the ±80 px overlap rule.
##
## Usage:
##   var errors := PlayabilityValidator.validate(data_dict)
##   if errors.is_empty(): # valid
class_name PlayabilityValidator
extends RefCounted

# Mirrors check_movements.py constants (kept in sync with GameConstants).
const CANVAS_H: float = 1920.0
const CANVAS_W: float = 1080.0
const JUDGMENT_X: float = 200.0
const BASE_SPEED: float = 408.0
const FLOAT_TERMINAL: float = 480.0
const DIVE_TERMINAL: float = 720.0
const SKIP_INTENSITY: float = 0.08
const EPS: float = 1e-9
const OVERLAP_Y_PX: float = 80.0   # §6.3 same-beat lane overlap threshold

# Positional gate types — all others are point hazards excluded from gap analysis.
const POSITIONAL_TYPES: Array[String] = ["pressure_wall", "kelp_curtain"]


## Validate a parsed .brl Dictionary.
## Returns an Array of human-readable error strings.  Empty = valid.
static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []

	var meta: Dictionary = data.get("metadata", {}) as Dictionary
	var base_bpm: float = float(meta.get("bpm", 110.0))
	var is_variable: bool = bool(meta.get("bpm_variable", false))
	var bpm_changes_raw: Array = (meta.get("bpm_changes", []) if is_variable else []) as Array
	var bpm_changes: Array[Dictionary] = []
	for c: Variant in bpm_changes_raw:
		bpm_changes.append(c as Dictionary)

	var speed_zones: Array = data.get("speed_zones", []) as Array
	var beat_map: Array = data.get("beat_map", []) as Array
	var zone: int = int(meta.get("zone", 1))
	var cap: int = _max_per_measure(zone)

	# ── GDD §6.3: density cap ────────────────────────────────────────────────
	# Count obstacles per 4-beat window.
	var measure_counts: Dictionary = {}
	for entry: Variant in beat_map:
		var e: Dictionary = entry as Dictionary
		var beat_idx: float = float(e.get("beat_index", 0))
		var measure: int = int(beat_idx / 4.0)
		measure_counts[measure] = int(measure_counts.get(measure, 0)) + 1

	for measure: Variant in measure_counts.keys():
		var count: int = int(measure_counts[measure])
		if count > cap:
			errors.append(
				"Measure %d: %d obstacles exceeds zone %d density cap of %d per measure." % [
					int(measure), count, zone, cap
				]
			)

	# ── GDD §6.3: ±80 px overlap rule ───────────────────────────────────────
	# Group all beat_map entries by beat_index.
	var by_beat: Dictionary = {}
	for entry: Variant in beat_map:
		var e: Dictionary = entry as Dictionary
		var beat_idx: float = float(e.get("beat_index", 0))
		var key: String = "%.4f" % beat_idx
		if not by_beat.has(key):
			by_beat[key] = []
		(by_beat[key] as Array).append(e)

	for key: Variant in by_beat.keys():
		var group: Array = by_beat[key] as Array
		for i: int in range(group.size()):
			for j: int in range(i + 1, group.size()):
				var yi: float = float((group[i] as Dictionary).get("lane_position", 0.5)) * CANVAS_H
				var yj: float = float((group[j] as Dictionary).get("lane_position", 0.5)) * CANVAS_H
				if absf(yi - yj) < OVERLAP_Y_PX - EPS:
					errors.append(
						"Beat %.2f: two obstacles lane_y=%.0f and lane_y=%.0f overlap within %.0f px." % [
							float(key), yi, yj, OVERLAP_Y_PX
						]
					)

	# ── Movement budget check ─────────────────────────────────────────────────
	var gates: Array[Dictionary] = []
	for entry: Variant in beat_map:
		var e: Dictionary = entry as Dictionary
		if _is_active_positional(e):
			gates.append(e)

	gates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("beat_index", 0)) < float(b.get("beat_index", 0))
	)

	for i: int in range(1, gates.size()):
		var prev: Dictionary = gates[i - 1]
		var curr: Dictionary = gates[i]
		var b_prev: float = float(prev.get("beat_index", 0))
		var b_curr: float = float(curr.get("beat_index", 0))
		var beats: float = b_curr - b_prev
		if beats <= 0.0:
			continue

		var actual_s: float = _beats_to_seconds(b_prev, b_curr, base_bpm, bpm_changes)
		var max_up: float = (FLOAT_TERMINAL * actual_s) / CANVAS_H
		var max_down: float = (DIVE_TERMINAL  * actual_s) / CANVAS_H

		var y0: float = _get_gap_y(prev)
		var y1: float = _get_gap_y(curr)
		var delta: float = y1 - y0

		if delta < -(max_up + EPS):
			errors.append(
				"B%.1f(%.3f) → B%.1f(%.3f): up Δ=%.4f > budget %.4f (%.1f beats, %.3fs)." % [
					b_prev, y0, b_curr, y1, -delta, max_up, beats, actual_s
				]
			)
		elif delta > max_down + EPS:
			errors.append(
				"B%.1f(%.3f) → B%.1f(%.3f): down Δ=%.4f > budget %.4f (%.1f beats, %.3fs)." % [
					b_prev, y0, b_curr, y1, delta, max_down, beats, actual_s
				]
			)

	# ── Speed-zone readability ────────────────────────────────────────────────
	for i: int in range(gates.size()):
		var gate: Dictionary = gates[i]
		var beat: float = float(gate.get("beat_index", 0))
		var mult: float = _get_speed_mult(beat, speed_zones)
		if mult <= 0.0:
			continue

		var lead: float = (CANVAS_W - JUDGMENT_X) / (BASE_SPEED * mult)
		if lead < 1.0 - EPS:
			errors.append(
				"B%.1f: speed mult %.2f× → lead time %.2fs < 1.0s." % [beat, mult, lead]
			)

		if mult > 1.3 and i + 1 < gates.size():
			var next_beat: float = float(gates[i + 1].get("beat_index", 0))
			var gap: float = next_beat - beat
			if gap < 2.0 - EPS:
				errors.append(
					"B%.1f: speed mult %.2f× > 1.3 but next gate only %.1f beats away (need ≥ 2)." % [
						beat, mult, gap
					]
				)

	return errors


## Max obstacles per 4-beat measure, keyed by zone.
static func _max_per_measure(zone: int) -> int:
	match zone:
		1: return 4
		2, 3: return 6
		4, 5: return 8
		_: return 10   # zone 6


## True iff the beat_map entry is a spawned positional gate (not rest/mine/jelly).
static func _is_active_positional(entry: Dictionary) -> bool:
	var otype: String = str(entry.get("obstacle_type", ""))
	if not (otype in POSITIONAL_TYPES):
		return false
	if _get_gap_y(entry) < 0.0:
		return false
	if otype == "pressure_wall":
		var intensity: float = float((entry.get("parameters", {}) as Dictionary).get("intensity", 1.0))
		if intensity <= SKIP_INTENSITY:
			return false
	return true


## Extract the normalised gap centre Y from an entry.  Returns -1 if absent.
static func _get_gap_y(entry: Dictionary) -> float:
	var params: Dictionary = entry.get("parameters", {}) as Dictionary
	var y: Variant = params.get("gap_y_normalized")
	if y == null:
		y = entry.get("lane_position")
	if y == null:
		return -1.0
	return float(y)


## Interpolate BPM at a fractional beat index (port of check_movements.py).
static func _get_bpm_at_beat(beat: float, base_bpm: float, bpm_changes: Array[Dictionary]) -> float:
	if bpm_changes.is_empty():
		return base_bpm
	var current: float = base_bpm
	for change: Dictionary in bpm_changes:
		var cb: float = float(change.get("beat_index", 0))
		if cb > beat:
			break
		var new_bpm: float = float(change.get("new_bpm", base_bpm))
		var transition: float = float(change.get("transition_beats", 0))
		if transition > 0.0 and beat < cb + transition:
			var t: float = clampf((beat - cb) / transition, 0.0, 1.0)
			current = lerpf(current, new_bpm, t)
		else:
			current = new_bpm
	return current


## Duration of a single beat in seconds.
static func _beat_duration_s(beat: float, base_bpm: float, bpm_changes: Array[Dictionary]) -> float:
	return 60.0 / _get_bpm_at_beat(beat, base_bpm, bpm_changes)


## Integrate beat durations from from_beat to to_beat (integer steps + fractional tail).
static func _beats_to_seconds(from_beat: float, to_beat: float, base_bpm: float, bpm_changes: Array[Dictionary]) -> float:
	var total: float = 0.0
	var b: int = int(from_beat)
	while b < int(to_beat):
		total += _beat_duration_s(float(b), base_bpm, bpm_changes)
		b += 1
	var frac: float = to_beat - int(to_beat)
	if frac > 0.0:
		total += frac * _beat_duration_s(float(int(to_beat)), base_bpm, bpm_changes)
	return total


## Return speed multiplier from speed_zones array at the given beat.
static func _get_speed_mult(beat: float, speed_zones: Array) -> float:
	for zone: Variant in speed_zones:
		var z: Dictionary = zone as Dictionary
		if beat >= float(z.get("start_beat", 0)) and beat < float(z.get("end_beat", 0)):
			return float(z.get("speed_multiplier", 1.0))
	return 1.0
