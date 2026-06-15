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
var active_difficulty: String = "normal"

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
## Co-Pilot contribution from last run — read by ResultsScreen.
var last_copilot_contribution: Dictionary = {}

## Pass & Play — active session; null when not in P&P mode.
var active_pass_play_session: PassPlaySession = null
## Passed to PassPlayScoreboardScreen via its _ready() so TransitionLayer can load it.
var pending_pass_play_session: PassPlaySession = null
## Previous player info shown on PassPlayNextPlayerScreen.
var pp_prev_profile: String = ""
var pp_prev_score: int = 0
## Active profile before P&P started — restored when session ends.
var _pp_original_profile: String = ""

## Playlist (Daily Dive / Radio Shuffle) — levels queued after start_playlist().
var playlist: Array[String] = []
var playlist_index: int = 0
## "daily_dive" | "radio_shuffle" | "treasure_hunt" | "" — determines end-of-playlist save behaviour.
var playlist_context: String = ""

## Treasure Hunt — set by LevelRoot._on_level_ended before run_completed fires.
var last_all_treasures_collected: bool = false
## Number of coins already saved before the current run started (read by HUDController).
var last_th_pre_collected: int = 0

## BuildMode: session stashed before test-play, restored in BuildModeRoot._ready().
var pending_build_session = null  # BuildSession ref — untyped to avoid forward dep
## Temp BRL path written before test-play; deleted after the run completes/fails.
var pending_build_test_path: String = ""
## Physics overrides set by PhysicsTuner (debug builds only). Empty = use defaults.
var physics_overrides: Dictionary = {}


func _ready() -> void:
	EventBus.run_failed.connect(_on_run_failed)
	EventBus.run_completed.connect(_on_run_completed)
	EventBus.run_progress.connect(_on_run_progress)
	EventBus.retry_requested.connect(retry_level)
	EventBus.level_load_requested.connect(start_level)
	_active_profile = SaveSystem.get_active_profile_id()
	# Apply stored text scale immediately on startup.
	Accessibility._apply_text_scale(Accessibility.text_scale())


func start_level(level_id: String) -> void:
	# Any launch that isn't the active build test-play clears leaked build state,
	# so finishing a Journey level can never boomerang back into the editor.
	if level_id != pending_build_test_path:
		_abandon_build_test()
	current_state = State.LOADING
	current_level_id = level_id
	_last_progress_pct = 0.0
	consecutive_deaths = 0
	TransitionLayer.go_to(LEVEL_ROOT_SCENE)


func retry_level() -> void:
	TransitionLayer.go_to(LEVEL_ROOT_SCENE)


func go_to_menu() -> void:
	current_state = State.MENU
	_abandon_build_test()
	_clear_session_state()
	# Cleared here (not in _clear_session_state) so PartyHub's
	# show_ghost → go_to_zone_select() flow survives navigation.
	show_ghost = ""
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
	SaveSystem.update_difficulty_stars(_active_profile, current_level_id, active_difficulty, stars)
	# Evaluate achievements AFTER update so level results are current.
	AchievementSystem.evaluate_run(_active_profile, current_level_id, score, stars)
	# Evaluate active rule cards (e.g. Treasure Hunt) so ResultsScreen can display results.
	if not RuleCardSystem.active_rules.is_empty():
		var run_data: Dictionary = {
			"score": score,
			"all_treasures_collected": last_all_treasures_collected,
		}
		RuleCardSystem.evaluate_run(current_level_id, run_data)
	TransitionLayer.go_to(RESULTS_SCENE)


func go_to_zone_select() -> void:
	current_state = State.MENU
	_abandon_build_test()
	_clear_session_state()
	TransitionLayer.go_to(ZONE_SELECT_SCENE)


func go_to_level_select(zone_id: String) -> void:
	current_zone_id = zone_id
	current_state = State.MENU
	TransitionLayer.go_to(LEVEL_SELECT_SCENE)


func open_build_mode() -> void:
	current_state = State.BUILD_MODE
	_clear_session_state()
	TransitionLayer.go_to(BUILD_MODE_SCENE)


## Clear per-session transient state when navigating away from a run.
func _clear_session_state() -> void:
	playlist.clear()
	playlist_index = 0
	playlist_context = ""
	copilot_profile_b = ""
	last_copilot_contribution = {}
	last_all_treasures_collected = false
	last_th_pre_collected = 0
	RuleCardSystem.set_active_rules([])
	MutatorSystem.active_mutators.erase("treasure_only")


func go_to_settings(return_scene: String = MAIN_MENU_SCENE) -> void:
	_settings_return_scene = return_scene
	TransitionLayer.go_to(SETTINGS_SCENE)


func return_from_settings() -> void:
	TransitionLayer.go_to(_settings_return_scene)


func start_pass_play(session: PassPlaySession) -> void:
	_pp_original_profile = SaveSystem.get_active_profile_id()
	active_pass_play_session = session
	pp_prev_profile = ""
	pp_prev_score = 0
	# Switch to first player's profile so saves are credited correctly.
	SaveSystem.set_active_profile(session.get_current_profile())
	start_level(session.level_id)


func start_playlist(levels: Array[String], context: String = "") -> void:
	playlist = levels.duplicate()
	playlist_index = 0
	playlist_context = context
	if context == "treasure_hunt":
		if not MutatorSystem.is_active("treasure_only"):
			MutatorSystem.active_mutators.append("treasure_only")
		RuleCardSystem.set_active_rules(["treasure_hunt"])
	if not playlist.is_empty():
		start_level(playlist[0])


func _on_run_progress(_level_id: String, pct: float) -> void:
	_last_progress_pct = pct


func _cleanup_build_test() -> void:
	if not pending_build_test_path.is_empty():
		DirAccess.remove_absolute(pending_build_test_path)
		pending_build_test_path = ""
	is_practice_mode = false


## Fully abandon a build test-play: delete the temp file, drop the stashed
## session, and clear the practice flag. No-op when no build test is active,
## so it never disturbs a normal (e.g. practice) run launch.
func _abandon_build_test() -> void:
	if pending_build_session == null and pending_build_test_path.is_empty():
		return
	if not pending_build_test_path.is_empty():
		DirAccess.remove_absolute(pending_build_test_path)
		pending_build_test_path = ""
	pending_build_session = null
	is_practice_mode = false


func _on_run_failed(level_id: String, score: int) -> void:
	# Build test-play: auto-return to editor on death.
	if pending_build_session != null:
		_cleanup_build_test()
		open_build_mode()
		return

	if is_practice_mode:
		return  # PracticeController handles respawn; no death/progress tracking

	# Pass & Play: death counts as the attempt — advance the turn immediately.
	if active_pass_play_session != null and active_pass_play_session.is_active():
		_active_profile = SaveSystem.get_active_profile_id()
		pp_prev_profile = _active_profile
		var distance_bonus: int = int(_last_progress_pct * 5.0)
		pp_prev_score = score + distance_bonus
		active_pass_play_session.submit_score(_active_profile, score + distance_bonus, false)
		var still_going: bool = active_pass_play_session.advance_turn()
		if still_going:
			current_state = State.MENU
			TransitionLayer.go_to(PASS_PLAY_NEXT_PLAYER_SCENE)
		else:
			pending_pass_play_session = active_pass_play_session
			active_pass_play_session = null
			SaveSystem.set_active_profile(_pp_original_profile)
			current_state = State.RESULTS
			TransitionLayer.go_to(PASS_PLAY_SCOREBOARD_SCENE)
		return

	# Normal campaign death.
	current_state = State.PLAYING
	consecutive_deaths += 1
	_active_profile = SaveSystem.get_active_profile_id()
	SaveSystem.record_attempt(_active_profile, level_id)
	SaveSystem.record_progress_pct(_active_profile, level_id, _last_progress_pct)


func _on_run_completed(level_id: String, score: int, stars: int) -> void:
	consecutive_deaths = 0
	_active_profile = SaveSystem.get_active_profile_id()
	SaveSystem.record_attempt(_active_profile, level_id)

	# Build test-play: mark session played_through and return to editor.
	if pending_build_session != null:
		pending_build_session.call("mark_played_through")
		_cleanup_build_test()
		open_build_mode()
		return

	# Pass & Play: route the score to the session, then advance turn.
	if active_pass_play_session != null and active_pass_play_session.is_active():
		pp_prev_profile = _active_profile
		var distance_bonus: int = int(_last_progress_pct * 5.0)
		pp_prev_score = score + distance_bonus
		active_pass_play_session.submit_score(_active_profile, score + distance_bonus, true)
		var still_going: bool = active_pass_play_session.advance_turn()
		if still_going:
			current_state = State.MENU
			TransitionLayer.go_to(PASS_PLAY_NEXT_PLAYER_SCENE)
		else:
			pending_pass_play_session = active_pass_play_session
			active_pass_play_session = null
			SaveSystem.set_active_profile(_pp_original_profile)
			current_state = State.RESULTS
			TransitionLayer.go_to(PASS_PLAY_SCOREBOARD_SCENE)
		return

	# Playlist (Daily Dive / Radio Shuffle): advance to next level.
	if not playlist.is_empty():
		playlist_index += 1
		if playlist_index < playlist.size():
			# Save stats for intermediate levels without showing the results screen.
			_active_profile = SaveSystem.get_active_profile_id()
			var prev: Dictionary = SaveSystem.get_all_level_results(_active_profile)
			last_prev_best_score = int((prev.get(level_id, {}) as Dictionary).get("best_score", 0))
			last_coins_earned = EconomyService.process_run_completed(level_id, score, stars)
			SaveSystem.update_level_result(_active_profile, level_id, score, stars)
			AchievementSystem.evaluate_run(_active_profile, level_id, score, stars)
			start_level(playlist[playlist_index])
			return
		# Final level in playlist — save Daily Dive date result, then show results.
		if playlist_context == "daily_dive":
			_active_profile = SaveSystem.get_active_profile_id()
			var date: String = Time.get_date_string_from_system()
			SaveSystem.set_daily_dive_result(_active_profile, date, score)
			EventBus.daily_dive_completed.emit(date, score)
		playlist.clear()
		playlist_index = 0
		playlist_context = ""

	finish_level(score, stars)
