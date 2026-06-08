#!/usr/bin/env python3
"""
Check movement constraints in .brl level files.

For each consecutive pair of active positional obstacles (pressure_wall,
kelp_curtain), verifies the player can physically reach the next gap_y from
the previous one within the given beat window. Uses research-derived physics:

  max_up_per_beat   = (float_terminal_px_s * beat_s) / screen_h
                    = (480 * 60/bpm) / 1920
  max_down_per_beat = (dive_terminal_px_s * beat_s) / screen_h
                    = (720 * 60/bpm) / 1920

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
FLOAT_TERMINAL: float = 480.0   # px/s, matches PlayerController.max_float_speed
DIVE_TERMINAL: float = 720.0    # px/s, matches PlayerController.max_dive_speed
SKIP_INTENSITY: float = 0.08    # matches ObstacleSpawner.SKIP_INTENSITY
# Float subtraction epsilon — prevents false positives when delta == budget exactly
# (e.g. 0.40 - 0.55 = -0.15000000000000002 in IEEE 754, not exactly -0.15).
EPS: float = 1e-9

POSITIONAL_TYPES = {"pressure_wall", "kelp_curtain"}


def get_budget(bpm: float) -> tuple[float, float]:
    """Return (max_up_norm, max_down_norm) per beat for the given BPM."""
    beat_s = 60.0 / bpm
    return (FLOAT_TERMINAL * beat_s) / SCREEN_H, (DIVE_TERMINAL * beat_s) / SCREEN_H


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
    # Rest beats open to clear water — no positional constraint
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

    bpm = float(data["metadata"]["bpm"])
    max_up, max_down = get_budget(bpm)

    gates = [e for e in data.get("beat_map", []) if is_active_positional(e)]
    gates.sort(key=lambda e: float(e["beat_index"]))

    errors: list[str] = []
    for i in range(1, len(gates)):
        prev, curr = gates[i - 1], gates[i]
        beats = float(curr["beat_index"]) - float(prev["beat_index"])
        if beats <= 0:
            continue
        y0, y1 = get_gap_y(prev), get_gap_y(curr)
        delta = y1 - y0           # positive = downward
        budget_up   = max_up   * beats
        budget_down = max_down * beats

        if delta < -(budget_up + EPS):
            errors.append(
                f"  B{prev['beat_index']}({y0:.3f}) → B{curr['beat_index']}({y1:.3f}): "
                f"up Δ {-delta:.4f} > budget {budget_up:.4f}  ({beats:.0f}-beat gap, BPM {bpm:.0f})"
            )
        elif delta > budget_down + EPS:
            errors.append(
                f"  B{prev['beat_index']}({y0:.3f}) → B{curr['beat_index']}({y1:.3f}): "
                f"down Δ {delta:.4f} > budget {budget_down:.4f}  ({beats:.0f}-beat gap, BPM {bpm:.0f})"
            )

    label = os.path.relpath(path)
    if errors:
        print(f"FAIL  {label}  (BPM={bpm:.0f}, up/beat={max_up:.4f}, down/beat={max_down:.4f})")
        for e in errors:
            print(e)
        return False

    print(f"PASS  {label}  (BPM={bpm:.0f}, {len(gates)} active positional obstacles)")
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
