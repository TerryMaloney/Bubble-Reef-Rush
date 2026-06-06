# Bubble Reef Rush — Rhythm System API Reference

**System:** Rhythm (T-2)  
**Engine:** Godot 4.3  
**Language:** GDScript (static typing)  
**Last Updated:** 2026-06-06  

---

## Overview

The rhythm system consists of four scripts. Two are used every level without exception; the other two are per-level instances managed by GameManager.

| Script | Type | Lifetime |
|---|---|---|
| `BeatConductor.gd` | Autoload singleton | Entire game session |
| `TimingJudge.gd` | Per-level `Node` child | One level run |
| `RhythmMap.gd` | Per-level `Node` child | One level run |
| `BeatVisualizer.gd` | Per-level `Node2D` child of player | One level run |

---

## BeatConductor

**File:** `src/rhythm/BeatConductor.gd`  
**Autoload name:** `BeatConductor`  
**Registration:** Project → Project Settings → Autoload → path `res://src/rhythm/BeatConductor.gd`, name `BeatConductor`

The master rhythm clock. All other systems derive their time reference from BeatConductor. It owns the `AudioStreamPlayer` for level music and synchronises the beat grid to `AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()` for low-latency accuracy.

---

### Exported Variables

```gdscript
@export var user_latency_offset_ms: float = 0.0
```

Player-adjustable timing correction in milliseconds. Range: −200 to +200. Persist this in `user://save_data.json` and assign it before calling `start_level()`. A positive value shifts the timing windows forward (player hears music later than the raw clock; most devices need a positive value). Set via the Settings → Timing Adjust slider.

---

### Signals

```gdscript
signal beat_fired(beat_index: int)
```
Emitted on every quarter beat. `beat_index` is 0-based and increments monotonically for the duration of the level. Beat 0 fires on the first beat after `start_level()` is called.

```gdscript
signal half_beat_fired(beat_index: float)
```
Emitted halfway between each pair of quarter beats (eighth-note precision). `beat_index` is a `.5` decimal: `0.5`, `1.5`, `2.5`, etc.

```gdscript
signal bar_changed(bar_number: int)
```
Emitted when the beat grid crosses into a new 4/4 bar. `bar_number` is 1-based (first bar = 1).

```gdscript
signal conductor_started
```
Emitted at the end of `start_level()` and `start_level_variable_bpm()` once the audio player has begun. Also re-emitted on app resume.

```gdscript
signal conductor_stopped
```
Emitted by `stop_level()` and when the app goes to the background (NOTIFICATION_APPLICATION_PAUSED).

---

### Methods

```gdscript
func start_level(bpm: float, music_stream: AudioStream) -> void
```
Start a fixed-BPM level. `bpm` is the level's `metadata.bpm` from the level schema. `music_stream` is a pre-loaded `AudioStreamOGGVorbis` resource. Resets all state and begins the beat clock. Safe to call while another level is already running (performs a clean teardown first).

```gdscript
func start_level_variable_bpm(music_stream: AudioStream, beat_timestamps: Array[float]) -> void
```
Start a Zone 5 variable-BPM level. `beat_timestamps` is a sorted array of playback-position seconds (from track start) at which each beat index falls. Index 0 is the time of beat 0, index 1 is beat 1, etc. This array is authored once per Zone 5 level and stored in a companion resource (e.g. `zone_5_beat_map.tres` or JSON). BeatConductor reads `music_player.get_playback_position()` each frame and fires beats by comparing against this array rather than using a fixed interval.

```gdscript
func stop_level() -> void
```
Stop the active level immediately. Stops audio, resets state, emits `conductor_stopped`.

```gdscript
func get_current_beat_time_ms() -> float
```
Returns elapsed milliseconds since level start, corrected for `AudioServer.get_output_latency()` and `user_latency_offset_ms`. **This is the timestamp you must pass to `TimingJudge.judge_input()`.** Capture it at the exact frame the input event is received — do not call it later and back-calculate.

```gdscript
func get_current_beat_position() -> float
```
Returns the fractional beat position (e.g. `3.72` means 72% of the way through beat 3). Useful for ObstacleSpawner lookahead: compute how many beats ahead to spawn so an obstacle arrives on screen at the right moment given current scroll speed.

```gdscript
func get_bpm_at_beat(beat_index: float) -> float
```
Returns the effective BPM at the given beat. For fixed-BPM levels always returns the base BPM. For variable-BPM levels interpolates through the bpm_changes array.

```gdscript
func resync_to_playback_position() -> void
```
Resets the beat cursor to match the current audio playback position. Call this after `NOTIFICATION_APPLICATION_RESUMED` to avoid a cascade of catch-up beat signals from accumulated missed frames. BeatConductor calls this automatically in its `_notification` handler, but it is also public for testing or manual recovery scenarios.

---

### Usage Example — ObstacleSpawner connecting to beat events

```gdscript
# ObstacleSpawner.gd (T-1 team)
extends Node

func _ready() -> void:
    BeatConductor.beat_fired.connect(_on_beat_fired)
    BeatConductor.bar_changed.connect(_on_bar_changed)
    BeatConductor.conductor_started.connect(_on_conductor_started)
    BeatConductor.conductor_stopped.connect(_on_conductor_stopped)


func _on_beat_fired(beat_index: int) -> void:
    # Ask RhythmMap which obstacles appear at this beat.
    var obstacles: Array[Dictionary] = _rhythm_map.get_obstacles_at_beat(float(beat_index))
    for obstacle_data: Dictionary in obstacles:
        _spawn_obstacle(obstacle_data)


func _on_bar_changed(bar_number: int) -> void:
    # Every new bar: adjust scroll speed from the speed zone lookup.
    var current_beat: float = BeatConductor.get_current_beat_position()
    var speed: float = _rhythm_map.get_speed_multiplier_at_beat(current_beat)
    _scroll_system.set_speed_multiplier(speed)


func _on_conductor_started() -> void:
    _scroll_system.resume()


func _on_conductor_stopped() -> void:
    _scroll_system.pause()
```

---

## TimingJudge

**File:** `src/rhythm/TimingJudge.gd`  
**Class name:** `TimingJudge`  
**Type:** Regular `Node` — instantiated per level, NOT an autoload.

Evaluates player input against the current beat position using timing windows from GDD §1.6:

| Result | Window |
|---|---|
| PERFECT | \|offset\| ≤ 50 ms |
| GOOD | 50 ms < \|offset\| ≤ 150 ms |
| MISS | \|offset\| > 150 ms |

At BPM ≥ 160 both windows compress linearly toward 80 % of their nominal size at 180 BPM, reflecting increased rhythm density at high tempo.

---

### Enum

```gdscript
enum TimingResult { PERFECT, GOOD, MISS }
```

Defined in `TimingJudge.gd`. Reference from other scripts as `TimingJudge.TimingResult.PERFECT` etc.

---

### Signals

```gdscript
signal input_judged(result: TimingJudge.TimingResult, offset_ms: float, beat_index: int)
```
Emitted by every `judge_input()` call. `offset_ms` is the signed offset from the beat centre (negative = early, positive = late). `beat_index` is the integer beat the input was judged against (may be the previous beat if input arrived fractionally late).

```gdscript
signal combo_updated(count: int)
```
Emitted after every `judge_input()` call when the combo count changes. `count` = 0 signals a MISS/combo-break. Does not emit if the count is unchanged (impossible in practice since each input either increments or resets).

---

### Methods

```gdscript
func judge_input(input_time_ms: float) -> TimingResult
```
Core judgement method. Call this in your input handler:

```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("dive"):
        var result: TimingJudge.TimingResult = _timing_judge.judge_input(
            BeatConductor.get_current_beat_time_ms()
        )
        # result is also available via input_judged signal
```

`input_time_ms` must be the value from `BeatConductor.get_current_beat_time_ms()` captured at input time — not `Time.get_ticks_msec()`.

```gdscript
func get_current_window_ms() -> float
```
Returns the half-width of the PERFECT window in ms, accounting for BPM compression. Useful for displaying the window size on an accessibility/calibration screen.

```gdscript
func get_combo() -> int
```
Returns the current consecutive non-MISS hit count synchronously (does not emit a signal).

```gdscript
func reset() -> void
```
Clears all state. Call at level start, level fail, and retry.

---

### Instantiation and Per-Level Usage

```gdscript
# GameManager.gd
var _timing_judge: TimingJudge = null

func _start_level(level_id: String) -> void:
    # Instantiate a fresh judge for each level run.
    if is_instance_valid(_timing_judge):
        _timing_judge.queue_free()

    _timing_judge = TimingJudge.new()
    add_child(_timing_judge)
    _timing_judge.reset()

    # Connect score and combo handlers.
    _timing_judge.input_judged.connect(_on_input_judged)
    _timing_judge.combo_updated.connect(_on_combo_updated)

    # Also wire BeatVisualizer to reflect judgement quality.
    _beat_visualizer.set_timing_quality  # called directly in _on_input_judged


func _on_input_judged(
        result: TimingJudge.TimingResult,
        offset_ms: float,
        beat_index: int) -> void:
    _score_system.record_hit(result, _timing_judge.get_combo())
    _beat_visualizer.set_timing_quality(result)
    # Fire EventBus for any other systems (audio SFX, UI flash, etc.).
    EventBus.timing_result_received.emit(result, offset_ms)


func _on_combo_updated(count: int) -> void:
    _hud.update_combo(count)
    if count == 0:
        EventBus.combo_broken.emit()
    elif count in [10, 20, 40, 80]:
        EventBus.combo_milestone_reached.emit(count)
```

---

## RhythmMap

**File:** `src/rhythm/RhythmMap.gd`  
**Class name:** `RhythmMap`  
**Type:** Regular `Node` — instantiated per level.

Loads a `.json` level file conforming to `level_schema.json`, validates it, and caches beat/obstacle data into O(1)-lookup structures.

---

### Signals

```gdscript
signal map_loaded(level_id: String)
```
Emitted once the file is parsed, validated, and all caches are populated. `level_id` matches `metadata.id` from the JSON.

```gdscript
signal map_load_failed(error: String)
```
Emitted if the file cannot be found, parsed, or fails validation. `error` is a human-readable description. The caller should surface this to the developer console and either abort level start or fall back to a safe default.

---

### Methods

```gdscript
func load_level(level_id_or_path: String) -> void
```
Load a level. Pass either:
- A level ID like `"z1-l1"` (resolves to `res://assets/levels/z1-l1.json`).
- A full Godot path like `"res://assets/levels/z5-l3.json"` or `"user://levels/my_level.json"`.

Asynchronous in the sense that signals fire in the same frame after parsing completes — there is no background thread. For large level files (>200 obstacles) parse time is under 1 ms on modern mobile hardware.

```gdscript
func get_obstacles_at_beat(beat_index: float) -> Array[Dictionary]
```
Returns all obstacle entries scheduled at exactly `beat_index`. Each Dictionary contains the full beat_map entry from the JSON: `beat_index`, `beat_subdivision`, `obstacle_type`, `lane_position`, and `parameters`.

```gdscript
func get_all_beats() -> Array[float]
```
Returns a sorted array of every beat index that has at least one obstacle. Use this in a pre-pass to pre-instantiate obstacle nodes ahead of time, or to draw the timeline in the level editor.

```gdscript
func get_speed_multiplier_at_beat(beat_index: float) -> float
```
Returns the `speed_multiplier` from the speed_zones array that covers `beat_index`. Returns `1.0` if no zone covers that beat.

```gdscript
func get_bpm_at_beat(beat_index: float) -> float
```
Returns the effective BPM at the given beat. For fixed-BPM levels this is always `metadata.bpm`. For variable-BPM levels (Zone 5) it interpolates through the `bpm_changes` array, handling both instant and gradual transitions (`transition_beats` > 0).

```gdscript
func get_raw_data() -> Dictionary
```
Returns the entire parsed JSON dictionary. Use this for metadata, music filename, par_score thresholds, background keys, and unlock requirements.

```gdscript
func is_loaded() -> bool
```
Returns `true` if a level has been successfully loaded and cached.

```gdscript
func get_level_id() -> String
```
Returns `metadata.id` from the loaded level.

---

### Validation Behaviour

On load, RhythmMap:

1. Verifies all required top-level keys exist (`schema_version`, `metadata`, `music`, `beat_map`, `speed_zones`, `background`, `unlock_requirements`, `par_score`).
2. Verifies all required `metadata` sub-keys exist.
3. Verifies all required `music` sub-keys exist.
4. Emits `push_warning()` (non-fatal) if `music.filename` does not resolve to an existing file under `res://assets/audio/music/`. The level loads but audio will be silent.
5. Verifies `beat_map` is an Array and each entry has `beat_index`, `obstacle_type`, and `lane_position`.
6. On any hard failure, emits `map_load_failed(error)` and does not cache any data.

---

### Usage Example — GameManager integrating RhythmMap with ObstacleSpawner

```gdscript
# GameManager.gd
var _rhythm_map: RhythmMap = null

func _start_level(level_id: String) -> void:
    _rhythm_map = RhythmMap.new()
    add_child(_rhythm_map)
    _rhythm_map.map_loaded.connect(_on_map_loaded)
    _rhythm_map.map_load_failed.connect(_on_map_load_failed)
    _rhythm_map.load_level(level_id)


func _on_map_loaded(level_id: String) -> void:
    var raw: Dictionary = _rhythm_map.get_raw_data()
    var meta: Dictionary = raw["metadata"] as Dictionary
    var music_data: Dictionary = raw["music"] as Dictionary

    var bpm: float = float(meta.get("bpm", 110.0))
    var is_variable: bool = bool(meta.get("bpm_variable", false))
    var music_path: String = "res://assets/audio/music/" + str(music_data.get("filename", ""))
    var music_stream: AudioStream = load(music_path)

    if is_variable:
        # Zone 5: load the companion beat timestamps resource.
        var beat_map_res: Resource = load("res://assets/levels/zone_5_beat_map.tres")
        var timestamps: Array[float] = beat_map_res.timestamps  # custom Resource property
        BeatConductor.start_level_variable_bpm(music_stream, timestamps)
    else:
        BeatConductor.start_level(bpm, music_stream)

    # Hand the map reference to ObstacleSpawner (T-1).
    _obstacle_spawner.set_rhythm_map(_rhythm_map)


func _on_map_load_failed(error: String) -> void:
    push_error("GameManager: Level load failed — " + error)
    # Navigate back to level select or show an error screen.
```

---

## BeatVisualizer

**File:** `src/rhythm/BeatVisualizer.gd`  
**Class name:** `BeatVisualizer`  
**Type:** `Node2D` — attach as a child of the player node.

Renders the beat-pulse ring described in GDD §1.5. The ring expands from `pulse_scale_min` to `pulse_scale_max` and fades out over `pulse_duration_sec` seconds on every `beat_fired` signal. Calling `set_timing_quality()` changes the ring color to gold (PERFECT), blue (GOOD), or gray (MISS) and triggers an additional burst.

---

### Exported Variables

```gdscript
@export var base_color: Color          # Default ring color (white, α 0.85)
@export var pulse_scale_max: float     # Maximum ring scale (default 1.5)
@export var pulse_duration_sec: float  # Full animation duration (default 0.1 s)
@export var ring_width: float          # Stroke width in pixels (default 6.0)
@export var ring_radius: float         # Ring radius at scale 1.0 (default 48.0 px)
@export var pulse_scale_min: float     # Starting scale each pulse (default 0.2)
```

---

### Methods

```gdscript
func set_timing_quality(result: TimingJudge.TimingResult) -> void
```
Sets the ring color based on the last timing judgement and triggers a pulse:
- `PERFECT` → `Color(1.0, 0.85, 0.0, 1.0)` (gold)
- `GOOD` → `Color(0.2, 0.6, 1.0, 1.0)` (blue)
- `MISS` → `Color(0.5, 0.5, 0.5, 0.7)` (gray)

```gdscript
func reset_color() -> void
```
Resets the ring color to `base_color`. Call at level start or on retry.

---

### Typical Wiring

```gdscript
# In GameManager or PlayerController after both nodes exist in the scene tree:
_timing_judge.input_judged.connect(
    func(result: TimingJudge.TimingResult, _offset: float, _beat: int) -> void:
        _beat_visualizer.set_timing_quality(result)
)
```

The visualizer connects to `BeatConductor.beat_fired` automatically in `_ready()`. No manual connection is needed for the beat pulse — only for the color change.

---

## Zone 5 Variable BPM — Pre-Baked Beat Map Approach

### Why a pre-baked map is required

Zone 5's audio track (`zone_5_twilight_trench.ogg`) contains built-in tempo automation that accelerates from 80 BPM to 140 BPM over its 90–120 second duration. This tempo change is baked into the audio file by the DAW; there is no DAW metadata accessible to Godot at runtime.

A clock-based conductor that divides the playback clock by a fixed `beat_duration_sec` would accumulate drift as the real musical tempo changes. After 32 bars the beat cursor would be off by several seconds, making obstacles spawn on the wrong beats and timing judgement meaningless.

### How the pre-baked map works

A companion resource file stores an array of playback-position timestamps — one float per beat:

```
beat 0  → 0.000 s  (80 BPM, beat interval = 0.750 s)
beat 1  → 0.750 s
beat 2  → 1.500 s
...
beat 64 → 32.1 s   (BPM now ~110, interval = 0.545 s)
...
beat 128 → 60.4 s  (BPM now ~135, interval = 0.444 s)
```

These timestamps are authored once (using a DAW or a Python script that reads the automation curve) and saved to `res://assets/levels/zone_5_beat_map.tres` or embedded as a `bpm_changes` array in each Zone 5 level JSON. The `bpm_changes` approach uses the interpolation logic in `RhythmMap.get_bpm_at_beat()` to reconstruct timestamps on demand from authored control points.

### How BeatConductor uses the map

When `start_level_variable_bpm()` is called, BeatConductor stores the timestamp array. Each `_process()` frame it reads `music_player.get_playback_position()` and fires all beat signals whose timestamp has been passed since the last frame. This approach:

- Requires no polling of AudioServer's mix clock for the beat grid (the audio itself is the ground truth).
- Automatically resyncs after app resume because it always reads live playback position.
- Handles scrubbing and seek operations correctly.

### Authoring the beat timestamps

For Zone 5 levels, the level designer provides `bpm_changes` entries in the level JSON. `RhythmMap.get_bpm_at_beat()` handles interpolation. For the full pre-baked `Array[float]` required by `start_level_variable_bpm()`, GameManager reconstructs the array from the `bpm_changes` data at level load time, or loads a separately authored `.tres` resource if precision demands it.

### Example: reconstructing timestamps from bpm_changes

```gdscript
# In GameManager, after RhythmMap loads a variable-BPM level:
func _build_beat_timestamps(rhythm_map: RhythmMap, total_beats: int) -> Array[float]:
    var timestamps: Array[float] = []
    var t: float = 0.0
    for i: int in range(total_beats):
        timestamps.append(t)
        var bpm: float = rhythm_map.get_bpm_at_beat(float(i))
        t += 60.0 / bpm
    return timestamps
```

This is accurate to within the granularity of the `bpm_changes` control points. For the official Zone 5 tracks, the designer provides densely-spaced control points so the interpolated curve closely matches the DAW automation.

---

## Cross-System EventBus Conventions

BeatConductor emits directly. Downstream systems (ScoreManager, HUD, AudioSFX) should listen through EventBus rather than connecting directly to BeatConductor where possible, to keep dependencies unidirectional. Suggested EventBus signals to declare in `EventBus.gd`:

```gdscript
# EventBus.gd (autoload)
signal timing_result_received(result: TimingJudge.TimingResult, offset_ms: float)
signal combo_milestone_reached(count: int)
signal combo_broken()
signal level_beat_fired(beat_index: int)   # re-emits BeatConductor.beat_fired for UI systems
signal level_bar_changed(bar_number: int)  # re-emits BeatConductor.bar_changed
```

GameManager is the single connector between BeatConductor/TimingJudge and EventBus, keeping the rhythm scripts dependency-free of any game systems other than each other.
