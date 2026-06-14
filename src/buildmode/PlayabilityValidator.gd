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
const FLOAT_TERMINAL: float = 700.0
const DIVE_TERMINAL: float = 1100.0
const SKIP_INTENSITY: float = 0.08
const EPS: float = 1e-9
const OVERLAP_Y_PX: float = 80.0   # §6.3 same-beat lane overlap threshold

# Positional gate types — all others are point hazards excluded from gap analysis.
const POSITIONAL_TYPES: Array[String] = ["pressure_wall", "kelp_curtain"]

# ── Reachable-band geometry (mirrors tools/check_movements.py) ────────────────
const PLAYER_HALF: float = 28.0      # half of the 56px player capsule height
const SAFETY: float = 0.90           # use 90% of theoretical budget — leave room
const CLAMP_MARGIN: float = 60.0
const Y_MIN: float = CLAMP_MARGIN
const Y_MAX: float = CANVAS_H - CLAMP_MARGIN
const GAP_MAX_PX: float = 280.0
const GAP_MIN_PX: float = 200.0
# Centre-to-centre danger half-height (px) for avoidable point hazards.
const EXCL_HALF: Dictionary = {
	"jellyfish_drift": 128.0,  # body 40 + player 28 + ±60 drift
	"bubble_mine": 84.0,       # body 56 + player 28
	"crystal_shard": 68.0,     # capsule half 40 + player 28
}


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

	# ── Reachable-band movement check (gates + avoidable point hazards) ───────
	errors.append_array(_reachability_errors(beat_map, base_bpm, bpm_changes))

	# Active gates, needed below for speed-zone readability.
	var gates: Array[Dictionary] = []
	for entry: Variant in beat_map:
		var e: Dictionary = entry as Dictionary
		if _is_active_positional(e):
			gates.append(e)

	gates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("beat_index", 0)) < float(b.get("beat_index", 0))
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


# ── Reachable-band engine ─────────────────────────────────────────────────────
# Intervals are Vector2(lo, hi) in px; a band is an Array[Vector2], sorted/disjoint.

## Safe centre-band for a gate, or Vector2(-1,-1) if open water / no gap.
static func _gate_corridor(entry: Dictionary) -> Vector2:
	var otype: String = str(entry.get("obstacle_type", ""))
	if not (otype in POSITIONAL_TYPES):
		return Vector2(-1.0, -1.0)
	var y: float = _get_gap_y(entry)
	if y < 0.0:
		return Vector2(-1.0, -1.0)
	var intensity: float = float((entry.get("parameters", {}) as Dictionary).get("intensity", 0.5))
	if otype == "pressure_wall" and intensity <= SKIP_INTENSITY:
		return Vector2(-1.0, -1.0)
	var gap_px: float = lerpf(GAP_MAX_PX, GAP_MIN_PX, clampf(intensity, 0.0, 1.0))
	var center: float = clampf(y * CANVAS_H, gap_px * 0.5 + 40.0, CANVAS_H - gap_px * 0.5 - 40.0)
	return Vector2(center - gap_px * 0.5 + PLAYER_HALF, center + gap_px * 0.5 - PLAYER_HALF)


static func _merge(bands: Array) -> Array:
	var cleaned: Array = []
	for iv: Vector2 in bands:
		if iv.y - iv.x > EPS:
			cleaned.append(iv)
	cleaned.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	if cleaned.is_empty():
		return []
	var out: Array = [cleaned[0]]
	for k: int in range(1, cleaned.size()):
		var iv: Vector2 = cleaned[k]
		var last: Vector2 = out[-1]
		if iv.x <= last.y + EPS:
			out[-1] = Vector2(last.x, maxf(last.y, iv.y))
		else:
			out.append(iv)
	return out


static func _intersect(bands: Array, lo: float, hi: float) -> Array:
	if hi - lo <= EPS:
		return []
	var out: Array = []
	for iv: Vector2 in bands:
		out.append(Vector2(maxf(iv.x, lo), minf(iv.y, hi)))
	return _merge(out)


static func _subtract(bands: Array, lo: float, hi: float) -> Array:
	var out: Array = []
	for iv: Vector2 in bands:
		if hi <= iv.x + EPS or lo >= iv.y - EPS:
			out.append(iv)
			continue
		if iv.x < lo - EPS:
			out.append(Vector2(iv.x, lo))
		if iv.y > hi + EPS:
			out.append(Vector2(hi, iv.y))
	return _merge(out)


## Forward-propagate the feasible height-band through every gate and avoidable
## point hazard. Returns an error string for each beat where no safe path exists.
static func _reachability_errors(beat_map: Array, base_bpm: float, bpm_changes: Array[Dictionary]) -> Array[String]:
	var events: Array[Dictionary] = []
	for entry: Variant in beat_map:
		var e: Dictionary = entry as Dictionary
		var is_gate: bool = _gate_corridor(e).x >= 0.0
		var is_haz: bool = EXCL_HALF.has(str(e.get("obstacle_type", "")))
		if is_gate or is_haz:
			events.append(e)
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("beat_index", 0)) < float(b.get("beat_index", 0))
	)

	var errors: Array[String] = []
	if events.is_empty():
		return errors

	var bands: Array = [Vector2(Y_MIN, Y_MAX)]
	var prev_beat: float = float(events[0].get("beat_index", 0))
	var idx: int = 0
	while idx < events.size():
		var beat: float = float(events[idx].get("beat_index", 0))
		# Collect all events on this beat.
		var group: Array[Dictionary] = []
		while idx < events.size() and absf(float(events[idx].get("beat_index", 0)) - beat) < EPS:
			group.append(events[idx])
			idx += 1

		if beat > prev_beat:
			var dt: float = _beats_to_seconds(prev_beat, beat, base_bpm, bpm_changes)
			var rise: float = FLOAT_TERMINAL * dt * SAFETY
			var dive: float = DIVE_TERMINAL * dt * SAFETY
			var expanded: Array = []
			for iv: Vector2 in bands:
				expanded.append(Vector2(maxf(Y_MIN, iv.x - rise), minf(Y_MAX, iv.y + dive)))
			bands = _merge(expanded)
		prev_beat = beat

		for e: Dictionary in group:
			var corridor: Vector2 = _gate_corridor(e)
			if corridor.x >= 0.0:
				bands = _intersect(bands, corridor.x, corridor.y)
			else:
				var hy: float = _get_gap_y(e)
				if hy < 0.0:
					hy = 0.5
				var h: float = float(EXCL_HALF[str(e.get("obstacle_type", ""))])
				bands = _subtract(bands, hy * CANVAS_H - h, hy * CANVAS_H + h)

		if bands.is_empty():
			errors.append(
				"Beat %.1f: no reachable path — player cannot be anywhere safe on this beat." % beat
			)
			bands = [Vector2(Y_MIN, Y_MAX)]   # reset to surface further independent breaks

	return errors
