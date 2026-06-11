## CoPilotController — manages Player B in Co-Pilot mode.
## Player B activates powers (tap right half of screen / second gamepad).
## Tracks P2 contributions separately; credited to _profile_b in SaveSystem at run end.
extends Node

class_name CoPilotController

var _profile_b: String = ""
var _resonance: Node = null
var _p2_power_activations: int = 0


func setup(profile_b: String, resonance: Node) -> void:
	_profile_b = profile_b
	_resonance = resonance


## Call when P2 triggers their power input. Routes to ResonanceController.fire().
func trigger_power() -> void:
	_p2_power_activations += 1
	if _resonance != null and _resonance.has_method("fire"):
		_resonance.fire()


func get_profile_b() -> String:
	return _profile_b


## Returns contribution stats for the results screen.
func get_contribution() -> Dictionary:
	return {"power_activations": _p2_power_activations}


func reset_contribution() -> void:
	_p2_power_activations = 0
