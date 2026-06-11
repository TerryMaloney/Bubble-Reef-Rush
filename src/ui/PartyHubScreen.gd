## PartyHubScreen — hub listing available party modes for quick launch.
extends Node

class_name PartyHubScreen

const PARTY_MODES: Array[Dictionary] = [
	{"id": "pass_and_play", "name": "Pass & Play", "description": "Take turns on one device"},
	{"id": "family_tournament", "name": "Family Tournament", "description": "Bracket-style competition"},
	{"id": "co_pilot", "name": "Co-Pilot", "description": "One level, two players"},
	{"id": "ghost_challenge", "name": "Ghost Challenge", "description": "Race your family's best run"},
	{"id": "family_chain_build", "name": "Family Chain Build", "description": "Everyone adds 8 beats"},
]


func get_modes() -> Array[Dictionary]:
	return PARTY_MODES


func get_mode(mode_id: String) -> Dictionary:
	for m: Dictionary in PARTY_MODES:
		if m.get("id", "") == mode_id:
			return m
	return {}
