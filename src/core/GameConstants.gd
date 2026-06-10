## GameConstants.gd
## Single source of truth for all research-derived non-negotiable game values.
## Reference these from GDScript; the Python tools mirror them in their own comments.
extends Node

# ---------------------------------------------------------------------------
# Canvas / coordinate space
# ---------------------------------------------------------------------------

const CANVAS_W: float = 1080.0
const CANVAS_H: float = 1920.0

# ---------------------------------------------------------------------------
# Scroll
# ---------------------------------------------------------------------------

## Base horizontal scroll speed in canvas px/s. All obstacles move left at this
## rate unless a ScrollService speed-zone multiplier is active (Phase 4).
const SCROLL_SPEED: float = 408.0

# ---------------------------------------------------------------------------
# Player physics (research-derived, never change without full re-tuning)
# ---------------------------------------------------------------------------

const PLAYER_FLOAT_FORCE: float = 480.0
const PLAYER_DIVE_FORCE: float = 1220.0
const PLAYER_MAX_FLOAT_SPEED: float = 480.0
const PLAYER_MAX_DIVE_SPEED: float = 720.0
const PLAYER_DRAG: float = 0.983
const PLAYER_DIVE_IMPULSE: float = 480.0

## Canvas-px height of the player collision capsule.
const PLAYER_HEIGHT_PX: float = 56.0

## Y margin from canvas top/bottom walls before the player is clamped.
const PLAYER_CLAMP_MARGIN: float = 60.0

# ---------------------------------------------------------------------------
# Timing windows
# ---------------------------------------------------------------------------

const TIMING_PERFECT_HALF_MS: float = 80.0
const TIMING_GOOD_OUTER_HALF_MS: float = 160.0

# ---------------------------------------------------------------------------
# Obstacle spawn geometry
# ---------------------------------------------------------------------------

## Gap size range in canvas px for pressure_wall gates.
const GATE_GAP_MAX_PX: float = 280.0
const GATE_GAP_MIN_PX: float = 200.0

## Width (px) of a single CoralSpike.
const SPIKE_WIDTH_PX: float = 60.0

## Minimum DDA intensity that still spawns a gap (below this → skip obstacle).
const SKIP_INTENSITY: float = 0.08

## How many beats ahead the spawner places entities so they arrive on-beat.
const SPAWN_LOOKAHEAD_BEATS: float = 4.0
