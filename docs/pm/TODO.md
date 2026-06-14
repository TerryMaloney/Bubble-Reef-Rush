# Bubble Reef Rush — Running TODO

Living checklist so nothing gets lost. Updated as work lands.

## ✅ Done (recent sessions)
- Physics tuning: rise/dive speeds, hold-dive fast (terminal 1100).
- Ghost player: synced to live physics (no longer sinks to the floor).
- Character art drop-in: `assets/characters/player.png`, auto-scaled.
- Versus / Pass & Play: real scores + distance bonus, 👑 winner, Next Level / Try Again flow.
- BubbleBurst projectile actually hits enemies (+150 pts); bigger pause button.
- **Difficulty reachability engine**: forward reachable-band validation incl. point hazards.
- **Build Mode overhaul**: bottom palette, place-vs-pan fix, WYSIWYG footprints, trash pill,
  grab-to-slide, Play crash fixed, live slider preview, "You made it X%" death banner.
- **Global input bug**: AchievementToast no longer eats taps in the top ~140px.
- **Invisible killers fixed**: EelSnap strike + AnchorChain segments now have visuals.
- Shipwreck levels (z3-l7/l8) eased (less-frequent eel/jet strikes).
- **Parallax background system**: drop-in PNG scrolls automatically; flat gradient fallback.
- **UI theme + modal coverage**: global theme.tres, all modals have 75% black dim.
- **Profile delete with confirm**: two-tap delete, last-profile guard.
- **Zone/Level Select polish**: zone cards 200px + font 36; level select shows score + ghost ★.
- **Pass & Play UX**: hub hides on launch, large player cards, Add Player shortcut.
- **Ghost Challenge**: intro label + live +/- delta in HUD.
- **MirrorFish 20% slower + SHADOW APPROACHING warning**.
- **DarkVoid fade-in** + "DARKNESS FALLS" warning; sudden_darkness mutator active.
- **Difficulty modes** (Easy/Normal/Hard): DifficultyModifier applies param tweaks at spawn
  time; per-difficulty star tracking in SaveSystem; LevelSelect difficulty row with unlock gates.
- **Full obstacle roster in Build Mode**: all 12 types shown regardless of unlock status.
- **CoralSpike 4-way orientations** (bottom/top/left/right) + continuous height slider.
- **Build Mode "N Problems" tappable**: tap to see popup listing each issue.
- **game_flow_test**: fixed (fires correct beat count, waits for level load signal).
- **Visual polish**: ResultsScreen buttons 88px, title 40pt; ProfileManager error 28pt;
  difficulty buttons 88px.

## 🚧 Art drop-in (pipelines ready — just add files)
- [ ] Zone backgrounds: `assets/backgrounds/z<zone>_bg_l<0-5>.png`. Start Zone 1.
- [ ] Player character: `assets/characters/player.png` (Bubble Diver swimming pose).
- [ ] Modular spike art: `coral_spike_tip/body/base.png`.
- [ ] Obstacle palette thumbnails: `assets/ui/palette/<type>.png`.

## 🐛 Bugs — re-test now (likely fixed)
- [ ] Wild West (Party Shuffle) random death — EEL/CHAIN FIX should resolve; re-test.
- [ ] Treasure Hunt invisible hit — DARKVOID FADE should resolve; re-test.
- [ ] Shipwreck Alley / Eel Alley — re-test with new visible eels + eased timing.

## 🧹 Nice-to-have
- [ ] Split passages (upper/lower choose-your-path).
