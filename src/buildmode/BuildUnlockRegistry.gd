## BuildUnlockRegistry — autoload that maps level completions to Build Mode palette unlocks.
## Clearing a level in a zone unlocks that zone's advanced obstacle types in Build Mode.
## Called from AchievementSystem.evaluate_run() after every run.
extends Node

const ZONE_UNLOCKS: Dictionary = {
	"z2": ["current_jet"],
	"z3": ["anchor_chain", "eel_snap"],
	"z4": ["lava_burst", "pressure_wall"],
	"z5": ["dark_void", "mirror_fish"],
	"z6": ["crystal_shard"],
}


func check_unlocks(profile_id: String, level_id: String, stars: int) -> void:
	if stars <= 0:
		return
	var zone: String = _zone_from_level_id(level_id)
	if zone.is_empty() or not ZONE_UNLOCKS.has(zone):
		return
	for otype: Variant in ZONE_UNLOCKS[zone]:
		var otype_str: String = str(otype)
		if not SaveSystem.has_build_unlock(profile_id, "obstacles", otype_str):
			SaveSystem.add_build_unlock(profile_id, "obstacles", otype_str)
			EventBus.build_unlock_earned.emit("obstacles", otype_str)


func _zone_from_level_id(level_id: String) -> String:
	if "-" not in level_id:
		return ""
	return level_id.split("-")[0].to_lower()


func get_unlocked_obstacles(profile_id: String) -> Array[String]:
	var result: Array[String] = []
	for zone: String in ZONE_UNLOCKS:
		for otype: Variant in ZONE_UNLOCKS[zone]:
			var otype_str: String = str(otype)
			if SaveSystem.has_build_unlock(profile_id, "obstacles", otype_str):
				result.append(otype_str)
	return result
