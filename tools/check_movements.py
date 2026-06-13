#!/usr/bin/env python3
"""
Check movement constraints in .brl level files.

For each consecutive pair of active positional obstacles (pressure_wall,
kelp_curtain), verifies the player can physically reach the next gap_y from
the previous one within the given beat window. Uses research-derived physics:

  max_up_per_beat   = (float_terminal_px_s * beat_s) / screen_h
                    = (700 * 60/bpm_at_that_beat) / 1920
  max_down_per_beat = (dive_terminal_px_s * beat_s) / screen_h
                    = (1100 * 60/bpm_at_that_beat) / 1920

For variable-BPM levels (bpm_variable=true), per-beat BPM is interpolated
from bpm_changes so that budget calculations are always beat-clock accurate.
Speed zones change horizontal scroll speed but NOT the beat clock, so vertical
budgets are computed from beat durations only (speed multipliers are excluded).

Speed-zone readability rules (checked independently of movement budgets):
  - On-screen lead time ≥ 1.0 s per gate: (CANVAS_W - JUDGMENT_X) / (408 × mult) ≥ 1.0
  - Multiplier > 1.3: consecutive positional gates must be ≥ 2 beats apart

Rest gates (pressure_wall intensity <= SKIP_INTENSITY) are excluded — they
produce open water and impose no positional constraint.
BubbleMines and jellyfish_drift are point hazards (not positional gates) and
are also excluded from consecutive-gap analysis.

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

    gates = [e for e in data.get("beat_map", []) if is_active_positional(e)]
    gates.sort(key=lambda e: float(e["beat_index"]))

    errors: list[str] = []

    # ── Movement budget check ─────────────────────────────────────────────────
    for i in range(1, len(gates)):
        prev, curr = gates[i - 1], gates[i]
        b_prev = float(prev["beat_index"])
        b_curr = float(curr["beat_index"])
        beats = b_curr - b_prev
        if beats <= 0:
            continue

        actual_seconds = beats_to_seconds(b_prev, b_curr, base_bpm, bpm_changes)
        max_up   = (FLOAT_TERMINAL * actual_seconds) / SCREEN_H
        max_down = (DIVE_TERMINAL  * actual_seconds) / SCREEN_H

        y0, y1 = get_gap_y(prev), get_gap_y(curr)
        delta = y1 - y0  # positive = downward

        if delta < -(max_up + EPS):
            errors.append(
                f"  B{b_prev:.1f}({y0:.3f}) → B{b_curr:.1f}({y1:.3f}): "
                f"up Δ {-delta:.4f} > budget {max_up:.4f}  "
                f"({beats:.1f} beats, {actual_seconds:.3f}s)"
            )
        elif delta > max_down + EPS:
            errors.append(
                f"  B{b_prev:.1f}({y0:.3f}) → B{b_curr:.1f}({y1:.3f}): "
                f"down Δ {delta:.4f} > budget {max_down:.4f}  "
                f"({beats:.1f} beats, {actual_seconds:.3f}s)"
            )

    # ── Speed-zone readability check ─────────────────────────────────────────
    for i, gate in enumerate(gates):
        beat = float(gate["beat_index"])
        mult = get_speed_multiplier_at_beat(beat, speed_zones)
        if mult <= 0.0:
            continue

        # Rule 1: on-screen lead time ≥ 1.0s
        lead_time_s = (CANVAS_W - JUDGMENT_X) / (BASE_SPEED * mult)
        if lead_time_s < 1.0 - EPS:
            errors.append(
                f"  B{beat:.1f}: speed mult {mult:.2f}× → lead time {lead_time_s:.2f}s < 1.0s"
            )

        # Rule 2: mult > 1.3 → next gate must be ≥ 2 beats away
        if mult > 1.3 and i + 1 < len(gates):
            next_beat = float(gates[i + 1]["beat_index"])
            gap_beats = next_beat - beat
            if gap_beats < 2.0 - EPS:
                errors.append(
                    f"  B{beat:.1f}: speed mult {mult:.2f}× > 1.3 but next gate only {gap_beats:.1f} beats away (need ≥ 2)"
                )

    label = os.path.relpath(path)
    if errors:
        print(f"FAIL  {label}  (BPM={base_bpm:.0f}, variable={is_variable})")
        for e in errors:
            print(e)
        return False

    print(f"PASS  {label}  (BPM={base_bpm:.0f}, {len(gates)} active positional obstacles)")
    return True


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
