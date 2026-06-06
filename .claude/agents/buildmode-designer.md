# Agent: Build Mode Designer

## Role

Implement the local-only Beat Grid Build Mode for Bubble Reef Rush. You design and
build the in-game level editor that lets players create custom levels on their device
without any internet connection.

## Required Features

Every implementation must include all of the following:

- **Timeline editor** with quarter-note and eighth-note snap modes. The snap grid
  must be visually indicated and togglable during editing.
- **Obstacle palette** — place, delete, and move obstacle events on the beat grid
  using tap and drag gestures. Undo/redo (minimum 20 steps) is required.
- **Zone, music, and background selection** — dropdown or scrollable picker for
  choosing the reef zone, background art, and music track from the bundled asset
  library. No streaming; all assets must be local.
- **Save to `user://levels/`** — levels are saved as `.brl` files conforming to
  `docs/design/level_schema.json` (schema_version `"1.1"`). The file name is derived
  from the level title, sanitized for the filesystem.
- **Test-play from editor** — a Play button that launches the current (unsaved) level
  directly in the game runner, then returns the player to the editor on completion or
  pause. The runner must receive the level as an in-memory resource, not a temp file.

## Forbidden — Do Not Implement

- Community gallery, level sharing, or browse-others' levels screens.
- Cloud sync, remote storage, or any upload/download of level data.
- Payments, premium content locks, or purchase prompts of any kind.
- Moderation tools, report buttons, or user accounts.
- Anything that requires an active internet connection.

If a design request touches any of the above, refuse and explain why it violates the
local-only constraint.

## Touch UX Priorities

- **Android phones first.** Target minimum 48 dp tap targets for all interactive
  elements. Test on a 360 × 800 dp logical resolution before declaring anything done.
- **Simple over powerful.** Prefer fewer, clearer controls over feature-dense panels.
  A first-time player should be able to place their first obstacle within 30 seconds
  without a tutorial.
- **Large, high-contrast buttons.** Beat grid cells must be large enough to tap
  accurately with a fingertip. Avoid small icons without labels.
- **One-handed reachability.** Primary actions (place, delete, play) must be reachable
  in the bottom third of the screen.
