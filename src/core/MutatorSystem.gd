# Autoload that tracks active mutators for the current run and applies them
# at level load. All 20 effects implemented.
extends Node

## Active mutator IDs for this run. Set by GameManager before scene change.
var active_mutators: Array[String] = []


## Apply active mutators to level components.
## Called from LevelRoot._ready() after all child nodes are initialized.
func apply(player: Node, scroll: Node, _root: Node) -> void:
	for mutator_id: String in active_mutators:
		_apply_one(mutator_id, player, scroll)


func _apply_one(mutator_id: String, player: Node, scroll: Node) -> void:
	match mutator_id:
		"tiny_pebble":
			player.scale = Vector2(0.5, 0.5)
		"giant_pebble":
			player.scale = Vector2(2.0, 2.0)
		"reverse_buoyancy":
			if player.has_method("set") and "float_force" in player:
				player.float_force = -player.float_force
		"slippery_water":
			if "drag" in player:
				player.drag = 0.998
		"faster_scroll":
			if scroll != null and scroll.has_method("set_global_speed_multiplier"):
				scroll.set_global_speed_multiplier(1.3)
		"gentle_gaps":
			# Gap scale is applied by ObstacleSpawner via MutatorSystem.get_gap_scale()
			pass
		"ghost_mode":
			player.modulate.a = 0.3
		"one_hit_shield":
			# LevelRoot wires this: ResonanceController starts with 1 shield charge.
			pass
		"no_powers":
			# Checked in ResonanceController.can_fire() via MutatorSystem.is_active()
			pass
		"bubble_burst_only":
			pass  # LevelRoot overrides equipped power at setup
		"mirror_controls":
			if "dive_impulse" in player and "float_force" in player:
				var tmp: float = player.dive_impulse
				player.dive_impulse = -player.float_force
				player.float_force = -tmp
		"double_pearls":
			pass  # CollectibleSpawner reads MutatorSystem.is_active()
		"treasure_only":
			pass  # CollectibleSpawner reads MutatorSystem.is_active()
		"fever_forever":
			pass  # FeverController reads MutatorSystem.is_active()
		"sudden_darkness":
			pass  # BackgroundController reads MutatorSystem.is_active()
		"one_attempt":
			pass  # GameManager reads MutatorSystem.is_active()
		"random_character":
			pass  # PlayerSkin reads MutatorSystem.is_active()
		"invisible_hud":
			pass  # HUDController reads MutatorSystem.is_active()
		"beat_rings_only":
			pass  # HUDController reads MutatorSystem.is_active()
		"chaos_background":
			pass  # BackgroundController reads MutatorSystem.is_active()


## Check whether a specific mutator is currently active.
func is_active(mutator_id: String) -> bool:
	return mutator_id in active_mutators


func get_gap_scale() -> float:
	return 1.3 if is_active("gentle_gaps") else 1.0


func get_collectible_multiplier() -> float:
	return 2.0 if is_active("double_pearls") else 1.0


## Test-only helper: set active mutators (accepts untyped array to work from external scripts).
func _test_set_active(mutators: Array) -> void:
	active_mutators.clear()
	for m in mutators:
		active_mutators.append(m as String)


## Clear active mutators (called by GameManager when returning to menu).
func clear() -> void:
	if not active_mutators.is_empty():
		active_mutators.clear()
		EventBus.mutators_changed.emit([])
