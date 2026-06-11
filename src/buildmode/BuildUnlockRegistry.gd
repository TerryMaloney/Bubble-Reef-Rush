# Autoload that maps level completions to Build Mode palette unlocks.
# Called by AchievementSystem after a run completes with stars > 0.
extends Node

# Maps zone prefix → obstacle types unlocked upon clearing any level in that zone.
const ZONE_UNLOCKS: Dictionary = {
	"z2": ["current_jet"],
	"z3": ["anchor_chain", "eel_snap"],
	"z4": ["lava_burst", "pressure_wall"],
	"z5": ["dark_void", "mirror_fish"],
	"z6": ["crystal_shard"],
}


## Check and grant any build unlocks earned by clearing level_id with the given stars.
## level_id format: "z3-l2", "z1-l8", etc.
func check_unlocks(profile_id: String, level_id: String, stars: int) -> void:
	if stars <= 0:
		return
	var zone: String = _zone_from_level_id(level_id)
	if zone.is_empty() or not ZONE_UNLOCKS.has(zone):
		return
	for otype: String in (ZONE_UNLOCKS[zone] as Array):
		SaveSystem.add_build_unlock(profile_id, "obstacles", otype)


func _zone_from_level_id(level_id: String) -> String:
	if "-" not in level_id:
		return ""
	return level_id.split("-")[0].to_lower()
