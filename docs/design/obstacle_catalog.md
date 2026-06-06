# Bubble Reef Rush — Obstacle Catalog
**Version:** 1.0  
**Total obstacle types:** 12  
**Referenced by:** GDD.md Section 2, level_schema.json beat_map entries  

Each entry covers the obstacle's code identity, plain-English behavior, exact movement specification, collision dimensions, asset and audio references, zone distribution, difficulty rating, and all configurable properties available in Build Mode.

---

## Quick Reference

| # | `slug_case` | Display Name | Difficulty | Zones |
|---|---|---|---|---|
| 1 | `coral_spike` | Coral Spike | 1 — Beginner | Z1, Z2 |
| 2 | `jellyfish_drift` | Drifting Jellyfish | 1 — Beginner | Z1, Z2, Z3 |
| 3 | `kelp_curtain` | Kelp Curtain | 2 — Intermediate | Z2, Z3 |
| 4 | `bubble_mine` | Bubble Mine | 2 — Intermediate | Z2, Z3, Z4 |
| 5 | `current_jet` | Current Jet | 2 — Intermediate | Z2, Z3, Z4, Z5 |
| 6 | `anchor_chain` | Anchor Chain | 2 — Intermediate | Z3 |
| 7 | `lava_burst` | Lava Burst | 3 — Hard | Z4, Z6 |
| 8 | `eel_snap` | Snapping Eel | 3 — Hard | Z3, Z4, Z5 |
| 9 | `pressure_wall` | Pressure Wall | 3 — Hard | Z4, Z5 |
| 10 | `dark_void` | Dark Void | 2 — Intermediate | Z5 |
| 11 | `crystal_shard` | Crystal Shard | 3 — Hard | Z6 |
| 12 | `mirror_fish` | Mirror Fish | 3 — Hard | Z5, Z6 |

---

## 1. `coral_spike` — Coral Spike

**Description**  
A cluster of sharp coral protrusions fixed permanently to either the top or bottom wall of the lane. It never moves. The player must hold-to-dive to pass under top-wall spikes, or release-to-float to pass above bottom-wall spikes. It is the first obstacle players ever encounter and serves as the teaching tool for the fundamental hold/release input.

**Behavior Spec**  
- Node type: `StaticBody2D`
- Spawned at the beat-indexed horizontal position when that x-position scrolls into view. It does not move laterally — the player scrolls toward it.
- No movement code. `process()` function is empty.
- Collision detection: `Area2D` child node. When player `CharacterBody2D` enters the `Area2D`: calls `player.on_hit()`, then plays `anim_hit` (brief orange flash on the spike), then obstacle returns to normal appearance.
- The obstacle remains on screen and active for the full level — it does not disappear after the player passes it (the player scrolls past it).
- Colorblind-safe: spikes always have a jagged silhouette shape that reads as a hazard even without the color cue.

**Collision Box**  
- Width: 80 px (wall-to-tip)
- Height: configurable — 120 px / 180 px / 240 px (three presets corresponding to small, medium, large clusters)
- Effective hitbox (inset for fairness): 72 px wide × 90% of configured height
- Attachment axis: origin point is the wall surface (top wall → origin at y=0, extends downward; bottom wall → origin at y=1080px, extends upward)

**Asset Placeholder**  
- Top-wall variant: [ASSET: obs_coral_spike_top.png] — 80×240 px sprite sheet, 3 frames (small/medium/large cluster), coral-pink color, jagged tips pointing downward
- Bottom-wall variant: [ASSET: obs_coral_spike_bottom.png] — same dimensions, tips pointing upward
- Hit flash overlay: [ASSET: obs_coral_spike_hit_flash.png] — orange tinted version, 1 frame

**Audio Cue**  
- On player collision: [SFX: obs_coral_impact] — a dry scraping crunch, 0.4 sec, plays on the SFX bus. No spatialization (2D HUD sound, not positioned).
- Ambient (when within 300 px): none — coral is silent when not hit.

**Zones**  
- Zone 1 (Sunlit Shallows): primary teaching obstacle, appears in all 8 levels
- Zone 2 (Kelp Forest Canyon): continues as filler/contrast with new obstacles; appears in L1, L3, L5, L6, L7, L8

**Difficulty**  
1 — Beginner. Static, always in a fixed position, never requires prediction. Only demands the player know how to hold or release at the right time. Generous clearance gap between spike tip and the far wall always ≥ 400 px.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `wall_attachment` | enum | `top`, `bottom` | `bottom` | Which wall the spike cluster is fixed to |
| `height` | int (preset) | `120`, `180`, `240` | `120` | Height of the spike cluster in pixels |
| `beat_position` | number | any valid beat index | (required) | Beat index when this spike scrolls into the player's approach window |

Editor validation: a `coral_spike` may not be placed at a beat_position where another coral_spike on the same wall is within 4 beats (would create an impossible corridor).

---

## 2. `jellyfish_drift` — Drifting Jellyfish

**Description**  
A free-floating jellyfish that drifts slowly toward the player from the right side of the screen while oscillating gently up and down in a sine-wave pattern. Its bell is the hazard; its trailing tentacles are purely visual. The player learns to track a moving obstacle and adjust their vertical position fluidly — the second layer of skill after mastering hold/release basics.

**Behavior Spec**  
- Node type: `CharacterBody2D`
- Spawns at x = screen_width + 80 px (off right edge), at a configured `lane_start_y` position.
- Lateral movement: `velocity.x = -(scroll_speed + lateral_speed_bonus)` where `lateral_speed_bonus` = 20 px/sec. Applied every `_physics_process()`.
- Vertical movement: `velocity.y = sin(elapsed_time * sine_frequency * TAU) * sine_amplitude`. Note this is velocity, not position — so amplitude here is in px/sec, not px displacement. The resulting positional amplitude is approximately `sine_amplitude / (sine_frequency * TAU)` px.
- Wall clamping: if `position.y < 60` or `position.y > 1020`, vertical velocity reflects (the jellyfish bounces off playfield bounds).
- Despawn: when `position.x < -120` (fully off left edge), `queue_free()`.
- Collision: `CircleShape2D` radius 48 px centered on bell. On player entry: `player.on_hit()`.
- The jellyfish does NOT accelerate or change behavior based on player position — it is entirely predictable from its spawn parameters.

**Collision Box**  
- Shape: circle, radius 48 px
- Center: bell center (visual center of the dome)
- Tentacle sprites extend 120 px below bell center — tentacles have no collision

**Asset Placeholder**  
- Purple variant: [ASSET: obs_jellyfish_a.png] — 100×200 px sprite, 4-frame animation (pulsing bell), purple-violet palette
- Pink variant: [ASSET: obs_jellyfish_b.png] — same dimensions, pink-magenta palette
- Both variants: tentacles are a separate `Sprite2D` child node with a gentle sway animation independent of bell animation

**Audio Cue**  
- On player collision: [SFX: obs_jellyfish_sting] — electric zap with a wet snap, 0.35 sec, SFX bus
- Ambient while on screen: [SFX: obs_jellyfish_ambient] — faint rhythmic pulsing tone, loops for duration on screen. Volume scales with `1.0 - (distance_to_player / 400)`. Plays on Ambient SFX bus at 30% max volume so it does not distract from music.

**Zones**  
- Zone 1 (Sunlit Shallows): introduced at L3. Low sine amplitude and frequency.
- Zone 2 (Kelp Forest Canyon): higher amplitude and frequency variants used.
- Zone 3 (Shipwreck Alley): continues as background filler density; players now familiar with it.

**Difficulty**  
1 — Beginner. Predictable sine pattern, slow approach speed, large clearance around hitbox vs visual sprite size. Introduced only after `coral_spike` has been mastered for at least one level.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `color_variant` | enum | `purple`, `pink` | `purple` | Visual only, no gameplay effect |
| `sine_amplitude` | int (preset) | `50`, `100`, `150` | `100` | Peak oscillation speed (px/sec) |
| `sine_frequency` | float (preset) | `0.5`, `1.0`, `2.0` | `1.0` | Cycles per second |
| `lane_start_y` | float | 0.05–0.95 | `0.5` | Normalized screen Y at spawn (0=top, 1=bottom) |

Editor validation: at least 180 px of clearance between `lane_start_y` position and any wall spike at the same beat range.

---

## 3. `kelp_curtain` — Kelp Curtain

**Description**  
A row of kelp blades rooted to either the top or bottom wall that sways side-to-side in a synchronized wave pattern. The blades fill the lane but a gap appears in the curtain at a predictable rhythmic moment — always aligned to a beat. The player must read the sway pattern and position themselves at the right vertical height to drift through the gap as it opens on the beat.

**Behavior Spec**  
- Node type: `Node2D` (container), child blades are individual `AnimatedSprite2D` + `CollisionShape2D` nodes
- Blade count: 4, 6, or 8 blades depending on configuration
- Each blade sways on a sine rotation: `blade.rotation = max_sway_radians * sin(elapsed_time * sway_speed * TAU + phase_offset)`
- Phase offsets are distributed to create a wave effect: `phase_offset = i * (TAU / blade_count)` where `i` is blade index
- The gap in the curtain is not a missing blade — it is formed by the sway cycle pushing blades to one side, naturally creating a gap at the apex of the sway. The gap aligns to `gap_beat_alignment` which the level designer specifies.
- `ShapeCast2D` on the gap node detects whether the gap is wide enough for player passage (≥ 120 px clear) and broadcasts `gap_open` signal when true. This signal triggers the gap glow visual.
- Collision: each blade has a `CapsuleShape2D` (20 px radius × 180 px height). On player entry: `player.on_hit()`.
- The full curtain object is stationary (does not scroll in from off-screen) — it exists at a fixed x position on the level layout. Player scrolls into it.

**Collision Box**  
- Per blade: capsule, 20 px radius × 180 px tall (effective contact area 40 px wide × 180 px tall)
- Blade count × 40 px = full curtain width varies 160–320 px depending on blade count
- Gap (safe zone): 120 px wide, formed between two blades at sway apex. Effective safe clearance: 110 px (blade capsule radii reduce gap slightly).

**Asset Placeholder**  
- Single blade: [ASSET: obs_kelp_curtain_blade.png] — 40×200 px sprite, 2-frame sway animation (blade slightly curved left, slightly curved right), dark green with lighter edge highlight
- Gap glow indicator: [ASSET: fx_kelp_gap_glow.png] — 120×220 px soft green radial glow, appears when `gap_open` signal fires, fades over 0.2 sec

**Audio Cue**  
- Ambient while player is within 600 px: [SFX: obs_kelp_sway] — low, rhythmic whooshing/brushing sound, 2-sec loop, plays on Ambient SFX bus at 25% max volume
- On player collision with blade: [SFX: obs_kelp_hit] — wet thwap, 0.3 sec, SFX bus

**Zones**  
- Zone 2 (Kelp Forest Canyon): primary zone. Introduced at L2 with slow sway.
- Zone 3 (Shipwreck Alley): re-skinned as barnacle-covered hanging hull plates, same behavior. Asset key differs: [ASSET: obs_hull_plate_curtain.png] but behavior node is the same `kelp_curtain` type with `hull_skin` parameter.

**Difficulty**  
2 — Intermediate. Requires reading a periodic pattern and timing vertical positioning to beat alignment. Not lethal on first encounter if player understands the gap concept. Becomes harder when combined with other obstacles at the same beat.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `blade_count` | int (preset) | `4`, `6`, `8` | `6` | More blades = narrower gap proportionally |
| `sway_speed` | float (preset) | `0.5`, `1.0`, `1.5` | `1.0` | Cycles per second of the wave |
| `gap_beat_alignment` | number | any valid beat | (required) | Beat when gap is fully open; designer must set this intentionally |
| `wall_attachment` | enum | `bottom`, `top` | `bottom` | Wall the blades root from |
| `skin_override` | enum | `default`, `hull_plate` | `default` | `hull_plate` replaces kelp art with rusted metal panels (Z3 thematic use) |

---

## 4. `bubble_mine` — Bubble Mine

**Description**  
A stationary spherical mine wrapped in bubble film that floats in the middle of the lane. It does nothing while the player is far away, then begins pulsing a warning as they approach. Making direct contact with the mine detonates it and damages the player. A skilled player can pass close to it without touching it, or plan their vertical position far enough in advance to swim above or below it entirely.

**Behavior Spec**  
- Node type: `Area2D` with `CircleShape2D`
- The mine is stationary at its configured lane_y position. It does not move.
- State machine with three states:
  - **IDLE**: player further than `arm_radius` px. Mine shows idle animation (slow bubble shimmer). No audio.
  - **WARNING**: player within `arm_radius` px but not touching. Mine plays `anim_pulse` (red-orange pulsing glow). [SFX: obs_mine_tick] plays, ticking rate = `tick_base_rate * (1 + (1 - (distance / arm_radius)))` — ticks faster as player approaches. Min distance reached without contact: mine plays a brief "safe pass" dim animation after player exits.
  - **DETONATION**: player enters `CircleShape2D` (radius 56 px). Calls `player.on_hit()`, then `mine.explode()`. `explode()` instantiates [ASSET: fx_mine_explode.png] particle emitter at mine position, plays [SFX: obs_mine_explode], then `mine.queue_free()`.
- If the mine scrolls off the left edge without detonating: plays a small harmless pop [SFX: obs_mine_offscreen_pop], then `queue_free()`.

**Collision Box**  
- Shape: circle, radius 56 px (the hitbox), centered on mine center
- Warning radius: circle, radius per configuration (160/200/240 px) — this is a detection range, not a collision shape

**Asset Placeholder**  
- Mine sprite: [ASSET: obs_bubble_mine.png] — 120×120 px sprite sheet, 4 animation frames: idle shimmer (2 frames), warning pulse (2 frames)
- Detonation burst: [ASSET: fx_mine_explode.png] — particle texture, 64×64 px burst, instantiated with `GPUParticles2D`, 0.6 sec duration, 40 particles, radial emission

**Audio Cue**  
- Warning ticking: [SFX: obs_mine_tick] — short 0.1-sec click, pitch rises from 0.8 to 1.4 over the approach curve
- Detonation: [SFX: obs_mine_explode] — low-mid frequency bubble pop with reverb tail, 0.8 sec
- Safe pass (player exited warning zone without hitting): [SFX: obs_mine_safe_pass] — descending pitch sweep, 0.4 sec, subtle

**Zones**  
- Zone 2 (Kelp Forest Canyon): introduced at L4. Single mines in open lanes.
- Zone 3 (Shipwreck Alley): pairs and clusters of mines.
- Zone 4 (Volcanic Vent Fields): mines in narrow corridors between lava vents.

**Difficulty**  
2 — Intermediate. Static position is predictable, but the proximity warning can cause panic in new players. The key teaching moment is "mines don't chase you — stay calm and plan ahead."

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `lane_y` | float | 0.1–0.9 | `0.5` | Normalized vertical center of mine |
| `arm_radius` | int (preset) | `160`, `200`, `240` | `160` | Proximity radius for warning state (px) |

Editor validation: two `bubble_mine` entries may not have overlapping warning radii at the same beat (would create a forced-hit gauntlet). Editor warns but does not block — this allows expert-tier player-created levels to intentionally do this.

---

## 5. `current_jet` — Current Jet

**Description**  
A high-pressure water jet that fires horizontally from one of the lane walls, crossing the entire playfield. It has a clearly telegraphed warning phase before firing, giving the player time to move their character out of the jet's horizontal path. The jet fires for a short burst, then has a cooldown, and repeats on a beat-synced cycle for as long as it is on screen.

**Behavior Spec**  
- Node type: `Node2D` container with `Area2D` child for the jet stream
- The nozzle fixture is a `StaticBody2D` embedded in the wall at `lane_position` (configured normalized Y for left/right origin, or normalized X for top/bottom origin). The nozzle does not move.
- State machine cycle: **IDLE** (1 beat at 120 BPM) → **TELEGRAPHING** (0.5 sec) → **FIRING** (0.4 sec) → **COOLDOWN** (0.3 sec based on `cycle_beats` setting) → back to IDLE
- Cycle duration maps to beats: at default `cycle_beats = 2`, one full IDLE-to-IDLE cycle = 2 beats. The cycle is synchronized to the level's beat clock using `beat_timer.timeout` signals, not raw elapsed time — ensuring the jet always fires on-beat regardless of frame rate.
- During TELEGRAPHING: `anim_warning` plays on nozzle — a bright glow and pre-pressure shudder. Jet stream area is visible as a semi-transparent [ASSET: obs_current_jet_stream.png] overlay at 30% opacity.
- During FIRING: jet stream `Area2D` collision shape activates. Jet stream opacity rises to 100%, particles emit [ASSET: fx_jet_particles.png]. [SFX: obs_jet_stream] plays for duration.
- During COOLDOWN: collision deactivates, stream fades to 0%, nozzle plays cool-down animation.
- On player collision during FIRING: `player.on_hit()`, [SFX: obs_jet_hit].
- Jet stream geometry: full playfield width in direction of travel (640 px default, scales with resolution). In the perpendicular axis, the jet is 80 px tall (for left/right jets) or 80 px wide (for top/bottom jets).

**Collision Box**  
- Shape: rectangle, 640 px (travel axis) × 80 px (cross-section axis)
- Origin anchored to nozzle position
- Hitbox active only during FIRING state (0.4 sec per cycle)
- Effective hitbox: 640 × 72 px (10% narrower cross-section for fairness)

**Asset Placeholder**  
- Nozzle fixture: [ASSET: obs_current_jet_nozzle.png] — 60×80 px, pipe/vent shape protruding from wall, gray-green metal
- Jet stream texture: [ASSET: obs_current_jet_stream.png] — 640×80 px repeating texture, turbulent water appearance, UV-scrolls along travel axis at 200 px/sec during FIRING
- Jet particles: [ASSET: fx_jet_particles.png] — 16×16 px foam particle, used by `GPUParticles2D` emitter at nozzle mouth

**Audio Cue**  
- Telegraph charge: [SFX: obs_jet_charge] — rising pressure hiss over 0.5 sec, ends with a click just before firing
- Firing stream: [SFX: obs_jet_stream] — high-pressure rushing water loop, 0.4 sec (non-looping, just the burst), spatial (volume scales with distance from jet center at player Y)
- Player hit: [SFX: obs_jet_hit] — knockback splash, wet impact, 0.4 sec

**Zones**  
- Zone 2 (Kelp Forest Canyon): introduced at L2. Single slow-cycle jets from left wall only.
- Zone 3 (Shipwreck Alley): jets from both left and right walls. Faster cycle.
- Zone 4 (Volcanic Vent Fields): jets retextured as steam vents. Same behavior with [ASSET: obs_steam_jet_nozzle.png] skin.
- Zone 5 (Twilight Trench): jets combined with dark void phases.

**Difficulty**  
2 — Intermediate. Telegraph is generous. Core challenge is maintaining vertical position through multiple jet cycles while other obstacles are present.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `origin_wall` | enum | `left`, `right`, `top`, `bottom` | `left` | Wall the nozzle is mounted on |
| `lane_position` | float | 0.1–0.9 | `0.5` | Perpendicular-axis position (Y for L/R jets, X for T/B jets) |
| `beat_phase_offset` | float | 0.0–1.0 | `0.0` | Fraction of a beat to offset the start of the first cycle |
| `cycle_beats` | int (preset) | `2`, `3`, `4` | `2` | Total beats per full cycle (shorter = more frequent firing) |
| `skin_override` | enum | `default`, `steam_vent` | `default` | `steam_vent` for Z4 visual theming |

---

## 6. `anchor_chain` — Anchor Chain

**Description**  
A heavy anchor hangs from the top of the screen on a long chain, swinging back and forth like a pendulum. Both the chain links and the anchor itself are solid hazards. The pendulum arc is wide enough that the chain sweeps most of the horizontal lane area, but at the two apex points (extreme left and extreme right of the swing), the chain briefly pauses — and a glow highlight signals this as the safe moment to cross. The player must time passing through the chain's path to this apex window.

**Behavior Spec**  
- Node type: `Node2D` with pivot at the top center attachment point (x = configured x position, y = 0)
- Pendulum physics: `rotation = max_angle_radians * sin(elapsed_time * pendulum_frequency * TAU)`. This is kinematic — not physics-based — for deterministic behavior.
- `angular_velocity = d(rotation)/dt`. Apex detection: when `abs(angular_velocity) < apex_threshold` (0.05 rad/sec), the `on_apex` signal fires, triggering [ASSET: fx_chain_apex_glow.png] glow on the chain.
- Collision structure: 6 `CapsuleShape2D` segments placed along the chain length. Each is 16 px radius × 60 px tall. Positioned relative to the pivot using `transform` calculations each frame as the chain rotates. The anchor at the chain bottom is a `RectangleShape2D` 80×60 px.
- All collision shapes are child `Area2D` nodes under the rotating `Node2D`, so they rotate automatically with the parent.
- On player collision with any shape: `player.on_hit()`.
- The chain does not scroll — it is at a fixed x position and the player scrolls past it.

**Collision Box**  
- Per chain segment: capsule, 16 px radius × 60 px tall, 6 segments (total chain coverage ≈ 360 px)
- Anchor: rectangle, 80 × 60 px at chain bottom
- Full swing arc width at widest: 2 × chain_length × sin(max_angle_radians) px

**Asset Placeholder**  
- Chain + anchor sprite sheet: [ASSET: obs_anchor_chain.png] — 100×800 px sprite, contains chain links tiling pattern and anchor head at bottom; rendered as a `Line2D` + `Sprite2D` combination
- Top attachment: [ASSET: obs_anchor_mount.png] — 80×40 px rusted ceiling mount fixture
- Apex glow: [ASSET: fx_chain_apex_glow.png] — 160×400 px soft white radial glow, placed at chain midpoint, plays 0.3 sec then fades

**Audio Cue**  
- Ambient loop (while on screen): [SFX: obs_chain_creak] — deep metallic groaning with a rhythmic creak at each swing apex, 4-sec loop synchronized to pendulum period
- Player collision: [SFX: obs_chain_hit] — ringing metal clang with resonant tail, 0.6 sec
- Apex signal (safe moment): [SFX: obs_chain_apex_chime] — very brief (0.1 sec) high-frequency ping, subtle but distinct from the creak

**Zones**  
- Zone 3 (Shipwreck Alley): exclusive. The anchor is thematically appropriate here. No other zones use this obstacle (it would feel out-of-place).

**Difficulty**  
2 — Intermediate. Predictable sinusoidal pattern. Main challenge: the apex window is brief, and at faster pendulum speeds the timing required approaches GOOD/PERFECT window territory.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `max_angle_degrees` | int (preset) | `20`, `35`, `50` | `35` | Full swing arc (half angle each side) |
| `pendulum_frequency` | float (preset) | `0.3`, `0.5`, `0.8` | `0.5` | Full swings per second |
| `chain_length` | int (preset) | `300`, `500`, `700` | `500` | Chain length in pixels from pivot |
| `beat_phase_offset` | float | 0.0–1.0 | `0.0` | Fractional beat to offset chain start phase |
| `x_position` | float | 0.1–0.9 | `0.5` | Normalized horizontal position of chain pivot |

---

## 7. `lava_burst` — Lava Burst

**Description**  
A volcanic vent in the floor (or ceiling) builds up pressure and erupts a scalding column of superheated water straight across the lane. A bright ground-glow and audio rumble telegraph the eruption with enough time for the player to swim away from the vent's horizontal position. The column is wide and covers the full lane height — there is no gap to pass through. The only safe response is to be at a different horizontal position before it fires. This forces the player to use their dive/float skill to change lane position laterally (relative to incoming obstacles) rather than just vertically.

**Behavior Spec**  
- Node type: `Node2D` with `Area2D` child for eruption column
- Vent fixture is a `StaticBody2D` at the floor (or ceiling), x position set by `x_position` parameter
- State machine: **DORMANT** (configurable beats) → **TELEGRAPHING** (0.6 sec) → **ERUPTING** (0.3 sec) → **COOLDOWN** (0.2 sec) → back to DORMANT
- Cycle repeats until obstacle scrolls off screen
- TELEGRAPHING: `anim_glow` plays on vent, expanding orange-white glow on floor. Audio: [SFX: obs_lava_rumble]. Eruption column `Area2D` is invisible and collision off.
- ERUPTING: Instantiates [ASSET: obs_lava_column.png] particle column at vent x position, full screen height. Column `Area2D` collision activates (RectangleShape2D 96×1080 px, centered on vent x). Camera micro-shake: `magnitude=4, duration=0.3s`. Audio: [SFX: obs_lava_erupt].
- COOLDOWN: Column fades over 0.2 sec. No collision. Vent plays short cool-down animation.
- On player collision during ERUPTING: `player.on_hit()`. [SFX: obs_lava_hit].
- Player cannot dodge the column once it erupts — they must have moved away during TELEGRAPHING.

**Collision Box**  
- Shape: rectangle, 96 px wide × 1080 px tall (full screen height)
- Centered on vent x position
- Active only during ERUPTING state (0.3 sec)
- Visual eruption column is 120 px wide; hitbox is 96 px (20% narrower for fairness at the edges)

**Asset Placeholder**  
- Vent base: [ASSET: obs_lava_vent_base.png] — 120×80 px, circular vent opening in volcanic rock floor
- Telegraph glow: [ASSET: obs_lava_vent_glow.png] — 200×200 px radial glow, orange-white, animated 4 frames of expanding pulse
- Eruption column: [ASSET: obs_lava_column.png] — 120×1080 px vertical particle texture, hot white core with orange-red edges, UV-scrolls upward at 800 px/sec during ERUPTING
- Z6 skin (steam vent): [ASSET: obs_steam_vent_base.png] and [ASSET: obs_steam_column.png] — same behavior, cooler visual palette (blue-white steam)

**Audio Cue**  
- Telegraph: [SFX: obs_lava_rumble] — sub-bass rumble building from 0 to full over 0.6 sec, low-frequency heavy
- Eruption: [SFX: obs_lava_erupt] — explosive burst, 0.3 sec, mid-high frequency crack with steam hiss tail
- Player hit: [SFX: obs_lava_hit] — sizzling hiss + impact crunch, 0.5 sec
- Dormant ambient (while on screen): [SFX: obs_lava_idle] — quiet bubbling hiss, spatial, volume scales with distance, max 20% volume

**Zones**  
- Zone 4 (Volcanic Vent Fields): primary zone. Multiple vents per level.
- Zone 6 (Crystal Caves): re-skinned as steam vents, same behavior. Uses `steam_vent` skin parameter.

**Difficulty**  
3 — Hard. Column width and full-height coverage leave no vertical escape — player must have correct horizontal position before eruption. Hardest aspect: at higher BPMs, dormant phase is shorter, leaving less time to plan.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `wall_origin` | enum | `bottom`, `top` | `bottom` | Which wall the vent erupts from |
| `x_position` | float | 0.1–0.9 | `0.5` | Normalized horizontal position of vent |
| `dormant_beats` | int (preset) | `2`, `4`, `8` | `4` | Beats between eruptions |
| `erupt_beat_index` | number | any valid beat | (required) | Beat of first eruption trigger |
| `skin_override` | enum | `default`, `steam_vent` | `default` | Asset skin for Z6 use |

---

## 8. `eel_snap` — Snapping Eel

**Description**  
A moray eel lurks inside a hole bored in the left or right wall. It briefly pokes its head out to warn the player, then shoots its body forward at high speed to a fixed strike length before retracting. The eel occupies a fixed vertical lane row — the player must have their character above or below the eel's vertical position during the strike. The fast extension makes it punishing if ignored, but the 0.5-second telegraph is intentionally generous for the age group.

**Behavior Spec**  
- Node type: `Node2D` containing a wall-hole `Sprite2D` and an eel `AnimatedSprite2D` that extends
- State machine: **DORMANT** (configurable beats, eel fully hidden) → **TELEGRAPH** (0.5 sec, eel head visible 40 px out of hole) → **STRIKE** (0.15 sec, eel extends to `strike_length`) → **RETRACT** (0.3 sec, eel slides back into hole) → **DORMANT**
- Extension via `Tween`: `tween.tween_property(eel_body, "position:x", strike_length, 0.15).set_ease(Tween.EASE_IN)` (for left-wall eel, direction flipped for right-wall)
- Collision: `RectangleShape2D` on eel body, 60 px tall × `strike_length` px long. Attached as child `Area2D`, only monitoring during STRIKE state. On player entry: `player.on_hit()`.
- Retraction is also fast but not dangerous (collision off during RETRACT).
- Eel remains at its wall position for entire level. Does not scroll.
- Colorblind safety: eel uses a distinct silhouette (long thin form) and the hole has a unique frame [ASSET: obs_eel_hole.png] that signals "danger lives here."

**Collision Box**  
- Width: 200 / 300 / 400 px (matches `strike_length`)
- Height: 60 px
- Centered on eel's vertical lane position
- Active only during STRIKE state (0.15 sec)

**Asset Placeholder**  
- Eel head: [ASSET: obs_eel_head.png] — 80×64 px, moray eel face with open mouth, green-brown spotted pattern
- Eel body segment: [ASSET: obs_eel_body_segment.png] — 60×64 px, repeating body tile; extended length = strike_length / 60 tiles rendered as `MultiMeshInstance2D`
- Wall hole: [ASSET: obs_eel_hole.png] — 100×80 px, dark circular opening in wall texture with algae fringe
- Retract animation: head and body tiles contract back into hole via Tween simultaneously

**Audio Cue**  
- Telegraph: [SFX: obs_eel_hiss] — brief raspy hiss, 0.4 sec, spatial
- Strike: [SFX: obs_eel_snap] — sharp forward-rushing "schwick" sound, 0.15 sec, fast attack
- Player hit: [SFX: obs_eel_hit] — wet crunch + eel squeal, 0.5 sec
- Dormant ambient: none (eel is silent when hidden)

**Zones**  
- Zone 3 (Shipwreck Alley): introduced at L4. Single eels in open lane. Used thematically in ship hull sections.
- Zone 4 (Volcanic Vent Fields): multiple eels, shorter dormant periods.
- Zone 5 (Twilight Trench): eels combined with dark void phases — audio telegraph becomes critical.

**Difficulty**  
3 — Hard. The 0.15-sec strike extension requires the player to have started moving before the strike begins. Reaction to the strike itself is impossible; reaction to the telegraph is the intended skill. At 165 BPM, two beats = 0.73 sec — just enough for telegraph + response.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `origin_wall` | enum | `left`, `right` | `left` | Which wall the eel lives in |
| `lane_y` | float | 0.1–0.9 | `0.5` | Normalized vertical center of eel hole |
| `strike_length` | int (preset) | `200`, `300`, `400` | `300` | How far the eel extends into the lane (px) |
| `dormant_beats` | int (preset) | `2`, `4`, `6` | `4` | Beats between strike attempts |

---

## 9. `pressure_wall` — Pressure Wall

**Description**  
A wall of compressed deep-water pressure slides across the screen from one side, covering the full lane height and pushing toward the player. The wall has exactly one safe gap — a clearly illuminated opening in the pressure field. The player must be vertically aligned with this gap before the wall reaches them. Unlike the lava burst (fixed position to avoid), this challenge requires the player to navigate TO a specific vertical position: the gap location.

**Behavior Spec**  
- Node type: `Node2D` sliding laterally
- Structure: two `Area2D` rectangles representing the upper wall (top of screen to gap top) and lower wall (gap bottom to screen bottom). A `Sprite2D` visual fills between them. The gap is the absence of these rectangles.
- Movement: `position.x -= travel_speed * delta` (for right-entry wall). Spawns off right edge of screen, exits off left edge.
- Gap highlight: `Sprite2D` [ASSET: fx_pressure_gap_highlight.png] placed at gap y center, moves with wall, always visible.
- Collision: Both `Area2D` rectangles have collision active for the entire traversal. On player entry into either rectangle: `player.on_hit()`.
- Despawn: when `position.x < -screen_width - 100`, `queue_free()`.
- Visual: semi-transparent animated texture [ASSET: obs_pressure_wall.png] with UV-scrolling to suggest moving water. Upper/lower sections each rendered with this texture at full opacity.
- Pre-spawn warning: one beat before the wall enters the screen, a brief [SFX: obs_pressure_build] plays and a thin colored line briefly appears at the entry edge to signal the wall is coming.

**Collision Box**  
- Upper section: full wall width × (gap_y_center - gap_height/2) px tall from top
- Lower section: full wall width × (1080 - gap_y_center - gap_height/2) px tall from gap bottom to screen bottom
- Full wall width = travel distance = screen_width + 200 px
- Effective hitbox: 90% of visual wall width (leading edge is not instantly lethal — a 10% grace on approach side)

**Asset Placeholder**  
- Wall body: [ASSET: obs_pressure_wall.png] — 200×1080 px repeating texture, blue-white compressed water with horizontal streamlines; UV scrolls at 100 px/sec perpendicular to travel for "alive" look
- Gap highlight: [ASSET: fx_pressure_gap_highlight.png] — gap_height × gap_height px soft rectangular glow, cyan-white, pulses gently at beat rate

**Audio Cue**  
- Incoming warning: [SFX: obs_pressure_build] — rising hum, 0.5 sec, plays one beat before wall enters screen
- Traversal (while wall is on screen): [SFX: obs_pressure_traverse] — sustained deep pressure drone, 1-sec loop, volume based on wall proximity to player. Spatial horizontal only.
- Wall exits screen: [SFX: obs_pressure_pass] — whooshing release, 0.5 sec, doppler-style pitch drop
- Player hit: [SFX: obs_pressure_hit] — deep resonant thump, as if hitting a wall of water, 0.6 sec

**Zones**  
- Zone 4 (Volcanic Vent Fields): introduced at L4. Gap always in center-ish position.
- Zone 5 (Twilight Trench): combined with dark_void — player must find gap by sound when vision is obscured.

**Difficulty**  
3 — Hard. Unlike other hazards, this requires proactive positioning — the player must be at the right height BEFORE the wall arrives. Players who react to it typically fail.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `entry_side` | enum | `left`, `right` | `right` | Side wall enters from |
| `gap_y_normalized` | float | 0.1–0.9 | `0.5` | Normalized Y center of safe gap |
| `gap_height` | int (preset) | `120`, `160`, `200` | `160` | Height of gap in px (larger = easier) |
| `travel_speed` | int (preset) | `300`, `450`, `600` | `450` | Px/sec lateral speed of wall |
| `beat_index` | number | any valid beat | (required) | Beat when wall enters the screen |

---

## 10. `dark_void` — Dark Void

**Description**  
A zone of supernatural darkness descends over the lane, reducing the player's visibility to a tiny halo around their own character. The void itself cannot be collided with — it is an environmental effect. Any other obstacles already placed in the level continue to function normally during a void. The challenge is navigating those other obstacles using only the audio cues and the brief beat-synchronized pulse of the player's glow. This is the only obstacle designed to teach sound-as-guidance rather than sight.

**Behavior Spec**  
- Node type: `CanvasLayer` (renders above gameplay, below HUD)
- Implementation: full-screen `ColorRect` set to `Color(0, 0, 0, 0.95)` (near-opaque black) with a `ShaderMaterial` that carves a soft radial transparent hole centered on the player's screen position.
- Radial cutout formula in shader: `alpha = max(0, 0.95 - (1.0 - smoothstep(0.0, radius_normalized, dist_from_player)))`. Where `radius_normalized = 40px / screen_half_height`. Result: 40 px fully visible zone around player, feathered over 20 px.
- On beat (synchronized via `SignalBus.beat_fired` signal): cutout radius pulses from 40 → 80 px and back over 0.1 sec via `Tween`, simulating a heartbeat-style pulse. This helps players feel the beat through vision even when dark.
- Transition in: `ColorRect` alpha animates 0 → 0.95 over 0.3 sec via `Tween`.
- Transition out: same, 0.95 → 0 over 0.3 sec.
- Duration: `duration_beats` beats from the triggering beat index. After duration, void dissolves.
- During void, [ASSET: fx_beat_ring_dark.png] white ring (instead of normal beat ring) pulses from player at double radius (80 px) on each beat, providing a larger visual reference.
- Has no collision. `dark_void` cannot damage the player. Only other obstacles during the void can damage.

**Collision Box**  
None — environmental effect only.

**Asset Placeholder**  
- Void overlay: full-screen shader [ASSET: shader_dark_void.gdshader] — takes `player_screen_pos: vec2` and `cutout_radius: float` as uniform parameters. Attached to `ColorRect`.
- Beat ring during void: [ASSET: fx_beat_ring_dark.png] — 200×200 px white circle outline, 4 px stroke, used by player beat ring emitter when void is active

**Audio Cue**  
- Void entry: [SFX: obs_dark_void_enter] — deep, resonant fade-in hum, 0.3 sec
- Void loop: [SFX: obs_dark_void_loop] — a bass-heavy heartbeat-style pulse, 2-sec loop, plays for full void duration. Tempo of the loop is locked to level BPM (via AudioStreamPlayer `pitch_scale` adjustment: `pitch = bpm / 72.0` where 72 BPM = native loop tempo).
- Void exit: [SFX: obs_dark_void_exit] — reverse of entry hum, 0.3 sec
- Note: during void, music continues at normal volume — the void loop is mixed at 40% volume underneath it.

**Zones**  
- Zone 5 (Twilight Trench): exclusive. Thematically appropriate for the deep trench setting where bioluminescence is the only light source.

**Difficulty**  
2 — Intermediate. The void itself deals no damage. Difficulty scales entirely with what other obstacles have been placed during the void beats. A void with no other obstacles is trivially easy; a void during an eel_snap sequence is very hard.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `duration_beats` | int (preset) | `2`, `4`, `6`, `8` | `4` | How many beats the darkness lasts |
| `beat_index` | number | any valid beat | (required) | Beat when void begins |
| `pulse_with_beat` | bool | `true`, `false` | `true` | Whether cutout radius pulses on each beat |

Editor note: build mode warns (but does not block) if a `dark_void` is placed on a level flagged as "Beginner" difficulty. Dark voids in beginner levels should have `duration_beats = 2` and no hard obstacles during the void period.

---

## 11. `crystal_shard` — Crystal Shard

**Description**  
A large, spinning crystal fragment shoots across the screen in a diagonal trajectory. It bounces off the top and bottom walls of the playfield, reflecting off each wall at the angle it hit — predictable physics. It moves fast — significantly faster than any other obstacle — but its path is completely deterministic from spawn parameters. The player who tracks it carefully can always predict where it will be. The player who ignores it will be surprised.

**Behavior Spec**  
- Node type: `CharacterBody2D`
- Spawn: at x = screen_width + 40 px (off right edge), y = `entry_y_normalized * screen_height`
- Initial velocity: `Vector2(-lateral_speed, initial_vertical_speed)` where `initial_vertical_speed` = 300 px/sec if `diagonal_speed_initial = down`, -300 px/sec if `up`. This is a fixed vertical speed, not configurable — only direction is set.
- Movement: `move_and_collide()` handles wall collisions. Godot's built-in wall reflection provides angle-of-incidence = angle-of-reflection behavior.
- Wall layers: top and bottom playfield boundaries are `StaticBody2D` walls. The shard collides with them, not the player; the shard's main `Area2D` detects the player.
- Rotation: `rotation += rotation_speed * delta` where `rotation_speed` = ±3.5 rad/sec (clockwise/counter based on parameter). Rotation is continuous and does not affect velocity.
- Despawn: when `position.x < -100`, `queue_free()`.
- Collision: `CapsuleShape2D` on `Area2D` child, 40 px radius × 80 px tall, rotates with sprite. On player overlap: `player.on_hit()`.
- Player skill: because trajectory is fully deterministic, a skilled player can predict bounces ahead of time and plan vertical position accordingly.

**Collision Box**  
- Shape: capsule, 40 px radius × 80 px tall
- Rotates with sprite rotation
- Note: because the shard rotates, the effective collision shape sweeps an approximately circular area of 80 px diameter at any given moment

**Asset Placeholder**  
- Blue variant: [ASSET: obs_crystal_shard_a.png] — 80×160 px sprite, elongated hexagonal crystal shape, ice-blue with bright specular highlight, 2-frame sparkle animation
- Teal variant: [ASSET: obs_crystal_shard_b.png] — same dimensions, teal-cyan palette
- Wall bounce spark: [ASSET: fx_crystal_bounce_spark.png] — 40×40 px particle burst, instantiated at wall contact point and destroyed after 0.3 sec

**Audio Cue**  
- While on screen: [SFX: obs_crystal_hum] — high-pitched resonant tone, pitch shifts slightly based on velocity direction (Doppler approximation via `pitch_scale` parameter)
- Wall bounce: [SFX: obs_crystal_bounce] — clear glass ping, 0.2 sec, spatial at bounce point
- Player hit: [SFX: obs_crystal_hit] — shattering glass burst with reverb, 0.8 sec
- Spawn: [SFX: obs_crystal_spawn] — brief rising crystal tone as shard enters screen, 0.2 sec

**Zones**  
- Zone 6 (Crystal Caves): exclusive. The crystal environment makes shards feel native to the world. No other zone uses this obstacle.

**Difficulty**  
3 — Hard. High speed gives minimal reaction time. Multiple shards on screen simultaneously multiply complexity. Core skill tested: predictive tracking, not reflexes.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `entry_side` | enum | `left`, `right` | `right` | Side screen the shard enters from |
| `entry_y_normalized` | float | 0.05–0.95 | `0.3` | Normalized Y of spawn position |
| `lateral_speed` | int (preset) | `400`, `600`, `800` | `600` | Horizontal speed in px/sec |
| `diagonal_speed_initial` | enum | `up`, `down` | `down` | Initial vertical travel direction |
| `color_variant` | enum | `blue`, `teal` | `blue` | Visual palette variant |
| `rotation_direction` | enum | `clockwise`, `counter` | `clockwise` | Spin direction |

Editor validation: at 800 px/sec, a shard crosses the full screen in ~1.2 sec. At 180 BPM (0.33 sec/beat), the shard is on screen for ~3.6 beats. Editor calculates and displays "screen time: X beats" for each placed shard so designers can judge reaction time windows.

---

## 12. `mirror_fish` — Mirror Fish

**Description**  
An exact visual copy of the player character that copies the player's past movements — but with a time delay. It approaches the player from the front (right side of screen, moving left — opposite to scroll direction), and its vertical position at any moment is where the player was a set number of frames ago. To avoid it, the player must perform vertical movements now that, when delayed, will place the mirror fish in a safe position when it arrives. This is the only obstacle that requires predicting one's own future actions.

**Behavior Spec**  
- Node type: `CharacterBody2D`
- Position tracking: a `RingBuffer` (circular array) stores `player.global_position.y` every `_physics_process()` frame. Size = `delay_frames` entries (20, 30, or 45 frames).
- `mirror_fish.global_position.y = ring_buffer.read_oldest()` each frame. This means the mirror fish's Y exactly matches where the player was `delay_frames` frames ago.
- `mirror_fish.global_position.x` advances leftward: `position.x -= (scroll_speed + approach_speed_bonus) * delta`. Spawns at x = screen_width + 80 px.
- The mirror fish does not apply physics — it purely reads from the ring buffer for Y and advances on its own for X. It cannot be bumped, pushed, or redirected.
- Visual indicator: a thin dashed line [ASSET: fx_mirror_fish_trail.png] drawn as a `Line2D` between the player's current position and the mirror fish's current position, rendered at 30% opacity. This helps players understand the offset.
- On player collision (player `Area2D` overlaps mirror fish `Area2D`): `player.on_hit()`. The mirror fish then plays `anim_shatter` and `queue_free()`.
- If mirror fish exits left edge without collision: `queue_free()` silently.
- The ring buffer begins filling from the moment the obstacle spawns. If the player hasn't provided `delay_frames` frames of input yet, the buffer is pre-filled with the player's current Y position (so the fish spawns at the same height and moves with the player until the buffer fills).

**Collision Box**  
- Identical to player hitbox: 80 px wide × 60 px tall ellipse
- This is intentional — the mirror fish is the same "size" as the player character

**Asset Placeholder**  
- Mirror fish sprite: [ASSET: obs_mirror_fish.png] — uses the currently selected player character sprite with a `ShaderMaterial` applying a blue-tint + horizontal-flip effect: `COLOR.rgb = mix(COLOR.rgb, vec3(0.2, 0.6, 1.0), 0.5); UV.x = 1.0 - UV.x;`
- Trail line: [ASSET: fx_mirror_fish_trail.png] — dashed line texture used by `Line2D`, blue-tinted, 4 px width
- Shatter effect: [ASSET: fx_mirror_fish_shatter.png] — particle texture for the `on_hit()` burst, 8 fragments, blue-tinted player character sprite pieces

**Audio Cue**  
- Spawn (enters from right): [SFX: obs_mirror_appear] — reversed-audio whoosh, creates an "appearing from the future" sensation, 0.4 sec
- While on screen: [SFX: obs_mirror_ambient] — quiet echo of the player's own movement sounds at 20% volume with a 0.5-sec delay. The echo effect reinforces the time-delay mechanic aurally.
- Safe pass (mirror fish exits left without collision): [SFX: obs_mirror_pass] — brief descending chime, 0.3 sec
- Player hit: [SFX: obs_mirror_hit] — dual-impact "thump" — one normal and one echoed 0.1 sec after, reinforcing the mirror concept

**Zones**  
- Zone 5 (Twilight Trench): introduced at L3. Single mirror fish, 30-frame delay.
- Zone 6 (Crystal Caves): combined with crystal shards and other Z6 obstacles. Multiple mirror fish on screen simultaneously (each with independent ring buffers) are possible at expert difficulty.

**Difficulty**  
3 — Hard. Unique cognitive demand: the player must think ahead about their own movements. No other obstacle in the game requires this. Combined with `dark_void` or `crystal_shard`, it becomes the game's highest difficulty pairing.

**Level Editor Properties**

| Property | Type | Options | Default | Notes |
|---|---|---|---|---|
| `delay_frames` | int (preset) | `20`, `30`, `45` | `30` | Frames of delay (at 60fps: 0.33s / 0.5s / 0.75s) |
| `approach_speed_bonus` | int (preset) | `50`, `100`, `150` | `100` | Additional px/sec on top of scroll speed for approach |
| `beat_index` | number | any valid beat | (required) | Beat when mirror fish enters from right edge |

Editor note: placing multiple `mirror_fish` entries at the same or adjacent beats creates situations where both fish are reading from the same player input sequence simultaneously. This can create unavoidable collisions if not carefully spaced. The editor displays predicted Y paths for each placed mirror fish so the designer can verify no two fish overlap.

---

*End of Obstacle Catalog v1.0*  
*For integration with Godot 4: obstacle classes are located in `scripts/obstacles/`. Each slug maps to a scene file: `scenes/obstacles/{slug_case}.tscn`.*
