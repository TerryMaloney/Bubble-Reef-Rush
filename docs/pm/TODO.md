# Bubble Reef Rush — Running TODO

Living checklist so nothing gets lost. Updated as work lands.

## ✅ Done (recent playtest-repair sessions)
- Physics tuning: rise/dive speeds, hold-dive fast (terminal 1100).
- Ghost player: synced to live physics (no longer sinks to the floor).
- Character art drop-in: `assets/characters/player.png`, auto-scaled.
- Versus / Pass & Play: real scores + distance bonus, 👑 winner, Next Level /
  Try Again flow.
- BubbleBurst projectile actually hits enemies (+150 pts); bigger pause button.
- **Difficulty reachability engine**: forward reachable-band validation incl.
  point hazards (tools/check_movements.py + PlayabilityValidator.gd). Catches
  impossible sections; powers Build Mode "is this beatable?".
- **Build Mode overhaul**: bottom palette, place-vs-pan fix (ruler = pan,
  place-mode previews), WYSIWYG obstacle footprints, trash pill, grab-to-slide,
  Play crash fixed, live slider preview, "You made it X%" death banner.
- **Global input bug**: AchievementToast no longer eats taps in the top ~140px
  of every screen (this was the dead Back/Save/top-bar buttons everywhere).
- **Invisible killers fixed**: EelSnap strike + AnchorChain segments now have
  visuals (were pure invisible hitboxes).
- Shipwreck levels (z3-l7/l8) eased slightly (less-frequent eel/jet strikes).
- **Parallax background system**: drop-in `assets/backgrounds/z<zone>_bg_l<0-5>.png`,
  scrolls automatically; flat gradient fallback when no art.

## 🚧 Next up (big tracks)
- [ ] **Difficulty modes**: standardized Easy / Normal / Hard selection; only
      unlock a difficulty once the previous one is beaten. (Design + save schema
      + level-select UI + apply to gate gaps / hazard timing.)
- [ ] **Modular spike system**: tip/body/base tiling, generated collision, 4
      orientations, Build-Mode height slider with live preview (per spec).
- [ ] **More obstacles in the Build palette** (expose the full roster).
- [ ] **Visual polish pass**: consistent theme, spacing, colours; Build Mode
      aesthetics; menus.

## 🐛 Bugs to repro / confirm
- [ ] Wild West (Party Shuffle) random death — needs repro; check which hazards
      that playlist spawns (likely shared with the now-fixed invisible killers,
      or a mutator). 
- [ ] Treasure Hunt invisible hit — repro (suspect: darkness obscuring a hazard).
- [ ] Re-test Shipwreck Alley / Eel Alley now that eels + chains are visible.

## 🎨 Art to create (pipelines are ready — just drop files in)
- [ ] Zone backgrounds: `assets/backgrounds/z<zone>_bg_l<0-5>.png` (see that
      folder's README). Start with Zone 1 Sunlit Shallows.
- [ ] Player character: `assets/characters/player.png` (Bubble Diver swimming pose).
- [ ] Modular spike art: `coral_spike_tip/body/base.png` (for the spike system).
- [ ] Obstacle palette thumbnails: `assets/ui/palette/<type>.png`.

## 🧹 Minor / nice-to-have
- [ ] "N Problems" readout in Build Mode → tappable to list the actual issues.
- [ ] Split passages (upper/lower choose-your-path) — reachability engine already
      supports validating both branches.
- [ ] `game_flow_test` masked-failure cleanup (pre-existing, non-blocking).
