#!/usr/bin/env python3
"""
drop_assets.py — Bubble Reef Rush art drop-in organizer.

Drag all downloaded images into one staging folder, then run:
    python3 tools/drop_assets.py /path/to/your/staging/folder

The script matches filenames (fuzzy, case-insensitive) to their correct
game destinations and copies them there. It prints a summary of what moved
and what it couldn't match so you know exactly what needs renaming.

Destinations are relative to the repo root. Run from the repo root or
pass --repo /path/to/repo as a second argument.
"""

import os
import sys
import shutil
import argparse
from pathlib import Path

# ---------------------------------------------------------------------------
# Mapping: (keywords that must ALL appear in filename) -> destination path
# Add new entries here as more art is generated.
# ---------------------------------------------------------------------------
RULES = [
    # ── Characters ──────────────────────────────────────────────────────────
    (["player", "base"],        "assets/characters/player.png"),
    (["player", "swim"],        "assets/characters/player_swim.png"),
    (["player", "dive"],        "assets/characters/player_dive.png"),
    (["player", "death"],       "assets/characters/player_death.png"),

    # ── Zone 1 backgrounds ───────────────────────────────────────────────────
    (["z1", "l0"],              "assets/backgrounds/z1_bg_l0.png"),
    (["z1", "l1"],              "assets/backgrounds/z1_bg_l1.png"),
    (["z1", "l2"],              "assets/backgrounds/z1_bg_l2.png"),
    (["z1", "l3"],              "assets/backgrounds/z1_bg_l3.png"),
    (["z1", "l4"],              "assets/backgrounds/z1_bg_l4.png"),
    (["z1", "l5"],              "assets/backgrounds/z1_bg_l5.png"),

    # ── Zone 2 backgrounds ───────────────────────────────────────────────────
    (["z2", "l0"],              "assets/backgrounds/z2_bg_l0.png"),
    (["z2", "l1"],              "assets/backgrounds/z2_bg_l1.png"),
    (["z2", "l2"],              "assets/backgrounds/z2_bg_l2.png"),
    (["z2", "l3"],              "assets/backgrounds/z2_bg_l3.png"),
    (["z2", "l4"],              "assets/backgrounds/z2_bg_l4.png"),
    (["z2", "l5"],              "assets/backgrounds/z2_bg_l5.png"),

    # ── Zone 3 backgrounds ───────────────────────────────────────────────────
    (["z3", "l0"],              "assets/backgrounds/z3_bg_l0.png"),
    (["z3", "l1"],              "assets/backgrounds/z3_bg_l1.png"),
    (["z3", "l2"],              "assets/backgrounds/z3_bg_l2.png"),
    (["z3", "l3"],              "assets/backgrounds/z3_bg_l3.png"),
    (["z3", "l4"],              "assets/backgrounds/z3_bg_l4.png"),
    (["z3", "l5"],              "assets/backgrounds/z3_bg_l5.png"),

    # ── Zone 4 backgrounds ───────────────────────────────────────────────────
    (["z4", "l0"],              "assets/backgrounds/z4_bg_l0.png"),
    (["z4", "l1"],              "assets/backgrounds/z4_bg_l1.png"),
    (["z4", "l2"],              "assets/backgrounds/z4_bg_l2.png"),
    (["z4", "l3"],              "assets/backgrounds/z4_bg_l3.png"),
    (["z4", "l4"],              "assets/backgrounds/z4_bg_l4.png"),
    (["z4", "l5"],              "assets/backgrounds/z4_bg_l5.png"),

    # ── Zone 5 backgrounds ───────────────────────────────────────────────────
    (["z5", "l0"],              "assets/backgrounds/z5_bg_l0.png"),
    (["z5", "l1"],              "assets/backgrounds/z5_bg_l1.png"),
    (["z5", "l2"],              "assets/backgrounds/z5_bg_l2.png"),
    (["z5", "l3"],              "assets/backgrounds/z5_bg_l3.png"),
    (["z5", "l4"],              "assets/backgrounds/z5_bg_l4.png"),
    (["z5", "l5"],              "assets/backgrounds/z5_bg_l5.png"),

    # ── Zone 6 backgrounds ───────────────────────────────────────────────────
    (["z6", "l0"],              "assets/backgrounds/z6_bg_l0.png"),
    (["z6", "l1"],              "assets/backgrounds/z6_bg_l1.png"),
    (["z6", "l2"],              "assets/backgrounds/z6_bg_l2.png"),
    (["z6", "l3"],              "assets/backgrounds/z6_bg_l3.png"),
    (["z6", "l4"],              "assets/backgrounds/z6_bg_l4.png"),
    (["z6", "l5"],              "assets/backgrounds/z6_bg_l5.png"),

    # ── Obstacle sprites ─────────────────────────────────────────────────────
    (["coral", "tip"],          "assets/obstacles/coral_spike_tip.png"),
    (["coral", "body"],         "assets/obstacles/coral_spike_body.png"),
    (["coral", "base"],         "assets/obstacles/coral_spike_base.png"),
    (["jellyfish"],             "assets/obstacles/jellyfish_drift.png"),
    (["bubble", "mine"],        "assets/obstacles/bubble_mine.png"),
    (["eel"],                   "assets/obstacles/eel_snap.png"),
    (["anchor"],                "assets/obstacles/anchor_chain.png"),
    (["mirror", "fish"],        "assets/obstacles/mirror_fish.png"),
    (["lava", "burst"],         "assets/obstacles/lava_burst.png"),
    (["pressure", "wall"],      "assets/obstacles/pressure_wall.png"),
    (["dark", "void"],          "assets/obstacles/dark_void.png"),
    (["kelp", "curtain"],       "assets/obstacles/kelp_curtain.png"),

    # ── UI sprites ───────────────────────────────────────────────────────────
    (["palette", "coral"],      "assets/ui/palette/coral_spike.png"),
    (["palette", "jelly"],      "assets/ui/palette/jellyfish_drift.png"),
    (["palette", "mine"],       "assets/ui/palette/bubble_mine.png"),
]


def match_file(filename: str):
    """Return (destination, matched_keywords) for the first matching rule."""
    lower = filename.lower()
    for keywords, dest in RULES:
        if all(kw in lower for kw in keywords):
            return dest, keywords
    return None, None


def main():
    parser = argparse.ArgumentParser(description="Auto-sort Bubble Reef Rush art assets.")
    parser.add_argument("staging", help="Folder containing downloaded images")
    parser.add_argument("--repo", default=".", help="Repo root (default: current directory)")
    parser.add_argument("--dry-run", action="store_true", help="Show what would happen without copying")
    args = parser.parse_args()

    staging = Path(args.staging).expanduser().resolve()
    repo = Path(args.repo).expanduser().resolve()

    if not staging.is_dir():
        print(f"ERROR: staging folder not found: {staging}")
        sys.exit(1)

    images = sorted(p for p in staging.iterdir()
                    if p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"})

    if not images:
        print(f"No images found in {staging}")
        sys.exit(0)

    moved = []
    skipped = []
    unmatched = []

    for src in images:
        dest_rel, keywords = match_file(src.name)
        if dest_rel is None:
            unmatched.append(src.name)
            continue

        dest_abs = repo / dest_rel
        dest_abs.parent.mkdir(parents=True, exist_ok=True)

        # Always use .png for the destination regardless of source extension.
        dest_final = dest_abs.with_suffix(".png")

        if dest_final.exists():
            print(f"  SKIP (exists): {src.name} → {dest_rel}")
            skipped.append(src.name)
            continue

        if args.dry_run:
            print(f"  WOULD COPY:   {src.name} → {dest_rel}")
        else:
            shutil.copy2(src, dest_final)
            print(f"  COPIED:       {src.name} → {dest_rel}")

        moved.append(src.name)

    print()
    print(f"{'DRY RUN — ' if args.dry_run else ''}Done.")
    print(f"  Moved:     {len(moved)}")
    print(f"  Skipped:   {len(skipped)}  (already exist)")
    print(f"  Unmatched: {len(unmatched)}")

    if unmatched:
        print()
        print("Unmatched files (add a rule or rename before re-running):")
        for name in unmatched:
            print(f"    {name}")


if __name__ == "__main__":
    main()
