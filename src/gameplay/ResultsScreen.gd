extends Control

class_name ResultsScreen


func _ready() -> void:
	var score: int = GameManager.last_score
	var stars: int = GameManager.last_stars

	$ScoreLabel.text = "Score: %d" % score
	$StarsLabel.text = _stars_text(stars)

	$RetryButton.pressed.connect(_on_retry_pressed)
	$LevelsButton.pressed.connect(_on_levels_pressed)
	$MenuButton.pressed.connect(_on_menu_pressed)


func _stars_text(stars: int) -> String:
	match stars:
		3: return "* * *"
		2: return "* *"
		1: return "*"
		_: return "- - -"


func _on_retry_pressed() -> void:
	GameManager.start_level(GameManager.current_level_id)


func _on_levels_pressed() -> void:
	var zone_id: String = GameManager.current_level_id.split("-")[0]
	GameManager.go_to_level_select(zone_id)


func _on_menu_pressed() -> void:
	GameManager.go_to_menu()
