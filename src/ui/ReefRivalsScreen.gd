## ReefRivalsScreen — hub for competitive/social features.
## Entry point: Reef Rivals button in MainMenu.
extends Control

class_name ReefRivalsScreen

const PASS_PLAY_SETUP_SCENE: String = "res://scenes/ui/PassPlaySetupScreen.tscn"
const IMPORT_SCENE: String = "res://scenes/ui/ChallengeImportScreen.tscn"

@onready var _pass_play_btn: Button = $Panel/VBox/PassPlayButton
@onready var _ghost_btn: Button = $Panel/VBox/GhostChallengeButton
@onready var _import_btn: Button = $Panel/VBox/ImportChallengeButton
@onready var _close_btn: Button = $Panel/VBox/CloseButton


func _ready() -> void:
	_pass_play_btn.pressed.connect(_on_pass_play)
	_ghost_btn.pressed.connect(_on_ghost_challenge)
	_import_btn.pressed.connect(_on_import)
	_close_btn.pressed.connect(func() -> void: queue_free())


func _on_pass_play() -> void:
	_open_child_screen(PASS_PLAY_SETUP_SCENE)


func _on_ghost_challenge() -> void:
	# Launch level select with ghost mode set to "family_champion".
	GameManager.show_ghost = "family_champion"
	GameManager.go_to_level_select("z1")
	queue_free()


func _on_import() -> void:
	_open_child_screen(IMPORT_SCENE)


## Opens a sub-screen and hides this hub; closing the sub-screen (queue_free /
## Back) re-shows the hub so Back never lands on a bare MainMenu.
func _open_child_screen(scene_path: String) -> void:
	var screen: Control = (load(scene_path) as PackedScene).instantiate() as Control
	get_parent().add_child(screen)
	hide()
	screen.tree_exited.connect(show)
