## BeatConductor.gd
## Master rhythm clock for Bubble Reef Rush.
## Autoload singleton — register as "BeatConductor" in Project > Project Settings > Autoload.
##
## Synchronises the beat grid to AudioServer's low-latency clock so that obstacle
## spawning, visual pulses, and timing judgement all share the same timeline.
## Supports fixed-BPM zones (Z1-Z4, Z6) and the pre-baked beat-map required by
## Zone 5's variable-BPM audio track.

extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Fired on every quarter beat. beat_index counts from 0 at level start.
signal beat_fired(beat_index: int)

## Fired on every eighth beat (halfway between quarter beats).
## beat_index is a .5 decimal, e.g. 0.5, 1.5, 2.5 …
signal half_beat_fired(beat_index: float)

## Fired whenever the bar number advances (every 4 beats).
## bar_number counts from 1.
signal bar_changed(bar_number: int)

## Fired when the conductor begins playing.
signal conductor_started

## Fired when the conductor stops (level end, stop_level call, or pause).
signal conductor_stopped

# ---------------------------------------------------------------------------
# Exported settings
# ---------------------------------------------------------------------------

## Player-adjustable latency correction in milliseconds.
## Positive = player hears music later than the raw clock suggests (most phones).
## Range: −200 ms … +200 ms. Persisted in user save data and applied here.
@export var user_latency_offset_ms: float = 0.0

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

## BPM used for fixed-BPM levels.
var _current_bpm: float = 110.0

## Seconds per quarter beat at the current BPM.
var _beat_duration_sec: float = 0.0

## AudioServer-relative timestamp when the next quarter beat is due.
var _next_beat_time_sec: float = 0.0

## AudioServer-relative timestamp when the next half-beat is due.
var _next_half_beat_time_sec: float = 0.0

## Running quarter-beat index (0-based, increments on every beat_fired).
var _beat_index: int = 0

## Running bar number (1-based, increments every 4 beats).
var _bar_number: int = 0

## AudioServer time captured at level start (used as the level epoch).
var _level_start_time_sec: float = 0.0

## True between start_level and stop_level.
var _running: bool = false

## True when the level is paused (app background).
var _paused: bool = false

## True when Zone 5 variable-BPM mode is active.
var _variable_bpm_mode: bool = false

## When no audio stream is present, fall back to wall-clock timing.
var _use_wall_clock: bool = false
var _wall_clock_start_msec: int = 0

## Pre-baked beat timestamps for Zone 5.
## Each element is a float: the playback-position (in seconds from track start)
## at which that beat index occurs. Index 0 → beat 0 timestamp, etc.
var _beat_map_timestamps: Array[float] = []

## Current index into _beat_map_timestamps used during variable-BPM playback.
var _vbpm_next_beat_map_idx: int = 0

## AudioStreamPlayer that owns the current level's music.
var _music_player: AudioStreamPlayer = null

# ---------------------------------------------------------------------------
# Node lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Create the music player as a child so it lives with this autoload.
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)


func _process(_delta: float) -> void:
	if not _running or _paused:
		return

	var now: float = _get_corrected_time()

	# Handle variable-BPM (Zone 5) path.
	if _variable_bpm_mode:
		_process_variable_bpm(now)
		return

	# Fixed-BPM path: fire as many beats as have elapsed since last frame.
	while now >= _next_beat_time_sec:
		_fire_beat()
		_next_beat_time_sec += _beat_duration_sec
		# Advance half-beat cursor to sit halfway to the next beat.
		_next_half_beat_time_sec = _next_beat_time_sec - (_beat_duration_sec * 0.5)

	# Fire half-beat when its time arrives.
	if now >= _next_half_beat_time_sec and _next_half_beat_time_sec > 0.0:
		half_beat_fired.emit(float(_beat_index) - 0.5)
		# Disarm until the next beat fires and resets this.
		_next_half_beat_time_sec = _next_beat_time_sec + (_beat_duration_sec * 0.5)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Start a fixed-BPM level.
## bpm: the level's BPM (from level metadata).
## music_stream: the AudioStream resource to play (null = headless/wall-clock mode).
## from_beat: optional seek point; 0.0 = level start, 16.0 = checkpoint mid-level.
## For Zone 5 variable-BPM, call start_level_variable_bpm() instead.
func start_level(bpm: float, music_stream: AudioStream, from_beat: float = 0.0) -> void:
	_stop_internal()

	_current_bpm = bpm
	_beat_duration_sec = 60.0 / bpm
	_variable_bpm_mode = false
	_beat_map_timestamps.clear()

	var seek_sec: float = from_beat * _beat_duration_sec
	if music_stream != null:
		_music_player.stream = music_stream
		_music_player.play(seek_sec)
		_use_wall_clock = false
		_wall_clock_start_msec = 0
	else:
		_use_wall_clock = true
		# Offset wall clock so _get_corrected_time() returns seek_sec immediately.
		_wall_clock_start_msec = Time.get_ticks_msec() - int(seek_sec * 1000.0)

	var now: float = _get_corrected_time()
	# Anchor epoch so get_current_beat_position() returns from_beat right after start.
	_level_start_time_sec = now - seek_sec
	_beat_index = int(from_beat)
	_bar_number = _beat_index / 4
	var frac: float = fmod(from_beat, 1.0)
	_next_beat_time_sec = now + (1.0 - frac) * _beat_duration_sec
	_next_half_beat_time_sec = now + ((0.5 - frac) if frac < 0.5 else (1.5 - frac)) * _beat_duration_sec
	_running = true
	_paused = false

	conductor_started.emit()


## Start a variable-BPM level (Zone 5).
## music_stream: the full Zone 5 audio track (null = headless/wall-clock mode).
## beat_timestamps: array of playback-position floats (seconds from track start),
##   one entry per beat, in ascending order.
## from_beat: optional seek point (integer beats only for vbpm).
func start_level_variable_bpm(music_stream: AudioStream, beat_timestamps: Array[float], from_beat: float = 0.0) -> void:
	_stop_internal()

	_variable_bpm_mode = true
	_beat_map_timestamps = beat_timestamps.duplicate()
	_vbpm_next_beat_map_idx = maxi(0, int(from_beat))

	var seek_sec: float = 0.0
	if _vbpm_next_beat_map_idx < _beat_map_timestamps.size():
		seek_sec = _beat_map_timestamps[_vbpm_next_beat_map_idx]

	if music_stream != null:
		_music_player.stream = music_stream
		_music_player.play(seek_sec)
		_use_wall_clock = false
		_wall_clock_start_msec = 0
	else:
		_use_wall_clock = true
		_wall_clock_start_msec = Time.get_ticks_msec() - int(seek_sec * 1000.0)

	var now: float = _get_corrected_time()
	_level_start_time_sec = now - seek_sec
	_beat_index = int(from_beat)
	_bar_number = _beat_index / 4
	_running = true
	_paused = false

	conductor_started.emit()


## Stop the current level cleanly.
func stop_level() -> void:
	_stop_internal()
	conductor_stopped.emit()


## Returns elapsed milliseconds since level start, corrected for output latency
## and the user's personal latency offset. Use this when comparing input
## timestamps in TimingJudge.
func get_current_beat_time_ms() -> float:
	if not _running:
		return 0.0
	return (_get_corrected_time() - _level_start_time_sec) * 1000.0


## Returns the current beat index as a float (includes fractional progress
## toward the next beat), useful for ObstacleSpawner lookahead calculations.
func get_current_beat_position() -> float:
	if not _running:
		return 0.0
	if _variable_bpm_mode:
		return _get_vbpm_beat_position()
	var elapsed_sec: float = _get_corrected_time() - _level_start_time_sec
	return elapsed_sec / _beat_duration_sec


## Returns the BPM at a given beat index for the active level.
## For fixed-BPM levels this is always _current_bpm.
## For variable-BPM levels, interpolates between the two surrounding timestamps.
func get_bpm_at_beat(beat_index: float) -> float:
	if not _variable_bpm_mode or _beat_map_timestamps.size() < 2:
		return _current_bpm
	var idx: int = int(beat_index)
	idx = clampi(idx, 0, _beat_map_timestamps.size() - 2)
	var dt: float = _beat_map_timestamps[idx + 1] - _beat_map_timestamps[idx]
	if dt <= 0.0:
		return _current_bpm
	return 60.0 / dt


## Pause or resume the conductor from gameplay (e.g. pause menu).
## Unlike the app-lifecycle notification path, this is called explicitly by
## PauseMenu so the in-game pause button and Esc key work correctly.
func set_paused(paused: bool) -> void:
	if not _running:
		return
	if paused == _paused:
		return
	_paused = paused
	if _paused:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
		_music_player.stream_paused = true
		conductor_stopped.emit()
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
		_music_player.stream_paused = false
		resync_to_playback_position()
		conductor_started.emit()


## Resync the beat clock to the current audio playback position.
## Call this after app resume (NOTIFICATION_APPLICATION_RESUMED) to avoid a
## wall of catch-up beats when the clock was frozen during backgrounding.
func resync_to_playback_position() -> void:
	if not _running:
		return

	if _variable_bpm_mode:
		_resync_variable_bpm()
		return

	var pos_sec: float = _music_player.get_playback_position()
	var beats_elapsed: float = pos_sec / _beat_duration_sec
	_beat_index = int(beats_elapsed)
	var fractional: float = beats_elapsed - float(_beat_index)
	var now: float = _get_corrected_time()
	_next_beat_time_sec = now + ((1.0 - fractional) * _beat_duration_sec)
	_next_half_beat_time_sec = _next_beat_time_sec - (_beat_duration_sec * 0.5)
	_bar_number = _beat_index / 4

# ---------------------------------------------------------------------------
# App lifecycle notifications
# ---------------------------------------------------------------------------

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			if _running:
				_paused = true
				AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
				_music_player.stream_paused = true
				conductor_stopped.emit()

		NOTIFICATION_APPLICATION_RESUMED:
			if _running and _paused:
				AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
				_music_player.stream_paused = false
				_paused = false
				resync_to_playback_position()
				conductor_started.emit()

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Returns the AudioServer's latency-compensated "now" in seconds, plus the
## user's personal offset. This is the single source of truth for all timing
## comparisons in the rhythm system.
func _get_corrected_time() -> float:
	if _use_wall_clock:
		var elapsed: float = float(Time.get_ticks_msec() - _wall_clock_start_msec) / 1000.0
		return elapsed + (user_latency_offset_ms / 1000.0)
	var raw: float = _music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return raw + (user_latency_offset_ms / 1000.0)


## Advance one quarter beat: emit beat_fired, update bar if needed.
func _fire_beat() -> void:
	beat_fired.emit(_beat_index)

	var new_bar: int = (_beat_index / 4) + 1
	if new_bar != _bar_number:
		_bar_number = new_bar
		bar_changed.emit(_bar_number)

	_beat_index += 1


## Variable-BPM processing: compare music playback position against
## pre-baked timestamps rather than a fixed interval.
func _process_variable_bpm(now: float) -> void:
	if _beat_map_timestamps.is_empty():
		return

	var playback_pos: float
	if _use_wall_clock:
		playback_pos = now - _level_start_time_sec
	else:
		playback_pos = _music_player.get_playback_position()

	# Fire all beats whose timestamp has been passed since last frame.
	while _vbpm_next_beat_map_idx < _beat_map_timestamps.size():
		var beat_ts: float = _beat_map_timestamps[_vbpm_next_beat_map_idx]
		if playback_pos < beat_ts:
			break
		_fire_beat()

		# Emit half-beat between this beat and the next, if there is a next.
		if _vbpm_next_beat_map_idx + 1 < _beat_map_timestamps.size():
			var next_ts: float = _beat_map_timestamps[_vbpm_next_beat_map_idx + 1]
			var half_ts: float = beat_ts + (next_ts - beat_ts) * 0.5
			# Schedule a deferred half-beat using a timer so it fires mid-interval.
			var timer_duration: float = maxf(0.001, half_ts - playback_pos)
			var timer: SceneTreeTimer = get_tree().create_timer(timer_duration)
			var captured_index: int = _beat_index - 1  # beat just fired
			timer.timeout.connect(
				func() -> void:
					if _running and not _paused:
						half_beat_fired.emit(float(captured_index) + 0.5)
			)

		_vbpm_next_beat_map_idx += 1


## Compute fractional beat position for variable-BPM mode.
func _get_vbpm_beat_position() -> float:
	if _beat_map_timestamps.is_empty():
		return 0.0
	var pos: float
	if _use_wall_clock:
		pos = _get_corrected_time() - _level_start_time_sec
	else:
		pos = _music_player.get_playback_position()
	var idx: int = _vbpm_next_beat_map_idx
	if idx == 0:
		return 0.0
	if idx >= _beat_map_timestamps.size():
		return float(_beat_map_timestamps.size() - 1)
	var prev_ts: float = _beat_map_timestamps[idx - 1]
	var next_ts: float = _beat_map_timestamps[idx]
	if next_ts <= prev_ts:
		return float(idx - 1)
	var frac: float = (pos - prev_ts) / (next_ts - prev_ts)
	return float(idx - 1) + clampf(frac, 0.0, 1.0)


## Resync beat cursor for variable-BPM after app resume.
func _resync_variable_bpm() -> void:
	var pos: float
	if _use_wall_clock:
		pos = _get_corrected_time() - _level_start_time_sec
	else:
		pos = _music_player.get_playback_position()
	_vbpm_next_beat_map_idx = 0
	for i: int in range(_beat_map_timestamps.size()):
		if _beat_map_timestamps[i] <= pos:
			_vbpm_next_beat_map_idx = i + 1
		else:
			break
	_beat_index = _vbpm_next_beat_map_idx
	_bar_number = _beat_index / 4


## Shared teardown used by both stop_level and start_level (restart).
func _stop_internal() -> void:
	_running = false
	_paused = false
	if _music_player != null and _music_player.playing:
		_music_player.stop()
	_beat_index = 0
	_bar_number = 0
	_next_beat_time_sec = 0.0
	_next_half_beat_time_sec = 0.0
	_vbpm_next_beat_map_idx = 0
	_beat_map_timestamps.clear()
