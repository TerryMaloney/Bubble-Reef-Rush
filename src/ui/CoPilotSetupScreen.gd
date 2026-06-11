## CoPilotSetupScreen — lets two players choose profiles and launch Co-Pilot mode.
## Player A controls movement; Player B activates powers from the right screen half.
extends Node

class_name CoPilotSetupScreen


func start_copilot(profile_a: String, profile_b: String, level_id: String) -> void:
	GameManager.copilot_profile_b = profile_b
	GameManager.start_level(level_id)
	_ = profile_a  # profile_a is already set as the active profile
