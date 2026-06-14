## DifficultyModifier — applies Easy/Normal/Hard parameter tweaks to obstacle params.
##
## Normal uses authored values unchanged. Easy widens gaps and slows hazards;
## Hard narrows gaps and speeds them up. All clamping respects schema limits.
class_name DifficultyModifier
extends RefCounted

const MODES: Array[String] = ["easy", "normal", "hard"]

## Apply difficulty-based tweaks to a copy of `params` for the given obstacle_type.
## Returns the (possibly modified) params dict; never mutates the original.
static func apply(params: Dictionary, obstacle_type: String, difficulty: String) -> Dictionary:
	if difficulty == "normal":
		return params
	var out: Dictionary = params.duplicate()
	match obstacle_type:
		"pressure_wall":
			_tweak_float(out, "intensity", difficulty, 0.18, 1.0, -0.12, 0.12)
		"kelp_curtain":
			_tweak_float(out, "gap_height", difficulty, 120.0, 500.0, 60.0, -60.0)
		"eel_snap":
			_tweak_int(out, "dormant_beats", difficulty, 2, 8, 2, -2)
		"lava_burst":
			_tweak_int(out, "cycle_beats", difficulty, 2, 8, 2, -2)
		"current_jet":
			_tweak_int(out, "cycle_beats", difficulty, 2, 8, 2, -2)
		"anchor_chain":
			_tweak_float(out, "pendulum_frequency", difficulty, 0.2, 1.0, -0.1, 0.15)
	return out


static func _tweak_float(d: Dictionary, key: String, diff: String,
		lo: float, hi: float, easy_delta: float, hard_delta: float) -> void:
	if not d.has(key):
		return
	var v: float = float(d[key])
	v += easy_delta if diff == "easy" else hard_delta
	d[key] = clampf(v, lo, hi)


static func _tweak_int(d: Dictionary, key: String, diff: String,
		lo: int, hi: int, easy_delta: int, hard_delta: int) -> void:
	if not d.has(key):
		return
	var v: int = int(d[key])
	v += easy_delta if diff == "easy" else hard_delta
	d[key] = clampi(v, lo, hi)
