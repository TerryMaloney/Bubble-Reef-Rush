# Autoload that tracks active mutators for the current run and applies them
# at level load. All 20 Phase 19 mutator effects implemented here.
extends Node

## Active mutator IDs for this run. Set by GameManager before scene change.
var active_mutators: Array[String] = []


## Apply active mutators to level components.
## Called from LevelRoot._ready() after all child nodes are initialized.
## player: PlayerController node, scroll: ScrollService autoload, root: LevelRoot node.
func apply(player: Node, scroll: Node, root: Node) -> void:
	if active_mutators.is_empty():
		return

	for id: String in active_mutators:
		match id:
			"tiny_pebble":
				player.scale = Vector2(0.5, 0.5)
			"giant_pebble":
				player.scale = Vector2(2.0, 2.0)
			"reverse_buoyancy":
				if player.has_method("set") and "float_force" in player:
					player.float_force = -player.float_force
					player.dive_force = -player.dive_force
			"slippery_water":
				if "drag" in player:
					player.drag = 0.998
			"double_pearls":
				_set_pearl_multiplier(root, 2)
			"treasure_only":
				_hide_pearls(root)
			"one_hit_shield":
				_grant_start_shield(root)
			"no_powers":
				_force_power_mode(root, "disabled")
			"bubble_burst_only":
				_force_power_type(root, "bubble_burst")
			"ghost_mode":
				player.modulate.a = 0.3
			"mirror_controls":
				if "diving" in player:
					# Mirror controls: swap float/dive behavior.
					# We achieve this by swapping forces at the start.
					var tmp_float: float = player.float_force
					player.float_force = player.dive_force
					player.dive_force = tmp_float
			"faster_scroll":
				if scroll != null and scroll.has_method("set") and "speed_now" in scroll:
					scroll.speed_now *= 1.3
			"gentle_gaps":
				pass  # Handled by ObstacleSpawner reading MutatorSystem.is_active()
			"sudden_darkness":
				pass  # DarkVoid obstacle activated from beat_map; handled by level metadata injection
			"fever_forever":
				var fc: Node = root.get_node_or_null("FeverController")
				if fc != null and fc.has_method("force_fever"):
					fc.force_fever()
			"one_attempt":
				pass  # RetryController reads MutatorSystem.is_active("one_attempt") to block retry
			"random_character":
				_apply_random_character(player)
			"invisible_hud":
				var hud: Node = root.get_node_or_null("HUD")
				if hud != null:
					hud.modulate.a = 0.0
			"beat_rings_only":
				_hide_score_labels(root)
			"chaos_background":
				pass  # BackgroundController reads MutatorSystem.is_active() to enable chaos mode


## Check whether a specific mutator is currently active.
func is_active(mutator_id: String) -> bool:
	return mutator_id in active_mutators


## Clear active mutators (called by GameManager when returning to menu).
func clear() -> void:
	if not active_mutators.is_empty():
		active_mutators.clear()
		EventBus.mutators_changed.emit([])


# ── Private helpers ────────────────────────────────────────────────────────────

func _set_pearl_multiplier(root: Node, multiplier: int) -> void:
	var spawner: Node = root.get_node_or_null("CollectibleSpawner")
	if spawner != null and "pearl_value_multiplier" in spawner:
		spawner.pearl_value_multiplier = multiplier


func _hide_pearls(root: Node) -> void:
	var spawner: Node = root.get_node_or_null("CollectibleSpawner")
	if spawner != null and "pearls_visible" in spawner:
		spawner.pearls_visible = false


func _grant_start_shield(root: Node) -> void:
	var rc: Node = root.get_node_or_null("ResonanceController")
	if rc != null and rc.has_method("grant_shield"):
		rc.grant_shield()


func _force_power_mode(root: Node, mode: String) -> void:
	var rc: Node = root.get_node_or_null("ResonanceController")
	if rc != null:
		rc.set("_mode", mode)


func _force_power_type(root: Node, power_type: String) -> void:
	var rc: Node = root.get_node_or_null("ResonanceController")
	if rc != null and "equipped_power" in rc:
		rc.equipped_power = power_type


func _apply_random_character(player: Node) -> void:
	var profile: String = SaveSystem.get_active_profile_id()
	var equipped: String = SaveSystem.get_equipped_character(profile)
	var chars: Array[String] = ["default", "zap", "pip", "crusher", "finn", "lumina", "mochi", "grumble"]
	var unlocked: Array[String] = []
	for c: String in chars:
		if SaveSystem.get_character_unlocked(profile, c):
			unlocked.append(c)
	if not unlocked.is_empty():
		var chosen: String = unlocked[randi() % unlocked.size()]
		if chosen != equipped:
			PlayerSkin.apply_skin(player, chosen)


func _hide_score_labels(root: Node) -> void:
	var hud: Node = root.get_node_or_null("HUD")
	if hud == null:
		return
	for child_name: String in ["ScoreLabel", "ComboLabel", "JudgmentLabel"]:
		var node: Node = hud.get_node_or_null(child_name)
		if node != null:
			node.visible = false
