#!/usr/bin/env python3
"""
Check movement constraints in .brl level files.

REACHABLE-BAND ENGINE
---------------------
Rather than checking gates pairwise (which ignored the point hazards sitting
between them), we propagate the *set of heights the player can occupy* forward
through every obstacle in beat order. This is standard forward-reachability
analysis and is the only consistent way to prove a level is beatable.

  time between events  t   = Δbeats × (60 / BPM)            [beat-clock accurate]
  rise budget (px)         = max_float_speed (700)  × t × SAFETY
  dive budget (px)         = max_dive_speed  (1100) × t × SAFETY

State is a list of feasible height-intervals (usually one, but a point hazard
can split it into two — which is exactly how an upper/lower "choose your path"
section is validated). Each step:

  1. EXPAND every interval by the budgets   [lo - rise, hi + dive]  (up is -y)
  2. At each obstacle on this beat:
       - GATE  (pressure_wall / kelp_curtain): INTERSECT with its gap corridor
       - POINT HAZARD (jellyfish / mine / shard): SUBTRACT its exclusion band
  3. Drop empty intervals. If none remain → the level is IMPOSSIBLE here.

SAFETY (<1.0) leaves a little slack so sections are hard but not frame-perfect.

Geometry mirrors ObstacleSpawner.gd exactly:
  gap_px      = lerp(280, 200, effective_intensity)
  corridor    = [center - gap/2 + PLAYER_HALF, center + gap/2 - PLAYER_HALF]
  hazard band = [y - EXCL_HALF[type], y + EXCL_HALF[type]]   (EXCL incl. player)

Reactive / screen-spanning hazards (mirror_fish, lava_burst, current_jet,
anchor_chain, eel_snap, dark_void, gravity_well) are NOT simple vertical-position
gates and are left out of the band (they are handled by their own runtime logic);
the band still validates the gates and avoidable point hazards around them.

Speed-zone readability rules (checked independently):
  - On-screen lead time ≥ 1.0 s per gate: (CANVAS_W - JUDGMENT_X) / (408 × mult) ≥ 1.0
  - Multiplier > 1.3: consecutive positional gates must be ≥ 2 beats apart

Usage:
  python3 tools/check_movements.py assets/levels/z2-l1.brl [more...]
  python3 tools/check_movements.py assets/levels/          # whole directory
"""

import json
import os
import sys

SCREEN_H: float = 1920.0
CANVAS_W: float = 1080.0
JUDGMENT_X: float = 200.0
BASE_SPEED: float = 408.0
FLOAT_TERMINAL: float = 700.0   # px/s, matches PlayerController.max_float_speed
DIVE_TERMINAL: float = 1100.0   # px/s, matches PlayerController.max_dive_speed
SKIP_INTENSITY: float = 0.08    # matches ObstacleSpawner.SKIP_INTENSITY
# Float subtraction epsilon — prevents false positives when delta == budget exactly
EPS: float = 1e-9

# ── Reachable-band geometry (mirrors ObstacleSpawner.gd + Player.tscn) ─────────
PLAYER_HALF: float = 28.0       # px, half of the 56px player capsule height
SAFETY: float = 0.90            # use 90% of theoretical budget — leave a little room
CLAMP_MARGIN: float = 60.0      # PlayerController clamps centre to [60, H-60]
Y_MIN: float = CLAMP_MARGIN
Y_MAX: float = SCREEN_H - CLAMP_MARGIN
GAP_MAX_PX: float = 280.0       # easiest gate gap
GAP_MIN_PX: float = 200.0       # hardest gate gap

# Centre-to-centre danger half-height (px) for avoidable POINT hazards.
# Already includes PLAYER_HALF; jellyfish adds its ±drift sweep.
EXCL_HALF = {
    # Jelly sweeps its full ±60 drift by the time it reaches the player, so the
    # honest danger band is body(40) + player(28) + drift(60).
    "jellyfish_drift": 40.0 + PLAYER_HALF + 60.0,
    "bubble_mine": 56.0 + PLAYER_HALF,             # body 56 + player 28
    "crystal_shard": 40.0 + PLAYER_HALF,           # capsule half 40 + player 28
}
POINT_HAZARDS = set(EXCL_HALF)

POSITIONAL_TYPES = {"pressure_wall", "kelp_curtain"}


def get_bpm_at_beat(beat_index: float, base_bpm: float, bpm_changes: list) -> float:
    """Interpolate BPM at a fractional beat for variable-BPM levels."""
    if not bpm_changes:
        return base_bpm
    current_bpm = base_bpm
    for change in bpm_changes:
        change_beat = float(change["beat_index"])
        if change_beat > beat_index:
            break
        new_bpm = float(change["new_bpm"])
        transition = float(change.get("transition_beats", 0))
        if transition > 0.0 and beat_index < change_beat + transition:
            t = (beat_index - change_beat) / transition
            t = max(0.0, min(1.0, t))
            current_bpm = current_bpm + (new_bpm - current_bpm) * t
        else:
            current_bpm = new_bpm
    return current_bpm


def beat_duration_seconds(beat: float, base_bpm: float, bpm_changes: list) -> float:
    """Duration in seconds of the beat starting at integer beat index."""
    bpm = get_bpm_at_beat(beat, base_bpm, bpm_changes)
    return 60.0 / bpm


def beats_to_seconds(from_beat: float, to_beat: float, base_bpm: float, bpm_changes: list) -> float:
    """Integrate beat durations from from_beat to to_beat (integer steps)."""
    total = 0.0
    b = int(from_beat)
    while b < int(to_beat):
        total += beat_duration_seconds(float(b), base_bpm, bpm_changes)
        b += 1
    # Fractional remainder of the last beat
    frac = to_beat - int(to_beat)
    if frac > 0.0:
        total += frac * beat_duration_seconds(float(int(to_beat)), base_bpm, bpm_changes)
    return total


def get_speed_multiplier_at_beat(beat: float, speed_zones: list) -> float:
    """Return the speed multiplier active at the given beat index."""
    for zone in speed_zones:
        if float(zone["start_beat"]) <= beat < float(zone["end_beat"]):
            return float(zone["speed_multiplier"])
    return 1.0


def get_gap_y(entry: dict) -> float | None:
    """Extract gap centre Y (normalised) from a beat_map entry."""
    params = entry.get("parameters") or {}
    y = params.get("gap_y_normalized")
    if y is None:
        y = entry.get("lane_position")
    return float(y) if y is not None else None


def is_active_positional(entry: dict) -> bool:
    """True iff this entry is a spawned positional gate (not rest, not mine, not jellyfish)."""
    otype = entry.get("obstacle_type", "")
    if otype not in POSITIONAL_TYPES:
        return False
    if get_gap_y(entry) is None:
        return False
    if otype == "pressure_wall":
        intensity = float((entry.get("parameters") or {}).get("intensity", 1.0))
        if intensity <= SKIP_INTENSITY:
            return False
    return True


# ── Interval algebra (lists of (lo, hi) px intervals, kept sorted & disjoint) ──

def _merge(intervals: list) -> list:
    """Merge overlapping/touching intervals; drop empty ones."""
    cleaned = [(lo, hi) for lo, hi in intervals if hi - lo > EPS]
    if not cleaned:
        return []
    cleaned.sort()
    out = [cleaned[0]]
    for lo, hi in cleaned[1:]:
        if lo <= out[-1][1] + EPS:
            out[-1] = (out[-1][0], max(out[-1][1], hi))
        else:
            out.append((lo, hi))
    return out


def _intersect(intervals: list, lo: float, hi: float) -> list:
    """Intersect every interval with [lo, hi]."""
    if hi - lo <= EPS:
        return []
    out = [(max(a, lo), min(b, hi)) for a, b in intervals]
    return _merge(out)


def _subtract(intervals: list, lo: float, hi: float) -> list:
    """Remove the open band (lo, hi) from every interval — may split intervals."""
    out = []
    for a, b in intervals:
        if hi <= a + EPS or lo >= b - EPS:   # no overlap
            out.append((a, b))
            continue
        if a < lo - EPS:                     # left remainder
            out.append((a, lo))
        if b > hi + EPS:                     # right remainder
            out.append((hi, b))
    return _merge(out)


def gate_corridor(entry: dict) -> tuple | None:
    """Safe centre-band (px) for a gate, or None if it is open water / no gap."""
    otype = entry.get("obstacle_type", "")
    if otype not in POSITIONAL_TYPES:
        return None
    y = get_gap_y(entry)
    if y is None:
        return None
    params = entry.get("parameters") or {}
    intensity = float(params.get("intensity", 0.5))
    if otype == "pressure_wall" and intensity <= SKIP_INTENSITY:
        return None  # rest gate → open water, no constraint
    gap_px = GAP_MAX_PX + (GAP_MIN_PX - GAP_MAX_PX) * max(0.0, min(1.0, intensity))
    center = max(gap_px * 0.5 + 40.0, min(SCREEN_H - gap_px * 0.5 - 40.0, y * SCREEN_H))
    lo = center - gap_px * 0.5 + PLAYER_HALF
    hi = center + gap_px * 0.5 - PLAYER_HALF
    return (lo, hi)


def reachability_errors(data: dict, base_bpm: float, bpm_changes: list) -> list:
    """Forward-propagate the feasible height-band; report where it empties."""
    events = [e for e in data.get("beat_map", [])
              if gate_corridor(e) is not None or e.get("obstacle_type") in POINT_HAZARDS]
    events.sort(key=lambda e: float(e["beat_index"]))
    if not events:
        return []

    # Group by beat so simultaneous obstacles are applied together.
    groups: list = []
    for e in events:
        b = float(e["beat_index"])
        if groups and abs(groups[-1][0] - b) < EPS:
            groups[-1][1].append(e)
        else:
            groups.append((b, [e]))

    bands = [(Y_MIN, Y_MAX)]
    prev_beat = groups[0][0]
    errors: list = []

    for beat, group in groups:
        if beat > prev_beat:
            dt = beats_to_seconds(prev_beat, beat, base_bpm, bpm_changes)
            rise = FLOAT_TERMINAL * dt * SAFETY
            dive = DIVE_TERMINAL * dt * SAFETY
            bands = _merge([(max(Y_MIN, lo - rise), min(Y_MAX, hi + dive)) for lo, hi in bands])
        prev_beat = beat

        for e in group:
            corridor = gate_corridor(e)
            if corridor is not None:
                bands = _intersect(bands, corridor[0], corridor[1])
            else:  # point hazard
                y = (get_gap_y(e) or 0.5) * SCREEN_H
                h = EXCL_HALF[e["obstacle_type"]]
                bands = _subtract(bands, y - h, y + h)

        if not bands:
            kinds = ", ".join(sorted({str(e.get("obstacle_type")) for e in group}))
            errors.append(
                f"  B{beat:.1f}: no reachable path through [{kinds}] "
                f"— player cannot be anywhere safe on this beat"
            )
            # Reset to full band so we can surface additional independent breaks.
            bands = [(Y_MIN, Y_MAX)]

    return errors


def apply_difficulty_patch(data: dict, difficulty: str) -> dict:
    """Return a copy of data with obstacle params adjusted for Easy/Normal/Hard."""
    if difficulty == "normal":
        return data
    import copy
    patched = dict(data)
    patched["beat_map"] = []
    for entry in data.get("beat_map", []):
        e = dict(entry)
        otype = e.get("obstacle_type", "")
        if otype in ("pressure_wall", "kelp_curtain"):
            params = dict(e.get("parameters") or {})
            if otype == "pressure_wall":
                delta = 0.12 if difficulty == "hard" else -0.12
                intensity = float(params.get("intensity", 0.5)) + delta
                params["intensity"] = max(0.18, min(1.0, intensity))
            elif otype == "kelp_curtain":
                delta = -60.0 if difficulty == "hard" else 60.0
                gh = float(params.get("gap_height", 240.0)) + delta
                params["gap_height"] = max(120.0, min(500.0, gh))
            e["parameters"] = params
        patched["beat_map"].append(e)
    return patched


def band_at_beat(data: dict, target_beat: float, base_bpm: float, bpm_changes: list) -> list:
    """Return reachable bands (list of (lo,hi)) at target_beat using the beat_map in data."""
    events = [e for e in data.get("beat_map", [])
              if gate_corridor(e) is not None or e.get("obstacle_type") in POINT_HAZARDS]
    events = [e for e in events if float(e["beat_index"]) <= target_beat + EPS]
    events.sort(key=lambda e: float(e["beat_index"]))

    bands = [(Y_MIN, Y_MAX)]
    if not events:
        if target_beat > 0.0:
            dt = beats_to_seconds(0.0, target_beat, base_bpm, bpm_changes)
            rise = FLOAT_TERMINAL * dt * SAFETY
            dive = DIVE_TERMINAL * dt * SAFETY
            bands = _merge([(max(Y_MIN, lo - rise), min(Y_MAX, hi + dive)) for lo, hi in bands])
        return bands

    groups: list = []
    for e in events:
        b = float(e["beat_index"])
        if groups and abs(groups[-1][0] - b) < EPS:
            groups[-1][1].append(e)
        else:
            groups.append([b, [e]])

    prev_beat = groups[0][0]
    for beat, group in groups:
        if beat > prev_beat:
            dt = beats_to_seconds(prev_beat, beat, base_bpm, bpm_changes)
            rise = FLOAT_TERMINAL * dt * SAFETY
            dive = DIVE_TERMINAL * dt * SAFETY
            bands = _merge([(max(Y_MIN, lo - rise), min(Y_MAX, hi + dive)) for lo, hi in bands])
        prev_beat = beat
        for e in group:
            corridor = gate_corridor(e)
            if corridor is not None:
                bands = _intersect(bands, corridor[0], corridor[1])
            else:
                y = (get_gap_y(e) or 0.5) * SCREEN_H
                h = EXCL_HALF[e["obstacle_type"]]
                bands = _subtract(bands, y - h, y + h)
        if not bands:
            return []

    if target_beat > prev_beat + EPS:
        dt = beats_to_seconds(prev_beat, target_beat, base_bpm, bpm_changes)
        rise = FLOAT_TERMINAL * dt * SAFETY
        dive = DIVE_TERMINAL * dt * SAFETY
        bands = _merge([(max(Y_MIN, lo - rise), min(Y_MAX, hi + dive)) for lo, hi in bands])

    return bands


def pearl_reachability_errors(data: dict, base_bpm: float, bpm_changes: list) -> list:
    """Check every pearl in collectibles against the reachable band at its beat."""
    errors: list[str] = []
    for pearl in data.get("collectibles", []):
        if pearl.get("collectible_type") != "pearl":
            continue
        pb = float(pearl["beat_index"])
        lane = float(pearl.get("lane_position", 0.5))
        py = lane * SCREEN_H
        bands = band_at_beat(data, pb, base_bpm, bpm_changes)
        reachable = any(lo - EPS <= py <= hi + EPS for lo, hi in bands)
        if not reachable:
            if bands:
                band_str = f"{bands[0][0]:.0f}–{bands[-1][1]:.0f}px"
                mid = (bands[0][0] + bands[-1][1]) * 0.5 / SCREEN_H
                hint = f"  Suggested lane: {mid:.2f}"
            else:
                band_str = "no path (level unbeatable before this beat)"
                hint = ""
            errors.append(
                f"  B{pb:.1f}: pearl lane={lane:.2f} (y={py:.0f}px) unreachable — band [{band_str}].{hint}"
            )
    return errors


def check_file(path: str) -> bool:
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        print(f"FAIL  {os.path.relpath(path)}  (cannot parse: {exc})")
        return False

    meta = data["metadata"]
    base_bpm = float(meta["bpm"])
    is_variable = bool(meta.get("bpm_variable", False))
    bpm_changes = meta.get("bpm_changes", []) if is_variable else []
    speed_zones = data.get("speed_zones", [])
    label = os.path.relpath(path)
    all_ok = True

    for difficulty in ("normal", "easy", "hard"):
        patched = apply_difficulty_patch(data, difficulty)
        gates = [e for e in patched.get("beat_map", []) if is_active_positional(e)]
        gates.sort(key=lambda e: float(e["beat_index"]))

        errors: list[str] = []

        # ── Reachable-band check (gates + avoidable point hazards) ────────────
        errors.extend(reachability_errors(patched, base_bpm, bpm_changes))

        # ── Pearl reachability check ──────────────────────────────────────────
        errors.extend(pearl_reachability_errors(patched, base_bpm, bpm_changes))

        # ── Speed-zone readability check (Normal only — speed zones don't change) ─
        if difficulty == "normal":
            for i, gate in enumerate(gates):
                beat = float(gate["beat_index"])
                mult = get_speed_multiplier_at_beat(beat, speed_zones)
                if mult <= 0.0:
                    continue
                lead_time_s = (CANVAS_W - JUDGMENT_X) / (BASE_SPEED * mult)
                if lead_time_s < 1.0 - EPS:
                    errors.append(
                        f"  B{beat:.1f}: speed mult {mult:.2f}× → lead time {lead_time_s:.2f}s < 1.0s"
                    )
                if mult > 1.3 and i + 1 < len(gates):
                    next_beat = float(gates[i + 1]["beat_index"])
                    gap_beats = next_beat - beat
                    if gap_beats < 2.0 - EPS:
                        errors.append(
                            f"  B{beat:.1f}: speed mult {mult:.2f}× > 1.3 but next gate only "
                            f"{gap_beats:.1f} beats away (need ≥ 2)"
                        )

        if errors:
            print(f"FAIL  {label}  [{difficulty}]  (BPM={base_bpm:.0f})")
            for e in errors:
                print(e)
            all_ok = False

    if all_ok:
        normal_gates = [e for e in data.get("beat_map", []) if is_active_positional(e)]
        print(f"PASS  {label}  (BPM={base_bpm:.0f}, {len(normal_gates)} active positional obstacles)")
    return all_ok


def collect_paths(args: list[str]) -> list[str]:
    paths: list[str] = []
    for arg in args:
        if os.path.isdir(arg):
            for fn in sorted(os.listdir(arg)):
                if fn.endswith(".brl"):
                    paths.append(os.path.join(arg, fn))
        elif os.path.isfile(arg) and arg.endswith(".brl"):
            paths.append(arg)
    return paths


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print("Usage: python3 tools/check_movements.py <file.brl>... or <directory>")
        return 1

    paths = collect_paths(args)
    if not paths:
        print("No .brl files found.")
        return 1

    passed = 0
    for p in paths:
        if check_file(p):
            passed += 1

    failed = len(paths) - passed
    print(f"\n{passed}/{len(paths)} files passed movement check.")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
