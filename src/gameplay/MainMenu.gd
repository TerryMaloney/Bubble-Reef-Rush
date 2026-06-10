extends Control

class_name MainMenu


func _ready() -> void:
	$Layout/PlayButton.pressed.connect(_on_play_pressed)
	$Layout/SettingsButton.pressed.connect(_on_settings_pressed)


func _on_play_pressed() -> void:
	GameManager.go_to_zone_select()


func _on_settings_pressed() -> void:
	GameManager.go_to_settings(GameManager.MAIN_MENU_SCENE)
