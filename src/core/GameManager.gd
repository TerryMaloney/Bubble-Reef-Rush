# Autoload scene state machine — owns scene transitions, retry logic, and level lifecycle.
extends Node


enum State { MENU, LOADING, PLAYING, PAUSED, RESULTS, BUILD_MODE }

const MAIN_MENU_SCENE: String = "res://scenes/gameplay/MainMenu.tscn"
const LEVEL_ROOT_SCENE: String = "res://scenes/gameplay/LevelRoot.tscn"
const RESULTS_SCENE: String = "res://scenes/gameplay/ResultsScreen.tscn"
const BUILD_MODE_SCENE: String = "res://scenes/buildmode/BuildModeRoot.tscn"

var current_state: State = State.MENU
var current_level_id: String = ""

## Consecutive deaths on the current level, carried across instant-retries so
## the DifficultyDirector can ease a level a player is stuck on. Reset when a
## fresh level is chosen from the menu, or when the level is completed.
var consecutive_deaths: int = 0

## Stored at level completion so ResultsScreen can read them without a signal.
var last_score: int = 0
var last_stars: int = 0

var _active_profile: String = ""


func _ready() -> void:
	EventBus.run_failed.connect(_on_run_failed)
	EventBus.run_completed.connect(_on_run_completed)
	EventBus.retry_requested.connect(retry_level)
	EventBus.level_load_requested.connect(start_level)
	_active_profile = SaveSystem.get_active_profile_id()


func start_level(level_id: String) -> void:
	current_state = State.LOADING
	current_level_id = level_id
	# A deliberately-chosen level starts fresh — clear the carried-death assist.
	consecutive_deaths = 0
	get_tree().change_scene_to_file(LEVEL_ROOT_SCENE)


func retry_level() -> void:
	get_tree().change_scene_to_file(LEVEL_ROOT_SCENE)


func go_to_menu() -> void:
	current_state = State.MENU
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func finish_level(score: int, stars: int) -> void:
	last_score = score
	last_stars = stars
	current_state = State.RESULTS
	_active_profile = SaveSystem.get_active_profile_id()
	SaveSystem.update_level_result(_active_profile, current_level_id, score, stars)
	get_tree().change_scene_to_file(RESULTS_SCENE)


func open_build_mode() -> void:
	current_state = State.BUILD_MODE
	get_tree().change_scene_to_file(BUILD_MODE_SCENE)


func _on_run_failed(_level_id: String, _score: int) -> void:
	# RetryController handles the prompt; GameManager just records state.
	current_state = State.PLAYING
	consecutive_deaths += 1


func _on_run_completed(level_id: String, score: int, stars: int) -> void:
	consecutive_deaths = 0
	finish_level(score, stars)
