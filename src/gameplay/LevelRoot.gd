extends Node2D

class_name LevelRoot

var _hud_controller: HUDController
var _level_loader: LevelLoader


func _ready() -> void:
	var director: DifficultyDirector = $DifficultyDirector

	_level_loader = $LevelLoader
	_level_loader.obstacle_spawner = $ObstacleSpawner
	_level_loader.collectible_spawner = $CollectibleSpawner

	$ObstacleSpawner.director = director
	director.seed_from_deaths(GameManager.consecutive_deaths)

	_hud_controller = $HUD/HUDController
	_hud_controller.score_label = $HUD/ScoreLabel
	_hud_controller.combo_label = $HUD/ComboLabel
	_hud_controller.judgment_label = $HUD/JudgmentLabel
	_hud_controller.progress_bar = $HUD/ProgressBar
	_hud_controller.attempt_label = $HUD/AttemptLabel

	var retry_btn: Button = $HUD/RetryButton
	_hud_controller.retry_button = retry_btn
	retry_btn.pressed.connect(func() -> void: EventBus.retry_requested.emit())
	retry_btn.hide()

	var drop_cp_btn: Button = $HUD/DropCPButton
	_hud_controller.drop_cp_button = drop_cp_btn

	var player: PlayerController = $Player
	_hud_controller.connect_timing_judge(player.timing_judge)
	player.timing_judge.combo_updated.connect(director.on_combo_updated)

	BeatConductor.user_latency_offset_ms = Accessibility.timing_offset_ms()
	player.timing_judge.window_scale = 1.25 if Accessibility.wide_timing_windows() else 1.0

	($JuiceDirector as JuiceDirector).setup($Camera2D as Camera2D)
	($BackgroundController as BackgroundController).setup($Background as ColorRect)

	var practice: PracticeController = $PracticeController
	practice.setup(player, _hud_controller, _level_loader)
	if GameManager.is_practice_mode:
		drop_cp_btn.pressed.connect(practice.drop_checkpoint)
		drop_cp_btn.show()
	else:
		drop_cp_btn.hide()

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
