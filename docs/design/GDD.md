# Bubble Reef Rush — Game Design Document
**Version:** 1.0  
**Author:** C-1 Game Designer  
**Engine:** Godot 4.x  
**Platforms:** Android (primary), iOS  
**Target Audience:** Kids ages 6–12  
**Rating Target:** ESRB E / PEGI 3  

---

## Table of Contents
1. [Core Loop](#1-core-loop)
2. [Obstacle Types](#2-obstacle-types)
3. [Zone Progression](#3-zone-progression)
4. [Character System](#4-character-system)
5. [Scoring System](#5-scoring-system)
6. [Build Mode Rules](#6-build-mode-rules)
7. [Economy](#7-economy)
8. [Kid Safety Design Rules](#8-kid-safety-design-rules)

---

## 1. Core Loop

### 1.1 One-Sentence Loop
Tap and hold to dive, release to float — guide your fish through a rhythmic ocean obstacle course while the music drives every beat.

### 1.2 Session Flow
```
Main Menu → Zone Select → Level Select → Level Intro (3-beat countdown)
→ Gameplay → Results Screen → Stars + Coins Awarded → Next Level or Retry
```

Each session from tap-to-play to results screen targets 90–180 seconds for zones 1–4, up to 240 seconds for zones 5–6.

### 1.3 Input Mapping

| Input | Device Action | Game Action | Physics Effect |
|---|---|---|---|
| **HOLD** | Finger down on screen (anywhere) | Dive | Apply downward force: `velocity.y += DIVE_FORCE * delta` |
| **RELEASE** | Finger lifted | Float | Remove dive force; buoyancy applies upward drift |
| **No touch** | Idle | Float (default state) | Player drifts upward at float speed |

**Platform-specific mapping:**

- **Android/iOS touchscreen:** Any single-finger touch = HOLD. Multi-touch is treated as one hold (prevents accidental double-input). Touch position is irrelevant — the entire screen is the button.
- **Keyboard (editor/testing):** `Space` or `Down Arrow` = HOLD.
- **Mouse (editor/testing):** Left mouse button held = HOLD.

### 1.4 Physics Constants

All values are in Godot units (pixels at 1080×1920 base resolution). Tuned for feel first; adjust `DIVE_FORCE` and `FLOAT_FORCE` via exported variables on `PlayerPhysics.gd`.

```
FLOAT_FORCE        =  480.0   # upward units/sec² (buoyancy, always active)
DIVE_FORCE         =  900.0   # downward units/sec² (applied while held)
MAX_FLOAT_SPEED    =  320.0   # terminal velocity upward (units/sec)
MAX_DIVE_SPEED     =  640.0   # terminal velocity downward (units/sec)
DRAG_COEFFICIENT   =    0.92  # velocity multiplied each frame (light water drag)
```

**Physics feel description:** The player character feels like a real air-bladder fish — natural, buoyant, and forgiving. On release the character does NOT snap immediately upward; it decelerates from any downward momentum first, then drifts up smoothly. Holding down produces a gentle parabolic dive arc, not a sudden fall. The drag coefficient keeps speed from feeling "sticky" but prevents uncontrolled rocketing.

### 1.5 Visual Cue Reference: Player State

- **Floating:** Character animation plays `anim_float` — gentle idle fin wiggle, mild upward bobbing. Trail particle effect [ASSET: bubble_trail_float.png] emits small white bubbles at rate 3/sec.
- **Diving:** Character plays `anim_dive` — body angles 30° downward, fin tucked. Trail shifts to [ASSET: bubble_trail_dive.png] — larger, faster, angled upward behind character.
- **On beat (rhythm pulse):** A white ring [ASSET: fx_beat_ring.png] expands from player center on every quarter beat. Scales from 0.2 to 1.5 in 0.1 sec then fades. Always visible regardless of input.
- **Hit obstacle:** Character plays `anim_hurt` — flashes red×white at 10Hz for 0.3 sec, brief scale pulse to 1.3× then returns. Camera shakes (magnitude 8, duration 0.2 sec).
- **Death/level fail:** Character plays `anim_squish`, scales to 0.1 vertically, then [ASSET: fx_star_burst_fail.png] particle burst. Transitions to Fail Screen after 0.8 sec hold.

### 1.6 Rhythm Timing Windows

The game reads the music's BPM to calculate beat intervals. Beat interval in milliseconds = `(60 / BPM) * 1000`.

At 100 BPM: beat interval = 600 ms. At 180 BPM: beat interval = 333 ms.

**Timing windows are symmetrical around the exact beat:**

| Rating | Window | Score per Beat | Visual Cue | Audio Cue |
|---|---|---|---|---|
| **PERFECT** | ±50 ms of beat | 100 points | Gold star burst [ASSET: fx_perfect_star.png] | [SFX: timing_perfect] — bright chime |
| **GOOD** | ±101–150 ms of beat | 60 points | Blue ripple [ASSET: fx_good_ripple.png] | [SFX: timing_good] — soft bell |
| **MISS** | >150 ms or no input | 0 points | Gray X flash [ASSET: fx_miss_x.png] | [SFX: timing_miss] — low thud |

> Note: "Timing" applies to rhythmic obstacle avoidance beats — moments when the game expects the player to be in a specific vertical position or perform an input transition. Non-rhythmic obstacles (those that require sustained avoidance) do not generate timing events.

**Why ±150 ms for MISS (not ±100 ms as often cited):**
Internal playtesting with the 6–12 age group showed ±100 ms felt punishing on mobile. The ±150 ms boundary is inclusive — anything within 150 ms of a beat still scores GOOD. Only truly missed beats (>150 ms off or completely skipped) score zero.

### 1.7 Combo Multiplier

```
Combo count    Multiplier
0–9 hits       ×1
10–19 hits     ×2
20–39 hits     ×3
40–79 hits     ×4
80+ hits       ×5 (MAX)
```

Combo resets to 0 on any MISS. Combo does NOT reset on GOOD — only PERFECT and GOOD maintain combo. A combo counter [ASSET: ui_combo_counter.png] appears in the top-right corner after 10 consecutive non-miss beats. It pulses on each PERFECT hit.

**Audio cue:** At combo milestones 10, 20, 40, 80 the background music mix briefly brightens — an extra instrument layer fades in [SFX: combo_milestone_layer]. This uses Godot's AudioStreamPlayer bus mix, not additional files.

### 1.8 Level Structure

Each level is a fixed-length music track. The player character scrolls rightward automatically at a base speed tied to BPM. The level ends when the music ends. There is no "infinite" mode in the base game — every level has a defined start and end.

**Base scroll speed formula:**
```
scroll_speed = base_units_per_beat * (bpm / 60.0)
base_units_per_beat = 180  # units advanced per beat at 1× speed
```

Speed zones within a level can multiply this (see level_schema.json). The level's scroll speed is purely visual — the physics system is always on the same clock. Faster scroll speed means obstacles come faster, not that physics changes.

---

## 2. Obstacle Types

There are exactly **12 obstacle types** across all zones. Each has a code slug, display name, behavior, collision box, asset reference, audio cue, zone appearances, difficulty tier, and editor properties.

A summary table precedes the detailed entries:

| # | Slug | Display Name | Difficulty | Zones |
|---|---|---|---|---|
| 1 | `coral_spike` | Coral Spike | 1 | Z1, Z2 |
| 2 | `jellyfish_drift` | Drifting Jellyfish | 1 | Z1, Z2, Z3 |
| 3 | `kelp_curtain` | Kelp Curtain | 2 | Z2, Z3 |
| 4 | `bubble_mine` | Bubble Mine | 2 | Z2, Z3, Z4 |
| 5 | `current_jet` | Current Jet | 2 | Z2, Z3, Z4, Z5 |
| 6 | `anchor_chain` | Anchor Chain | 2 | Z3 |
| 7 | `lava_burst` | Lava Burst | 3 | Z4, Z6 |
| 8 | `eel_snap` | Snapping Eel | 3 | Z3, Z4, Z5 |
| 9 | `pressure_wall` | Pressure Wall | 3 | Z4, Z5 |
| 10 | `dark_void` | Dark Void | 2 | Z5 |
| 11 | `crystal_shard` | Crystal Shard | 3 | Z6 |
| 12 | `mirror_fish` | Mirror Fish | 3 | Z5, Z6 |

---

### 2.1 `coral_spike` — Coral Spike
**Behavior:** Static obstacle. A cluster of sharp coral protrusions fixed to either the top wall (spikes pointing downward) or bottom wall (spikes pointing upward). Does not move. Occupies a vertical band of 120–240 units depending on `height` parameter. Player must hold-to-dive under top spikes or release-to-float above bottom spikes.

**Exact behavior spec:** Spawned at a fixed beat-indexed position. `RigidBody2D` with `PhysicsBody2D` mode STATIC. No movement code. Collision activates `on_hit()` on player.

**Collision box:** 80 px wide × 120–240 px tall (configurable). Hitbox is slightly smaller than sprite (90% scale) to feel fair: effective hitbox = 72 px wide × 108–216 px tall.

**Visual placeholder:** [ASSET: obs_coral_spike_top.png] / [ASSET: obs_coral_spike_bottom.png]

**Audio cue:** [SFX: obs_coral_impact] — sharp scrape sound on hit. No sound when passed.

**Zones:** Z1 (Sunlit Shallows), Z2 (Kelp Forest Canyon)

**Difficulty:** 1 (Beginner)

**Level editor properties:**
- `wall_attachment`: `top` | `bottom`
- `height`: 120 | 180 | 240 (px, three presets)
- `beat_position`: integer beat index

---

### 2.2 `jellyfish_drift` — Drifting Jellyfish
**Behavior:** Moves slowly in a sine-wave vertical pattern while drifting rightward (toward the player in screen space). It spawns off the right edge and moves left at a fixed lateral speed matching scroll speed + 20 units/sec. The vertical sine amplitude and frequency are configurable.

**Exact behavior spec:** `CharacterBody2D`. Each frame: `position.x -= (scroll_speed + 20) * delta`. Vertical: `position.y += sin(time * freq) * amplitude * delta`. Collision sphere. On player collision → `on_hit()`.

**Collision box:** Circular, radius 48 px (the tentacles are visual-only, not part of the hitbox).

**Visual placeholder:** [ASSET: obs_jellyfish_a.png] (purple), [ASSET: obs_jellyfish_b.png] (pink)

**Audio cue:** [SFX: obs_jellyfish_sting] — electric zap on hit. Passive [SFX: obs_jellyfish_ambient] — soft pulse loop while on screen (spatial, fades with distance from player).

**Zones:** Z1, Z2, Z3

**Difficulty:** 1 (Beginner)

**Level editor properties:**
- `color_variant`: `purple` | `pink`
- `sine_amplitude`: 50 | 100 | 150 (px)
- `sine_frequency`: 0.5 | 1.0 | 2.0 (Hz)
- `lane_start_y`: float (screen Y at spawn, 0.0–1.0 normalized)

---

### 2.3 `kelp_curtain` — Kelp Curtain
**Behavior:** A vertical row of kelp blades attached to the bottom, swaying left-right in a wave pattern. Fills a lane gap of configurable width with swaying blades. Player must time their vertical position to pass through a gap in the kelp, or wait for the sway to open. Gap appears at a rhythmically predictable moment — always on a beat.

**Exact behavior spec:** Composed of 4–8 individual `AnimatedSprite2D` nodes, each swaying with phase offset: `rotation = max_sway * sin(time * sway_speed + phase_offset)`. A `ShapeCast2D` detects the open gap each frame. On beat when gap aligns: a brief glow [ASSET: fx_kelp_gap_glow.png] highlights the safe passage.

**Collision box:** Each blade is 24 px wide × 180 px tall. Gap is 120 px wide (2× player width).

**Visual placeholder:** [ASSET: obs_kelp_curtain_blade.png] (single blade, tiled)

**Audio cue:** [SFX: obs_kelp_sway] — low whooshing loop. [SFX: obs_kelp_hit] — wet thud on collision.

**Zones:** Z2, Z3

**Difficulty:** 2 (Intermediate)

**Level editor properties:**
- `blade_count`: 4 | 6 | 8
- `sway_speed`: 0.5 | 1.0 | 1.5 (Hz)
- `gap_beat_alignment`: beat index when gap opens (must be set per placement)
- `wall_attachment`: `bottom` | `top`

---

### 2.4 `bubble_mine` — Bubble Mine
**Behavior:** Stationary sphere that detonates when the player gets within 160 px. Detonation creates a radial shockwave (visual only — no damage from shockwave, only from direct contact). The mine itself is the hazard: collision = hit. After detonation, it is destroyed. If player avoids it and the mine exits screen-left, it self-destructs with a small harmless pop.

**Exact behavior spec:** `Area2D` with `CollisionShape2D` (radius 56 px). Each frame: if `player_distance < 160` and player is not overlapping (near-miss range), play `anim_warning` (pulsing red). At `player_distance < 56` → `on_hit()` then `explode()`. `explode()` instantiates [ASSET: fx_mine_explode.png] particle burst, plays [SFX: obs_mine_explode], then `queue_free()`.

**Collision box:** Circular, radius 56 px.

**Visual placeholder:** [ASSET: obs_bubble_mine.png]

**Audio cue:** [SFX: obs_mine_tick] — ticking beep loop that speeds up as player approaches. [SFX: obs_mine_explode] — pop + bubble burst on detonation.

**Zones:** Z2, Z3, Z4

**Difficulty:** 2 (Intermediate)

**Level editor properties:**
- `lane_y`: float (0.0–1.0 normalized vertical position)
- `arm_radius`: 160 | 200 | 240 (px — detonation warning radius)

---

### 2.5 `current_jet` — Current Jet
**Behavior:** A horizontal jet of water shoots from one wall (left, right, top, or bottom) across the lane. It is not instant — it has a telegraph phase (visual warning stream) for 0.5 sec, then fires for 0.4 sec, then cools for 0.3 sec. The cycle repeats on a beat interval. Player must time their position to be outside the jet's path during the fire phase.

**Exact behavior spec:** `Area2D`. State machine: IDLE → TELEGRAPHING (0.5 sec, plays warning sprite) → FIRING (0.4 sec, collision active) → COOLDOWN (0.3 sec). Total cycle = 1.2 sec. Cycle aligns to BPM: at 120 BPM (0.5 sec/beat), one cycle = 2.4 beats. Phase offset is configurable. During FIRING, continuous [SFX: obs_jet_stream] plays.

**Collision box:** 48 px wide (in direction of travel) × 80 px tall (cross-section). Full lane width in travel direction (640 px or full screen width for horizontal jets).

**Visual placeholder:** [ASSET: obs_current_jet_nozzle.png] (wall fixture), [ASSET: obs_current_jet_stream.png] (animated stream, stretches across lane)

**Audio cue:** [SFX: obs_jet_charge] — rising hiss during telegraph. [SFX: obs_jet_stream] — rushing water during fire. [SFX: obs_jet_hit] — knockback splash on collision.

**Zones:** Z2, Z3, Z4, Z5

**Difficulty:** 2 (Intermediate)

**Level editor properties:**
- `origin_wall`: `left` | `right` | `top` | `bottom`
- `lane_position`: float (perpendicular axis, 0.0–1.0)
- `beat_phase_offset`: float (0.0–1.0, fraction of beat)
- `cycle_beats`: 2 | 3 | 4 (how many beats per full cycle)

---

### 2.6 `anchor_chain` — Anchor Chain
**Behavior:** A long vertical chain with an anchor at the bottom, suspended from the top of the screen, swinging left-right like a pendulum. The chain and anchor are both collidable. The swing arc and period are fixed per placement. Player must time swimming through the chain's path at the apex (when it pauses briefly) or avoid it entirely by staying to one side.

**Exact behavior spec:** `Node2D` with pivot at top-center. Each frame: `rotation = max_angle * sin(time * pendulum_freq)`. Chain is a `Line2D` with multiple `CollisionShape2D` capsules along its length (6 capsule segments). At apex: `abs(angular_velocity) < 0.05` — a brief glow [ASSET: fx_chain_apex_glow.png] signals the safe pass moment.

**Collision box:** Chain segments: 16 px wide × 60 px tall each, 6 segments. Anchor: 80 px wide × 60 px tall at chain bottom.

**Visual placeholder:** [ASSET: obs_anchor_chain.png] (chain + anchor sprite sheet)

**Audio cue:** [SFX: obs_chain_creak] — low metallic groan loop. [SFX: obs_chain_hit] — metal clang on collision.

**Zones:** Z3 (Shipwreck Alley only)

**Difficulty:** 2 (Intermediate)

**Level editor properties:**
- `max_angle_degrees`: 20 | 35 | 50
- `pendulum_frequency`: 0.3 | 0.5 | 0.8 (Hz)
- `chain_length`: 300 | 500 | 700 (px)
- `beat_phase_offset`: float (0.0–1.0)

---

### 2.7 `lava_burst` — Lava Burst
**Behavior:** A vent in the bottom wall (or ceiling) erupts with a vertical column of superheated water and particles. It telegraphs with a rumble-and-glow for 0.6 sec, then fires a column 120 px wide × full screen height for 0.3 sec, then goes dormant for a configurable number of beats. Player must move laterally (via dive/float to change vertical position) out of the column's path during telegraph.

**Exact behavior spec:** Eruption column is an `Area2D` with `CollisionShape2D` (rectangle 120 × 1080 px). States: DORMANT → TELEGRAPHING (0.6 sec) → ERUPTING (0.3 sec, collision active) → COOLDOWN (configurable). Visual: lava glow [ASSET: obs_lava_vent_glow.png] in telegraph; particle column [ASSET: obs_lava_column.png] in eruption. Camera micro-shake during eruption (magnitude 4, duration 0.3 sec).

**Collision box:** 120 px wide × full screen height. Hitbox slightly narrower than visual: 96 px wide.

**Visual placeholder:** [ASSET: obs_lava_vent_glow.png], [ASSET: obs_lava_column.png], [ASSET: obs_lava_vent_base.png]

**Audio cue:** [SFX: obs_lava_rumble] — low rumble during telegraph. [SFX: obs_lava_erupt] — explosive burst on fire. [SFX: obs_lava_hit] — sizzling hiss on collision.

**Zones:** Z4 (Volcanic Vent Fields), Z6 (Crystal Caves — repurposed as steam vent visually)

**Difficulty:** 3 (Hard)

**Level editor properties:**
- `wall_origin`: `bottom` | `top`
- `x_position`: float (0.0–1.0, horizontal position)
- `dormant_beats`: 2 | 4 | 8
- `erupt_beat_index`: beat when first eruption triggers

---

### 2.8 `eel_snap` — Snapping Eel
**Behavior:** An eel emerges from a hole in a wall (left or right side), extends rapidly to a fixed length, then retracts. The extension is fast (0.15 sec) but the telegraph is generous (0.5 sec of head-peeking). Player must be in a vertical position that avoids the eel's strike zone during extension.

**Exact behavior spec:** `Node2D`. Eel head peeks 40 px out for 0.5 sec (TELEGRAPH). Then extends to full strike length (200–400 px, configurable) in 0.15 sec (STRIKE — collision active during this phase only). Retracts in 0.3 sec. Dormant for configurable beats. Extension uses `Tween` on `position.x` offset. Collision: `RectangleShape2D` 60 px tall × strike_length px wide. On STRIKE collision → `on_hit()`.

**Collision box:** 60 px tall × 200–400 px long (while extended). Only active during STRIKE phase.

**Visual placeholder:** [ASSET: obs_eel_head.png], [ASSET: obs_eel_body_segment.png] (tiled), [ASSET: obs_eel_hole.png] (wall sprite)

**Audio cue:** [SFX: obs_eel_hiss] — brief hiss during telegraph. [SFX: obs_eel_snap] — sharp snap on strike. [SFX: obs_eel_hit] — wet crunch on collision.

**Zones:** Z3, Z4, Z5

**Difficulty:** 3 (Hard)

**Level editor properties:**
- `origin_wall`: `left` | `right`
- `lane_y`: float (0.0–1.0 — vertical position of eel hole)
- `strike_length`: 200 | 300 | 400 (px)
- `dormant_beats`: 2 | 4 | 6

---

### 2.9 `pressure_wall` — Pressure Wall
**Behavior:** A wall of dense water pressure (visualized as a transparent blue-white wave) slides across the screen from left or right, compressing the safe lane into a narrow vertical band. The wall moves at a fixed speed and exits the opposite side. Player must be within the narrow visible safe band (indicated by a highlighted gap in the wall) to avoid damage. There is exactly one gap per wall, and its vertical position is fixed at placement time.

**Exact behavior spec:** Full-screen-height `Area2D` rectangle sliding laterally. Gap is a rectangular exclusion zone (120 px tall × full wall width) — implemented by two separate collision rectangles (above and below gap). Wall speed: 300–600 px/sec (configurable). On collision with non-gap area → `on_hit()`. Gap highlighted by [ASSET: fx_pressure_gap_highlight.png] strip.

**Collision box:** Two rectangles: upper portion (from top to gap start) and lower portion (from gap end to bottom). Each rectangle full wall width × calculated height. Effective hitbox is 90% of visual width.

**Visual placeholder:** [ASSET: obs_pressure_wall.png] (semi-transparent animated wave texture, scrolls UV)

**Audio cue:** [SFX: obs_pressure_build] — rising pressure hiss as wall approaches. [SFX: obs_pressure_pass] — whoosh as wall exits. [SFX: obs_pressure_hit] — deep thump on collision.

**Zones:** Z4, Z5

**Difficulty:** 3 (Hard)

**Level editor properties:**
- `entry_side`: `left` | `right`
- `gap_y_normalized`: float (0.1–0.9, center of safe gap)
- `gap_height`: 120 | 160 | 200 (px)
- `travel_speed`: 300 | 450 | 600 (px/sec)
- `beat_index`: beat when wall enters screen

---

### 2.10 `dark_void` — Dark Void
**Behavior:** A moving sphere of total darkness that obscures the lane ahead. It does not deal direct damage — instead it reduces visible area to a 40 px radius around the player, hiding upcoming obstacles. The void lasts for a configurable duration (2–8 beats). The player must navigate by audio cues and memory. Obstacle hits during a void phase still deal normal damage.

**Exact behavior spec:** `CanvasLayer` with a full-screen dark rectangle minus a radial gradient cutout around player. Cutout radius: 40 px normally, pulsing ±10 px on each beat. Transition in/out: 0.3 sec fade. During void, beat pulse from player is larger [ASSET: fx_beat_ring_dark.png] (white, radius 80 px) to compensate for reduced visibility.

**Collision box:** None — `dark_void` itself cannot be collided with. It is a visual/audio effect modifier.

**Visual placeholder:** [ASSET: obs_dark_void_overlay.png] (full-screen shader mask)

**Audio cue:** [SFX: obs_dark_void_enter] — deep resonant hum fade in. [SFX: obs_dark_void_loop] — spatial audio of heartbeat-style bass pulse (plays for duration). [SFX: obs_dark_void_exit] — reverse hum fade out.

**Zones:** Z5 (Twilight Trench only)

**Difficulty:** 2 (Intermediate — disorienting but not directly lethal)

**Level editor properties:**
- `duration_beats`: 2 | 4 | 6 | 8
- `beat_index`: beat when void begins
- `pulse_with_beat`: bool (default true — cutout radius pulses on beat)

---

### 2.11 `crystal_shard` — Crystal Shard
**Behavior:** A rapidly rotating crystal fragment that moves in a diagonal trajectory across the screen. It bounces off the top and bottom walls (angle of incidence = angle of reflection). Speed is high — faster than any other obstacle. Extremely predictable if the player tracks it, but punishing if ignored.

**Exact behavior spec:** `CharacterBody2D`. Initial velocity: `Vector2(lateral_speed, diagonal_speed)` where `diagonal_speed` alternates sign on wall bounce. `move_and_collide()` handles wall reflection. Rotation: `rotation += ROT_SPEED * delta` (2–4 radians/sec). Collision: capsule shape rotated with sprite.

**Collision box:** Capsule, 40 px wide × 80 px tall, rotates with sprite.

**Visual placeholder:** [ASSET: obs_crystal_shard_a.png], [ASSET: obs_crystal_shard_b.png] (two color variants: blue, teal)

**Audio cue:** [SFX: obs_crystal_hum] — high-pitched crystal resonance while on screen. [SFX: obs_crystal_bounce] — glass ping on wall bounce. [SFX: obs_crystal_hit] — shattering on player collision.

**Zones:** Z6 (Crystal Caves only)

**Difficulty:** 3 (Hard)

**Level editor properties:**
- `entry_side`: `left` | `right`
- `entry_y_normalized`: float (0.0–1.0)
- `lateral_speed`: 400 | 600 | 800 (px/sec)
- `diagonal_speed_initial`: `up` | `down` (initial vertical direction)
- `color_variant`: `blue` | `teal`
- `rotation_direction`: `clockwise` | `counter`

---

### 2.12 `mirror_fish` — Mirror Fish
**Behavior:** An exact visual copy of the player character that mirrors the player's vertical movement with a 0.5-second delay. It travels in the opposite horizontal direction (right-to-left, toward the player from the front). The player must perform movements that, delayed by 0.5 sec, will NOT collide with the mirror fish's position when it reaches the player's lane position. Requires predictive thinking.

**Exact behavior spec:** `CharacterBody2D`. Records player's `y_position` at each frame into a `RingBuffer` of 30 frames (0.5 sec at 60 fps). Mirror fish `y_position = ring_buffer[current_frame - 30]`. Moves leftward at scroll speed + 100 px/sec. Does not apply physics — purely position-matched from buffer.

**Collision box:** Same dimensions as player: 80 px wide × 60 px tall ellipse.

**Visual placeholder:** [ASSET: obs_mirror_fish.png] (player sprite with blue-tint shader applied)

**Audio cue:** [SFX: obs_mirror_appear] — whooshing reverse sound on spawn. [SFX: obs_mirror_pass] — echo tone when it safely passes. [SFX: obs_mirror_hit] — dual-impact sound on collision.

**Zones:** Z5, Z6

**Difficulty:** 3 (Hard)

**Level editor properties:**
- `delay_frames`: 20 | 30 | 45 (0.33 / 0.5 / 0.75 sec delay at 60fps)
- `approach_speed_bonus`: 50 | 100 | 150 (px/sec added to scroll speed)
- `beat_index`: beat when mirror fish enters from right edge

---

## 3. Zone Progression

### Zone Overview

| Zone | Name | BPM Range | Levels | Unlock |
|---|---|---|---|---|
| Z1 | Sunlit Shallows | 100–115 | 8 | Default unlocked |
| Z2 | Kelp Forest Canyon | 120–130 | 8 | Complete Z1-L4 |
| Z3 | Shipwreck Alley | 130–145 | 8 | Complete Z2-L4 |
| Z4 | Volcanic Vent Fields | 145–165 | 8 | Complete Z3-L4 + Full Reef IAP |
| Z5 | Twilight Trench | Variable (80–165) | 8 | Complete Z4-L4 + Full Reef IAP |
| Z6 | Crystal Caves | 170–180 | 8 | Secret: earn 3 stars on all Z1–Z5 levels |

**Total levels:** 48. Full Reef IAP unlocks Z4–Z5 (16 levels). Z6 is earned through mastery, not purchase.

**Free-to-play access:** Z1 all 8 levels free. Z2 levels 1–4 free, 5–8 require Full Reef IAP or reaching Z3 (which requires completing Z2-L4, which is free). Z3 all 8 levels free. Summary: 24 levels free, 24 behind Full Reef IAP, 8 bonus secret levels earned.

---

### 3.1 Zone 1 — Sunlit Shallows

**BPM Range:** 100–115 (ramps from 100 on L1 to 115 on L8)  
**Unlock Condition:** Default — available from first launch  
**Setting:** Bright, clear tropical shallows. Sandy bottom, shafts of sunlight, colorful fish in background.  
**Color Palette:** Cyan, warm yellow, coral pink, white  
**Background:** [ASSET: bg_sunlit_shallows_scroll.png] (parallax layers: sand bottom, mid coral, surface light shafts)

**Unique Zone Mechanic — Sunbeam Boost:**
Vertical columns of sunlight appear periodically (every 4–8 beats). Floating up into a sunbeam for 1+ full beats grants a ×1.5 score multiplier for the next 3 beats and a burst of golden sparkle particles [ASSET: fx_sunbeam_burst.png]. This teaches the float mechanic in a rewarding way. Sunbeams are visual features of the background, not obstacles.

**Audio cue:** [SFX: zone1_sunbeam_enter] — warm chime sequence when entering a sunbeam.

**Obstacle Set:** coral_spike, jellyfish_drift only. No more than 2 obstacle types simultaneously on screen.

**Level List (Z1):**

| Level | BPM | Obstacles | Teaching Focus | Unique Feature |
|---|---|---|---|---|
| Z1-L1 | 100 | coral_spike only | Introduce hold-to-dive | 4 bottom spikes, very spaced |
| Z1-L2 | 100 | coral_spike only | Top spikes + bottom spikes | Alternating spike positions |
| Z1-L3 | 105 | coral_spike, jellyfish | Introduce moving obstacles | 2 jellyfish, slow sine |
| Z1-L4 | 105 | coral_spike, jellyfish | Combining static + moving | First sunbeam boost column |
| Z1-L5 | 110 | coral_spike, jellyfish | Faster jellies, more spikes | Double jellyfish moment |
| Z1-L6 | 110 | coral_spike, jellyfish | Density increase | First 3-obstacle cluster |
| Z1-L7 | 112 | coral_spike, jellyfish | Combo targeting (reach 10) | Bonus coin trail path |
| Z1-L8 | 115 | coral_spike, jellyfish | Zone 1 mastery run | Sunbeam finale sequence |

**Par scores for Z1:** 1-star = 40% of max, 2-star = 70%, 3-star = 90%. Max score per level ≈ 3,200 points (32-beat level at 100 points per beat × 5 max multiplier capped at realistic expectation of ×2 average).

---

### 3.2 Zone 2 — Kelp Forest Canyon

**BPM Range:** 120–130  
**Unlock Condition:** Complete Z1-L4 (any star rating)  
**Setting:** Towering kelp forests with filtered green-gold light. Rocky canyon walls with gaps. Fish darting in background.  
**Color Palette:** Deep green, gold, dark teal, amber  
**Background:** [ASSET: bg_kelp_forest_scroll.png] (parallax: rocky walls, kelp columns, light shafts from above)

**Unique Zone Mechanic — Kelp Tunnel:**
On levels 5–8, at specific beat ranges, the canyon walls close into a narrow tunnel of kelp for 8–16 beats. The safe lane is reduced to 50% of normal height. During this phase, new obstacles cannot be placed (by zone design rule — it's hard enough). The tunnel is highlighted with a [ASSET: fx_kelp_tunnel_edge.png] glowing border so players can see the boundaries. Entering a tunnel triggers [SFX: zone2_tunnel_enter] — ambient creaking.

**Obstacle Set:** coral_spike, jellyfish_drift, kelp_curtain, bubble_mine

**Level List (Z2):**

| Level | BPM | Obstacles | Teaching Focus | Unique Feature |
|---|---|---|---|---|
| Z2-L1 | 120 | coral_spike, jellyfish | Adjust to 120 BPM | Familiar obstacles, new speed |
| Z2-L2 | 120 | kelp_curtain | Introduce kelp curtain | Timing the gap passage |
| Z2-L3 | 122 | coral_spike, kelp_curtain | Combining curtains + spikes | First 2-obstacle approach |
| Z2-L4 | 124 | bubble_mine | Introduce bubble mine | Mine avoidance only |
| Z2-L5 | 125 | all four types | Mixed challenge | First kelp tunnel section |
| Z2-L6 | 127 | all four types | Density + tunnel | Double mine + curtain combo |
| Z2-L7 | 128 | all four types | Timing mastery | Tunnel extends 16 beats |
| Z2-L8 | 130 | all four types | Zone 2 mastery | Chain of all 4 types + tunnel |

---

### 3.3 Zone 3 — Shipwreck Alley

**BPM Range:** 130–145  
**Unlock Condition:** Complete Z2-L4 (any star rating)  
**Setting:** Sunken shipwrecks, rusted hulls, broken masts, schools of fish swimming through portholes.  
**Color Palette:** Rust orange, dark navy, seafoam green, pale gray  
**Background:** [ASSET: bg_shipwreck_scroll.png] (parallax: ship silhouettes, debris, fish schools)

**Unique Zone Mechanic — Hull Breach Passages:**
Some level sections route the player THROUGH the inside of a sunken ship. Inside sections have strictly bounded walls (top and bottom at 30% screen height, leaving 40% lane), different background [ASSET: bg_shipwreck_interior.png], and dimmer lighting with flickering porthole glow. Inside sections last 8–24 beats. The transition in/out is marked by a [ASSET: fx_hull_breach.png] frame and [SFX: zone3_hull_enter] — grinding metal echo.

**Obstacle Set:** coral_spike, jellyfish_drift, kelp_curtain, bubble_mine, current_jet, anchor_chain, eel_snap

**Level List (Z3):**

| Level | BPM | Obstacles | Teaching Focus | Unique Feature |
|---|---|---|---|---|
| Z3-L1 | 130 | coral_spike, jellyfish, bubble_mine | Speed adjustment | Familiar set at new BPM |
| Z3-L2 | 132 | current_jet | Introduce current jet | Telegraph reading focus |
| Z3-L3 | 133 | anchor_chain | Introduce anchor chain | Pendulum timing |
| Z3-L4 | 135 | eel_snap | Introduce snapping eel | Vertical positioning |
| Z3-L5 | 138 | current_jet, anchor_chain | Jet + chain combo | First hull interior section |
| Z3-L6 | 140 | eel_snap, bubble_mine, coral_spike | Dense corridor | Extended interior 24 beats |
| Z3-L7 | 142 | all Z3 types | Mixed complexity | Chain inside hull |
| Z3-L8 | 145 | all Z3 types | Zone 3 mastery | Dual eels + hull finale |

---

### 3.4 Zone 4 — Volcanic Vent Fields

**BPM Range:** 145–165  
**Unlock Condition:** Complete Z3-L4 AND own Full Reef IAP  
**Setting:** Deep volcanic seafloor. Glowing magma vents, superheated water columns, volcanic rock formations.  
**Color Palette:** Deep red, orange, black, white hot  
**Background:** [ASSET: bg_volcanic_scroll.png] (parallax: volcanic rock floor, lava glow columns, bubbling vents, ash particles)

**Unique Zone Mechanic — Heat Wave Distortion:**
On certain beat ranges (configurable per level), the screen applies a heat-shimmer shader [ASSET: shader_heat_wave.gdshader] that distorts the visual slightly. No gameplay change — purely visual. Duration: 4–8 beats. Timed to music intensity peaks. Camera does not shake during heat wave (kept separate from collision shake). [SFX: zone4_heatwave] — low rumble loop during distortion.

**Obstacle Set:** coral_spike, bubble_mine, current_jet, eel_snap, lava_burst, pressure_wall

**Level List (Z4):**

| Level | BPM | Obstacles | Teaching Focus | Unique Feature |
|---|---|---|---|---|
| Z4-L1 | 145 | coral_spike, eel_snap, current_jet | Speed ramp | Familiar obstacles faster |
| Z4-L2 | 148 | lava_burst | Introduce lava burst | Telegraph to safe column |
| Z4-L3 | 150 | lava_burst, bubble_mine | Mine + burst combo | Heat wave first appearance |
| Z4-L4 | 152 | pressure_wall | Introduce pressure wall | Finding and holding the gap |
| Z4-L5 | 155 | lava_burst, pressure_wall | Dual hazard lanes | Extended heat wave |
| Z4-L6 | 158 | all Z4 types | Density surge | Multiple lava bursts |
| Z4-L7 | 162 | all Z4 types | Speed + complexity | Heat wave during pressure wall |
| Z4-L8 | 165 | all Z4 types | Zone 4 mastery | Eruption finale sequence |

---

### 3.5 Zone 5 — Twilight Trench

**BPM Range:** Variable — 80–165 (BPM changes within levels to match ambient music shifts)  
**Unlock Condition:** Complete Z4-L4 AND own Full Reef IAP  
**Setting:** Deep trench, near-total darkness, bioluminescent creatures, eerie silence punctuated by distant rumbles.  
**Color Palette:** Near-black background, electric blue, violet, neon teal, deep purple  
**Background:** [ASSET: bg_twilight_trench_scroll.png] (parallax: pitch-black water, bioluminescent jellyfish trails, depth pressure lines)

**Unique Zone Mechanic — BPM Drift:**
Zone 5 is the only zone where BPM is not fixed. Each level's music slows and speeds based on musical narrative (e.g., slow dread at 80 BPM, tense burst at 165 BPM). The beat grid and timing windows adjust in real time with the music. A BPM indicator [ASSET: ui_bpm_indicator.png] at the top-left pulses with the current beat so players can always feel the rhythm. Obstacle placement adapts to beat indexes, not elapsed seconds — so a beat-4 obstacle always appears on beat 4 regardless of tempo.

**Obstacle Set:** all types except coral_spike and kelp_curtain (too shallow-zone-specific). Uses: jellyfish_drift, bubble_mine, current_jet, eel_snap, pressure_wall, dark_void, mirror_fish

**Level List (Z5):**

| Level | BPM | Obstacles | Teaching Focus | Unique Feature |
|---|---|---|---|---|
| Z5-L1 | 100→145 | jellyfish, bubble_mine | BPM drift introduction | Slow opener, accelerates |
| Z5-L2 | 80→120 | dark_void | Introduce dark void | Sound-only navigation |
| Z5-L3 | 120→160 | mirror_fish | Introduce mirror fish | Prediction mechanic |
| Z5-L4 | 90→150 | dark_void, mirror_fish | Void + mirror combo | Worst-case navigation |
| Z5-L5 | 100→165 | all Z5 types | Full chaos opener | Multiple void phases |
| Z5-L6 | 80→165 | all Z5 types | Max BPM range | Near-total darkness finale |
| Z5-L7 | 100→150 | all Z5 types | Precision run | Mirror fish in void |
| Z5-L8 | 80→165 | all Z5 types | Zone 5 mastery | All mechanics, full range |

---

### 3.6 Zone 6 — Crystal Caves (Secret)

**BPM Range:** 170–180  
**Unlock Condition:** Earn 3 stars on all 40 levels in Z1–Z5 (120 total stars required)  
**Setting:** Breathtaking bioluminescent crystal caves. Giant crystal formations, rainbow light refraction, absolute clarity.  
**Color Palette:** Prismatic — shifts through full spectrum on scroll  
**Background:** [ASSET: bg_crystal_caves_scroll.png] (parallax: crystal walls, prismatic light rays, floating crystal dust)

**Unique Zone Mechanic — Crystal Resonance:**
Every PERFECT timing hit causes a nearby crystal to light up [ASSET: fx_crystal_resonate.png] with a matching color. Building a streak of PERFECTs causes cascading crystal illuminations that reveal hidden bonus coin clusters [ASSET: collectible_bonus_coin.png] floating in the lane. No PERFECTs = caves stay dim (still playable). Full PERFECT streak = blinding rainbow finale at level end. This is purely cosmetic/bonus — not required for completion.

**Obstacle Set:** all types. Primary: crystal_shard, mirror_fish, lava_burst, pressure_wall, eel_snap, dark_void. Secondary fillers: jellyfish_drift, bubble_mine.

**Level List (Z6):**

| Level | BPM | Obstacles | Teaching Focus | Unique Feature |
|---|---|---|---|---|
| Z6-L1 | 170 | crystal_shard | Introduce crystal shard | Diagonal bounce patterns |
| Z6-L2 | 170 | crystal_shard, mirror_fish | Shard + mirror | Simultaneous tracking |
| Z6-L3 | 172 | crystal_shard, lava_burst | Burst + shard | Shard appears post-burst |
| Z6-L4 | 174 | pressure_wall, crystal_shard | Wall + shard in gap | Shard through narrow gap |
| Z6-L5 | 175 | dark_void, crystal_shard | Dark void + shard | Audio-only shard tracking |
| Z6-L6 | 176 | all Z6 types | Peak difficulty | Resonance chain challenge |
| Z6-L7 | 178 | all Z6 types | Mastery run | Triple crystal shard gauntlet |
| Z6-L8 | 180 | all Z6 types | Final level | Full rainbow finale, 180 BPM |

---

## 4. Character System

All characters are **cosmetic only**. No character has better or worse physics, collision boxes, or timing windows. Pay-to-win is prohibited by design and Google Play Families policy. Characters differ only in animation style, trail particles, and personality audio clips.

### 4.1 Character Table

| # | Name | Species | Unlock | Personality |
|---|---|---|---|---|
| 1 | **Pebble** | Pufferfish | Default — always unlocked | Cheerful, round, determined |
| 2 | **Zap** | Electric Ray | Complete Z2 (any star) | Cool, energetic, crackles |
| 3 | **Mochi** | Moon Jellyfish | Earn 50 stars (all zones) | Dreamy, gentle, glows |
| 4 | **Crusher** | Hermit Crab | Complete Z3 with 3 stars on any 4 levels | Tough, grumpy exterior, soft inside |
| 5 | **Pip** | Sea Turtle hatchling | Complete Z1 with 3 stars on all 8 levels | Earnest, slow-seeming but precise |
| 6 | **Lumina** | Anglerfish | Complete Z5 (any star) | Mysterious, wise, sarcastic |
| 7 | **Finn** | Great White Shark (friendly) | Own Full Reef IAP | Excitable, big, surprisingly timid |
| 8 | **Grumble** | Giant Isopod | Earn 3 stars on Z6-L8 | Ancient, stoic, secretly delighted |

### 4.2 Character Detail Entries

**Pebble (pufferfish)**  
- Unlock: Always available  
- Animation style: Wobbles slightly on float, tucks into a tight ball on dive, puffs up on PERFECT hit  
- Trail: Small white bubbles [ASSET: char_pebble_trail.png]  
- Hit reaction: Deflates with a squeaky [SFX: pebble_ouch]  
- Idle (menu): Bobs up and down, occasionally blows a bubble  
- Personality audio: [SFX: pebble_cheer] on level complete, [SFX: pebble_surprised] on 3-star achievement  

**Zap (electric ray)**  
- Unlock: Complete Z2  
- Animation style: Flaps wide fins on float, goes flat on dive. On PERFECT hit, flashes blue-white  
- Trail: Electric sparks [ASSET: char_zap_trail.png]  
- Hit reaction: Discharges — brief static frame [SFX: zap_shock]  
- Idle: Slow fin undulation, occasional spark  
- Personality audio: [SFX: zap_excited] on level complete  

**Mochi (moon jellyfish)**  
- Unlock: Earn 50 stars total  
- Animation style: Pulsing bell on float, elongates on dive. Glow intensifies on PERFECT  
- Trail: Soft neon tendrils [ASSET: char_mochi_trail.png]  
- Hit reaction: Bell flattens with [SFX: mochi_blorp]  
- Idle: Slow pulse, semi-transparent shimmer  
- Personality audio: [SFX: mochi_hum] — soft melody on level complete  

**Crusher (hermit crab)**  
- Unlock: 3 stars on any 4 Z3 levels  
- Animation style: Shell bobs on float, retreats partway into shell on dive. Peeks out on PERFECT  
- Trail: Tiny sand puffs [ASSET: char_crusher_trail.png]  
- Hit reaction: Full shell retreat, [SFX: crusher_clunk]  
- Idle: Polishes shell, occasional grumpy eye-roll  
- Personality audio: [SFX: crusher_grunt] on level complete — reluctant approval  

**Pip (sea turtle hatchling)**  
- Unlock: 3 stars on all Z1 levels  
- Animation style: Steady flipper strokes on float, torpedo posture on dive. Shell glows on PERFECT  
- Trail: Tiny bubbles + flipper wake [ASSET: char_pip_trail.png]  
- Hit reaction: Tucks flippers with [SFX: pip_squeak]  
- Idle: Slow deliberate paddle, looks at camera curiously  
- Personality audio: [SFX: pip_yay] on level complete — tiny triumphant chirp  

**Lumina (anglerfish)**  
- Unlock: Complete Z5  
- Animation style: Lure light bobs on float, lure retracts on dive. On PERFECT, lure shines bright spotlight briefly  
- Trail: Dim purple bio-light motes [ASSET: char_lumina_trail.png]  
- Hit reaction: Lure flickers out with [SFX: lumina_gasp]  
- Idle: Watches player, lure sways, occasionally blinks slowly  
- Personality audio: [SFX: lumina_pleased] — dry satisfied exhale on level complete  

**Finn (friendly great white)**  
- Unlock: Own Full Reef IAP  
- Animation style: Tall dorsal fin visible above body on float; tucked for streamlining on dive. On PERFECT, big toothy grin animation  
- Trail: Bubbles in a wide V-wake [ASSET: char_finn_trail.png]  
- Hit reaction: Jumps in surprise [SFX: finn_yelp] — surprisingly high-pitched  
- Idle: Paddles in place, waves a fin, smiles nervously  
- Personality audio: [SFX: finn_cheer] — overly enthusiastic roar on level complete  

**Grumble (giant isopod)**  
- Unlock: Earn 3 stars on Z6-L8 (final level)  
- Animation style: Many legs undulate rhythmically on float; curls into armadillo ball on dive. On PERFECT, all legs flutter at once  
- Trail: Ancient deep-sea particles, faint [ASSET: char_grumble_trail.png]  
- Hit reaction: Curls defensively [SFX: grumble_rumble] — deep subsonic thrum  
- Idle: Absolutely still, then one slow head turn  
- Personality audio: [SFX: grumble_satisfied] — single long exhale on level complete  

---

## 5. Scoring System

### 5.1 Score Formula

```
level_score = sum of (beat_score × combo_multiplier) for each beat event
beat_score  = 100 (PERFECT) | 60 (GOOD) | 0 (MISS)

combo_multiplier:
  combo  0–9   → ×1
  combo 10–19  → ×2
  combo 20–39  → ×3
  combo 40–79  → ×4
  combo 80+    → ×5

bonus_score = sunbeam_boosts × 150  (Z1 only)
            + crystal_resonance_bonus (Z6 only, up to 500 per level)

final_score = level_score + bonus_score
```

**Example calculation (Z1-L1, 8 obstacles, all PERFECT, combo builds to 8):**
- Beats 1–8: all PERFECT (100 pts each), combo peaks at 8 → all at ×1
- level_score = 8 × 100 × 1 = 800
- No bonuses
- final_score = 800

**Example calculation (Z3-L8, 32 beats, mixed timing, combo sustained):**
- Assume 20 PERFECT + 8 GOOD + 4 MISS, combo reaches 20 during PERFECT streak
- PERFECT: 20 × 100 = 2,000 base, with ×2 for many = ~3,500 scored
- GOOD: 8 × 60 × 1 = 480 base
- MISS resets combo, cost ~600 in potential multiplied score
- Realistic final ≈ 4,200–5,500 depending on combo maintenance

### 5.2 Star Rating Thresholds

Star ratings are calculated as a percentage of the level's **par_score** (stored in level schema). Par scores are hand-tuned per level to reflect realistic good-but-not-perfect play.

| Stars | Threshold | Description |
|---|---|---|
| 0 stars | < 40% of par | Did not pass the level (level can still be completed with 0 stars) |
| 1 star | 40–69% of par | Completed with some mistakes |
| 2 stars | 70–89% of par | Good run with minor errors |
| 3 stars | 90–100%+ of par | Excellent — near-perfect execution |

**Note:** Scoring above 100% of par is possible (par is tuned conservatively) — this shows as "100%+" on the results screen and awards a visual gold border [ASSET: ui_star_frame_gold.png].

### 5.3 High Score Persistence

- Scores stored locally in Godot `user://save_data.json`
- Per-level: best score, best star count, total play count, first clear date
- Per-zone: total stars earned, fastest total completion time
- Global: total coins collected, total stars, characters unlocked (bool per character)
- Cloud save: via Google Play Games Services (Android) and Apple Game Center (iOS). Syncs on level complete and app focus-out.
- Local save always wins over cloud if both exist (prevents data loss on sync failure)
- Score does NOT reset on retry — only improves if new score > stored best

---

## 6. Build Mode Rules

Build Mode is accessed from the main menu as "Create" tab. It is a simplified but fully functional beat-synced level editor.

### 6.1 What Players Can Place

**Always available (no Creator Pass required):**
- Any obstacle type from zones the player has unlocked
- Speed zones (start beat, end beat, multiplier)
- Zone/background selection (from unlocked zones)
- Music selection (from unlocked zone tracks)
- Level name and description text fields

**Requires Creator Pass ($1.99):**
- Publishing levels publicly to the community gallery (Share button)
- Downloading other players' published levels
- Using any obstacle from zones not yet personally unlocked (access to full obstacle catalog)

### 6.2 Beat Grid Snap Rules

The editor operates on a beat grid. All obstacle placements snap to the nearest valid beat subdivision.

**Available subdivisions:**
- Quarter beat (×1) — default, always available
- Eighth beat (×0.5) — unlocked when zone Z3+ is unlocked
- Sixteenth beat (×0.25) — unlocked when zone Z5+ is unlocked

**Placing an obstacle:**
1. Player scrolls the timeline (horizontal scroll, drag left/right)
2. Timeline shows beats as vertical grid lines, with measure markers every 4 beats
3. Tap a position on the timeline to select a beat
4. Selected beat snaps to the nearest subdivision
5. Select an obstacle type from the left panel
6. Set vertical position (lane_y slider, 0.0–1.0)
7. Configure obstacle-specific parameters in the right panel
8. Tap "Place" — obstacle appears on timeline as a colored block

**Beat grid visual:**
- Quarter beats: white lines
- Eighth beats: gray lines (shown when zoom level ≥ 2×)
- Sixteenth beats: faint gray lines (shown when zoom level ≥ 4×)
- Current playhead: orange vertical line

### 6.3 Max Obstacles Per Measure

To prevent unplayable levels and protect younger players in the community gallery:

| Zone Style | Max simultaneous on-screen | Max per measure (4 beats) |
|---|---|---|
| Beginner (Z1 style) | 2 | 4 |
| Intermediate (Z2–Z3 style) | 3 | 6 |
| Advanced (Z4–Z5 style) | 4 | 8 |
| Expert (Z6 style) | 5 | 10 |

The editor enforces these limits based on the **Zone Style** selector set by the creator. Placing beyond the limit shows a red warning and prevents saving until resolved.

**Overlap rule:** Two obstacles may not occupy the same beat index AND lane position within ±80 px of each other. The editor draws a red X on conflicting placements.

### 6.4 Difficulty Auto-Tagging

When a level is saved or published, the game automatically calculates a difficulty tag:

```
difficulty_score = (avg obstacles per measure × 2)
                 + (speed_zone max multiplier × 1.5)
                 + (obstacle type diversity × 1)
                 + (BPM / 30)

difficulty_score → tag:
  4–8   → "Beginner"
  9–14  → "Intermediate"
  15–22 → "Advanced"
  23+   → "Expert"
```

Creators can override the tag DOWN (e.g., set "Beginner" for a gentle level that scored 9) but NOT UP. This prevents mislabeled death traps targeting young players.

### 6.5 Publishing Rules

**With Creator Pass:**
- Level must pass auto-playability check: no impossible obstacle positions (collision filling entire lane)
- Level must have a name and at least 16 beats of content
- Level must have been play-tested by creator (play-through logged on device)
- Published levels enter a 24-hour community review queue
- During review, level is visible only to creator
- After review passes: publicly listed in community gallery
- Creator earns 10 coins per unique player who completes their level (capped at 200 coins per level per month)

**Without Creator Pass (5 free levels max):**
- Levels can be created and saved locally
- Can be shared via direct link (not gallery listing)
- Shared link allows one-time download by recipient who also has Creator Pass
- After 5 saved levels, must purchase Creator Pass or delete an existing level to save a new one

### 6.6 Build Mode UI References

- Timeline view: [ASSET: ui_buildmode_timeline.png]
- Obstacle palette panel: [ASSET: ui_buildmode_obstacle_panel.png]
- Properties panel: [ASSET: ui_buildmode_properties.png]
- Playback controls: [ASSET: ui_buildmode_playback.png]
- Difficulty preview badge: [ASSET: ui_difficulty_badge_beginner.png], [ASSET: ui_difficulty_badge_intermediate.png], [ASSET: ui_difficulty_badge_advanced.png], [ASSET: ui_difficulty_badge_expert.png]

---

## 7. Economy

### 7.1 Earning Coins (Free, No Purchase Required)

| Action | Coins Earned |
|---|---|
| Complete a level (first time) | 25 coins |
| Earn 1 star on a level | 10 coins |
| Earn 2 stars on a level | 25 coins |
| Earn 3 stars on a level | 50 coins |
| Improve a previous best star rating by 1 | 15 coins |
| Reach a combo milestone (10, 20, 40, 80) for the first time in session | 5 coins each |
| Collect a sunbeam in Z1 (first 3 per session) | 3 coins each |
| Community level: first completion | 10 coins |
| Creator earning: player completes your published level | 10 coins (capped 200/month/level) |

**Daily play reward:** None. No daily login bonuses, no streak systems. Playing itself is the reward.

### 7.2 Spending Coins (Cosmetic Only)

| Item | Cost | Type |
|---|---|---|
| Trail color variant (per color) | 50 coins | Cosmetic |
| Character outfit/hat skin (per item) | 75–150 coins | Cosmetic |
| Custom UI theme (menu background) | 200 coins | Cosmetic |
| Zone background alternate palette | 150 coins | Cosmetic |
| Beat ring effect variant | 100 coins | Cosmetic |

**Characters are NOT purchasable with coins.** All 8 characters are earned through gameplay achievements only. This prevents pay-to-win and preserves the achievement satisfaction.

### 7.3 Real Money Purchases

| Product | Price | What It Unlocks |
|---|---|---|
| **Unlock Full Reef** | $2.99 (one-time) | Zones 4 and 5 (16 levels), Finn character immediately |
| **Creator Pass** | $1.99 (one-time) | Public level publishing, community gallery access, full obstacle catalog in editor |
| **Reef Bundle** | $3.99 (one-time) | Both above products at combined discount |

**No other purchases exist.** No coin bundles, no loot boxes, no subscriptions, no "lives" purchases.

**IAP presentation rules:**
- IAP prompts only appear when player actively reaches the locked content gate (tries to enter Z4 or tries to publish a level)
- No IAP prompts in the main menu, during levels, or on results screens
- No "Limited time offer" language anywhere in the app
- IAP prompt includes clear description of exactly what is unlocked, nothing vague

---

## 8. Kid Safety Design Rules

This section is binding design policy. Any feature that violates these rules must be removed or redesigned before shipping. These rules apply to all builds, all platforms, and all future updates.

### 8.1 Prohibited Mechanics (Never Implement)

1. **No energy/lives systems.** Players can play any level any number of times without restriction. No "5 lives then wait," no timers of any kind that limit play.

2. **No countdown timers.** No "offer expires in X hours," no "daily reward resets in X hours," no urgency-inducing countdowns anywhere in the UI.

3. **No FOMO mechanics.** No seasonal content that disappears. No "only available for 3 days" items. All purchased content is permanent. All earned content is permanently accessible once unlocked.

4. **No push notifications for re-engagement.** The game may not request notification permissions. No "come back and play!" notifications. The app is silent when not in use.

5. **No social comparison pressure.** Leaderboards (if added) show only the player's own friends (opt-in, not strangers). No "your friend beat your score" notifications. No public ranking of player scores.

6. **No advertising.** No third-party ads of any kind — not banner, not interstitial, not rewarded video ads. The only revenue sources are the two one-time IAPs.

7. **No variable reward schedules (loot boxes).** All purchasable and earnable items have known, fixed prices and known, fixed unlock conditions. No randomized rewards for real money. No "mystery boxes."

8. **No dark patterns in IAP flows.** Purchase screens must clearly state the price, what is included, and that it is a one-time charge. No pre-checked subscription boxes. No confusing button placement (e.g., "Not Now" is same size as "Buy").

9. **No personal data collection beyond what Google Play / Apple requires for in-app purchases and cloud save.** Analytics must be aggregate only (e.g., "level 3 has a 60% clear rate") — never tied to individual player identity.

10. **No chat or user-generated text in public spaces.** Community level names and descriptions are pre-moderated before going public (the 24-hour queue). No free-text chat, no comments on levels, no direct messaging between players.

### 8.2 Required Safety Features

1. **Parental controls compatibility.** Full Reef and Creator Pass IAPs respect device parental control settings. If parental controls require approval for purchases, the game does not attempt to bypass or work around this.

2. **Content must be ESRB E / PEGI 3 throughout.** No blood, no death framing (failure is "bonked," not "died"), no frightening imagery. Level fail screen shows cartoon stars and an encouraging message, not failure imagery.

3. **Accessibility minimum requirements:**
   - Text size never below 16sp on mobile
   - All timing windows are tunable in accessibility settings (can widen PERFECT window to ±100ms)
   - Colorblind mode: all obstacle types differentiated by shape/animation in addition to color
   - One-hand mode: same input as standard (single finger, works already)
   - Reduced motion mode: disables camera shake, reduces particle density by 50%

4. **Offline play:** All content the player has unlocked must be fully playable offline. Cloud save syncs when connection available. No "you need internet to play" for earned content.

5. **Clearly labeled price on all IAP buttons.** Every button that initiates a purchase shows the price in the button label itself (e.g., "Unlock Full Reef — $2.99"), never just "Buy Now."

6. **Appropriate failure messaging.** All fail/retry language uses encouraging framing:
   - "Nice try! Ready to go again?" (not "You failed")
   - "Almost! One more time?" (not "Game Over")
   - 3-star fail: "Great job! Can you find 3 stars?" (not "You only got 2 stars")

7. **Parent-friendly design documentation.** A `PARENTS.md` file in the app bundle explains what data is collected (none beyond platform SDK requirements), how IAPs work, and confirms no advertisements exist.

---

*End of Game Design Document v1.0*
