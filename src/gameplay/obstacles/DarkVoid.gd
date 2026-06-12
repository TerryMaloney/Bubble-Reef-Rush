extends Node2D

class_name DarkVoid

var _duration_beats: int = 4
var _pulse_with_beat: bool = true
var _entry_beat: float = 0.0
var _active: bool = false
var _beats_elapsed: int = 0
var _fade_tween: Tween = null

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
	EventBus.hazard_warning.emit("DARKNESS FALLS")


func _process(_delta: float) -> void:
	pass


func _on_beat_fired(beat_idx: int) -> void:
	if not _active:
		if float(beat_idx) >= _entry_beat:
			_active = true
			_beats_elapsed = 0
			if _overlay:
				_overlay.visible = true
				var rect: ColorRect = _overlay.get_node("Overlay") as ColorRect
				if Accessibility.reduced_motion():
					if rect:
						rect.color = Color(0.0, 0.0, 0.0, 0.35)
				else:
					if rect:
						rect.modulate.a = 0.0
						_fade_tween = create_tween()
						_fade_tween.tween_property(rect, "modulate:a", 1.0, 0.5)
						_fade_tween.tween_callback(func() -> void: _fade_tween = null)
		return

	_beats_elapsed += 1
	if _pulse_with_beat and _overlay and _fade_tween == null:
		var rect: ColorRect = _overlay.get_node("Overlay") as ColorRect
		if rect:
			rect.modulate.a = 0.9

	if _beats_elapsed >= _duration_beats:
		if _overlay:
			_overlay.visible = false
		_active = false
		BeatConductor.beat_fired.disconnect(_on_beat_fired)
		queue_free()
