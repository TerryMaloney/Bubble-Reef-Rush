## CollectionRoomScreen — museum of characters, achievements, boss trophies,
## family records, and blueprints. Headlessly testable via get_collection_data().
extends Node

class_name CollectionRoomScreen

const CHARACTER_IDS: Array[String] = [
	"pebble", "finn", "zap", "mochi", "pip", "crusher", "lumina", "grumble"
]
const BOSS_IDS: Array[String] = ["boss_z3", "boss_z4", "boss_z5", "boss_z6"]


## Returns structured collection data for profile_id.
## family_records keys are level_ids; values are {score, profile_id}.
func get_collection_data(profile_id: String) -> Dictionary:
	var characters: Array = []
	for cid: String in CHARACTER_IDS:
		characters.append({
			"id": cid,
			"unlocked": SaveSystem.get_character_unlocked(profile_id, cid)
		})

	var boss_trophies: Array = []
	for bid: String in BOSS_IDS:
		boss_trophies.append({
			"boss_id": bid,
			"defeated": SaveSystem.get_boss_trophy(profile_id, bid)
		})

	var blueprints: Array = []
	for bp: Variant in SaveSystem.get_blueprints(profile_id):
		blueprints.append({"id": str(bp), "owned": true})

	var family_records: Dictionary = {}
	for pid: String in SaveSystem.list_profiles():
		var results: Dictionary = SaveSystem.get_all_level_results(pid)
		for level_id: String in results.keys():
			var entry: Dictionary = results[level_id] as Dictionary
			var sc: int = int(entry.get("best_score", 0))
			if not family_records.has(level_id):
				family_records[level_id] = {"score": sc, "profile_id": pid}
			elif sc > int((family_records[level_id] as Dictionary).get("score", 0)):
				family_records[level_id] = {"score": sc, "profile_id": pid}

	return {
		"characters": characters,
		"boss_trophies": boss_trophies,
		"blueprints": blueprints,
		"family_records": family_records,
	}
