extends Control

class_name ResultsScreen


func _ready() -> void:
	$MenuButton.pressed.connect(_on_menu_pressed)


func _on_menu_pressed() -> void:
	GameManager.go_to_menu()
