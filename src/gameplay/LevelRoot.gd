extends Node2D

class_name LevelRoot

const BUBBLE_BURST_SCENE: PackedScene = preload("res://scenes/gameplay/powers/BubbleBurst.tscn")
const GHOST_PLAYER_SCENE: PackedScene = preload("res://scenes/gameplay/GhostPlayer.tscn")

const SPECIAL_CONTROLLER_GD: String = "res://src/gameplay/SpecialLevelController.gd"

var _hud_controller: HUDController
var _level_loader: LevelLoader
var _resonance: ResonanceController
var _recorder: GhostRecorder
var _special: Node = null
var _copilot: CoPilotController = null


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
	_hud_controller.resonance_bar = $HUD/ResonanceChargeBar if $HUD.has_node("ResonanceChargeBar") else null
	_hud_controller.power_button = $HUD/PowerButton if $HUD.has_node("PowerButton") else null
	_hud_controller.ghost_intro_label = $HUD/GhostIntroLabel if $HUD.has_node("GhostIntroLabel") else null
	_hud_controller.ghost_delta_label = $HUD/GhostDeltaLabel if $HUD.has_node("GhostDeltaLabel") else null

	var retry_btn: Button = $HUD/RetryButton
	_hud_controller.retry_button = retry_btn
	retry_btn.pressed.connect(func() -> void: EventBus.retry_requested.emit())
	retry_btn.hide()

	var drop_cp_btn: Button = $HUD/DropCPButton
	_hud_controller.drop_cp_button = drop_cp_btn

	if $HUD.has_node("PowerButton"):
		($HUD/PowerButton as Button).pressed.connect(_on_power_button_pressed)

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

	# ResonanceController — setup deferred to run_started so level metadata is available.
	if has_node("ResonanceController"):
		_resonance = $ResonanceController
		_resonance.add_to_group("resonance_controller")
		EventBus.run_started.connect(_on_run_started_resonance)
		EventBus.practice_respawned.connect(_on_practice_respawned_resonance)
		EventBus.power_activated.connect(_on_power_activated)

	# GhostRecorder — wired to PlayerController; saves on run_completed.
	if has_node("GhostRecorder"):
		_recorder = $GhostRecorder
		player.set_ghost_recorder(_recorder)
		EventBus.run_started.connect(_on_run_started_ghost)
		EventBus.practice_respawned.connect(_on_practice_respawned_ghost)
		EventBus.run_completed.connect(_on_run_completed_ghost)

	# GhostPlayer — instantiate if GameManager.show_ghost is set.
	_maybe_spawn_ghost_player(player)

	# SpecialLevelController — created on run_started when level_type != standard.
	EventBus.run_started.connect(_on_run_started_special)

	# Co-Pilot — instantiate when Player B is configured.
	if not GameManager.copilot_profile_b.is_empty() and _resonance != null:
		_copilot = CoPilotController.new()
		add_child(_copilot)
		_copilot.setup(GameManager.copilot_profile_b, _resonance)

	# Pause button — touch-friendly pause trigger.
	if $HUD.has_node("PauseButton"):
		($HUD/PauseButton as Button).pressed.connect(func() -> void: EventBus.pause_requested.emit())

	# Test-play banner.
	if $HUD.has_node("TestBanner") and GameManager.pending_build_session != null:
		var banner: Label = $HUD/TestBanner as Label
		var sd: Dictionary = (GameManager.pending_build_session as Node).call("get_data") as Dictionary
		var meta: Dictionary = sd.get("metadata", {}) as Dictionary
		var beat_count: int = (sd.get("beat_map", []) as Array).size()
		banner.text = "TESTING: %s  |  Objects: %d" % [str(meta.get("name", "My Level")), beat_count]
		banner.show()

	# Physics tuner overlay — debug builds only.
	if OS.is_debug_build():
		var tuner_scene: PackedScene = load("res://scenes/debug/PhysicsTuner.tscn")
		if tuner_scene != null:
			add_child(tuner_scene.instantiate())

	_level_loader.level_ended.connect(_on_level_ended)
	_level_loader.load_level(GameManager.current_level_id)


# ── Resonance ─────────────────────────────────────────────────────────────────

func _on_run_started_resonance(level_id: String) -> void:
	var raw: Dictionary = _level_loader.rhythm_map.get_raw_data()
	var meta: Dictionary = raw.get("metadata", {}) as Dictionary
	var mode: String = str(meta.get("power_mode", "allowed"))
	var max_charges: int = int(meta.get("max_charges", 1))
	var profile: String = SaveSystem.get_active_profile_id()
	var equipped: String = SaveSystem.get_equipped_power(profile)
	_resonance.setup(mode, max_charges, equipped)
	_hud_controller.update_power_button_mode(mode)


func _on_practice_respawned_resonance() -> void:
	_resonance.reset()


func _on_power_button_pressed() -> void:
	_resonance.fire()


func _on_power_activated(power_type: String, is_perfect: bool) -> void:
	if power_type == "bubble_burst":
		_spawn_bubble_burst(is_perfect)


func _spawn_bubble_burst(is_perfect: bool) -> void:
	var player: PlayerController = $Player
	var burst: BubbleBurst = BUBBLE_BURST_SCENE.instantiate() as BubbleBurst
	add_child(burst)
	burst.setup(player.global_position, is_perfect)


# ── Ghost ─────────────────────────────────────────────────────────────────────

func _on_run_started_ghost(_level_id: String) -> void:
	_recorder.start()


func _on_practice_respawned_ghost() -> void:
	_recorder.start()


func _on_run_completed_ghost(level_id: String, score: int, _stars: int) -> void:
	if GameManager.is_practice_mode:
		return
	_recorder.stop(score)
	if _recorder.is_empty():
		return
	var profile: String = SaveSystem.get_active_profile_id()
	var ghost_data: Dictionary = _recorder.get_ghost_data(level_id, "1.0")
	var existing: Dictionary = GhostLibrary.load_ghost(profile, level_id, "personal_best")
	var existing_score: int = int(existing.get("final_score", -1))
	if score > existing_score:
		GhostLibrary.save_ghost(profile, level_id, "personal_best", ghost_data)


func _maybe_spawn_ghost_player(_player: PlayerController) -> void:
	var ghost_type: String = GameManager.show_ghost
	GhostLibrary.last_ghost_score = -1
	if ghost_type.is_empty():
		return
	var ghost_data: Dictionary = {}
	if ghost_type == "family_champion":
		ghost_data = GhostLibrary.get_family_champion(GameManager.current_level_id)
	else:
		var profile: String = SaveSystem.get_active_profile_id()
		ghost_data = GhostLibrary.load_ghost(profile, GameManager.current_level_id, ghost_type)
	if ghost_data.is_empty():
		return
	GhostLibrary.last_ghost_score = int(ghost_data.get("final_score", -1))
	var gp: GhostPlayer = GHOST_PLAYER_SCENE.instantiate() as GhostPlayer
	add_child(gp)
	gp.setup(ghost_data)
	EventBus.run_started.connect(func(_id: String) -> void: gp.play())
	_hud_controller.show_ghost_intro(ghost_type, GhostLibrary.last_ghost_score)


# ── Co-Pilot ─────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _copilot == null:
		return
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		# Right half of screen → Player B power trigger; left half remains Player A swim/dive.
		if (event as InputEventScreenTouch).position.x > get_viewport_rect().size.x * 0.5:
			_copilot.trigger_power()
			get_viewport().set_input_as_handled()


# ── Special levels ────────────────────────────────────────────────────────────

func _on_run_started_special(_level_id: String) -> void:
	if _special != null:
		return
	var raw: Dictionary = _level_loader.rhythm_map.get_raw_data()
	var meta: Dictionary = raw.get("metadata", {}) as Dictionary
	if str(meta.get("level_type", "standard")) == "standard":
		return
	_special = load(SPECIAL_CONTROLLER_GD).new()
	add_child(_special)
	_special.setup(meta)


# ── Level end ────────────────────────────────────────────────────────────────

func _on_level_ended(level_id: String) -> void:
	if _copilot != null:
		GameManager.last_copilot_contribution = _copilot.get_contribution()
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
