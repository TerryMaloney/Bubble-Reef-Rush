extends Control

class_name MainMenu


func _ready() -> void:
	$Layout/PlayButton.pressed.connect(_on_play_pressed)


func _on_play_pressed() -> void:
	EventBus.level_load_requested.emit("z1-l1")
