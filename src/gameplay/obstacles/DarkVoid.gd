extends Node2D

class_name DarkVoid

var _duration_beats: int = 4
var _pulse_with_beat: bool = true
var _entry_beat: float = 0.0
var _active: bool = false
var _beats_elapsed: int = 0

@onready var _overlay: CanvasLayer = $DarkCanvas


func _ready() -> void:
	add_to_group("scrolling")
	if _overlay:
		_overlay.visible = false
	BeatConductor.beat_fired.connect(_on_beat_fired)


func setup(entry: Dictionary) -> void:
	_entry_beat = float(entry.get("beat_index", 0))
	var p: Dictionary = entry.get("parameters", {}) as Dictionary
	_duration_beats = int(p.get("duration_beats", 4))
	_pulse_with_beat = bool(p.get("pulse_with_beat", true))


func _process(_delta: float) -> void:
	pass


func _on_beat_fired(beat_idx: int) -> void:
	if not _active:
		if float(beat_idx) >= _entry_beat:
			_active = true
			_beats_elapsed = 0
			if _overlay:
				_overlay.visible = true
				if Accessibility.reduced_motion():
					(_overlay.get_node("Overlay") as ColorRect).color = Color(0.0, 0.0, 0.0, 0.35)
		return

	_beats_elapsed += 1
	if _pulse_with_beat and _overlay:
		var rect: ColorRect = _overlay.get_node("Overlay") as ColorRect
		if rect:
			rect.modulate.a = 0.9

	if _beats_elapsed >= _duration_beats:
		if _overlay:
			_overlay.visible = false
		_active = false
		BeatConductor.beat_fired.disconnect(_on_beat_fired)
		queue_free()
