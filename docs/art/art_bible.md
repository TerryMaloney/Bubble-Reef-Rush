# Bubble Reef Rush — Art Direction Bible
**Version:** 1.0
**Art Director:** C-2
**Target Platform:** Android / iOS — 1080×1920 portrait
**Engine:** Godot 4.x
**Audience:** Ages 6–12

---

## Table of Contents
1. [Visual Style Guide](#1-visual-style-guide)
2. [Character Specs](#2-character-specs)
3. [Obstacle Visual Specs](#3-obstacle-visual-specs)
4. [Background & Zone Art Specs](#4-background--zone-art-specs)
5. [UI Art Specs](#5-ui-art-specs)
6. [Effects (VFX) Specs](#6-effects-vfx-specs)

---

## 1. Visual Style Guide

### 1.1 Core Style Keywords

These seven adjectives define every art decision in this game. When in doubt, ask: does this asset embody all seven?

1. **Bubbly** — forms are round, inflated, never angular or sharp at the compositional level
2. **Luminous** — colors feel lit from within; subsurface scattering on everything organic
3. **Saturated** — no muted tones in gameplay elements; desaturation is used only as a deliberate contrast cue (danger, darkness)
4. **Bouncy** — squash-and-stretch is present everywhere; nothing holds a rigid silhouette for more than one frame
5. **Warm** — even cool blues and teals carry a warmth that reads as safe and inviting, not cold
6. **Readable** — every hazard is distinguishable from every other at 80×60 px on a phone screen
7. **Saturday-Morning** — the aesthetic reference is 1990s–2000s US Saturday morning cartoons: SpongeBob SquarePants, The Little Mermaid animated series, Finding Nemo. Clean ink outlines, expressive eyes, primary palettes.

### 1.2 Color Palette

#### Global Base Palette (used across all zones in UI and outlines)
| Role | Hex | Usage |
|---|---|---|
| Ink Outline | `#1A2233` | All character and obstacle outlines. Never pure black — the slight blue warmth keeps it from feeling harsh. |
| Pure White Highlight | `#FFFFFF` | Specular dots on eyes, bubble highlights, PERFECT hit burst center |
| Soft White | `#F0F8FF` | Beat rings, float trail bubbles, gap highlight pulses |
| Coin Yellow | `#FFD700` | Coins, star ratings, PERFECT hit burst outer ring |
| Alert Red | `#FF4040` | Combo break flash, hit reaction tint, mine warning pulse |
| UI Shadow | `#0D1A2E` | Drop shadows behind all UI panels — deep navy, never grey |

#### Zone 1 — Sunlit Shallows
| Role | Hex | Notes |
|---|---|---|
| Main Water | `#40C8E0` | Bright tropical cyan, mid-value. The "default ocean" read. |
| Floor / Wall | `#F5D88A` | Warm sandy yellow. Slightly textured, not flat. |
| Accent | `#FF7F5C` | Warm coral-orange. Used on coral spike obstacles and foreground pop elements. |
| Obstacle Tint | `#FF9AC1` | Pink-coral. Jellyfish and coral spike secondary hue. |
| Particle Color | `#FFFAAA` | Warm pale yellow. Sunbeam motes and float bubble shimmer. |

#### Zone 2 — Kelp Forest Canyon
| Role | Hex | Notes |
|---|---|---|
| Main Water | `#2A6B4A` | Deep forest green. Darker than Z1 — more enclosed feeling. |
| Floor / Wall | `#4A3020` | Dark warm brown-grey rocky canyon wall. |
| Accent | `#C8A830` | Gold. Filtered light and coin trails. |
| Obstacle Tint | `#1E8B4A` | Kelp medium green with slight yellow. |
| Particle Color | `#90E0B0` | Light seafoam. Bubble particles in the kelp. |

#### Zone 3 — Shipwreck Alley
| Role | Hex | Notes |
|---|---|---|
| Main Water | `#1A3A5C` | Dark navy. Sunken, shadowed feel. |
| Floor / Wall | `#6B4530` | Rust-brown. Oxidized hull metal and seafloor. |
| Accent | `#70C090` | Seafoam green. Bioluminescent fringe on wreck edges. |
| Obstacle Tint | `#A87840` | Amber. Porthole light glow and aged wood. |
| Particle Color | `#8FB8D0` | Pale grey-blue. Silt and debris motes. |

#### Zone 4 — Volcanic Vent Fields
| Role | Hex | Notes |
|---|---|---|
| Main Water | `#1A0A00` | Near-black with red undertone. Deep volcanic dark. |
| Floor / Wall | `#3D1800` | Very dark burnt sienna. Volcanic rock. |
| Accent | `#FF6010` | Hot orange. Lava vent glow and burst core. |
| Obstacle Tint | `#FF9040` | Orange-gold. Vent glow halos and heat shimmer. |
| Particle Color | `#FF3000` | Bright red-orange. Lava eruption particles. |

#### Zone 5 — Twilight Trench
| Role | Hex | Notes |
|---|---|---|
| Main Water | `#050818` | Near pitch-black navy. Almost pure dark. |
| Floor / Wall | `#120830` | Deep purple-black. Abyssal rock with slight purple tint. |
| Accent | `#30C8FF` | Electric blue. Bioluminescence. |
| Obstacle Tint | `#8840FF` | Violet. Dark void glow and mirror fish trail. |
| Particle Color | `#60FFCC` | Neon teal. Bioluminescent creature motes. |

#### Zone 6 — Crystal Caves
| Role | Hex | Notes |
|---|---|---|
| Main Water | `#E8F0FF` | Near-white with pale blue. Crystal-refracted clarity. |
| Floor / Wall | `#C0D8FF` | Pale lavender-blue. Crystal wall base. |
| Accent | Prismatic — animates through spectrum | Crystal resonance illumination cycles hue over 3 seconds. Base anchor: `#FFD0FF` (pale magenta). |
| Obstacle Tint | `#80F0FF` | Bright cyan. Crystal shard base color. |
| Particle Color | `#FFFFFF` with prismatic shimmer overlay | Crystal dust is white but each particle has a random hue shimmer on it. |

#### UI Palette
| Role | Hex | Notes |
|---|---|---|
| Primary Button | `#FF8820` | Warm orange. The single most important tap target. |
| Primary Button Pressed | `#CC6010` | Same hue, 20% darker. Instant visual press feedback. |
| Secondary Button | `#40C0FF` | Sky blue. Back, cancel, secondary actions. |
| Disabled Element | `#708090` | Neutral blue-grey. Never use pure grey — it reads "broken." |
| Panel Background | `#0A1E3A` | Deep ocean navy. HUD panel fill. |
| Panel Border | `#40A8D0` | Medium bright teal. Pill-border ring on all panels. |
| Score Text | `#FFFFFF` | White on dark panels. |
| Combo Text | `#FFD700` | Gold. Stands out above score text during multiplier. |
| Lives (full) | `#FF4080` | Hot pink heart. |
| Lives (empty) | `#3A2A3A` | Dark muted purple. Empty heart silhouette. |

### 1.3 Typography Direction

**Font personality:** Rounded, bubbly, approachable. Never serif. Never condensed. Letters should look like they have a little air inside them.

**Recommended Google Fonts (free, no licensing risk):**

| Role | Font | Notes |
|---|---|---|
| Game title / Zone name headers | **Baloo 2** ExtraBold (800 weight) | Wide, puffy letterforms. Reads clearly at large scale. |
| Score / Number display | **Nunito** ExtraBold (800 weight) | Rounded numerals, consistent width. Easy to read at speed. |
| Button labels | **Nunito** Bold (700 weight) | Same family as score, slightly lighter. |
| Body text (level descriptions, tooltips) | **Nunito** Regular (400 weight) | Minimum 16sp on mobile per accessibility rules. |
| Character name plates | **Baloo 2** SemiBold (600 weight) | Used in character select and dialogue labels. |

**Text size minimums (binding from GDD Section 8.2):**
- Body / tooltip text: 16sp minimum
- Button labels: 20sp minimum
- Score / combo display: 40sp minimum (must be legible mid-gameplay without squinting)
- Zone/level name headers: 32sp minimum

**Outline treatment:** All game-world text (score, combo counter) uses a 3px ink-outline stroke in `#1A2233` to separate it from busy backgrounds.

### 1.4 Shape Language Rules

These rules apply to every art asset. Violations will be called back.

**Characters (ALL must follow):**
- Primary body shape: circle or oval only. No character may have a dominant rectangular or triangular body mass.
- Fins, limbs, appendages may be slightly tapered but must terminate in a rounded tip — no sharp points.
- Eyes are always perfectly round (iris), never narrow or slit unless the character has a specific personality eye variant (Lumina is the sole exception — slightly narrowed ambient expression, but eye shape rounds fully on reaction frames).
- Maximum of 3 hard corners on any single character frame, and each must be immediately adjacent to a rounded region.

**Obstacles:**
- Hazard obstacles may use triangular/spike silhouettes to signal danger, but tips must be visually softened — rounded over approximately 4 px radius at the asset resolution. This maintains readability as a threat without being "sharp" in the toy-graphics sense.
- Bubble Mine and Jellyfish are fully circular — they should read as "friendly shaped but dangerous." The hazard is communicated through color (warning red, electric purple) and animation (pulse), not shape aggression.

**UI:**
- All buttons and panels use pill shapes (fully rounded rectangle, border-radius = 50% of short dimension).
- Progress bars use pill outer container, solid fill with no sharp leading edge — use a convex rounded cap on the fill segment.
- The combo counter badge is circular.
- Star icons: 5-point stars but with rounded tips and a puffed center — not geometric stars.

**Backgrounds:**
- Far/mid parallax elements: organic shapes only. No straight lines in coral, kelp, or rock formations. All rock edges are lumpy and irregular.
- Shipwreck geometry (Zone 3) may have straight lines (planks, hull panels) but must show wear, curve, and damage that breaks the straightness. No pristine right angles on organic/weathered material.

### 1.5 Lighting

**Top-down sunlight model:**
All zones (except Z5 and Z6) receive simulated overhead sunlight entering from the top of the screen. This is implemented as:
- A gradient overlay on the far background layer: lighter at top, darker at bottom.
- Character sprites rendered slightly lighter on their top surface, slightly darker on their underside. Baked into sprite art — not a runtime shader — except for Zone 6 crystal reflections.
- Caustic light patterns (animated ripple overlays on floor): present in Z1, Z2, Z3. Absent in Z4 (volcanic heat haze replaces), Z5 (no ambient light), Z6 (crystal refraction replaces).

**Subsurface scattering look:**
Organic soft-bodied characters (Pebble, Mochi, Lumina, jellyfish obstacles) should have their primary body mass lit with a slight warm glow at the thinnest areas — ears and extremity edges glow warm amber-yellow as if light is passing through them. This is baked into the sprite art as a color gradient at body edges: main body color transitions to `#FFE8A0` (warm yellow-cream) at the silhouette edge before the ink outline.

**Caustic pattern spec:**
- Asset: `fx_caustic_overlay_z{zone}.png` — 1080×1920 looping animated texture, 8 frames at 6fps.
- Blend mode: Screen (or Godot equivalent: `CanvasItem.blend_mode_add` at 15–20% opacity).
- Pattern description: irregular white-gold web of refracted light. Each "cell" of the web is 60–120 px wide. The web animates by gentle distortion, not movement — it does not scroll. It shimmers in place.
- Zones using caustics: Z1 (warm yellow-gold, dense), Z2 (cooler green-gold, sparse), Z3 (amber, flickering intensity for "murky" feel).

---

## 2. Character Specs

All characters share the same gameplay hitbox (80 px wide × 60 px tall ellipse) regardless of sprite dimensions. Sprites are rendered at 80×60 px in-game from 128×96 px source art (2× source resolution for crispness on high-DPI mobile screens).

**Sprite sheet structure for all characters:**
- Sheet dimensions: 2816×96 px (22 frames × 128 px wide, single row)
- Frame size: 128×96 px
- Frame order: idle_0, idle_1, idle_2, idle_3 | dive_0, dive_1, dive_2, dive_3 | float_0, float_1, float_2, float_3 | hit_0, hit_1 | death_0, death_1, death_2, death_3 | win_0, win_1, win_2, win_3
- All frames must have a clean, consistent ink outline in `#1A2233` at 2px at source resolution.
- Registration point (pivot): horizontal center, vertical 60% from top (roughly center-of-mass for a fish).

**Animation state FPS guide:**
- idle: 8 fps (lazy, calm)
- dive: 12 fps (energetic, committed motion)
- float: 8 fps (gentle drift)
- hit: 16 fps (snap reaction, fast)
- death: 10 fps (dramatic but not violent)
- win: 10 fps (celebratory)

**Eye design principle:**
Eyes are the emotional core of every character. They must be readable at game render size (80×60 px). Minimum eye diameter at source resolution: 20 px per eye. All eyes use a white sclera (or equivalent), a colored iris, a black pupil, and a single white specular dot. The specular dot is always positioned at 10 o'clock within the pupil.

---

### 2.1 Pebble (Pufferfish)

**Role:** Default character. The face of the game. Must be the most immediately appealing.

**Sprite Dimensions:** 128×96 px source (renders at 80×60 px)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Body Primary | `#FF8C42` | Main body orange — warm, bright, inviting |
| Body Secondary | `#FFB86A` | Belly and cheek highlight — lighter orange |
| Spine Tips | `#FFD080` | Pale yellow tips on pufferfish spines |
| Eye Color | `#4040A0` | Deep periwinkle blue iris |
| Accent / Blush | `#FF6090` | Small pink blush circles on cheeks (2 circles, always visible) |

**Key Silhouette:** Nearly perfect circle with a slightly flattened bottom. Small triangular spines distributed around the body (pointing outward) break the exact circle just enough to be readable as "spiky fish." At thumbnail size, reads as a round orange ball with small points.

**Animation State Details:**
- **idle (frames 0–3):** Entire body gently rises and falls 3 px, one complete cycle over 4 frames. On frame 2, a small bubble blows from the mouth and floats up. Spines fully extended.
- **dive (frames 4–7):** Body compresses into an oval (squash horizontally 75%, stretch vertically 115% of rest size). Body tilts 30° nose-down. Spines tuck slightly inward. On frame 4: begin tilt. Frame 6: maximum compression. Frame 7: hold compressed pose.
- **float (frames 8–11):** Body relaxes back to round shape. Gentle side-to-side fin wiggle (tiny pectoral fins on either side sway ±15° alternating). Body drifts up 2 px over 4 frames.
- **hit (frames 12–13):** Frame 12: body squashes to 120% wide × 80% tall, changes tint to `#FF4040` (alert red). Frame 13: snaps back toward normal, still slightly red-tinted. Both frames have a white flash ring behind the character.
- **death (frames 14–17):** Frame 14: eyes go to ×× (crossed-out pupils). Frame 15: body squashes vertically to 40% height (classic cartoon "squished" pose), arms/fins splay out. Frame 16: hold squish, color fades to greyscale. Frame 17: body is flat, stars orbit above.
- **win (frames 18–21):** Frame 18: body rapidly puffs to 140% of rest size (maximum inflation). Frame 19–20: bounces up and down while fully puffed. Frame 21: big grin expression, eyes arc upward (happy crescents), single sparkle on each spine tip.

**Squash/Stretch Notes:**
- Dive: body squashes to approximately 70% of normal height, elongates to 110% width. The "tucked ball" look — Pebble pulls inward for speed.
- Float: body is at 100% normal size or very slightly expanded. If floating at terminal velocity, a very gentle upward stretch to 105% height is acceptable on frame 1 of the float loop.
- Hit: sudden expansion to 125% in one frame, snap back. The "puffer" mechanic plays into this — Pebble reflexively puffs on impact.

**Eye Description:** Large circular eyes, approximately 22 px diameter at source resolution. Positioned slightly above center-mass of the face, 18 px apart. Periwinkle blue iris, solid black pupil occupying 60% of iris diameter. White specular dot at 10 o'clock, 4 px diameter. On idle and float states, eyes are fully open. On dive, eyes narrow to 80% height (slight determined squint). On win, eyes arc into happy crescents (upper lid curves down). On death, pupils become × marks.

---

### 2.2 Zap (Electric Ray)

**Role:** "Cool kid" character. Sleek, fast-looking, electric energy.

**Sprite Dimensions:** 128×96 px source (renders at 80×60 px)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Body Primary | `#3060E0` | Bright electric blue — flat ray body |
| Body Secondary | `#80B0FF` | Pale blue — underbelly and fin edge highlight |
| Electric Accent | `#E0FFAA` | Yellow-green — electric discharge markings, spark trails |
| Eye Color | `#FFFFFF` | White iris (unusual — signals electric, high-contrast look) |
| Spot Pattern | `#1A3080` | Dark navy — 3 circular spots on dorsal surface |

**Key Silhouette:** Wide flat diamond / kite shape. The two "wing" pectoral fins extend to nearly full sprite width, creating a distinctive top-down triangle silhouette with a thin tail trailing right. At thumbnail size, unmistakably wide and flat — opposite of Pebble's circle.

**Animation State Details:**
- **idle (frames 0–3):** Wing tips undulate in a slow wave — left tip rises while right tip falls, alternating over 4 frames. Small electric spark appears randomly on body surface every 2–3 seconds (appears on frame 2, fades by frame 4).
- **dive (frames 4–7):** Ray body goes flat (wing tips fold downward, toward tail). Body elongates 15%, wing span reduces to 60% of normal. Tail curves slightly upward. Electric markings brighten.
- **float (frames 8–11):** Wings fully extended, slow wing-flap undulation (same as idle but with upward drift implied by 3 px position rise over 4 frames). Wings catch water above and below.
- **hit (frames 12–13):** Full-body electric discharge — body flashes to `#E0FFAA` (yellow-green) on frame 12, immediately back to normal on frame 13 with a mini spark burst radius emanating from body center.
- **death (frames 14–17):** Electric charge fizzles — sparks shoot out in all directions on frame 14, body goes grey-blue on frame 15, wings droop on frame 16, body falls flat (rotates 90° clockwise) on frame 17.
- **win (frames 18–21):** Electric arc between wing tips (a spark that travels tip-to-tip). Eyes wide, mouth in a huge grin. Entire body crackles with yellow-green sparks for all 4 frames.

**Squash/Stretch Notes:**
- Dive: wing span compresses in, body elongates — like a ray that folds its wings to streamline for depth.
- Float: wings at maximum span — widest the character ever appears.
- Hit: brief bloom outward (110% overall scale) then snap-back.

**Eye Description:** Small but intense eyes, positioned at the front ("nose") end of the ray body. 16 px diameter at source. White iris, very small black pupil — making the eyes look wide and startled-but-cool at all times. Iris boundary is outlined with a thin `#3060E0` ring (matching body color, 2px). No soft sclera white separate from iris — white IS the iris.

---

### 2.3 Mochi (Moon Jellyfish)

**Role:** Dreamy, gentle, ethereal. The "floaty" personality.

**Sprite Dimensions:** 128×96 px source (renders at 80×60 px)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Bell Primary | `#D0E8FF` | Very pale blue-white. Semi-transparent look. |
| Bell Glow | `#80B0FF` | Soft periwinkle. Subsurface glow within the bell. |
| Tentacle Color | `#A090E0` | Pale violet. Trailing tentacles. |
| Inner Organ | `#FFB0D0` | Soft pink. Visible "flower" pattern inside bell. |
| Eye Color | `#8060C0` | Medium purple iris. |

**Key Silhouette:** Dome (half-circle) at top, trailing wisps below. The bell is the readable shape — a clear upside-down bowl. Tentacles extend below but are visual-only. At thumbnail size: a pale rounded dome with wavy streamers below.

**Animation State Details:**
- **idle (frames 0–3):** Bell slowly pulses — contracts to 90% height on frames 1–2, expands back to 100% on frames 3–4. The inner pink flower pattern pulses brighter on contraction. Gentle glow emanates from bell perimeter.
- **dive (frames 4–7):** Bell elongates vertically to 120% height × 80% width (tall and narrow, "power pulse" shape). Tentacles stream upward as if caught in the dive current. Bell contracts once per frame to drive.
- **float (frames 8–11):** Bell at full width, maximum dome profile. Tentacles drift downward gently. Body glows softly brighter on float than dive.
- **hit (frames 12–13):** Bell flattens completely (10% height × 150% width — classic cartoon pancake) on frame 12. Returns to 80% normal on frame 13 with a ripple emanating outward from the flatten point.
- **death (frames 14–17):** Bell deflates from bottom to top over frames 14–16 (like air escaping), going grey and transparent. Frame 17: completely flat, barely visible, tentacles gone.
- **win (frames 18–21):** Bell pulses rapidly (3 quick contractions over 3 frames), each pulse emitting a ring of small glowing orbs. Frame 21: full extension with every orb in orbit.

**Squash/Stretch Notes:**
- Dive: bell elongates vertically (tall and narrow — jellyfish pumping for depth).
- Float: bell widens (broad, open, passive ascent).
- These are the most extreme squash/stretch of any character — lean into it. Mochi should feel gelatinous and springy.

**Eye Description:** Very large eyes for such a small creature — 26 px diameter at source, positioned at the base of the dome (near the bell opening). This creates a slightly surreal look where the eyes peek out from inside the dome. Purple iris, round black pupil (50% iris diameter). Eyes are always half-lidded in idle/float (dreamy expression) — lid closes to 60% of iris diameter from above. On win: eyes fully open wide. On death: spiral pupils.

---

### 2.4 Crusher (Hermit Crab)

**Role:** Tough exterior, soft heart. The surprise comedian of the roster.

**Sprite Dimensions:** 128×96 px source (renders at 80×60 px)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Shell Primary | `#C06030` | Rust-red. The castle-shaped shell is the dominant visual. |
| Shell Detail | `#E09060` | Light orange. Battlements, ridges, and brick-pattern lines on shell. |
| Claw / Body | `#E08040` | Warm orange. Visible crab claws and face. |
| Eye Color | `#30A040` | Bright green iris. The contrast with the orange body makes eyes pop. |
| Shell Highlight | `#FFD0A0` | Pale cream. Specular on curved shell surface. |

**Key Silhouette:** A wide, lumpy snail-shell shape dominating the upper-right of the sprite frame, with crab claws and stalked eyes visible to the left. The shell is read as a miniature castle — battlements on top. At thumbnail size: a reddish-orange blob with a distinctive crenellated top edge.

**Animation State Details:**
- **idle (frames 0–3):** Crab body visible outside shell, polishes shell with one claw on frame 2. Eyes on stalks bob up and down slightly. Occasional slow eye-roll (eye rotates, then stalk droops) on frame 3.
- **dive (frames 4–7):** Body retreats partially into shell — claws pull in, only eye stalks and top of claws visible above shell rim. Shell tilts slightly forward (5°). Eyes squint in concentration.
- **float (frames 8–11):** Crab fully out of shell, claws extended wide, legs paddle. Shell bobs with the body. Crab looks pleased with itself.
- **hit (frames 12–13):** Full shell retreat — body disappears completely into shell on frame 12. Shell bounces (scale pulse to 115%) on frame 13. A small "ding" star effect appears at shell rim.
- **death (frames 14–17):** Frame 14: shell spins. Frame 15: shell flies off upward (out of frame). Frame 16: bare crab is fully visible, looking surprised and embarrassed. Frame 17: crab attempts to cover itself with its claws.
- **win (frames 18–21):** Crab emerges fully from shell, raises both claws in triumph, looking smug. Frame 20: a tiny flag waves from the top of the castle shell.

**Squash/Stretch Notes:**
- Dive: shell compresses slightly (squash in direction of travel), body retreats inside. The shell becomes the "safe ball" shape on dive.
- Float: body extends fully out, maximizing width as claws spread.
- Hit: shell is the squash element — it compresses and bounces like a rubber ball.

**Eye Description:** Stalked eyes — each eye is on a stalk that extends 10 px above the body. Eye itself is 16 px diameter. Bright green iris, round black pupil. The stalks can angle independently, creating expressive looks (both stalked up = alert, one drooping = sarcastic). Shell partially occludes the body in dive state — eyes remain visible above shell rim at all times.

---

### 2.5 Pip (Sea Turtle Hatchling)

**Role:** Small, earnest, precise. The mastery-reward character.

**Sprite Dimensions:** 128×96 px source (renders at 80×60 px)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Shell Top | `#4A7840` | Dark olive green. Shell dorsal surface. |
| Shell Pattern | `#2A4820` | Deep forest green. Hexagonal scute pattern lines on shell. |
| Body / Head | `#70A858` | Medium green. Head, neck, flippers. |
| Belly | `#C8E890` | Pale yellow-green. Underbelly visible on float frames. |
| Eye Color | `#8B4513` | Warm brown iris. Earnest, wide-eyed. |

**Key Silhouette:** Small, compact oval shell with four small flippers extending outward. The head protrudes from the front. At thumbnail size: a dark green oval (shell) with small paddle shapes around it and a small round head at one end. Smallest character on the roster — sprite should feel proportionally smaller than Pebble despite the same 128×96 canvas.

**Animation State Details:**
- **idle (frames 0–3):** Slow, deliberate flipper paddling cycle — front flippers alternate up-down strokes (one stroke per 2 frames). Head turns slightly left on frame 2, then right on frame 4, as if looking around curiously.
- **dive (frames 4–7):** All four flippers pull back against the shell (tuck position). Head retracts slightly. Body tilts 30° nose-down. Shell scutes glow faintly green — "dive mode."
- **float (frames 8–11):** Front flippers extend wide and stroke upward in unison. Belly visible (camera angle shifts subtly to imply upward tilt). Small stream of bubbles from nostrils.
- **hit (frames 12–13):** All four flippers snap inward (full tuck), head pulls back. Shell glows briefly red (hit tint overlay on frame 12). Flippers start coming back out on frame 13.
- **death (frames 14–17):** Shell flips upside down slowly (rotation over frames 14–16). Frame 17: shell rocking upside-down with tiny legs waving helplessly in the air.
- **win (frames 18–21):** Shell glows brightly green-gold. Small Pip peeks out of shell with the widest possible eyes and the biggest grin. Flippers do a rapid excited flutter for all 4 frames.

**Squash/Stretch Notes:**
- Pip has the least exaggerated squash/stretch of any character — by design. The character's personality is "steady and precise," so movement is less bouncy.
- Dive: primarily a rotation/tuck — not a body squash. The shell shape stays consistent.
- Float: flippers extend to their furthest — the only "expansion" on this character.

**Eye Description:** Proportionally large for a turtle — 20 px diameter at source. Warm brown iris, round black pupil, positioned at front of head. Eyes are always fully open (no half-lid — earnest, alert at all times). On win, eyes expand to 130% normal size (the "stars in eyes" moment). On death, eyes go to wide spiral pupils.

---

### 2.6 Lumina (Anglerfish)

**Role:** Mysterious, wise, slightly theatrical. Unlocked through endurance (completing Z5).

**Sprite Dimensions:** 128×96 px source (renders at 80×60 px)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Body Primary | `#2A1840` | Very dark purple-black. Deep sea creature. |
| Body Secondary | `#4A3060` | Slightly lighter purple. Fin and jaw underside. |
| Lure | `#C0FF80` | Bright yellow-green. The glowing lure (esca) on head stalk. |
| Lure Glow | `#E0FFC0` | Pale yellow-green. Lure glow halo (painted as soft radial bloom behind lure). |
| Eye Color | `#FF8040` | Amber-orange iris. Piercing, intelligent. |

**Key Silhouette:** Round-ish body (slightly wider than tall) with a distinct head stalk and glowing lure bobbing above the body center. Large, slightly open mouth with visible teeth at rest. At thumbnail size: dark blob with a bright glowing dot above it (the lure is the most readable element at small size — design to it).

**Animation State Details:**
- **idle (frames 0–3):** Body almost completely still (anglerfish are ambush predators — stillness is on-brand). Only the lure moves: it bobs on the stalk in a slow, deliberate arc (like a fishing rod swaying). On frame 3: one long, slow blink.
- **dive (frames 4–7):** Body tilts 30° forward, lure retracts (stalk pulls back, lure dims to 60% brightness). Body slightly elongates forward. The lure briefly flickers off entirely on frame 6 — the character "extinguishes" to dive.
- **float (frames 8–11):** Lure extends to maximum height above body, glowing brightly. Body tilts back slightly. Fins extend. Lure swings in a wider arc than idle.
- **hit (frames 12–13):** Lure flickers violently (4 rapid on/off flashes compressed into frame 12). Body scale pulses outward (115%). Frame 13: lure out, body back to 100%, expression shifts to startled.
- **death (frames 14–17):** Lure dims and goes out frame 14. Body slowly goes dark (color fades to near-black) over frames 15–16. Frame 17: body is nearly invisible except for outline; a single dim ember of the lure still faintly glows (poignant touch).
- **win (frames 18–21):** Lure blazes to full brightness, illuminating a wide radius (painted glow halo at 200% normal size). Mouth opens into a rare, wide, satisfied smile. Body rotates back slightly as if basking.

**Squash/Stretch Notes:**
- Lumina has minimal squash/stretch compared to bubbly characters — angular fish body is less elastic.
- Dive: elongation forward (15–20% stretch in travel direction, slight compression in perpendicular).
- Float: lure height extends, adding apparent vertical stretch.
- The lure (esca) is the character's "squash/stretch substitute" — it does the expressive physical work that the body doesn't.

**Eye Description:** Large round eyes, 22 px diameter. Amber-orange iris with an unusual thin slit pupil at rest (personality exception approved — reads as mysterious). On reaction frames (hit, win), pupil rounds fully. Eyes are positioned slightly too large and slightly too far forward on the face — the uncanny quality is intentional and age-appropriate-spooky, not frightening.

---

### 2.7 Finn (Friendly Great White Shark)

**Role:** Big, enthusiastic, surprisingly timid. IAP unlock — should feel premium but not intimidating.

**Sprite Dimensions:** 128×96 px source (renders at 80×60 px)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Dorsal Surface | `#8090A0` | Blue-grey. Classic shark coloring but softened. |
| Belly | `#F0F0F8` | Off-white. Visible on float frames. |
| Fin Edges | `#607080` | Slightly darker blue-grey. Fin silhouette definition. |
| Eye Color | `#40C080` | Aqua green iris. Warm and friendly, counters shark menace. |
| Blush | `#FFB0B0` | Soft pink. Large circular blush marks — essential for friendliness. |

**Key Silhouette:** Large triangular dorsal fin extending well above the body centerline — this is the single most recognizable silhouette element. Body is torpedo-shaped. Two large pectoral fins. The dorsal fin height should be approximately 40% of total sprite height and fully visible even in dive frames (it only tucks in partially). At thumbnail size: torpedo body with distinctive tall triangle on top.

**Animation State Details:**
- **idle (frames 0–3):** Body paddles gently. Dorsal fin at full height. One pectoral fin waves on frame 2 (a little "hi" wave). Nervous smile present — big toothy grin but eyes slightly anxious.
- **dive (frames 4–7):** Dorsal fin tucks partially into back (reduces to 60% height — streamlining). Body tilts 25° downward. Pectoral fins fold back. Expression becomes determined.
- **float (frames 8–11):** Dorsal fin fully extended, body tilts upward 15°. Pectoral fins spread wide. A small "V" bubble wake trails behind body (painted as 3 small bubbles, staggered).
- **hit (frames 12–13):** Frame 12: entire body shudders — every fin flares outward, eyes go wide (shocked expression). Frame 13: body pulls into a tight ball (as tight as a shark can get — body still torpedo-ish but scale reduces to 90%, all fins retract). This "flinch" behavior is the "surprisingly timid" personality moment.
- **death (frames 14–17):** Frame 14: Finn crosses eyes. Frame 15: slowly tips sideways. Frame 16: floating belly-up (rotated 90°), all fins drooped. Frame 17: small bubbles drift upward from the barely-open mouth.
- **win (frames 18–21):** Big toothy open-mouth grin (maximum tooth display, but teeth are blunt and friendly — no points). Dorsal fin waves like a flag. Eyes crescent-arched (pure joy). Body bounces up and down rapidly.

**Squash/Stretch Notes:**
- Finn has moderate squash/stretch — torpedo body resists extreme deformation but the dorsal fin is the stretch proxy.
- Dive: body elongates slightly, dorsal tucks.
- Float: dorsal fin extends to maximum — the "expansion" element.
- Hit: full-body flinch (every fin flares then tucks) is more interesting than standard squash — use it.

**Eye Description:** Medium-large eyes, 20 px diameter. Aqua-green iris, round black pupil. Very large pink blush circles (30 px diameter each) painted onto cheek areas are essential — without them Finn reads as threatening. Eyebrows (painted on as thick curved arcs above the eyes) default to slightly raised (anxious) in all neutral frames. Lower to calm on win frames.

---

### 2.8 Grumble (Giant Isopod)

**Role:** Ancient, stoic, secretly delighted. The ultimate challenge reward — earns only by 3-starring Z6-L8.

**Sprite Dimensions:** 128×96 px source (renders at 80×60 px)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Shell Primary | `#6070A0` | Slate blue-grey. Segmented armored carapace. |
| Shell Shadow | `#3A4860` | Dark navy-grey. Deep between shell segments (painted shadow). |
| Underside / Legs | `#B0C0D8` | Light blue-grey. Many tiny legs visible below shell edge. |
| Eye Color | `#D0B080` | Warm gold-amber iris. Ancient, knowing. |
| Shell Highlight | `#A0B8D8` | Pale blue highlight on segment ridges. |

**Key Silhouette:** Wide, flat oval — like a giant pill bug or armadillo. Segmented shell shows 5–6 visible horizontal segment lines. Many small legs visible as a fringe along the bottom edge. Two large compound eyes on stalks at the front. At thumbnail size: a wide grey-blue oval with a distinctive horizontally-banded pattern. Unmistakably different from every other character.

**Animation State Details:**
- **idle (frames 0–3):** Completely motionless for frame 0 and frame 1. Frame 2: one very slow head turn (20° rotation toward camera or away). Frame 3: returns to forward facing. The extreme stillness is the personality. Small antennae twitch on frame 3.
- **dive (frames 4–7):** Body curls into armadillo ball — the most dramatic shape change on the roster. Over frames 4–6, the body curves until it forms a nearly perfect sphere (the classic isopod defensive curl). Frame 7: rolled sphere, all legs tucked inside, traveling as a ball.
- **float (frames 8–11):** Body uncurls to full flat form. All legs undulate in a synchronized wave from front to back — the beautiful coordinated motion of a many-legged creature. Extremely regular and almost hypnotic.
- **hit (frames 12–13):** Curls partially (50% of the full dive curl) very rapidly on frame 12. A sharp clang effect around body perimeter. Immediately begins uncurling on frame 13.
- **death (frames 14–17):** Curls into full ball (frame 14). Ball slowly stops moving (frame 15–16). Frame 17: ball becomes completely still. One leg pokes out, then retracts. (Darkly funny — the character is fine but playing dead.)
- **win (frames 18–21):** Full body uncurled. All legs flutter simultaneously at double speed (wild, chaotic leg flutter — contrast to the careful synchronized float wave). Frame 20: the stoic face finally cracks — the tiniest upward curl of the mouth. Frame 21: returns to stoic expression. The almost-smile is the payoff.

**Squash/Stretch Notes:**
- Grumble's squash/stretch is architectural rather than cartoony.
- Dive: the full curl is a transformation, not a stretch. The character goes from flat oval to near-perfect sphere.
- Float: the flat form at maximum width is the "expanded" state.
- The contrast between these two extremes (flat vs sphere) is more dramatic than any squash/stretch on the roster.

**Eye Description:** Compound eyes on short stalks (8 px stalks). Each eye 18 px diameter. Warm gold-amber iris, with a honeycomb texture pattern painted inside the iris at source resolution to suggest compound eye facets. Round black pupil in center (50% iris). The eyes convey ancient calm — they do not animate expressively. Only on frame 20 (the win almost-smile) do the eyes soften even slightly.

---

## 3. Obstacle Visual Specs

All obstacles use the same ink outline style as characters: `#1A2233` at 2px at source resolution. All obstacle hitboxes are "fair" — the actual collision shape is always 10–20% smaller than the visible sprite in the critical threat direction.

**General hitbox visualization rule:** The hitbox boundary should fall 8–12 px inside the sprite outline at source resolution. This means the very edge of the drawn sprite (the ink outline itself plus approximately 3 px inside it) is always outside the collision zone. Players learn to trust this and it makes near-misses feel thrilling rather than unfair.

---

### 3.1 `coral_spike` — Coral Spike

**Sprite Dimensions:** 80×240 px (static, single sprite with 3 height variants — see note below)

**Note on dimensions:** The sprite sheet contains 3 frames side by side: 80×120 (small), 80×180 (medium), 80×240 (large), making the sheet 240×240 px. The game selects the appropriate frame based on the `height` parameter.

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Coral Body | `#FF7090` | Warm coral-pink. Main spike body. |
| Coral Highlight | `#FFB0C0` | Light pink. Ridge highlight on each spike. |
| Base Rock | `#B05040` | Dark terracotta. Base attachment area at wall. |

**Animation:** Static — no animation frames. However, on collision, a 1-frame orange flash overlay `#FF8040` at 80% opacity plays for 0.1 sec.

**Visual Telegraph / Warning State:** None — coral spikes are always visible and never activate. Their "warning" is their permanent presence. At first appearance in Z1-L1, a subtle glow pulse [a single ring expanding from the spike tip] plays once when the spike first scrolls on screen, teaching the player "this is a hazard."

**Hitbox Visualization:** Effective hitbox is 72 px wide × 90% of height. Visually, the outermost 4 px of each spike tip (the sharp coral nub at the furthest extent) is outside the hitbox. The ink outline at the spike tips is drawn in two layers — outer decorative tip (no collision) is slightly thinner ink (1px) vs inner collision boundary (2px) — a subtle readability cue for close looks.

---

### 3.2 `jellyfish_drift` — Drifting Jellyfish

**Sprite Dimensions:** 100×200 px (bell is top 100×100 px; tentacles occupy lower 100×100 px)

**Color Palette — Purple Variant (`obs_jellyfish_a.png`):**
| Swatch | Hex | Usage |
|---|---|---|
| Bell Primary | `#A060D0` | Medium violet. Main bell dome. |
| Bell Glow | `#D0A0FF` | Pale lavender. Inner bell glow (subsurface scattering). |
| Tentacle | `#804080` | Dark purple. Trailing tentacles — no collision. |

**Color Palette — Pink Variant (`obs_jellyfish_b.png`):**
| Swatch | Hex | Usage |
|---|---|---|
| Bell Primary | `#FF80A0` | Bright pink. Main bell dome. |
| Bell Glow | `#FFD0E0` | Very pale pink. Inner glow. |
| Tentacle | `#C06080` | Dark pink-rose. Tentacles. |

**Animation:** 4-frame loop. Frame 0: bell at rest (full dome). Frame 1: bell contracts to 85% height × 115% width (power stroke). Frame 2: bell extends back to 100%. Frame 3: bell slightly over-extends to 105% height (momentum). Plays at 8 fps.

**Visual Telegraph / Warning State:** No pre-activation telegraph — jellyfish are always actively moving. However, their sine-wave path is visually predictable. When first entering the screen from the right, a brief trail of 3 glowing dots (matching bell color) precedes the jellyfish by 20 px, suggesting direction of travel.

**Hitbox Visualization:** Collision circle radius 48 px centered on bell center. The tentacles extend 120 px below bell center and are purely visual — no collision. The ink outline on the tentacle area uses a dashed-style rendering (alternating 4px solid, 4px gap) as a subtle "non-dangerous" visual cue. Bell outline is solid. Bell is 96 px diameter; hitbox is 96 px diameter — a rare case where hitbox matches bell closely, but tentacles are clearly shown as non-hazardous.

---

### 3.3 `kelp_curtain` — Kelp Curtain

**Sprite Dimensions:** Single blade: 40×200 px (the game tiles multiple blades side by side)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Blade Primary | `#2A7840` | Deep forest green. Main blade. |
| Blade Highlight | `#50C870` | Lighter green. Central rib and edge catchlight. |
| Blade Base | `#1A5030` | Very dark green. Base of blade where it roots. |

**Animation:** 2-frame alternating sway — frame 0: blade curves 8° left; frame 1: blade curves 8° right. Each frame is held for 4–8 ticks depending on sway_speed parameter. The Godot scene actually handles rotation via code (not sprite animation), so these two frames serve as key-art variants rather than full motion sprites.

**Visual Telegraph / Warning State:** Gap glow indicator — `fx_kelp_gap_glow.png`. A soft green radial bloom (120×220 px) appears at the gap position as the gap opens on the beat. The glow pulses once at 100% opacity, then fades over 0.2 sec. This is the gap-is-open signal. Color: `#80FF80` at 60% opacity, Screen blend mode.

**Hull Plate skin variant (Z3):** Same blade dimensions. Colors replaced:
- Blade Primary: `#7A6050` (rust-brown metal)
- Blade Highlight: `#C0A080` (pale oxidized metal)
- Blade Base: `#503828` (dark rust)

**Hitbox Visualization:** Capsule per blade, 20 px radius × 180 px tall effective. The blade sprite is 40 px wide × 200 px tall — hitbox fits comfortably inside the visual with ~10 px clearance per side. The ink outline of each blade is drawn 4 px outside the capsule boundary — makes near-misses feel clean.

---

### 3.4 `bubble_mine` — Bubble Mine

**Sprite Dimensions:** 120×120 px sprite sheet, 4 frames (2 idle + 2 warning) in a 2×2 grid

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Mine Surface | `#A0D8FF` | Pale transparent blue. The bubble film surface. |
| Mine Core | `#40A0E0` | Medium blue. Inner "heavy" core visible through bubble. |
| Warning Glow | `#FF6020` | Hot orange-red. Warning pulse glow. |

**Animation:**
- Idle frames (0–1): Mine sits still. Frame 0: bubble surface has 3 small shimmer dots (white, semi-transparent). Frame 1: shimmer dots shift position. 4 fps.
- Warning frames (2–3): Frame 2: entire mine glows orange-red, scale increases to 110%. Frame 3: scale back to 100%, slightly darker orange. 8 fps when in warning state. The faster fps gives a tighter, more urgent pulse feel.

**Visual Telegraph / Warning State:** The warning animation IS the telegraph. Additionally, a faint concentric ripple ring expands from the mine's center each second in idle state — this communicates "here's my detection radius" visually without a hard circle. The ripple fades by the time it reaches the arm_radius distance.

**Hitbox Visualization:** Circle, 56 px radius — the mine core diameter. The outer bubble surface (painted surface of the sphere) is 60 px radius — hitbox is slightly inside the visible sphere. The "safe zone" between bubble surface and hitbox gives one frame of "I almost touched it" before taking damage. The mine's painted surface should have a subtle 4px-wide transparent band at its outermost rim to visually indicate this safe zone.

---

### 3.5 `current_jet` — Current Jet

**Nozzle Sprite Dimensions:** 60×80 px (the wall fixture)
**Stream Sprite Dimensions:** 640×80 px (stretches across full lane)

**Color Palette — Default (water):**
| Swatch | Hex | Usage |
|---|---|---|
| Nozzle Metal | `#708890` | Blue-grey metal. Pipe fixture. |
| Stream Active | `#C0E8FF` | Pale blue-white. Firing water stream. |
| Stream Telegraph | `#C0E8FF` at 30% opacity | Same color, transparent. Telegraph preview. |

**Color Palette — Steam Vent skin (Z4):**
| Swatch | Hex | Usage |
|---|---|---|
| Nozzle | `#5A4030` | Dark volcanic rock. Replaces metal pipe. |
| Stream Active | `#F0F0F0` at 90% opacity | Near-white steam. |
| Stream Telegraph | `#F0F0F0` at 25% opacity | Very faint steam preview. |

**Animation:**
- Nozzle: 3-state sprite. Rest: pipe closed. Telegraph: pipe opening, brief pressure shimmer at mouth (2-frame shimmer, 12 fps). Firing: wide emission burst frame.
- Stream: UV-scrolling texture (no animation frames needed — shader handles motion). UV scrolls along travel axis at 200 px/sec during FIRING.

**Visual Telegraph / Warning State:** Stream shows at 30% opacity during TELEGRAPHING state (0.5 sec). Nozzle glows with a subtle amber light on the rim. A small pressure gauge element (painted onto the nozzle fixture) shows a rising needle during telegraph — this is a single sprite swap on the nozzle (gauge frame 1 = low, frame 2 = high) and provides a readable "charging" visual even at small sizes.

**Hitbox Visualization:** 640 × 80 px rectangle, effective hitbox 640 × 72 px (4 px inset per horizontal edge). The stream sprite should show a 4px "soft edge" (the stream fades out slightly at its top and bottom edges) that visually communicates the non-lethal fringe.

---

### 3.6 `anchor_chain` — Anchor Chain

**Chain+Anchor Sprite:** 100×800 px rendered as Line2D + Sprite2D (not a single sprite sheet)
**Mount Fixture:** 80×40 px static sprite

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Chain Links | `#808888` | Desaturated blue-grey. Rusted iron links. |
| Chain Rust | `#A06030` | Orange-brown. Rust stains on link edges. |
| Anchor | `#707878` | Dark grey. Anchor head. |
| Apex Glow | `#FFFFFF` at 40% opacity | Soft white. Apex glow highlight. |

**Animation:** The chain rotation is handled entirely by code (Node2D rotation on pivot). The chain sprite itself does not animate — it is a static texture tiling the chain-link pattern. The anchor sprite at the bottom is static. The apex glow `fx_chain_apex_glow.png` is the only animated element: it fades in over 0.1 sec, holds for 0.15 sec, fades out over 0.1 sec each time the apex is reached.

**Visual Telegraph / Warning State:** The apex glow IS the telegraph — it signals the safe-pass window. Additionally, the chain emits a very faint golden shimmer along its length when approaching the apex (within 15% of maximum displacement) — this is a painted chain variant (frame 2) that shows the links catching light as if at rest.

**Hitbox Visualization:** 6 capsule segments along the chain. Each 16 px radius × 60 px tall. The chain links are drawn as chunky ovals approximately 36 px wide × 20 px tall — the hitbox (32 px diameter cylinder) fits snugly inside the visual. The anchor is 80 px wide × 60 px tall; hitbox rectangle 80×60 px. Anchor hitbox matches visual closely because the anchor shape is already boxy and the edge is meaningful.

---

### 3.7 `lava_burst` — Lava Burst

**Vent Base Sprite:** 120×80 px (static floor/ceiling fixture)
**Telegraph Glow Sprite:** 200×200 px (animated 4 frames)
**Eruption Column Sprite:** 120×1080 px (UV-scrolling texture)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Vent Rock | `#3D2010` | Very dark brown-black. Volcanic rock surround. |
| Vent Opening | `#FF6000` | Bright orange. Open vent mouth glow. |
| Telegraph Glow | `#FF8020` | Orange gradient, radiates outward. |
| Column Core | `#FFFFFF` | Bright white. Column center at full eruption. |
| Column Edge | `#FF4000` | Deep red-orange. Column perimeter. |

**Animation:**
- Vent base: static sprite.
- Telegraph glow: 4 frames, expanding pulse. Frame 0: small glow (80 px diameter). Frame 1: medium (120 px). Frame 2: large (160 px). Frame 3: full (200 px). Loop during telegraph state at 6 fps.
- Eruption column: no frame animation — UV scrolls upward at 800 px/sec. Entire column appears in one frame (no build-up within eruption state).

**Steam Vent skin (Z6):** Same dimensions. Column Core: `#C0E8FF` (pale blue); Column Edge: `#80B8FF` (soft blue-white). Vent Opening: `#40A0FF`. The steam look should read as "hot" but cooler-tinted than lava — more clinical, more otherworldly.

**Visual Telegraph / Warning State:** The 4-frame expanding glow is the primary telegraph. At 0.6 sec duration, the glow pulses twice before eruption (3 frames × 6 fps = 0.5 sec, close enough). Additionally, the screen edges near the vent show a faint red tint (2px color overlay on screen sides during telegraph) — a background cue for peripheral vision.

**Hitbox Visualization:** 96 px wide × 1080 px tall. Visual column is 120 px wide — effective hitbox is 12 px inside each visual edge. The column sprite should show a slightly softer, more diffuse edge on the outer 12 px to visually represent the "near but safe" zone.

---

### 3.8 `eel_snap` — Snapping Eel

**Head Sprite:** 80×64 px
**Body Segment Sprite:** 60×64 px (tiles to form body length)
**Wall Hole Sprite:** 100×80 px

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Skin Primary | `#50782A` | Earthy green-brown. Moray eel body. |
| Spot Pattern | `#3A5018` | Dark forest green. Irregular spot/stripe markings. |
| Belly | `#C8D080` | Pale yellow-green. Lighter underside. |
| Eye Color | `#FFAA00` | Bright amber. Predator eyes — the danger signal. |
| Mouth Interior | `#FF6060` | Red-pink. Open mouth interior — visible in telegraph frame. |

**Animation:**
- Head: 2 key states: Neutral (mouth closed, visible 40px from hole — telegraph state), and Strike (mouth open wide — 1 strike frame). A 3rd frame is used during retract: mouth closes partway.
- Body segment: single static tile. Tiling via MultiMeshInstance2D. No animation needed — the Tween handles stretch.

**Visual Telegraph / Warning State:** Head peeks 40 px out of wall hole in TELEGRAPH state (0.5 sec). The hole rim glows very faintly amber during telegraph — communicating "something is about to come out of here." The eel's large amber eyes are visible in the telegraph state (peeking out, eyes just visible), which reinforces the "I see you, I'm about to strike" read. On strike, eyes narrow to aggressive slits.

**Hitbox Visualization:** Rectangle, 60 px tall × strike_length wide. The eel body is 64 px tall (head 80 px tall) — hitbox is 60 px, meaning the top and bottom 2–4 px of the eel body visually extends outside the collision box. This matters for near-misses: a player who clips the very edge of the eel body but is within 2 px of the hitbox edge should survive, reinforcing "fair hitbox" feel.

---

### 3.9 `pressure_wall` — Pressure Wall

**Wall Body Sprite:** 200×1080 px (repeating texture)
**Gap Highlight Sprite:** variable height × variable width (matches gap_height parameter)

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Wall Body | `#2060C0` at 70% opacity | Blue pressure wall. Semi-transparent to show the zone behind it. |
| Wall Streamline | `#80C0FF` at 50% opacity | Horizontal lines suggesting compression. |
| Gap Highlight | `#60FFFF` | Bright cyan. The safe gap indicator — most important visual element. |
| Gap Pulse | `#FFFFFF` at 60% opacity | White. Periodic highlight pulse on gap. |

**Animation:**
- Wall body: UV scrolls horizontally at 100 px/sec perpendicular to travel direction. This gives the wall a "flowing, compressed" look without frame animation.
- Gap highlight: gentle scale pulse (98%–102%) at beat rate. The pulse confirms "this is the safe zone" rhythmically.

**Visual Telegraph / Warning State:** One beat before entry, a thin `#60FFFF` line appears at the entry edge of the screen (left or right edge) — 4 px wide, full screen height, flashing at 4Hz for one beat duration. This is the "wall is coming" signal. The gap position is indicated by a break in this edge line, so the player already knows gap height before the wall enters.

**Hitbox Visualization:** Two rectangles (above gap and below gap). The visible wall semi-transparency (70% opacity blue) clearly communicates "this region is dangerous, this gap is safe." The gap highlight color (`#60FFFF`) is deliberately distinct from any obstacle color in the game — it is the only bright cyan used on a non-player element. This makes it a learnable "safe zone color."

---

### 3.10 `dark_void` — Dark Void

**Overlay:** Full-screen shader (not a sprite — see spec)
**Beat Ring During Void:** 200×200 px sprite

**Color Palette:**
| Swatch | Hex | Usage |
|---|---|---|
| Void Overlay | `#000000` at 95% opacity | Near-total darkness overlay. |
| Player Halo | Radial gradient: player zone color at center → transparent | The visible radius around the player. |
| Beat Ring | `#FFFFFF` | White, high contrast — visible against the darkness. |

**Animation:**
- The dark void itself has no sprite animation — the shader handles the radial cutout with a smooth gradient edge.
- Beat ring: single ring sprite that scales from 0.2→2.0× size over 0.1 sec then fades. During void, this ring is double-radius (80 px vs normal 40 px) and pure white.

**Visual Telegraph / Warning State:** The dark void has no external telegraph — its onset IS the event. However, there is a transition: the overlay fades from 0% to 95% opacity over 0.3 sec, giving a "dusk to darkness" fade rather than instant blackout. The beat-pulse halo begins at onset to orient the player immediately.

**Hitbox Visualization:** N/A — no collision. The void UI design implicitly communicates "I cannot hurt you" through the absence of any danger-color visual (no red, no orange) in the void's own rendering.

---

### 3.11 `crystal_shard` — Crystal Shard

**Sprite Dimensions:** 80×160 px (each variant: 2-frame sparkle animation in 80×320 sprite sheet)

**Color Palette — Blue Variant:**
| Swatch | Hex | Usage |
|---|---|---|
| Primary | `#90D0FF` | Pale ice-blue. Main crystal body. |
| Edge Highlight | `#FFFFFF` | Pure white. Specular edge at crystal facet angle. |
| Inner Depth | `#3080C0` | Medium blue. Interior shadow/depth. |

**Color Palette — Teal Variant:**
| Swatch | Hex | Usage |
|---|---|---|
| Primary | `#60E0C0` | Bright teal. Main crystal body. |
| Edge Highlight | `#FFFFFF` | White. Same facet highlight. |
| Inner Depth | `#208060` | Dark teal-green. Interior depth. |

**Animation:** 2-frame sparkle. Frame 0: crystal at rest with a single bright specular dot at the top facet. Frame 1: specular dot flares to 3× size for one frame (sparkle pulse). Loop at 6 fps. Since the crystal is also continuously rotating in-game (handled by code), the sprite's rotation provides natural animation variation.

**Wall bounce spark `fx_crystal_bounce_spark.png`:** 40×40 px particle texture. 8 tiny crystal shard fragments arranged radially. Pure white with teal tint overlay. Single frame, instantiated as GPUParticles2D.

**Visual Telegraph / Warning State:** On spawn (entering from right edge), the crystal emits a brief 3-ring expand pulse (3 concentric white rings) that lasts 0.3 sec. This signals "something fast is entering." The crystal's high speed and distinctive silhouette then serve as the ongoing warning.

**Hitbox Visualization:** Capsule 40 px radius × 80 px tall, rotating with sprite. Because the shard rotates, the effective collision at any moment is close to a 80 px diameter circle. The sprite itself is 80×160 px — meaning the long axis extends beyond the collision capsule by 40 px per end. These "tips" of the elongated crystal shape are outside the hitbox. Players who clip a crystal tip but avoid the center will not take damage, which feels spectacular and skilled.

---

### 3.12 `mirror_fish` — Mirror Fish

**Sprite:** Uses current player character sprite with shader applied — no unique sprite asset
**Trail Line Texture:** 4 px wide dashed line, blue-tinted
**Shatter Particle Texture:** 8 character-shaped fragments per character variant

**Color Palette (shader parameters applied to player sprite):**
| Swatch | Hex | Notes |
|---|---|---|
| Tint Mix | `#3399FF` | The blue color mixed with character's colors at 50% |
| Opacity | 80% | Mirror fish is slightly transparent |
| Hue rotation | +180° (horizontal flip only — no hue rotation) | The mirror look is a flip, not a color replacement |

**Animation:** Mirror fish plays the same animation state as the current player character but mirrored horizontally. The animation is driven by the position ring buffer — if the player was diving 0.5 sec ago, the mirror fish is in the dive animation.

**Trail line `fx_mirror_fish_trail.png`:** A single horizontal dash segment, 20 px long × 4 px wide. Blue-tinted. Used as texture by Line2D with 8 px dash + 8 px gap pattern. The Line2D connects current player position to mirror fish position at 30% opacity.

**Visual Telegraph / Warning State:** The spawning "reversed whoosh" audio combined with the trail line (which appears immediately on spawn) is the warning. Visually, the mirror fish's distinctive blue tint and the trail line make it recognizable as "that's me, but inverted." First-time players may be confused — by design, this is the moment of discovery that teaches the mechanic.

**Hitbox Visualization:** Identical to player (80 px wide × 60 px tall ellipse). The visual is the same size as the player sprite. There is no margin between "looks like it might hit" and "actually hits" — the mirror fish is the most honest hitbox in the game, which is appropriate given its mechanic.

---

## 4. Background & Zone Art Specs

### Background Architecture (all zones)

All backgrounds use a 3-layer parallax system:
- **Far layer (Layer 0):** Scroll factor 0.2× (barely moves). Establishes ambient color, horizon, large shapes.
- **Mid layer (Layer 1):** Scroll factor 0.5×. Main zone scenery elements. Most visual detail lives here.
- **Near layer (Layer 2):** Scroll factor 0.8×. Foreground elements that pass close to camera. Creates depth.

All layer textures are designed as horizontal seamless loops (left and right edges match). The game tiles them horizontally and scrolls at the appropriate factor.

**Base canvas:** 1080×1920 px per layer tile. Minimum tile width: 3240 px (3× screen width) to reduce visual repetition in play. Wide tiles at 6480 px recommended for mid-layer where density is highest.

**Floor and ceiling:** The playable lane occupies the central 70% of screen height (lanes run from approximately y=190 to y=1730 in the 1920 px height, leaving ~10% margin top and bottom). Floor tiles are drawn as the bottom wall, ceiling tiles as the top wall, and the background fills the lane area.

---

### 4.1 Zone 1 — Sunlit Shallows

**Zone Color Identity:** `#40C8E0` (main water), `#F5D88A` (floor), `#FF7F5C` (accent)

**Far Layer (scroll 0.2×):**
- Content: Light shafts descending from unseen surface above. Several shafts at different X positions. Background fish silhouettes (5–8 small fish, painted, not animated) in two groups.
- Color palette: `#60D8F0` (lighter cyan than main water), shafts in `#FFFAAA` at 40% opacity.
- Level of detail: very low. No ink outlines. All shapes are soft and blurred at edges. Fish silhouettes are simple blobs with tail notch.
- Dimensions: 6480×1920 px tile.

**Mid Layer (scroll 0.5×):**
- Content: Coral formations in clusters at floor level. Pink and orange coral heads (rounded mushroom shapes, anemone tentacles, fan corals). Occasional sea grass patches. Large decorative seashells. A background school of small fish (10–15 individuals) painted as a single sprite that slowly undulates.
- Color palette: `#FF9AC1` (pink coral), `#FF7F5C` (orange coral), `#60D880` (sea grass), `#F5D88A` (sandy patches).
- Level of detail: medium. Characters get ink outlines. Coral gets simplified outlines (1px).
- Dimensions: 3240×1920 px tile.

**Near Layer (scroll 0.8×):**
- Content: Large rounded pebbles and smooth rocks in the foreground. Some sea grass blades at floor. Occasional large shell or piece of coral partially entering the frame from bottom edge.
- Color palette: `#C8B068` (warm sand rock), `#E8D890` (light sand).
- Level of detail: high for foreground rocks. Large silhouettes, simplified but with texture (rounded "pebble" shapes with subtle highlight). Elements should partially overlap the playfield only at the very bottom 50 px — they are floor decoration, not obstacles.
- Dimensions: 2160×400 px tile (only bottom portion of screen, composited onto lane floor).

**Ambient Particles:**
- System: Warm golden bubble particles.
- Behavior: Rise upward from random floor positions, slight horizontal drift. Size: 4–12 px diameter. Opacity: 30–70%. Spawn rate: 8 per second across full screen width.
- Color: `#FFFAAA` (matching light shaft color).
- Count cap: 30 simultaneously visible.

**Floor Tile:** 1080×120 px. Sandy, slightly rounded bump texture. Primary color `#F5D88A`. Highlight ridge at top edge `#FFE8A8`. Several small pebble shapes embedded in sand surface, painted. Seamless horizontal loop.

**Ceiling Tile:** 1080×60 px. Water surface (viewed from below). Rippling light-blue with white caustic fragments. Primary `#A0E8FF`. This is the only zone with a ceiling that reads as a water surface — all other zones have rock/structure ceilings.

---

### 4.2 Zone 2 — Kelp Forest Canyon

**Zone Color Identity:** `#2A6B4A` (main water), `#4A3020` (walls), `#C8A830` (accent)

**Far Layer (scroll 0.2×):**
- Content: Distant rocky canyon walls receding to a vanishing point. Shafts of filtered green-gold light from above. Several large kelp silhouettes as background elements (solid dark shapes, no detail).
- Color palette: `#1A4A30` (deep background green), `#3A6A30` (mid-distance walls), `#C8A830` at 20% opacity (light shafts).
- Level of detail: very low. No outlines. Atmospheric perspective makes far elements very dark and desaturated.
- Dimensions: 6480×1920 px tile.

**Mid Layer (scroll 0.5×):**
- Content: Kelp stalks rising from floor to near-top of frame. Each stalk 3–6 blades, swaying very gently. Rocky wall niches with bioluminescent anemones glowing faintly. Occasional large boulder with barnacles. Small fish darting between kelp.
- Color palette: `#2A7840` (kelp), `#4A3020` (rocks), `#60FFB0` (bioluminescent anemones at 40% opacity).
- Level of detail: medium-high. Kelp blades use same art as obstacle kelp but smaller scale. Rocks have strong ink outlines.
- Dimensions: 6480×1920 px tile.

**Near Layer (scroll 0.8×):**
- Content: Large foreground boulders at floor and ceiling edges. A few kelp blades partially visible at frame edges — they define the canyon walls. Dark, rocky texture.
- Color palette: `#3A2818` (very dark brown foreground rocks).
- Level of detail: silhouette-level. These rocks are large, simplified shapes with heavy shadow at edges. They frame the playfield.
- Dimensions: 2160×600 px tile (bottom 300 px + top 300 px of screen, composited as wall elements).

**Ambient Particles:**
- System: Small round bubbles, slightly larger than Z1, green-tinted.
- Behavior: Rise slowly, mild horizontal wobble. Some cluster near kelp bases.
- Color: `#90E0B0` (seafoam green).
- Spawn rate: 5 per second. Count cap: 20.

**Floor Tile:** 1080×180 px. Dark rocky substrate with embedded pebbles. Primary `#3A2818`. Algae patches in `#2A5830`. Seamless loop.

**Ceiling Tile:** 1080×100 px. Rocky cave ceiling with hanging stalactite nubs. `#2A1E10` primary. Some moss in `#2A5018`.

---

### 4.3 Zone 3 — Shipwreck Alley

**Zone Color Identity:** `#1A3A5C` (main water), `#6B4530` (hull/floor), `#70C090` (bioluminescence accent)

**Far Layer (scroll 0.2×):**
- Content: Silhouettes of large sunken ships in the distance. Three to five silhouettes, overlapping, at different depths suggested by scale (far ones very small). Murky blue-green water with low light.
- Color palette: `#0E2030` (near-black water), `#1A3A5C` (main water behind silhouettes), `#2A5A4A` (ship silhouettes — slightly different tint than water for separation).
- Level of detail: silhouette only. Ships read as bulk shapes with mast silhouettes and hull forms.
- Dimensions: 6480×1920 px tile.

**Mid Layer (scroll 0.5×):**
- Content: Partial ship hull sections — torn planks, porthole frames glowing amber, a barnacle-encrusted anchor, rope/chain hanging. Schools of fish silhouettes drifting through portholes. Seafloor debris: scattered treasure chests (closed, small), cannonballs, ceramic jars.
- Color palette: `#6B4530` (hull wood), `#A87840` (porthole glow), `#70C090` (bioluminescent kelp patches), `#4A4A5A` (debris metal).
- Level of detail: medium. Planks have wood grain texture (painted, not photographic). Portholes glow from behind.
- Dimensions: 6480×1920 px tile.

**Near Layer (scroll 0.8×):**
- Content: Large hull planks as foreground framing elements at top and bottom of screen. Rope silhouettes. A chain draped over the near-bottom edge.
- Color palette: `#4A3020` (dark weathered wood), `#7A6050` (lighter plank).
- Level of detail: high texture on wood grain, heavy shadow framing.
- Dimensions: 2160×600 px tile (floor 300 + ceiling 300 px).

**Interior Background (special: `bg_shipwreck_interior.png`):**
- Used during "hull breach" gameplay sections only.
- Content: Interior of ship hull. Wooden beam ribs arcing overhead, portholes on both sides (circular, glowing amber outside). Water flooding the interior at floor level with reflective surface. Barnacles and seaweed on beams.
- Color palette: `#1A1008` (very dark interior), `#A87840` (porthole glow), `#2A1A08` (timber beams).
- Same dimensions as mid layer but indicates an interior space.

**Ambient Particles:**
- System: Silt/debris motes. Light gray, slow drift.
- Color: `#8FB8D0` (pale grey-blue).
- Behavior: Very slow random drift. Some settle downward.
- Spawn rate: 4 per second. Count cap: 15. Density lower than Z1/Z2 — the murk is suggested, not emphasized.

**Floor Tile:** 1080×200 px. Sandy seafloor with debris (tiny shells, broken pottery, scattered barnacles). Primary `#3A2A1A`. Seamless loop.

**Ceiling Tile:** 1080×120 px. Weathered ship hull underside. Plank pattern with barnacles. `#4A3020` primary.

---

### 4.4 Zone 4 — Volcanic Vent Fields

**Zone Color Identity:** `#1A0A00` (main water), `#3D1800` (floor), `#FF6010` (accent)

**Far Layer (scroll 0.2×):**
- Content: Distant volcanic rock formations. A massive dormant vent on the horizon emitting a slow column of glowing orange particles. Faint red glow on the water floor far below.
- Color palette: `#0A0500` (near-black volcanic deep water), `#3D1800` (rock silhouettes), `#FF6010` at 15% opacity (lava glow on far ground).
- Level of detail: nearly none. Pure silhouette. This far layer should be oppressive and dark.
- Dimensions: 6480×1920 px tile.

**Mid Layer (scroll 0.5×):**
- Content: Active volcanic vent formations — small clusters of rock with glowing orange openings. Ash clouds drifting through the water. Volcanic rock spires and lava tube openings. Small bioluminescent creatures (simple blob shapes with glow) sheltering near rock formations. The rock shapes are more jagged here than previous zones — danger zone aesthetic.
- Color palette: `#3D1800` (rock), `#FF6010` (vent glow), `#FF9040` (ambient light from vents on rock surfaces), `#C0C0B0` (ash cloud).
- Level of detail: medium. Rock forms are angular — this is the only zone allowed to break the "all-rounded" rule for environmental objects because geological formations are genuinely angular.
- Dimensions: 6480×1920 px tile.

**Near Layer (scroll 0.8×):**
- Content: Large volcanic rock outcroppings at floor and ceiling. Some have glowing cracks of orange-red between rock faces. Very dark, imposing.
- Color palette: `#250C00` (darkest rock).
- Level of detail: silhouette with orange-crack glow lines painted on rock surfaces.
- Dimensions: 2160×700 px tile.

**Ambient Particles:**
- System: Ash particles — small irregular polygons, slowly drifting.
- Color: `#C0B0A0` (warm grey ash).
- Behavior: Drift downward (ash falls) with horizontal wobble. Some larger ash flakes.
- Spawn rate: 10 per second. Count cap: 40. High density emphasizes the hostile environment.
- Additional: tiny orange ember motes — `#FF6010`. Rise upward near vent obstacle positions. 3 per second, count cap 12.

**Floor Tile:** 1080×200 px. Black-dark-brown volcanic rock with glowing orange cracks. Rough, angular texture. Primary `#1A0A00`. Orange cracks in `#FF4000`. Seamless loop.

**Ceiling Tile:** 1080×120 px. Same volcanic rock, inverted. Stalactite-like drips of cooled lava (dark orange, solidified).

---

### 4.5 Zone 5 — Twilight Trench

**Zone Color Identity:** `#050818` (main water), `#120830` (walls), `#30C8FF` (bioluminescence accent)

**Far Layer (scroll 0.2×):**
- Content: Absolute deep-sea darkness. Almost nothing visible. Very faint bioluminescent trails from deep-sea creatures (thin curved lines of `#60FFCC` at 10% opacity). A sense of vast empty darkness.
- Color palette: `#030410` (near-absolute-black).
- Level of detail: essentially nothing — pure mood. Any visible element is a luminous trace.
- Dimensions: 6480×1920 px tile.

**Mid Layer (scroll 0.5×):**
- Content: Bioluminescent creatures drifting — simple blob forms with internal glow. Depth pressure line markings on abyssal rock walls (horizontal stripes, very faint). Dangling bioluminescent lures from above (like the anglerfish aesthetic — thin filaments with bright orbs at end). Clusters of glowing orb organisms.
- Color palette: `#120830` (barely-visible rock), `#30C8FF` (blue bioluminescence), `#8840FF` (violet bioluminescence), `#60FFCC` (teal bioluminescence).
- Level of detail: low. Everything is a glow source or near-invisible. Art is defined by light, not by form.
- Dimensions: 6480×1920 px tile.

**Near Layer (scroll 0.8×):**
- Content: Large dark rock surfaces at frame edges, barely visible. A few bioluminescent patches (anemone-like organisms) on rock surfaces at near layer.
- Color palette: `#0A0420` (near-black with slight purple tint), `#30C8FF` at 30% opacity (anemone glow patches).
- Dimensions: 2160×600 px tile.

**Ambient Particles:**
- System: Bioluminescent motes — tiny, slow, magical.
- Color: Mix of `#60FFCC`, `#30C8FF`, `#8840FF`. Randomly assigned per particle.
- Behavior: Almost no movement — extremely slow random drift. Occasional fade in/out cycle (they "blink" like deep-sea organisms).
- Spawn rate: 6 per second. Count cap: 25. Sparse — this zone's particles feel rare and precious.

**Floor Tile:** 1080×160 px. Dark abyssal rock. `#0A0420`. Faint horizontal pressure lines (geological stratification). Barely visible without close inspection.

**Ceiling Tile:** 1080×80 px. Same rock. Some hanging filaments (very thin, painted) with small orbs at tip (bioluminescent: `#60FFCC`).

---

### 4.6 Zone 6 — Crystal Caves

**Zone Color Identity:** `#E8F0FF` (main water), `#C0D8FF` (walls), prismatic spectrum (accent)

**Far Layer (scroll 0.2×):**
- Content: Vast crystal formations in the far distance. Their scale implies a giant cave. The light they refract creates rainbow bands on the cave walls. A prismatic shimmer diffuses through the background water.
- Color palette: `#D0E8FF` (pale crystal cave water), rainbow prismatic overlay at 20% opacity cycling through spectrum.
- Level of detail: low-medium. Crystal shapes are simple elongated hexagonal prisms at far scale. The color is the information here.
- Dimensions: 6480×1920 px tile.

**Mid Layer (scroll 0.5×):**
- Content: Medium-scale crystal formations growing from walls, floor, and ceiling. Columns of crystal, clusters of smaller shards. Prismatic light refractions painted as diagonal streaks on the cave floor. Crystal "flowers" at base of formations (small, rounded crystal clusters).
- Color palette: `#C0D8FF` (crystal base), spectrum highlights as animated prismatic bands, `#FFFFFF` (pure specular reflections on facets).
- Level of detail: high. Crystal facets should be painted with visible planes and highlights. This is the most visually complex background in the game.
- Dimensions: 6480×1920 px tile.

**Near Layer (scroll 0.8×):**
- Content: Large foreground crystal spires framing the screen at top and bottom. These are large, beautiful, and clearly non-hazardous (rounded base — they contrast with the angular crystal_shard obstacles which are explicitly sharp).
- Color palette: `#A0C8FF` (large crystal surfaces) with `#FFFFFF` edge highlights.
- Level of detail: very high for the near layer — these are impressive setpieces.
- Dimensions: 2160×800 px tile (400 px floor + 400 px ceiling).

**Ambient Particles:**
- System: Crystal dust — tiny prismatic flecks, very fine.
- Color: `#FFFFFF` with per-particle random hue overlay (each particle has a different saturation moment as it drifts).
- Behavior: Drift slowly in all directions — no gravity. Rotate slowly as they drift (reflecting light at different angles).
- Spawn rate: 12 per second. Count cap: 50. Richest particle environment in the game.

**Floor Tile:** 1080×200 px. Crystal floor surface. Pale lavender-blue base (`#C0D8FF`). Hexagonal crystal facet pattern (regular, geometric — fits the zone's aesthetic exception to organic-only rule). Prismatic spectrum highlights along facet edges.

**Ceiling Tile:** 1080×120 px. Crystal ceiling with downward-pointing stalactite-crystals. Same palette as floor.

---

## 5. UI Art Specs

### 5.1 Button States

All buttons use pill-shaped containers (border-radius = 50% of height).

| State | Background | Border | Label Text | Notes |
|---|---|---|---|---|
| Normal | `#FF8820` (primary) or `#40C0FF` (secondary) | 3px `#FFFFFF` at 60% opacity | `#FFFFFF` | Drop shadow: `#0D1A2E` at 40%, offset 0px 4px, blur 8px |
| Pressed | Same hue, 20% darker: `#CC6010` / `#2890D0` | 3px `#FFFFFF` at 80% opacity | `#FFFFF0` (slight warm tint) | Scale: 95% of normal (press feedback). Shadow: reduced to 2px offset. |
| Disabled | `#708090` (both types) | 3px `#506070` | `#A0B0C0` | Saturation 0% applied — greyscale. No shadow. |
| Hover (desktop editor only) | Normal + 10% brightness increase | Same as normal | Same as normal | Only for editor testing. Mobile has no hover state. |

**Button minimum tap target:** 88×64 px per mobile accessibility guidelines. Button label may be smaller (min 56×40 px) as long as the invisible tap area extends to 88×64 px.

**IAP purchase buttons** follow the same style but include a price badge (a small circular yellow badge with white text, positioned at top-right corner of the button). Badge diameter: 40 px. Text: bold Nunito, 16px, white.

### 5.2 HUD Element Sizes and Positions

Base resolution: 1080×1920 px portrait. All measurements in pixels at this resolution.

| Element | Dimensions | Position | Z-order | Notes |
|---|---|---|---|---|
| Score display | 280×60 px | Top-left, x=30, y=50 | HUD layer | White text on dark panel. |
| Score panel | 280×80 px | Behind score text, x=20, y=40 | HUD layer - 1 | `#0A1E3A` fill, `#40A8D0` border 2px, corner radius 40px (pill). |
| Combo counter badge | 120×120 px | Top-right, x=940, y=40 | HUD layer | Circular badge. Only visible at combo ≥10. |
| Combo multiplier text | Inside combo badge | — | — | "×2" "×3" etc. 40sp Baloo 2, Gold `#FFD700`. |
| Lives display | 3× hearts, each 52×52 px | Top-center, x=440-640, y=60 | HUD layer | Hearts equally spaced across center. |
| Beat ring origin | Player center | Player position | Effects layer | Expands from player in gameplay. |
| BPM indicator (Z5 only) | 80×80 px | Top-left, below score, y=140 | HUD layer | Pulse circle. Only rendered in Z5. |
| PERFECT / GOOD / MISS text | 240×60 px | Center-screen, x=420, y=800 | Effects layer | Appears above gameplay center. Floats upward 40px then fades. Duration: 0.5 sec. |
| Progress bar | 900×24 px | Bottom of screen, x=90, y=1880 | HUD layer | Horizontal bar indicating level completion %. |
| Progress bar fill | Dynamic width | Inside progress bar | HUD layer | `#40C0FF` fill, left-to-right. |

**Safe area margins:** Allow 60 px margin at top and bottom for device notches and home indicators. HUD score panel at top should have its top edge at y=50+ (60px safe area). Progress bar bottom should not go below y=1860 (60px from bottom).

### 5.3 Star Rating Display

**Star dimensions:** 96×96 px each. Three stars displayed horizontally.
**Total star row width:** 336 px (3 stars × 96 px + 2 × 24 px gap)
**Position on Results Screen:** Horizontally centered at x=372, y=700

| State | Visual | Color |
|---|---|---|
| Filled star | Full star shape, inner fill | `#FFD700` (gold) with `#FFB800` shadow on underside of star points |
| Empty star | Star outline only | `#3A2A3A` (dark muted) fill, `#806080` outline |
| Gold border frame (100%+ score) | Rect border around all 3 stars | `#FFD700` 4px animated glow border, `ui_star_frame_gold.png` |

**Star fill animation (on results screen):** Stars fill in sequence, left-to-right, with a 0.3 sec delay between each. Each star does a pop scale (from 0% to 130% to 100%) over 0.2 sec as it fills. Sound: [SFX: ui_star_appear] plays per star.

**Animated sparkle on filled stars:** Each filled star has 6 small sparkle particles (white, 8 px, radial burst) that emit once as the star fills. These fade over 0.4 sec.

### 5.4 Zone/Level Select Card

**Card dimensions:** 460×260 px per zone card. 480×160 px per level card.

**Zone Card Layout (460×260 px):**
- Background: zone's main water color at 80% + dark overlay gradient from bottom
- Zone name: Baloo 2 ExtraBold 32sp, white, drop shadow. Positioned at bottom-left, x=20, y=180 within card.
- Zone number badge: circular badge, 60 px diameter, top-left corner. Zone color accent.
- Star progress: zone total stars / zone max stars, displayed as "XX/24 ★" in Nunito Bold 20sp at bottom-right.
- Lock icon: shown on locked zones, centered on card, 80×80 px. Semi-transparent `#000000` overlay on locked card at 60% opacity.
- Card border: 3px, zone accent color. Rounded corners 24 px radius.

**Level Card Layout (480×160 px):**
- Background: zone's floor/wall color, darker.
- Level number: "L1" / "L8" etc., Baloo 2 Bold 28sp, white.
- Star display: 3 small stars (40×40 px each) in a row. Filled/empty per best completion.
- BPM tag: small pill badge, "100 BPM" in Nunito Regular 14sp, zone accent color background.
- Lock icon: if locked, centered lock icon 48×48 px.

### 5.5 Character Select Portrait

**Dimensions:** 200×200 px (source: 400×400 px for 2× quality).

**Portrait layout:**
- Background: character's zone affiliation or signature color (a circular gradient disc, 180 px diameter, centered in frame).
- Character sprite: character rendered at approximately 160×120 px within the 200×200 frame, centered.
- Character name: below portrait (not inside frame), Baloo 2 SemiBold 24sp, zone color.
- Lock status: locked characters show same art at 30% opacity with a large centered lock icon (80×80 px).
- Selected state: 4px `#FFD700` gold border ring around portrait frame, with an animated star burst at top corners.

**Portrait background colors per character:**
| Character | Background Gradient Start | Background Gradient End |
|---|---|---|
| Pebble | `#FF8C42` | `#FFB86A` |
| Zap | `#3060E0` | `#80B0FF` |
| Mochi | `#D0E8FF` | `#A090E0` |
| Crusher | `#C06030` | `#E09060` |
| Pip | `#4A7840` | `#C8E890` |
| Lumina | `#2A1840` | `#C0FF80` |
| Finn | `#8090A0` | `#F0F8FF` |
| Grumble | `#6070A0` | `#B0C0D8` |

### 5.6 Build Mode UI

**Timeline Bar (`ui_buildmode_timeline.png`):**
- Dimensions: 1080×200 px (bottom strip of editor screen)
- Background: `#0A1E3A` (deep navy panel)
- Beat grid lines:
  - Quarter beat lines: `#FFFFFF` at 60% opacity, 1px wide
  - Eighth beat lines: `#FFFFFF` at 30% opacity, 1px wide (shown at zoom ≥ 2×)
  - Sixteenth beat lines: `#FFFFFF` at 15% opacity, 1px wide (shown at zoom ≥ 4×)
  - Measure lines (every 4 beats): `#40C0FF` at 80% opacity, 2px wide
  - Playhead: `#FF8820` (orange) at 100%, 2px wide, with a small orange triangle indicator above
- Obstacle blocks on timeline: colored rectangle per obstacle type (see palette below), 24 px tall, width proportional to obstacle duration. 4px rounded corner. Label: obstacle slug in Nunito Bold 12sp, white.

**Obstacle palette tray (`ui_buildmode_obstacle_panel.png`):**
- Panel: left side of screen, 220 px wide × full screen height
- Background: `#0D1630` (darker than timeline)
- Each obstacle in the palette is a 180×60 px button with:
  - Obstacle display name, Nunito Bold 16sp, white
  - Obstacle color swatch (20×20 px circle, obstacle's primary color)
  - Difficulty tier indicator: 1–3 dots, colored `#AAFFAA` (green=easy), `#FFFF40` (yellow=medium), `#FF8040` (orange=hard)

**Obstacle block color coding on timeline:**
| Obstacle | Timeline Block Color |
|---|---|
| coral_spike | `#FF7090` |
| jellyfish_drift | `#A060D0` |
| kelp_curtain | `#2A7840` |
| bubble_mine | `#40A0E0` |
| current_jet | `#70A8C0` |
| anchor_chain | `#808888` |
| lava_burst | `#FF6010` |
| eel_snap | `#50782A` |
| pressure_wall | `#2060C0` |
| dark_void | `#120830` with `#30C8FF` outline |
| crystal_shard | `#90D0FF` |
| mirror_fish | `#3399FF` |

---

## 6. Effects (VFX) Specs

### 6.1 Beat Ring Pulse (`fx_beat_ring.png`)

**Purpose:** Expands from player center on every quarter beat. Always visible. Communicates the rhythm visually.

**Sprite:** 200×200 px circle outline. Stroke width: 6 px at source. Color: `#FFFFFF` (white). No fill.

**Animation behavior:**
- Trigger: `SignalBus.beat_fired` signal
- On trigger: ring instantiates at player center, scale = 0.2 (ring diameter = 40 px)
- Over 0.1 sec: scale lerps to 1.5 (ring diameter = 300 px)
- Simultaneously: opacity lerps from 0.8 to 0.0
- Easing: ease-out scale (fast start, decelerate), ease-in opacity (starts visible, ends invisible)
- Total duration: 0.1 sec
- Multiple rings can coexist (each beat spawns a new ring, old ones still fading)

**During dark void:** Ring color changes to `#FFFFFF` at 100% opacity, scale reaches 2.0 (ring diameter = 400 px). Communicates the beat more urgently in darkness.

**Implementation note:** Ring is a sprite on a `CPUParticles2D`-managed or manually code-spawned `Node2D`. One ring node per beat event, auto-freed after animation completes.

---

### 6.2 PERFECT Hit Burst (`fx_perfect_star.png`)

**Purpose:** Confirms a perfectly-timed beat interaction with maximum visual reward.

**Sprite:** Star burst — 8 rays emanating from center. 200×200 px. Color: gradient from `#FFFFFF` center to `#FFD700` edge (gold star).

**Animation behavior:**
- Trigger: player scores PERFECT
- On trigger: burst instantiates at player center
- Scale: 0 → 1.4 → 1.0 over 0.15 sec (pop-and-settle)
- Opacity: 1.0 → 0.0 over 0.25 sec (fade after pop settles)
- Rotation: burst rotates 15° clockwise over the full animation (slight spin energy)
- Also: 8 small star fragments (`fx_perfect_star_fragment.png`, 20×20 px each) emit radially at burst trigger, each traveling 60–100 px outward over 0.3 sec then fading

**Text display:** "PERFECT!" text appears 40 px above player position simultaneously. Baloo 2 ExtraBold 48sp. Color: `#FFD700` with `#FF8000` outline 3px. Floats upward 40 px and fades over 0.5 sec.

---

### 6.3 GOOD Hit Ripple (`fx_good_ripple.png`)

**Purpose:** Confirms a good (but not perfect) timing hit with a more subtle reward.

**Sprite:** 200×200 px circle outline with softer, wider stroke (10 px). Color: `#60C0FF` (sky blue).

**Animation behavior:**
- Trigger: player scores GOOD
- On trigger: ripple instantiates at player center
- Expands from scale 0.3 to 1.2 over 0.2 sec
- Opacity: 0.7 → 0.0 over 0.2 sec
- No star fragments (distinguishes from PERFECT)
- A second, slightly delayed ripple (same sprite, 0.05 sec later, 80% opacity) gives a double-pulse feel

**Text display:** "GOOD!" text, Baloo 2 Bold 36sp. Color: `#60C0FF` with `#1A3A7A` outline 2px. Same float-and-fade behavior as PERFECT text but slightly smaller and softer.

---

### 6.4 MISS Indicator (`fx_miss_x.png`)

**Purpose:** Communicates a missed beat opportunity clearly without being discouraging.

**Sprite:** 100×100 px "×" shape. Composed of two thick rounded rectangles crossing at 45°. Color: `#A0A0B0` (muted grey-blue — deliberately not red, to avoid feeling punishing).

**Animation behavior:**
- Trigger: player scores MISS
- On trigger: × appears at player center
- Scale: 0.5 → 1.0 over 0.05 sec (pop in)
- Hold at scale 1.0 for 0.1 sec
- Scale: 1.0 → 0.8 over 0.1 sec (shrink out)
- Opacity: 1.0 → 0.0 during the shrink phase
- NO screen shake for miss (shake is reserved for obstacle collision)
- No text label — the × communicates clearly without words

**Sound:** [SFX: timing_miss] — soft low thud, 0.2 sec. Not harsh.

---

### 6.5 Combo Milestone Flash (`fx_combo_milestone.png`)

**Purpose:** Celebrates reaching a combo threshold (10, 20, 40, 80) with a screen-edge burst.

**Sprite:** 1080×200 px horizontal band. Color gradient from zone accent color edges → transparent center. Appears at top and bottom screen edges simultaneously.

**Animation behavior:**
- Trigger: combo count crosses a milestone (10, 20, 40, 80)
- Both bands appear simultaneously (top and bottom edges)
- Scale (vertical): 0 → 1.0 → 0 over 0.3 sec (flash in and out)
- Opacity: 0.8 at peak
- Combo badge (top-right) pulses: scale 1.0 → 1.4 → 1.0 over 0.2 sec simultaneously

**Additionally:** The combo counter badge background changes color at each threshold:
- ×1 (no badge visible)
- ×2 (badge appears): `#40C0FF` (blue)
- ×3: `#40C0FF` → `#40FF80` (green)
- ×4: `#40FF80` → `#FFD700` (gold)
- ×5 (max): `#FFD700` → `#FF8020` (orange-gold, animated pulsing)

---

### 6.6 Death/Squish Effect

**Purpose:** Communicates level failure in a cartoon-safe, non-violent way.

**Sequence:**
1. Player sprite plays `anim_death` (frames 14–17 per character spec)
2. On frame 15 (squish frame): camera zoom in slightly (1.0× → 1.05× over 0.1 sec)
3. `fx_star_burst_fail.png` (200×200 px, 6 grey-white stars orbiting a central point) instantiates at player center, plays for 0.8 sec
4. Screen fade: `#FFFFFF` flash at 40% opacity for 0.05 sec (classic hit-white on death)
5. After 0.3 sec hold on death pose: slow full-screen fade to `#0A1E3A` (dark navy) over 0.5 sec
6. Fail screen transitions in after 0.8 sec total

**Star burst fail `fx_star_burst_fail.png`:** 200×200 px. 6 cartoon stars in white-grey (`#C0C0D0`), orbiting the center point. Pre-rendered as 12-frame animation (full rotation). Plays at 24 fps.

**No blood, no explosion, no dramatic music sting.** The effect should feel like a cartoon character sitting down and going "welp." The music ducks out (volume 100% → 20% over 0.2 sec). Silence for 0.3 sec. Then the fail screen music fades in.

---

### 6.7 Zone Transition Effect

**Purpose:** Marks the transition between zones in the zone select flow (not between levels — level transitions are just a loading fade).

**Sequence:**
1. Outgoing zone: screen slides out to left at constant velocity over 0.4 sec
2. A "curtain" of water washes across the screen from left to right over 0.3 sec — this is a full-screen `#40C8E0` (cyan) sweep at 80% opacity with a wave-edge leading shape
3. As the curtain clears: incoming zone's background is revealed, matching the zone's main water color
4. Incoming zone name text appears: Baloo 2 ExtraBold 56sp, white, centered, scales from 50% → 100% over 0.3 sec then fades over 0.5 sec

**Curtain sprite (`fx_zone_transition_curtain.png`):** 1080+200×1920 px (wider than screen to allow clean off-edge entry). Wave-shaped leading edge (sine wave, amplitude 80 px, frequency matching screen width at ~3 cycles). Color: zone destination's main water color.

---

### 6.8 Crystal Resonance (Zone 6 — `fx_crystal_resonate.png`)

**Purpose:** Rewards PERFECT hit streaks in Z6 with increasingly spectacular crystal illumination.

**Sprite:** 400×600 px crystal burst (elongated upward to match crystal shard silhouettes). Central column of white light with rainbow prismatic halos on sides.

**Animation behavior:**
- Trigger: player scores PERFECT in Zone 6
- Nearest crystal formation in the mid-layer background plays a "light up" animation: a `#FFFFFF` glow expands from the crystal's center over 0.2 sec, changing to the zone's prismatic color at full intensity, then fading over 0.4 sec.
- Each subsequent PERFECT in the streak illuminates an additional crystal formation (cumulative — already-lit formations stay lit until the streak ends).
- At 10 consecutive PERFECTs in Z6: all background crystals glow simultaneously in a synchronized pulse for 0.3 sec. A brief rainbow light wash crosses the entire screen (diagonal rainbow streak, 0.3 sec).
- At streak end (any non-PERFECT): crystals fade back to resting state over 0.5 sec.
- At level completion with a full-PERFECT streak: rainbow "finale" — all crystals pulse simultaneously in a rapid 3-flash sequence (`#FFD700` → spectrum → `#FFFFFF`) with a burst of prismatic particles filling the screen.

**Color cycling sequence for resonance:** Each crystal lights in a different hue. Sequence cycles through: `#FF80FF` (magenta), `#FF8040` (orange), `#FFFF40` (yellow), `#40FF80` (green), `#40FFFF` (cyan), `#8040FF` (violet). On each PERFECT, the next hue in sequence is used.

---

*End of Art Direction Bible v1.0*
*All hex codes verified for use on digital screen. All size specifications given at 1080×1920 base resolution. Source art produced at 2× (2160×3840) for high-DPI compatibility. All assets marked [needed] in asset_manifest.json.*
