# Bubble Reef Rush — Difficulty & Progression Design

> How the game stays fun for a 6-year-old who is great at Geometry Dash *and*
> for a parent who is not. Grounded in published game-design research, then
> mapped to concrete systems in this repo.

## 1. The research, in five principles

### 1.1 The flow channel
Players stay engaged in the band between **boredom** (too easy) and **anxiety**
(too hard) — Csikszentmihalyi's "flow." For rhythm/action games the practical
sweet spot is a **~70–90% success rate**: frequent enough success to feel
competent, frequent enough failure to feel challenged. Drop below ~60% and
players quit from frustration; stay above ~95% and they quit from boredom.

### 1.2 The difficulty sawtooth (not a straight ramp)
Difficulty should rise as a **saw blade**, not a line: climb for a stretch,
**drop for relief**, then climb to a *higher* peak than before. The valleys
are not wasted — they are what make the next peak feel earned and let the
player "catch their breath." A common authored pattern: ramp up over several
beats/sections, then deliberately ease at the next, repeating with each peak
higher than the last.

### 1.3 Intensity ramps with rests, tied to music
Within a single level, intensity is a series of **peaks and valleys that trend
upward**, ideally synced to musical structure (calm verse → building
pre-chorus → intense chorus/drop → breakdown rest). Obstacles placed *on the
beat* engage far more than random placement. Rests are mandatory: "if intensity
does not vary, you effectively have no intensity."

### 1.4 Teach-then-test
Never introduce a new mechanic at high difficulty. Show it in a safe, slow
context; let the player build muscle memory; *then* test it under pressure.
Lower difficulty immediately before raising it so the new skill is learned, not
gambled.

### 1.5 Dynamic Difficulty Adjustment — the "Reef Director"
Left 4 Dead's **AI Director** continuously gauges recent player state (health,
recent damage, time since the last big moment) and decides whether to send a
horde or grant a breather, keeping every player in their personal flow channel
**invisibly**. Rhythm games do the same by nudging difficulty up at >90%
precision and down below ~60%. This is what lets one authored level fit many
skill levels: the same chart, adapted in real time.

### 1.6 Kids & Self-Determination Theory
Competence + autonomy drive intrinsic motivation. For young players: guarantee
**early wins**, give confident positive feedback, and make failure cheap and
fast (instant retry, practice-mode forgiveness). But don't condescend — the
challenge must still *rise*, because mastering something hard is the reward.

## 2. How Bubble Reef Rush implements it

### 2.1 Core mechanic that scales smoothly
The buoyancy fish (hold = dive, release = float) navigates **gates**: a vertical
wall with a **gap** at a target lane. To pass, the player must be at the gap's
lane on the beat. This single mechanic exposes clean, continuous difficulty
knobs:

| Knob | Easier → Harder | Beat-safe? |
|------|-----------------|------------|
| `gap_size` (px) | large gap → tight gap | yes |
| gap-lane **variance** between consecutive gates | small moves → big swings | yes |
| **density** (gates per N beats) | sparse → every beat | yes |
| obstacle visual/telegraph time | long → short | yes |
| timing window (`TimingJudge`) | wide → tight (already BPM-scaled) | yes |

**Scroll speed is held constant per level** so obstacles stay locked to the
music — difficulty comes from the knobs above, never from desyncing the chart.

### 2.2 Authored intensity curve (the sawtooth)
Each level carries an **intensity curve**: a list of beat-ranged sections, each
tagged `intro | teach | build | peak | rest | climax | cooldown` with a target
intensity 0.0–1.0. The spawner reads the curve to decide gap size, density, and
lane variance per section. The slice level `z1-l1` is authored as:

```
intro(0.1) → teach-dive(0.2) → build(0.4) → PEAK(0.6) → rest(0.2)
           → build(0.6) → PEAK(0.8) → rest(0.3) → climax(0.9) → cooldown(0.1)
```

A textbook sawtooth: every peak is followed by a valley, and every peak is
higher than the last.

### 2.3 The Reef Director (DDA layer)
`DifficultyDirector` is a scene-local node in `LevelRoot`. It does **not** touch
the music or scroll speed. It maintains a per-run **assist** value and a
**push** value, bounded so it stays subtle:

- On `player_hit` (death): assist rises sharply (gaps widen, density thins) —
  practice-mode mercy so repeated failure never walls a kid out. Hard cap so
  the level still resembles its authored shape.
- On a clean streak / high combo: push rises (gaps tighten toward authored or
  slightly past), so a strong player like Brandon gets pressure instead of a
  cakewalk.
- The **effective intensity** fed to the spawner is
  `clamp(authored_intensity + push − assist, floor, ceil)`.

Targets the director steers toward:
- pass-rate sweet spot **75–85%**,
- **never** more than ~3 consecutive deaths without visible easing,
- guaranteed gentle **first ~8 beats** (early-win rule).

### 2.4 Failure is cheap
Instant retry (already implemented via `RetryController`). Each retry, the
director remembers recent deaths so the assist carries in — the level *learns*
the player is stuck and eases, mirroring Geometry Dash practice mode without a
separate mode.

## 3. Implementation phases
1. **Design doc** (this file). ✅
2. `DifficultyDirector` node + unit test for the assist/push math.
3. Gate model: spawner composes top+bottom spikes into a gap from intensity.
4. Author `z1-l1` intensity curve (schema v1.2, additive/optional).
5. Headless playtest: trace effective-intensity over time; verify sawtooth and
   that simulated deaths raise assist.
6. Human playtest on device → tune the constants.

## 4. Sources
- Game Developer — *Understanding the Flow Channel in Game Design*
- Game Developer — *Cognitive Flow: The Psychology of Great Game Design*
- Basalt — *The Art of Level Progression: Pacing and Difficulty Curves*
- DesignTheGame — *Balance: Mastering the Difficulty Curve* (difficulty saw)
- Chaotic Stupid — *Intensity Ramps* (ramps = peaks + rests, trending up)
- Left 4 Dead AI Director (dynamic intensity management) — DDA surveys
- Rhythm Quest devlog 13 — music structure ↔ level intensity
- Geometry Dash level-design analyses — beat-synced obstacles, gradual concept
  introduction, practice mode as low-frustration mastery
- Self-Determination Theory (competence + autonomy) in game motivation
