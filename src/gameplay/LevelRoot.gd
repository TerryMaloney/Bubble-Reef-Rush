extends Node2D

class_name LevelRoot

var _hud_controller: HUDController
var _level_loader: LevelLoader


func _ready() -> void:
	var director: DifficultyDirector = $DifficultyDirector

	_level_loader = $LevelLoader
	_level_loader.obstacle_spawner = $ObstacleSpawner
	_level_loader.collectible_spawner = $CollectibleSpawner

	# The spawner consults the director to size each gate's gap.
	$ObstacleSpawner.director = director
	# Carry the player's recent deaths in so a stuck level eases (practice mercy).
	director.seed_from_deaths(GameManager.consecutive_deaths)

	_hud_controller = $HUD/HUDController
	_hud_controller.score_label = $HUD/ScoreLabel
	_hud_controller.combo_label = $HUD/ComboLabel
	_hud_controller.judgment_label = $HUD/JudgmentLabel
	_hud_controller.progress_bar = $HUD/ProgressBar
	_hud_controller.attempt_label = $HUD/AttemptLabel

	# Wire retry button here since HUDController._ready() ran before we set export vars.
	var retry_btn: Button = $HUD/RetryButton
	_hud_controller.retry_button = retry_btn
	retry_btn.pressed.connect(func() -> void: EventBus.retry_requested.emit())
	retry_btn.hide()

	var player: PlayerController = $Player
	_hud_controller.connect_timing_judge(player.timing_judge)
	# Feed combo state to the director so expert play raises the pressure.
	player.timing_judge.combo_updated.connect(director.on_combo_updated)

	# Apply persisted settings before the level clock starts.
	BeatConductor.user_latency_offset_ms = Accessibility.timing_offset_ms()
	player.timing_judge.window_scale = 1.25 if Accessibility.wide_timing_windows() else 1.0

	_level_loader.level_ended.connect(_on_level_ended)
	_level_loader.load_level(GameManager.current_level_id)


func _on_level_ended(level_id: String) -> void:
	var raw: Dictionary = _level_loader.rhythm_map.get_raw_data()
	var par: Dictionary = raw.get("par_score", {}) as Dictionary
	var one_star: int = int(par.get("one_star", 280))
	var two_star: int = int(par.get("two_star", 490))
	var three_star: int = int(par.get("three_star", 630))
	var s: int = _hud_controller.score
	var stars: int = 0
	if s >= three_star:
		stars = 3
	elif s >= two_star:
		stars = 2
	elif s >= one_star:
		stars = 1
	EventBus.run_completed.emit(level_id, s, stars)
