## BackgroundController — scene-local node that tints the background per zone
## and pulses it on every beat. Gated by Accessibility.reduced_motion().
extends Node

class_name BackgroundController

const ZONE_COLORS: Dictionary = {
	1: Color(0.04, 0.24, 0.52),   # Sunlit Shallows — mid ocean blue
	2: Color(0.05, 0.30, 0.26),   # Kelp Forest — teal green
	3: Color(0.18, 0.18, 0.35),   # Shipwreck Alley — deep navy
	4: Color(0.32, 0.10, 0.06),   # Volcanic Vent — dark red-brown
	5: Color(0.03, 0.08, 0.25),   # Twilight Trench — near-black blue
	6: Color(0.14, 0.28, 0.42),   # Crystal Caves — pale crystalline blue
}
const PULSE_BRIGHTNESS: float = 0.10
const PULSE_DECAY: float = 8.0

var _background: ColorRect = null
var _base_color: Color = ZONE_COLORS[1]
var _pulse: float = 0.0


func setup(background: ColorRect) -> void:
	_background = background
	_base_color = ZONE_COLORS[1]
	if _background != null:
		_background.color = _base_color
	BeatConductor.beat_fired.connect(_on_beat_fired)
	EventBus.run_started.connect(_on_run_started)


func _on_run_started(level_id: String) -> void:
	# Parse zone from "z{N}-l{M}" level ids.
	var zone: int = 1
	if level_id.begins_with("z") and level_id.contains("-"):
		var z_str: String = level_id.substr(1, level_id.find("-") - 1)
		if z_str.is_valid_int():
			zone = int(z_str)
	_base_color = ZONE_COLORS.get(zone, ZONE_COLORS[1])
	if _background != null:
		_background.color = _base_color


func _process(delta: float) -> void:
	if _background == null:
		return
	_pulse = maxf(0.0, _pulse - PULSE_DECAY * delta)
	if not Accessibility.reduced_motion():
		_background.color = _base_color.lightened(_pulse * PULSE_BRIGHTNESS)
	else:
		_background.color = _base_color


func _on_beat_fired(_beat_index: int) -> void:
	if not Accessibility.reduced_motion():
		_pulse = 1.0
