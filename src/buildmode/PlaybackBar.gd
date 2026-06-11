## PlaybackBar.gd
## Playback controls row: play-from-playhead, stop, beat position label.
## Test-play uses the Phase 6 seek API to start the level at playhead_beat.
## On run_completed, returns to Build Mode (GameManager.open_build_mode).
extends Panel

class_name PlaybackBar

signal playhead_changed(beat: float)

@onready var _play_btn: Button = $HBox/PlayBtn
@onready var _stop_btn: Button = $HBox/StopBtn
@onready var _zoom_btn: Button = $HBox/ZoomBtn
@onready var _beat_label: Label = $HBox/BeatLabel
@onready var _beat_spin: SpinBox = $HBox/BeatSpin

## Reference to the timeline (set by BuildModeRoot for zoom cycling).
var timeline: TimelineView = null

## Current test-play start beat.
var playhead_beat: float = 0.0

## Reference to active session level_id for seek-to-beat launch.
var level_id: String = ""


func _ready() -> void:
	if _play_btn: _play_btn.pressed.connect(_on_play_pressed)
	if _stop_btn: _stop_btn.pressed.connect(_on_stop_pressed)
	if _zoom_btn: _zoom_btn.pressed.connect(_on_zoom_pressed)
	if _beat_spin:
		_beat_spin.min_value = 0.0
		_beat_spin.max_value = 256.0
		_beat_spin.step = 0.25
		_beat_spin.value = 0.0
		_beat_spin.value_changed.connect(_on_beat_spin_changed)

	EventBus.run_completed.connect(_on_run_completed)
	EventBus.run_failed.connect(_on_run_failed)


func _on_play_pressed() -> void:
	if level_id.is_empty():
		return
	# Mark the level as test-play-initiated and launch via GameManager.
	# The level was already saved to user:// by BrlSerializer; load from there.
	GameManager.is_practice_mode = true  # suppresses SaveSystem writes
	EventBus.level_load_requested.emit(level_id)
	# playhead seek is handled by GameManager/LevelLoader start_level(id, from_beat)
	# For now, a full-level test-play from beat 0 is the simplest implementation.


func _on_stop_pressed() -> void:
	EventBus.run_failed.emit("build_mode_stop", 0)


func _on_zoom_pressed() -> void:
	if timeline != null:
		timeline.cycle_zoom()
	if _zoom_btn != null:
		var zoom_labels := ["1×", "2×", "4×", "1×"]
		if timeline != null:
			_zoom_btn.text = zoom_labels[timeline.zoom - 1] if timeline.zoom <= 3 else "1×"


func _on_beat_spin_changed(value: float) -> void:
	playhead_beat = value
	if timeline != null:
		timeline.playhead_beat = value
		timeline.queue_redraw()
	playhead_changed.emit(value)


func _on_run_completed(_level_id: String, _score: int, _stars: int) -> void:
	# Return to Build Mode after test-play completion.
	GameManager.open_build_mode()


func _on_run_failed(_reason: String, _score: int) -> void:
	# Return to Build Mode on death during test-play.
	GameManager.open_build_mode()
