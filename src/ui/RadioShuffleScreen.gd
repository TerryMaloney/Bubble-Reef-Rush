## RadioShuffleScreen — builds playlists for the five Radio Shuffle modes.
## Boss Rush and Treasure Hunt return fixed ordered lists; the others are seeded-random.
extends Control

class_name RadioShuffleScreen

const BOSS_LEVELS: Array[String] = ["boss_z3", "boss_z4", "boss_z5", "boss_z6"]
const DAILY_DIVE_SCENE: String = "res://scenes/ui/DailyDiveScreen.tscn"


func _ready() -> void:
	$Panel/VBox/DailyDiveButton.pressed.connect(_on_daily_dive_pressed)
	$Panel/VBox/RelaxedButton.pressed.connect(func() -> void: _start_mode("relaxed"))
	$Panel/VBox/StandardButton.pressed.connect(func() -> void: _start_mode("standard"))
	$Panel/VBox/WildButton.pressed.connect(func() -> void: _start_mode("wild"))
	$Panel/VBox/TreasureHuntButton.pressed.connect(func() -> void: _start_mode("treasure_hunt"))
	$Panel/VBox/CloseButton.pressed.connect(func() -> void: queue_free())
	# Boss Rush not yet implemented — hide rather than confuse kids with a greyed button.
	($Panel/VBox/BossRushButton as Button).hide()


func _on_daily_dive_pressed() -> void:
	var packed: PackedScene = load(DAILY_DIVE_SCENE) as PackedScene
	if packed == null:
		push_error("RadioShuffleScreen: cannot load %s" % DAILY_DIVE_SCENE)
		return
	var screen: Control = packed.instantiate() as Control
	get_parent().add_child(screen)
	queue_free()


func _start_mode(mode: String) -> void:
	var levels: Array[String] = get_playlist(mode, 5)
	if levels.is_empty():
		return
	# Treasure Hunt gets its own context so GameManager can activate the mutator and rule card.
	var context: String = "treasure_hunt" if mode == "treasure_hunt" else "radio_shuffle"
	GameManager.start_playlist(levels, context)
	queue_free()


## Returns count level IDs for the given shuffle mode.
## mode: "relaxed" | "standard" | "wild" | "boss_rush" | "treasure_hunt"
func get_playlist(mode: String, count: int) -> Array[String]:
	var seed: int = DeterministicSeed.seed_from_string("%d" % Time.get_ticks_msec())
	match mode:
		"relaxed":
			return DeterministicSeed.pick_levels(seed, count, [1, 2])
		"standard":
			return DeterministicSeed.pick_levels(seed, count, [1, 4])
		"treasure_hunt":
			return DeterministicSeed.pick_levels(seed, count, [1, 4])
		"boss_rush":
			return BOSS_LEVELS.slice(0, min(count, BOSS_LEVELS.size()))
		_:
			return DeterministicSeed.pick_levels(seed, count, [1, 6])
