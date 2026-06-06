extends Node2D

class_name LevelRoot


func _ready() -> void:
	var level_loader: LevelLoader = $LevelLoader
	level_loader.obstacle_spawner = $ObstacleSpawner
	level_loader.collectible_spawner = $CollectibleSpawner

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

	level_loader.load_level(GameManager.current_level_id)
