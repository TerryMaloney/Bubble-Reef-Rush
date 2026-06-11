## RadioShuffleScreen — builds playlists for the five Radio Shuffle modes.
## Boss Rush and Treasure Hunt return fixed ordered lists; the others are seeded-random.
extends Node

class_name RadioShuffleScreen

const BOSS_LEVELS: Array[String] = ["boss_z3", "boss_z4", "boss_z5", "boss_z6"]


## Returns count level IDs for the given shuffle mode.
## mode: "relaxed" | "standard" | "wild" | "boss_rush" | "treasure_hunt"
func get_playlist(mode: String, count: int) -> Array[String]:
	var seed: int = DeterministicSeed.seed_from_string("%d" % Time.get_ticks_msec())
	match mode:
		"relaxed":
			return DeterministicSeed.pick_levels(seed, count, [1, 2])
		"standard":
			return DeterministicSeed.pick_levels(seed, count, [1, 4])
		"boss_rush":
			return BOSS_LEVELS.slice(0, min(count, BOSS_LEVELS.size()))
		_:
			return DeterministicSeed.pick_levels(seed, count, [1, 6])
