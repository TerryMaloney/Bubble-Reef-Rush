extends Control

class_name MainMenu


func _ready() -> void:
	$Layout/PlayButton.pressed.connect(_on_play_pressed)


func _on_play_pressed() -> void:
	GameManager.go_to_zone_select()
