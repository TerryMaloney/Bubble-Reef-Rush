# Bubble Reef Rush — Master Project Checklist

> Living document. Check off items as they ship. Add sub-items when scope is
> discovered. Do not skip sections — partial completion is worse than none
> because half-shipped systems create cascading bugs.
>
> **Legend:** ✅ Done · 🔄 In progress · ⬜ Not started · 🔒 Blocked (dependency noted)
>
> Last updated: 2026-06-07

---

## How to use this document

Work **top to bottom within each milestone**. Do not start a milestone until the
previous one's hard-blockers are cleared. Within a milestone, tackle items in
order of dependency — game loop before polish, core before optional.

Each session should target a single numbered section. Open the session with this
checklist, close it by ticking completed items and committing the updated file.

---

## Milestone 0 — Playable Vertical Slice ✅ (complete)

> One level, all core systems wired, headless tests passing.

- ✅ Autoload singletons: GameManager, EventBus, SaveSystem, BeatConductor
- ✅ LevelLoader — loads `.brl` files
- ✅ RhythmMap, TimingJudge, BeatVisualizer — rhythm engine
- ✅ ObstacleSpawner, CollectibleSpawner — beat-indexed spawning
- ✅ RetryController — instant retry on run_failed
- ✅ HUDController — score, combo, judgment labels live
- ✅ PlayerController — buoyancy physics + dive_impulse feel
- ✅ CoralSpike obstacle (top attachment working)
- ✅ JellyfishDrift obstacle (spawns, placeholder behavior)
- ✅ Pearl collectible — collision → collectible_taken signal
- ✅ DifficultyDirector (Reef Director) — assist/push/early-win DDA
- ✅ z1-l1.brl — sawtooth gate chart, 32 beats, DDA-driven gaps
- ✅ MainMenu — Play button → GameManager.start_level()
- ✅ LevelRoot — full scene with all systems wired
- ✅ ResultsScreen — stub (RESULTS label + MENU button)
- ✅ BuildModeRoot — stub (prevents GameManager crash)
- ✅ Headless test suite: smoke, director, collision, playtest — all passing
- ✅ docs/design/GDD.md, difficulty_design.md, docs/pm/ handoffs

---

## Milestone 1 — Complete Game Loop (current priority)

> Player can start, play, finish, see results, and return to menu.
> No audio or art required yet — all placeholder shapes.

### 1.1 Level ending

- ✅ **[CRITICAL]** Emit `EventBus.run_completed(level_id, score, stars)` when
  beat_map is exhausted. LevelLoader tracks beat count, connects to beat_fired,
  emits `level_ended` on final beat; LevelRoot handler reads score + par_score.
- ✅ Wire `run_completed` → transition to ResultsScreen via GameManager.finish_level
- ✅ Verify fix: game_flow_test manually fires all 32 beats, asserts run_completed fires

### 1.2 Results screen (real content)

- ✅ Show final score (stored in GameManager.last_score, read in ResultsScreen._ready)
- ✅ Show stars earned (calculated vs par_score from .brl: 1★=280, 2★=490, 3★=630)
- ✅ Show "PLAY AGAIN" button → GameManager.start_level(current_level_id)
- ✅ Show "MENU" button → GameManager.go_to_menu()
- ⬜ Show "NEXT LEVEL" button stub (grayed out if no next level yet)

### 1.3 Gate geometry fix

- ✅ **[NOT A CODE BUG]** Bottom spikes confirmed spawning — playtest `_has_bottom_spike`
  assertion passes. User only saw top spikes because portrait game (1920px tall) was
  displayed in a small landscape editor window; bottom of screen was off-panel.
- ⬜ Verify gates are navigable: player Y must pass through gap on at least one
  gate during 7-second playtest (player currently moves but may not thread gaps)

### 1.4 Score persistence

- ✅ SaveSystem.update_level_result(profile_id, level_id, score, stars) — already existed,
  called from GameManager.finish_level on every level completion
- ⬜ ResultsScreen shows personal best alongside current run score

### 1.5 Milestone 1 test gate

- ✅ All 5 headless tests passing: smoke, director, collision, game_flow, playtest
- ✅ game_flow_test.gd — fires all 32 beats manually, verifies run_completed + GameManager state

---

## Milestone 2 — Level Select + Zone Navigation

> Player can browse and choose levels. Lays groundwork for 48-level content
> pipeline.

### 2.1 Zone select screen

- ⬜ `scenes/gameplay/ZoneSelect.tscn` — shows 6 zone cards
- ⬜ Zone lock/unlock display (Z1 always unlocked; Z2+ locked until prior zone
  completed; Z4–Z5 require IAP flag, show lock icon)
- ⬜ `src/gameplay/ZoneSelect.gd` — reads unlock state from SaveSystem

### 2.2 Level select screen

- ⬜ `scenes/gameplay/LevelSelect.tscn` — grid of 8 level buttons per zone
- ⬜ Each button shows: level name, best star count (0–3), lock state
- ⬜ `src/gameplay/LevelSelect.gd` — tap button → GameManager.start_level(id)

### 2.3 GameManager navigation

- ⬜ `GameManager.go_to_zone_select()` — called from MainMenu PLAY button
- ⬜ `GameManager.go_to_level_select(zone_id)` — called from zone card tap
- ⬜ `GameManager.go_to_main_menu()` — already wired; verify works from results
- ⬜ Back-button handling on each screen (Android back gesture → previous screen)

### 2.4 Level data scaffold

- ⬜ Create stub `.brl` files for Z1-L2 through Z1-L8 (minimal: 8 beats, 1
  obstacle each). These do not need to be tuned yet — just exist so level select
  buttons are not broken.
- ⬜ Update SaveSystem to track "zone_completed" flags needed for unlock logic

---

## Milestone 3 — Obstacle Library Completion (Z1 + Z2)

> Add all obstacles needed to ship Zones 1 and 2. No art required — use
> placeholder shapes. GDD sections 2.1 and 2.2 define exact behavior.

### 3.1 CoralSpike fix + both attachments ✅ (partial)

- ✅ Top attachment — working
- ⬜ Bottom attachment — bug (see Milestone 1.3)
- ⬜ Gate pair spawning verified in playtest

### 3.2 JellyfishDrift complete behavior

- ✅ Spawns and moves
- ⬜ Sine-wave vertical oscillation (amplitude and frequency from GDD 2.2)
- ⬜ Exits screen-left → queue_free() (prevents memory leak)
- ⬜ Collision → player_hit signal fires (already in Pearl/CoralSpike, verify
  JellyfishDrift has same pattern)

### 3.3 KelpCurtain (Z2)

- ⬜ `scenes/obstacles/KelpCurtain.tscn`
- ⬜ `src/gameplay/obstacles/KelpCurtain.gd` — swaying blades, gap opens on beat
- ⬜ Beat-phase-aligned gap timing (gap aligns to `gap_beat_alignment` parameter)
- ⬜ Collision shape: each blade 24×180px; gap 120px wide
- ⬜ Add to ObstacleSpawner type routing

### 3.4 BubbleMine (Z2)

- ⬜ `scenes/obstacles/BubbleMine.tscn`
- ⬜ `src/gameplay/obstacles/BubbleMine.gd` — warning radius 160px, detonates on
  player overlap, self-destructs off-screen
- ⬜ State machine: IDLE → WARNING → EXPLODE → FREE
- ⬜ Add to ObstacleSpawner type routing

### 3.5 ObstacleSpawner routing table

- ⬜ Add `obstacle_type` dispatch for: `jellyfish_drift`, `kelp_curtain`,
  `bubble_mine` (coral_spike and pressure_wall already handled)
- ⬜ Unknown obstacle_type logs a warning and skips (already done, verify)

---

## Milestone 4 — Audio Foundation

> No music composition yet. Goal: beats are audible, hits/collects have sound.
> Silence is the #1 feel-killer for a rhythm game.

### 4.1 Beat click track (placeholder music)

- ⬜ Generate or source a royalty-free 100 BPM click track (`.ogg`), minimum 40
  seconds. Place at `assets/audio/music/zone_1_sunlit_shallows.ogg`
- ⬜ Update `z1-l1.brl` `music_file` field; verify BeatConductor syncs to audio
  instead of falling back to wall-clock
- ⬜ Audio latency calibration: test that beat-fired signal aligns visually to
  click (use `latency_offset` export on BeatConductor)

### 4.2 Sound effects (placeholder OK)

- ⬜ `[SFX: timing_perfect]` — bright chime on PERFECT beat
- ⬜ `[SFX: timing_good]` — soft bell on GOOD beat  
- ⬜ `[SFX: timing_miss]` — low thud on MISS
- ⬜ `[SFX: obs_coral_impact]` — hit sound when player touches CoralSpike
- ⬜ `[SFX: collectible_pearl]` — collection sound
- ⬜ AudioStreamPlayer nodes in HUD or LevelRoot; EventBus signals drive them

### 4.3 Audio bus routing

- ✅ `default_bus_layout.tres` — Master + Music buses exist
- ⬜ Add SFX bus (effects volume separate from music)
- ⬜ Volume controls in settings (future) — just wire correctly now

---

## Milestone 5 — Art Pass (Placeholder → Polished)

> Scope: Z1 only. Focus on the fish character and coral spike art. Everything
> else can stay placeholder until after core loop is stable.

### 5.1 Player character

- ⬜ Sprite sheet for Pebble (pufferfish): `anim_float`, `anim_dive`, `anim_hurt`
  — can be simple hand-drawn or generated art at first
- ⬜ AnimatedSprite2D wired in Player.tscn
- ⬜ Beat ring pulse: `fx_beat_ring.png` → white ring expands on beat from player
- ⬜ Trail particles: bubble_trail_float / bubble_trail_dive (use CPUParticles2D)

### 5.2 Coral spike art

- ⬜ `obs_coral_spike_top.png` / `obs_coral_spike_bottom.png`
- ⬜ Swap Polygon2D placeholder in CoralSpike for Sprite2D

### 5.3 Pearl collectible art

- ⬜ `collectible_pearl.png` — glowing pearl, 60px
- ⬜ Collection particle burst on pickup

### 5.4 UI polish (Z1 scope)

- ⬜ Score / combo fonts — readable at 1080×1920
- ⬜ HUD layout — anchored correctly for all screen ratios
- ⬜ Star rating display on ResultsScreen (0/1/2/3 star icons)
- ⬜ Zone 1 background: `bg_sunlit_shallows_scroll.png` (parallax layers or flat
  gradient placeholder)

---

## Milestone 6 — Build Mode (Phase 1: Local Creation)

> As defined in GDD section 6. Phase 1 = local save only. No publishing yet.
> This is a major feature — treat as a separate mini-project.

### 6.1 Build Mode scene

- ✅ `scenes/buildmode/BuildModeRoot.tscn` — stub exists
- ⬜ Timeline view: horizontal scrollable beat grid
- ⬜ Beat markers: quarter-beat lines, measure markers every 4 beats
- ⬜ Obstacle placement: tap beat → select type → configure parameters → place
- ⬜ Placed obstacle blocks visible on timeline (colored by type)
- ⬜ Playback: play from any beat, obstacles spawn in preview mode

### 6.2 Beat grid snap

- ⬜ Quarter-beat snap (always active)
- ⬜ Beat subdivision unlock system (8th at Z3+, 16th at Z5+)
- ⬜ Visual: orange playhead, white/gray grid lines at appropriate zoom

### 6.3 Level save/load

- ⬜ Build mode serializes to `.brl` JSON format (same schema as authored levels)
- ⬜ Save to `user://levels/<uuid>.brl`
- ⬜ Load from local saves in level select (separate "Your Levels" tab)
- ⬜ 5-level cap for non-Creator-Pass users (show upgrade prompt on cap)

### 6.4 Playability validator

- ⬜ Auto-check: no beat position has collision filling entire lane height
- ⬜ Minimum 16 beats of content before save allowed
- ⬜ Must have been played through once before publish (play-through flag)

### 6.5 Difficulty auto-tagger

- ⬜ Implement formula from GDD 6.4: `difficulty_score` → Beginner/Intermediate/
  Advanced/Expert tag
- ⬜ Tag shown on level card and in build mode sidebar
- ⬜ Creators can only lower the auto-assigned tag, not raise it

---

## Milestone 7 — Monetization Integration

> IAP flows. Do NOT start until Milestone 2 is complete (level select needed
> for lock/unlock UI). Platform SDKs require test accounts before live testing.

### 7.1 IAP product registration

- ⬜ Register products in Google Play Console: `unlock_full_reef` ($2.99),
  `creator_pass` ($1.99), `reef_bundle` ($3.99)
- ⬜ Register products in App Store Connect (same IDs)
- ⬜ Godot Android/iOS IAP plugin integrated (use GodotGooglePlayBilling or
  official Godot IAP addon)

### 7.2 Purchase flow

- ⬜ `src/core/IAPManager.gd` — wraps platform SDK, emits
  `purchase_completed(product_id)` and `purchase_failed(product_id, error)`
- ⬜ Lock icons on Z4/Z5 and Creator tab tap → `IAPManager.request_purchase()`
- ⬜ `SaveSystem.set_flag("full_reef_owned", true)` on purchase_completed
- ⬜ Restore purchases on app launch (required by Apple policy)
- ⬜ Receipt validation (at minimum: local; server-side validation deferred)

### 7.3 IAP UI requirements (from GDD 8.1 / monetization_spec.md)

- ⬜ Price shown IN the button label: "Unlock Full Reef — $2.99"
- ⬜ No pre-checked anything, no dark patterns
- ⬜ Purchase screen clearly lists what's included
- ⬜ "Not Now" button same size/prominence as "Buy"
- ⬜ No IAP prompts except at the content gate (not in menus, not during levels)

---

## Milestone 8 — Compliance & Safety

> Must be complete before any App Store submission. Many items are
> documentation/policy — do not skip.

### 8.1 COPPA / child privacy

- ✅ `docs/compliance/coppa_checklist.md` — checklist document exists
- ⬜ Implement: no analytics SDK that collects PII
- ⬜ Implement: aggregate-only analytics (level clear rates, not user IDs)
- ⬜ `PARENTS.md` in app bundle (see GDD 8.2, item 7) — explains data collection
  (none beyond platform SDK), IAP model, no ads. Must be human-readable.
- ⬜ Privacy policy accessible from main menu (link or in-app text)
- ⬜ No chat, no user-generated text in public spaces without 24h moderation

### 8.2 Google Play Families policy

- ✅ `docs/compliance/google_play_families_checklist.md` — checklist exists
- ⬜ Manifest flags: `android:isGame="true"`, content rating `Everyone`
- ✅ `docs/compliance/android_manifest_flags.md` — reference doc exists
- ⬜ No advertising SDKs declared in manifest
- ⬜ Target API 34+ (required 2024+)
- ⬜ App passes Google Play's pre-launch report: no crashes, no policy flags

### 8.3 Apple Kids category

- ✅ `docs/compliance/apple_kids_checklist.md` — checklist exists
- ⬜ No third-party analytics/advertising frameworks in the binary
- ⬜ Age gate: if app targets age band 5 and under in Kids category, no external
  links. Our target is 6–12, age band "Ages 9–11" or "Ages 6–8" — confirm
  which and apply appropriate restrictions.
- ⬜ No behavioral advertising
- ⬜ All IAP reviewed by Apple Kids team — no subscription products

### 8.4 Accessibility minimums (GDD 8.2, item 3)

- ⬜ Text never below 16sp on mobile
- ⬜ Colorblind mode: obstacle shapes differentiated without color
- ⬜ Reduced motion mode: disable camera shake, reduce particle density 50%
- ⬜ Timing windows tunable in accessibility settings (widen PERFECT to ±100ms)
- ⬜ One-hand mode: already works (single-finger input)

### 8.5 Content framing

- ⬜ Fail screen: "Nice try! Ready to go again?" (not "You failed" or "Game Over")
- ⬜ 3-star fail: "Great job! Can you find 3 stars?" (not "You only got 2 stars")
- ⬜ No blood, no death framing — failure = "bonked," character cartoon-squishes

---

## Milestone 9 — Android Export

> Ship on Android first. iOS export follows same pattern but requires Mac + Xcode
> for final signing/submission.

### 9.1 Export setup

- ✅ CI Android export job exists in `.github/workflows/`
- ⬜ Keystore generated and stored securely (NOT committed to git — use GitHub
  Secrets or local env var)
- ⬜ `export_presets.cfg` — Android target API 34, permissions scoped to minimum
- ⬜ Test APK on physical device (Pixel or Samsung, Android 12+)
- ⬜ Test APK on low-end device (4GB RAM, old Snapdragon)

### 9.2 Performance targets

- ⬜ 60fps maintained on mid-range device during gameplay
- ⬜ Max 3s cold start to MainMenu
- ⬜ APK size < 80MB (deferred asset downloads if needed for music)
- ⬜ Battery: < 5% per 15 minutes of play (no background processing)

### 9.3 Android-specific features

- ⬜ Touch input: entire screen = one finger = HOLD/DIVE (already coded; verify on
  device that `InputEventScreenTouch` fires correctly with Godot 4.6 on Android)
- ⬜ Back button: Android system back → confirm exit or navigate up
- ⬜ App lifecycle: pause/resume without losing mid-level state
- ⬜ Audio focus: duck/restore when another app takes audio (phone calls, etc.)

### 9.4 Google Play submission checklist

- ⬜ Store listing: screenshots (at least 2 phone), feature graphic, description
- ⬜ Content rating questionnaire completed in Play Console
- ⬜ Privacy policy URL entered in Play Console
- ⬜ Target audience declared (children)
- ⬜ Declared app content: no ads, no location, no user data
- ⬜ Internal testing track APK uploaded, tested by ≥ 1 testers
- ⬜ Production release after internal + closed testing sign-off

---

## Milestone 10 — Zones 2 and 3 Content

> After export pipeline works, build content for Z2 and Z3. Z4–Z6 are behind the
> IAP gate and can be deferred further. Each zone = 8 levels + zone mechanics.

### 10.1 Zone 2 — Kelp Forest Canyon

- ⬜ Z2-L1 through Z2-L8 `.brl` files authored
- ⬜ KelpCurtain and BubbleMine obstacles complete (see Milestone 3)
- ⬜ Kelp Tunnel zone mechanic (lane restriction 50% for 8–16 beats)
- ⬜ Zone 2 background art `bg_kelp_forest_scroll.png`
- ⬜ Zone 2 music track (BPM 120–130)

### 10.2 Zone 3 — Shipwreck Alley

- ⬜ Implement CurrentJet, AnchorChain, EelSnap obstacles (GDD 2.5–2.8)
- ⬜ Z3-L1 through Z3-L8 `.brl` files authored
- ⬜ Hull Breach interior passage mechanic
- ⬜ Zone 3 background + interior background art
- ⬜ Zone 3 music track (BPM 130–145)

### 10.3 Character unlock triggers

- ⬜ Zap: awarded on Z2 completion — implement in GameManager
- ⬜ Crusher: awarded on 3-star × 4 Z3 levels — implement in SaveSystem listener

---

## Milestone 11 — Cloud Save + Leaderboards

> Deferred until after Android launch. Required for iOS parity.

- ⬜ Google Play Games Services integration (sign-in, cloud save sync)
- ⬜ Apple Game Center integration (achievements, leaderboards)
- ⬜ Sync policy: local save always wins over cloud on conflict
- ⬜ Friends-only leaderboards (not public ranking, per GDD 8.1)
- ⬜ Offline play unaffected by cloud save failures

---

## Milestone 12 — Creator Pass + Community Gallery

> Behind the $1.99 IAP. Requires content moderation queue (can be manual at
> launch). Deferred until core game is launched and stable.

- ⬜ Publishing flow: level → 24h review queue → public gallery
- ⬜ Community gallery browse screen (filter by zone style, difficulty, newest)
- ⬜ Creator earnings: 10 coins per unique completion (capped 200/month/level)
- ⬜ Moderation: admin panel or email queue for community content review

---

## Ongoing / Every Session

These apply to every coding session regardless of milestone:

- ⬜ Run `tools/run_tests.sh` before and after changes (all 4 stages must pass)
- ⬜ Run `python3 tools/validate_brl.py` after any `.brl` edits
- ⬜ Run `python3 tools/check_secrets.py` before every push
- ⬜ Update `docs/pm/next_session_handoff.md` at end of each session
- ⬜ No hardcoded strings visible to players — all in `docs/narrative/ui_copy.md`
- ⬜ New feature → new test (or extend existing test to cover it)

---

## Known Bugs (backlog)

| # | Description | Severity | Status |
|---|-------------|----------|--------|
| B1 | Bottom CoralSpike not rendering — only top spikes appear in play | High | ✅ Not a bug — viewport display issue on landscape PC; confirmed spawning via headless test |
| B2 | Level never ends — run_completed not emitted after beat 32 | High | ✅ Fixed — LevelLoader._check_level_end + LevelRoot._on_level_ended |
| B3 | ResultsScreen never reached (no completion path) | High | ✅ Fixed — run_completed → GameManager.finish_level → ResultsScreen |
| B4 | JellyfishDrift does not exit screen — possible memory leak over long play | Medium | ⬜ M3 |
| B5 | BeatConductor wall-clock mode has no drift correction — drifts ~50ms/min | Low | ⬜ M4 |

---

## Content Pipeline Status

| Zone | BRL Files | Obstacles Ready | Art | Audio |
|------|-----------|-----------------|-----|-------|
| Z1 | 1/8 | 2/2 needed | ⬜ | ⬜ |
| Z2 | 0/8 | 0/4 needed | ⬜ | ⬜ |
| Z3 | 0/8 | 0/7 needed | ⬜ | ⬜ |
| Z4 | 0/8 | 0/6 needed | ⬜ | 🔒 IAP |
| Z5 | 0/8 | 0/7 needed | ⬜ | 🔒 IAP |
| Z6 | 0/8 | 0/8 needed | ⬜ | 🔒 earned |

---

## Dependencies / Risk Register

| Risk | Mitigation |
|------|------------|
| Godot Android export plugin for IAP not maintained | Evaluate Godot IAP addons early (M7 pre-work); have fallback of GDNative wrapper |
| Music composition takes longer than dev | Deferred — placeholder click track covers testing. Commission music after M4 is complete. |
| Community moderation burden at launch | Launch without community gallery; add Creator Pass post-launch once moderation process is defined |
| COPPA review rejection | Run compliance docs through lawyer review before M8 submission. Do not submit to Kids category without legal sign-off. |
| Scope creep on Build Mode | Build Mode is a hard-capped feature set per GDD 6. No additions without updating GDD first. |
