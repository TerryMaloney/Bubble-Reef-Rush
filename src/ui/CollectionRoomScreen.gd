## CollectionRoomScreen — museum of characters, achievements, boss trophies,
## family records, and blueprints. Headlessly testable via get_collection_data().
extends Control

class_name CollectionRoomScreen

const CHARACTER_IDS: Array[String] = [
	"pebble", "finn", "zap", "mochi", "pip", "crusher", "lumina", "grumble"
]
const BOSS_IDS: Array[String] = ["boss_z3", "boss_z4", "boss_z5", "boss_z6"]

const CHARACTER_DISPLAY: Dictionary = {
	"pebble": "Pebble", "finn": "Finn", "zap": "Zap", "mochi": "Mochi",
	"pip": "Pip", "crusher": "Crusher", "lumina": "Lumina", "grumble": "Grumble"
}
const BOSS_DISPLAY: Dictionary = {
	"boss_z3": "Zone 3 Boss", "boss_z4": "Zone 4 Boss",
	"boss_z5": "Zone 5 Boss", "boss_z6": "Zone 6 Boss"
}


func _ready() -> void:
	$CloseButton.pressed.connect(func() -> void: queue_free())
	_populate_ui()


func _populate_ui() -> void:
	var profile: String = SaveSystem.get_active_profile_id()
	var data: Dictionary = get_collection_data(profile)

	var char_grid: GridContainer = $TabContainer/Characters/CharacterGrid
	for c: Dictionary in (data.get("characters", []) as Array):
		var cid: String = str(c.get("id", ""))
		var unlocked: bool = bool(c.get("unlocked", false))
		var lbl: Label = Label.new()
		lbl.text = (CHARACTER_DISPLAY.get(cid, cid) as String) if unlocked else "???"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(180, 80)
		if not unlocked:
			lbl.modulate = Color(0.3, 0.3, 0.3)
		char_grid.add_child(lbl)

	var trophy_grid: GridContainer = $TabContainer/Boss\ Trophies/TrophyGrid
	for t: Dictionary in (data.get("boss_trophies", []) as Array):
		var bid: String = str(t.get("boss_id", ""))
		var defeated: bool = bool(t.get("defeated", false))
		var lbl: Label = Label.new()
		lbl.text = (BOSS_DISPLAY.get(bid, bid) as String) if defeated else "???"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(240, 80)
		if not defeated:
			lbl.modulate = Color(0.3, 0.3, 0.3)
		trophy_grid.add_child(lbl)

	var bp_list: VBoxContainer = $TabContainer/Blueprints/BlueprintList
	var bps: Array = data.get("blueprints", []) as Array
	if bps.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No blueprints yet — complete Creator Trials!"
		bp_list.add_child(lbl)
	else:
		for bp: Dictionary in bps:
			var lbl: Label = Label.new()
			lbl.text = str(bp.get("id", ""))
			bp_list.add_child(lbl)

	var rec_list: VBoxContainer = $TabContainer/Records/RecordList
	var records: Dictionary = data.get("family_records", {}) as Dictionary
	if records.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No records yet — complete some levels!"
		rec_list.add_child(lbl)
	else:
		var sorted_keys: Array = records.keys()
		sorted_keys.sort()
		for level_id: String in sorted_keys:
			var rec: Dictionary = records[level_id] as Dictionary
			var lbl: Label = Label.new()
			lbl.text = "%s  —  %d  (%s)" % [level_id, int(rec.get("score", 0)), str(rec.get("profile_id", ""))]
			rec_list.add_child(lbl)


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
