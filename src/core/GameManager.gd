# Autoload scene state machine — owns scene transitions, retry logic, and level lifecycle.
extends Node


enum State { MENU, LOADING, PLAYING, PAUSED, RESULTS, BUILD_MODE }

const MAIN_MENU_SCENE: String = "res://scenes/gameplay/MainMenu.tscn"
const LEVEL_ROOT_SCENE: String = "res://scenes/gameplay/LevelRoot.tscn"
const RESULTS_SCENE: String = "res://scenes/gameplay/ResultsScreen.tscn"
const BUILD_MODE_SCENE: String = "res://scenes/buildmode/BuildModeRoot.tscn"
const ZONE_SELECT_SCENE: String = "res://scenes/gameplay/ZoneSelect.tscn"
const LEVEL_SELECT_SCENE: String = "res://scenes/gameplay/LevelSelect.tscn"
const SETTINGS_SCENE: String = "res://scenes/gameplay/SettingsScreen.tscn"
const PASS_PLAY_SCOREBOARD_SCENE: String = "res://scenes/ui/PassPlayScoreboardScreen.tscn"
const PASS_PLAY_NEXT_PLAYER_SCENE: String = "res://scenes/ui/PassPlayNextPlayerScreen.tscn"

var current_state: State = State.MENU
var current_level_id: String = ""
var current_zone_id: String = ""

## Consecutive deaths on the current level, carried across instant-retries so
## the DifficultyDirector can ease a level a player is stuck on. Reset when a
## fresh level is chosen from the menu, or when the level is completed.
var consecutive_deaths: int = 0

## Stored at level completion so ResultsScreen can read them without a signal.
var last_score: int = 0
var last_stars: int = 0
## Personal best score from BEFORE this run, so ResultsScreen can show "New Best!".
var last_prev_best_score: int = 0

var _active_profile: String = ""
## Latest progress percentage emitted during the current run, used by run_failed handler.
var _last_progress_pct: float = 0.0
## Scene to return to after closing SettingsScreen.
var _settings_return_scene: String = MAIN_MENU_SCENE

## Set true by LevelSelect when launching a practice run.
## Suppresses SaveSystem writes and auto-retry; PracticeController handles respawn.
var is_practice_mode: bool = false
## Ghost type to show during a run: "" = none, "personal_best", "family_champion", "imported"
var show_ghost: String = ""
## Co-Pilot mode: profile ID of Player B; "" = disabled.
var copilot_profile_b: String = ""

## Pass & Play — active session; null when not in P&P mode.
var active_pass_play_session: PassPlaySession = null
## Passed to PassPlayScoreboardScreen via its _ready() so TransitionLayer can load it.
var pending_pass_play_session: PassPlaySession = null
## Previous player info shown on PassPlayNextPlayerScreen.
var pp_prev_profile: String = ""
var pp_prev_score: int = 0

## Playlist (Daily Dive / Radio Shuffle) — levels queued after start_playlist().
var playlist: Array[String] = []
var playlist_index: int = 0


func _ready() -> void:
	EventBus.run_failed.connect(_on_run_failed)
	EventBus.run_completed.connect(_on_run_completed)
	EventBus.run_progress.connect(_on_run_progress)
	EventBus.retry_requested.connect(retry_level)
	EventBus.level_load_requested.connect(start_level)
	_active_profile = SaveSystem.get_active_profile_id()


func start_level(level_id: String) -> void:
	current_state = State.LOADING
	current_level_id = level_id
	_last_progress_pct = 0.0
	consecutive_deaths = 0
	TransitionLayer.go_to(LEVEL_ROOT_SCENE)


func retry_level() -> void:
	TransitionLayer.go_to(LEVEL_ROOT_SCENE)


func go_to_menu() -> void:
	current_state = State.MENU
	TransitionLayer.go_to(MAIN_MENU_SCENE)


## Coins earned this run — stored so ResultsScreen can show the reward breakdown.
var last_coins_earned: int = 0

func finish_level(score: int, stars: int) -> void:
	last_score = score
	last_stars = stars
	current_state = State.RESULTS
	_active_profile = SaveSystem.get_active_profile_id()
	var prev_results: Dictionary = SaveSystem.get_all_level_results(_active_profile)
	last_prev_best_score = int((prev_results.get(current_level_id, {}) as Dictionary).get("best_score", 0))
	# Economy grants BEFORE update so improvement check sees previous best score.
	last_coins_earned = EconomyService.process_run_completed(current_level_id, score, stars)
	SaveSystem.update_level_result(_active_profile, current_level_id, score, stars)
	# Evaluate achievements AFTER update so level results are current.
	AchievementSystem.evaluate_run(_active_profile, current_level_id, score, stars)
	TransitionLayer.go_to(RESULTS_SCENE)


func go_to_zone_select() -> void:
	current_state = State.MENU
	TransitionLayer.go_to(ZONE_SELECT_SCENE)


func go_to_level_select(zone_id: String) -> void:
	current_zone_id = zone_id
	current_state = State.MENU
	TransitionLayer.go_to(LEVEL_SELECT_SCENE)


func open_build_mode() -> void:
	current_state = State.BUILD_MODE
	TransitionLayer.go_to(BUILD_MODE_SCENE)


func go_to_settings(return_scene: String = MAIN_MENU_SCENE) -> void:
	_settings_return_scene = return_scene
	TransitionLayer.go_to(SETTINGS_SCENE)


func return_from_settings() -> void:
	TransitionLayer.go_to(_settings_return_scene)


func start_pass_play(session: PassPlaySession) -> void:
	active_pass_play_session = session
	pp_prev_profile = ""
	pp_prev_score = 0
	start_level(session.level_id)


func start_playlist(levels: Array[String]) -> void:
	playlist = levels.duplicate()
	playlist_index = 0
	if not playlist.is_empty():
		start_level(playlist[0])


func _on_run_progress(_level_id: String, pct: float) -> void:
	_last_progress_pct = pct


func _on_run_failed(level_id: String, _score: int) -> void:
	if is_practice_mode:
		return  # PracticeController handles respawn; no death/progress tracking
	# RetryController handles the prompt; GameManager just records state.
	current_state = State.PLAYING
	consecutive_deaths += 1
	_active_profile = SaveSystem.get_active_profile_id()
	SaveSystem.record_attempt(_active_profile, level_id)
	SaveSystem.record_progress_pct(_active_profile, level_id, _last_progress_pct)


func _on_run_completed(level_id: String, score: int, stars: int) -> void:
	consecutive_deaths = 0
	_active_profile = SaveSystem.get_active_profile_id()
	SaveSystem.record_attempt(_active_profile, level_id)

	# Pass & Play: route the score to the session, then advance turn.
	if active_pass_play_session != null and active_pass_play_session.is_active():
		pp_prev_profile = _active_profile
		pp_prev_score = score
		active_pass_play_session.submit_score(_active_profile, score)
		var still_going: bool = active_pass_play_session.advance_turn()
		if still_going:
			current_state = State.MENU
			TransitionLayer.go_to(PASS_PLAY_NEXT_PLAYER_SCENE)
		else:
			pending_pass_play_session = active_pass_play_session
			active_pass_play_session = null
			current_state = State.RESULTS
			TransitionLayer.go_to(PASS_PLAY_SCOREBOARD_SCENE)
		return

	# Playlist (Daily Dive / Radio Shuffle): advance to next level.
	if not playlist.is_empty():
		playlist_index += 1
		if playlist_index < playlist.size():
			start_level(playlist[playlist_index])
			return
		playlist.clear()
		playlist_index = 0

	finish_level(score, stars)
