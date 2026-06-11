## PartyHubScreen — hub listing available party modes for quick launch.
extends Control

class_name PartyHubScreen

const PARTY_MODES: Array[Dictionary] = [
	{"id": "pass_and_play", "name": "Pass & Play", "description": "Take turns on one device"},
	{"id": "family_tournament", "name": "Family Tournament", "description": "Bracket-style competition"},
	{"id": "co_pilot", "name": "Co-Pilot", "description": "One level, two players"},
	{"id": "ghost_challenge", "name": "Ghost Challenge", "description": "Race your family's best run"},
	{"id": "family_chain_build", "name": "Family Chain Build", "description": "Everyone adds 8 beats"},
]

const PASS_PLAY_SETUP_SCENE: String = "res://scenes/ui/PassPlaySetupScreen.tscn"
const COPILOT_SETUP_SCENE: String = "res://scenes/ui/CoPilotSetupScreen.tscn"


func _ready() -> void:
	$Panel/VBox/PassAndPlayButton.pressed.connect(_on_pass_and_play)
	$Panel/VBox/FamilyTournamentButton.pressed.connect(_on_family_tournament)
	$Panel/VBox/CoPilotButton.pressed.connect(_on_copilot)
	$Panel/VBox/GhostChallengeButton.pressed.connect(_on_ghost_challenge)
	$Panel/VBox/FamilyChainBuildButton.pressed.connect(_on_family_chain_build)
	$Panel/VBox/CloseButton.pressed.connect(func() -> void: queue_free())


func get_modes() -> Array[Dictionary]:
	return PARTY_MODES


func get_mode(mode_id: String) -> Dictionary:
	for m: Dictionary in PARTY_MODES:
		if m.get("id", "") == mode_id:
			return m
	return {}


func _on_pass_and_play() -> void:
	var screen: Control = load(PASS_PLAY_SETUP_SCENE).instantiate() as Control
	get_parent().add_child(screen)
	queue_free()


func _on_family_tournament() -> void:
	var screen: Control = load(PASS_PLAY_SETUP_SCENE).instantiate() as Control
	get_parent().add_child(screen)
	queue_free()


func _on_copilot() -> void:
	var screen: Control = load(COPILOT_SETUP_SCENE).instantiate() as Control
	get_parent().add_child(screen)
	queue_free()


func _on_ghost_challenge() -> void:
	GameManager.show_ghost = "family_champion"
	GameManager.go_to_zone_select()
	queue_free()


func _on_family_chain_build() -> void:
	GameManager.open_build_mode()
	queue_free()
