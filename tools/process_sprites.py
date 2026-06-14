#!/usr/bin/env python3
"""
process_sprites.py — key out white backgrounds on game sprites.

The art was generated on solid white backgrounds. In-game, sprites need
transparency or they show as white boxes. This flood-fills the white
background (and the white gutters between frames in a sprite sheet) to
transparent, stopping at the thick black outlines of each sprite.

Backgrounds (assets/backgrounds/*) are full scenes and are LEFT ALONE.

Usage:
    python3 tools/process_sprites.py                 # process default sprite list
    python3 tools/process_sprites.py --backup        # keep <name>.orig.png copies
    python3 tools/process_sprites.py path/to/a.png   # process specific files

Approach:
  1. Walk the entire image border; wherever a border pixel is "white-ish"
     (all channels >= THRESHOLD and near-neutral), flood-fill from there.
  2. Flood-fill paints a sentinel color, expanding through connected
     white-ish pixels and halting at the dark outlines.
  3. Every sentinel pixel becomes fully transparent.
  4. A light de-halo pass knocks down alpha on the near-white fringe that
     PIL's flood tolerance leaves behind, so edges don't get a white rim.
"""

import sys
from pathlib import Path
from collections import deque
from PIL import Image

REPO = Path(__file__).resolve().parent.parent

# Default sprites to process (relative to repo root). Backgrounds excluded.
DEFAULT_TARGETS = [
    "assets/characters/player.png",
    "assets/characters/player_swim.png",
    "assets/characters/player_dive.png",
    "assets/characters/player_death.png",
    "assets/obstacles/coral_spike_tip.png",
    "assets/obstacles/coral_spike_body.png",
    "assets/obstacles/coral_spike_base.png",
    "assets/obstacles/jellyfish_drift.png",
    "assets/obstacles/bubble_mine.png",
]

WHITE_MIN = 232      # a pixel counts as background-white if every channel >= this
NEUTRAL_SPREAD = 24  # ...and max-min channel spread <= this (so it's grey/white, not a pale colour)
SENTINEL = (255, 0, 255)  # magenta marker for "this is background"


def is_whiteish(px) -> bool:
    r, g, b = px[0], px[1], px[2]
    if r < WHITE_MIN or g < WHITE_MIN or b < WHITE_MIN:
        return False
    return (max(r, g, b) - min(r, g, b)) <= NEUTRAL_SPREAD


def flood_from_borders(img: Image.Image) -> Image.Image:
    """Return an RGBA image with edge-connected white flooded to transparent."""
    rgb = img.convert("RGB")
    w, h = rgb.size
    px = rgb.load()

    visited = bytearray(w * h)  # 0 = untouched, 1 = sentinel/background
    q = deque()

    def consider(x: int, y: int) -> None:
        idx = y * w + x
        if visited[idx]:
            return
        if is_whiteish(px[x, y]):
            visited[idx] = 1
            px[x, y] = SENTINEL
            q.append((x, y))

    # Seed from every border pixel that is white-ish.
    for x in range(w):
        consider(x, 0)
        consider(x, h - 1)
    for y in range(h):
        consider(0, y)
        consider(w - 1, y)

    # 4-connected flood inward, halting at non-white (the black outlines).
    while q:
        x, y = q.popleft()
        if x > 0:
            consider(x - 1, y)
        if x < w - 1:
            consider(x + 1, y)
        if y > 0:
            consider(x, y - 1)
        if y < h - 1:
            consider(x, y + 1)

    # Build RGBA: sentinel -> transparent, keep originals otherwise.
    src = img.convert("RGBA")
    out = Image.new("RGBA", (w, h))
    sp = src.load()
    op = out.load()
    cleared = 0
    for y in range(h):
        row = y * w
        for x in range(w):
            if visited[row + x]:
                op[x, y] = (0, 0, 0, 0)
                cleared += 1
            else:
                op[x, y] = sp[x, y]
    out.info["_cleared"] = cleared
    return out


def dehalo(img: Image.Image) -> Image.Image:
    """Soften the near-white fringe left between sprite and transparency."""
    img = img.convert("RGBA")
    w, h = img.size
    p = img.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = p[x, y]
            if a == 0:
                continue
            # Opaque-but-very-pale pixel touching transparency -> fade it.
            if r >= 236 and g >= 236 and b >= 236 and (max(r, g, b) - min(r, g, b)) <= 18:
                touches_clear = False
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and p[nx, ny][3] == 0:
                        touches_clear = True
                        break
                if touches_clear:
                    p[x, y] = (r, g, b, 0)
    return img


def process(path: Path, backup: bool) -> bool:
    if not path.exists():
        print(f"  SKIP (missing): {path.relative_to(REPO)}")
        return False
    img = Image.open(path)
    keyed = flood_from_borders(img)
    cleared = keyed.info.get("_cleared", 0)
    keyed = dehalo(keyed)
    if backup:
        bak = path.with_suffix(".orig.png")
        if not bak.exists():
            Image.open(path).save(bak)
    keyed.save(path)
    total = keyed.size[0] * keyed.size[1]
    pct = 100.0 * cleared / total if total else 0.0
    print(f"  KEYED: {path.relative_to(REPO)}  ({pct:.0f}% made transparent)")
    return True


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "--backup"]
    backup = "--backup" in sys.argv[1:]
    targets = args if args else DEFAULT_TARGETS
    print("Keying white backgrounds to transparent:")
    done = 0
    for t in targets:
        p = Path(t)
        if not p.is_absolute():
            p = REPO / t
        if process(p, backup):
            done += 1
    print(f"Done. {done} sprite(s) processed.")


if __name__ == "__main__":
    main()
