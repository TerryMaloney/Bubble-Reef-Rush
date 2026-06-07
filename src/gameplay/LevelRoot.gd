extends Node2D

class_name LevelRoot


func _ready() -> void:
	var director: DifficultyDirector = $DifficultyDirector

	var level_loader: LevelLoader = $LevelLoader
	level_loader.obstacle_spawner = $ObstacleSpawner
	level_loader.collectible_spawner = $CollectibleSpawner

	# The spawner consults the director to size each gate's gap.
	$ObstacleSpawner.director = director
	# Carry the player's recent deaths in so a stuck level eases (practice mercy).
	director.seed_from_deaths(GameManager.consecutive_deaths)

	var hud_controller: HUDController = $HUD/HUDController
	hud_controller.score_label = $HUD/ScoreLabel
	hud_controller.combo_label = $HUD/ComboLabel
	hud_controller.judgment_label = $HUD/JudgmentLabel

	# Wire retry button here since HUDController._ready() ran before we set export vars.
	var retry_btn: Button = $HUD/RetryButton
	hud_controller.retry_button = retry_btn
	retry_btn.pressed.connect(func() -> void: EventBus.retry_requested.emit())
	retry_btn.hide()

	var player: PlayerController = $Player
	hud_controller.connect_timing_judge(player.timing_judge)
	# Feed combo state to the director so expert play raises the pressure.
	player.timing_judge.combo_updated.connect(director.on_combo_updated)

	level_loader.load_level(GameManager.current_level_id)
