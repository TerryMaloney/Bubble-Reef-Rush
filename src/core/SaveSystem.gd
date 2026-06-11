# Autoload node that manages local family profiles and per-profile level progress persistence.
extends Node

const SAVE_VERSION: int = 3

const PROFILE_INDEX_PATH: String = "user://profiles/index.cfg"
const LEVELS_DIR_TEMPLATE: String = "user://profiles/%s/levels/"


func _ready() -> void:
	ensure_profile(get_active_profile_id())


func _fresh_v3_extras() -> Dictionary:
	return {
		"powers_unlocked": {"bubble_burst": true},
		"equipped_power": "bubble_burst",
		"build_unlocks": {
			"obstacles": ["coral_spike", "jellyfish_drift", "kelp_curtain", "bubble_mine"],
			"backgrounds": [],
			"palettes": [],
			"particles": [],
			"blueprints": []
		},
		"blueprints": [],
		"lost_notes": [],
		"radio_keys": [],
		"world_stations_unlocked": ["ocean"],
		"workshop_rank": 0,
		"workshop_xp": 0,
		"family_tournament": {"history": []},
		"daily_dive": {"history": {}},
		"mutators_unlocked": ["tiny_pebble", "gentle_gaps"],
		"rule_cards_unlocked": ["beat_my_score", "no_miss", "collect_all_pearls"],
		"secret_exits_found": {},
		"collection": {"boss_trophies": [], "family_records": {}}
	}


func _fresh_profile(profile_id: String) -> Dictionary:
	var base: Dictionary = _fresh_v2_profile(profile_id)
	var extras: Dictionary = _fresh_v3_extras()
	for k: String in extras.keys():
		base[k] = extras[k]
	base["version"] = SAVE_VERSION
	return base


func ensure_profile(profile_id: String) -> void:
	var profile_dir: String = "user://profiles/%s/" % profile_id
	var levels_dir: String = LEVELS_DIR_TEMPLATE % profile_id
	var progress_path: String = profile_dir + "progress.json"

	if not DirAccess.dir_exists_absolute(profile_dir):
		DirAccess.make_dir_recursive_absolute(profile_dir)

	if not DirAccess.dir_exists_absolute(levels_dir):
		DirAccess.make_dir_recursive_absolute(levels_dir)

	if not FileAccess.file_exists(progress_path):
		_write_json(progress_path, _fresh_profile(profile_id))

	# Ensure this profile is registered in the index.
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PROFILE_INDEX_PATH)
	var profiles: Array = cfg.get_value("profiles", "list", [])
	if not (profile_id in profiles):
		profiles.append(profile_id)
		cfg.set_value("profiles", "list", profiles)
		cfg.save(PROFILE_INDEX_PATH)


func get_active_profile_id() -> String:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(PROFILE_INDEX_PATH)
	if err != OK:
		return "player1"
	var profile_id: String = cfg.get_value("active", "profile_id", "player1")
	if profile_id == "":
		return "player1"
	return profile_id


func set_active_profile(profile_id: String) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PROFILE_INDEX_PATH)
	cfg.set_value("active", "profile_id", profile_id)
	cfg.save(PROFILE_INDEX_PATH)
	EventBus.active_profile_changed.emit(profile_id)


func list_profiles() -> Array[String]:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(PROFILE_INDEX_PATH)
	if err != OK:
		return []
	var raw: Array = cfg.get_value("profiles", "list", [])
	var result: Array[String] = []
	for entry: Variant in raw:
		result.append(str(entry))
	return result


func _fresh_v2_profile(profile_id: String) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"profile_id": profile_id,
		"total_stars": 0,
		"coins": 0,
		"levels": {},
		"characters": {"default_fish": true},
		"cosmetics": {"owned": [], "equipped": {"trail": "", "ring": "", "palette": ""}},
		"achievements": {},
		"settings": {
			"timing_offset_ms": 0.0,
			"reduced_motion": false,
			"wide_timing_windows": false,
			"text_scale": 1.0,
			"colorblind_judgements": false,
			"volume_master": 1.0,
			"volume_music": 1.0,
			"volume_sfx": 1.0,
		}
	}


func _migrate(data: Dictionary) -> Dictionary:
	var ver: int = int(data.get("version", 1))
	if ver >= SAVE_VERSION:
		return data

	# Write a backup before migrating.
	var profile_id: String = str(data.get("profile_id", "player1"))
	var bak_path: String = "user://profiles/%s/progress.json.bak" % profile_id
	_write_json(bak_path, data)

	# ── v1 → v2 ──────────────────────────────────────────────────────────────
	if ver < 2:
		var fresh: Dictionary = _fresh_v2_profile(profile_id)
		fresh["total_stars"] = int(data.get("total_stars", 0))
		fresh["coins"] = int(data.get("coins", 0))
		fresh["characters"] = data.get("characters", {"default_fish": true}) as Dictionary
		var old_settings: Dictionary = data.get("settings", {}) as Dictionary
		var new_settings: Dictionary = fresh["settings"] as Dictionary
		for k: String in old_settings.keys():
			new_settings[k] = old_settings[k]
		fresh["settings"] = new_settings
		var old_levels: Dictionary = data.get("levels", {}) as Dictionary
		var new_levels: Dictionary = {}
		for lid: String in old_levels.keys():
			var old_entry: Dictionary = old_levels[lid] as Dictionary
			new_levels[lid] = {
				"best_score": int(old_entry.get("best_score", 0)),
				"best_stars": int(old_entry.get("best_stars", 0)),
				"attempts": int(old_entry.get("attempts", 1)),
				"best_progress_pct": float(old_entry.get("best_progress_pct", 100.0)),
				"treasure_coins": old_entry.get("treasure_coins", [false, false, false]) as Array,
				"practice_best_pct": float(old_entry.get("practice_best_pct", 0.0)),
			}
		fresh["levels"] = new_levels
		fresh["version"] = 2
		data = fresh

	# ── v2 → v3 ──────────────────────────────────────────────────────────────
	if int(data.get("version", 2)) < 3:
		var extras: Dictionary = _fresh_v3_extras()
		for k: String in extras.keys():
			if not data.has(k):
				data[k] = extras[k]
		data["version"] = 3

	return data


func load_progress(profile_id: String) -> Dictionary:
	var progress_path: String = "user://profiles/%s/progress.json" % profile_id
	if not FileAccess.file_exists(progress_path):
		return {}
	var file: FileAccess = FileAccess.open(progress_path, FileAccess.READ)
	if file == null:
		push_warning("SaveSystem: Could not open progress file for profile '%s'." % profile_id)
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_warning("SaveSystem: Failed to parse progress JSON for profile '%s'." % profile_id)
		return {}
	return _migrate(parsed as Dictionary)


func save_progress(profile_id: String, data: Dictionary) -> void:
	var progress_path: String = "user://profiles/%s/progress.json" % profile_id
	_write_json(progress_path, data)


func update_level_result(profile_id: String, level_id: String, score: int, stars: int) -> void:
	var data: Dictionary = load_progress(profile_id)
	if data.is_empty():
		ensure_profile(profile_id)
		data = load_progress(profile_id)

	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var existing: Dictionary = _ensure_level_entry(levels, level_id)
	var existing_score: int = int(existing.get("best_score", 0))

	if score > existing_score:
		existing["best_score"] = score
		existing["best_stars"] = stars
		existing["best_progress_pct"] = 100.0
	levels[level_id] = existing
	data["levels"] = levels
	# Recalculate total_stars across all level records.
	var total: int = 0
	for entry: Variant in levels.values():
		total += int((entry as Dictionary).get("best_stars", 0))
	data["total_stars"] = total
	save_progress(profile_id, data)


## Record that a run attempt started (called on run_failed or run_completed).
func record_attempt(profile_id: String, level_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if data.is_empty():
		ensure_profile(profile_id)
		data = load_progress(profile_id)
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var entry: Dictionary = _ensure_level_entry(levels, level_id)
	entry["attempts"] = int(entry.get("attempts", 0)) + 1
	levels[level_id] = entry
	data["levels"] = levels
	save_progress(profile_id, data)


## Record the furthest progress reached this run (0.0–100.0 percent of level).
func record_progress_pct(profile_id: String, level_id: String, pct: float) -> void:
	var data: Dictionary = load_progress(profile_id)
	if data.is_empty():
		ensure_profile(profile_id)
		data = load_progress(profile_id)
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var entry: Dictionary = _ensure_level_entry(levels, level_id)
	var best: float = float(entry.get("best_progress_pct", 0.0))
	if pct > best:
		entry["best_progress_pct"] = pct
		levels[level_id] = entry
		data["levels"] = levels
		save_progress(profile_id, data)


func get_best_stars(profile_id: String, level_id: String) -> int:
	var data: Dictionary = load_progress(profile_id)
	return int(((data.get("levels", {}) as Dictionary).get(level_id, {}) as Dictionary).get("best_stars", 0))


func get_best_progress_pct(profile_id: String, level_id: String) -> float:
	var data: Dictionary = load_progress(profile_id)
	return float(((data.get("levels", {}) as Dictionary).get(level_id, {}) as Dictionary).get("best_progress_pct", 0.0))


func get_attempts(profile_id: String, level_id: String) -> int:
	var data: Dictionary = load_progress(profile_id)
	return int(((data.get("levels", {}) as Dictionary).get(level_id, {}) as Dictionary).get("attempts", 0))


func get_total_stars(profile_id: String) -> int:
	var data: Dictionary = load_progress(profile_id)
	return int(data.get("total_stars", 0))


func is_level_cleared(profile_id: String, level_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	return (data.get("levels", {}) as Dictionary).has(level_id)


func get_all_level_results(profile_id: String) -> Dictionary:
	var data: Dictionary = load_progress(profile_id)
	return data.get("levels", {}) as Dictionary


func get_setting(profile_id: String, key: String, default: Variant) -> Variant:
	var data: Dictionary = load_progress(profile_id)
	return (data.get("settings", {}) as Dictionary).get(key, default)


func set_setting(profile_id: String, key: String, value: Variant) -> void:
	var data: Dictionary = load_progress(profile_id)
	if data.is_empty():
		ensure_profile(profile_id)
		data = load_progress(profile_id)
	var settings: Dictionary = data.get("settings", {}) as Dictionary
	settings[key] = value
	data["settings"] = settings
	save_progress(profile_id, data)


# ── Coins ────────────────────────────────────────────────────────────────────

func get_coins(profile_id: String) -> int:
	var data: Dictionary = load_progress(profile_id)
	return int(data.get("coins", 0))


func add_coins(profile_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var data: Dictionary = load_progress(profile_id)
	data["coins"] = int(data.get("coins", 0)) + amount
	save_progress(profile_id, data)
	EventBus.coins_changed.emit(profile_id, data["coins"])


## Returns true if deduction succeeded; false if insufficient funds.
func spend_coins(profile_id: String, amount: int) -> bool:
	var data: Dictionary = load_progress(profile_id)
	var current: int = int(data.get("coins", 0))
	if current < amount:
		return false
	data["coins"] = current - amount
	save_progress(profile_id, data)
	EventBus.coins_changed.emit(profile_id, data["coins"])
	return true


## Atomic purchase: deducts coins AND adds cosmetic in one save.
func buy_cosmetic(profile_id: String, item_id: String, cost: int) -> bool:
	var data: Dictionary = load_progress(profile_id)
	var current_coins: int = int(data.get("coins", 0))
	if current_coins < cost:
		return false
	data["coins"] = current_coins - cost
	if not data.has("cosmetics"):
		data["cosmetics"] = {"owned": [], "equipped": {"trail": "", "ring": "", "palette": ""}}
	var owned: Array = (data["cosmetics"] as Dictionary).get("owned", []) as Array
	if not (item_id in owned):
		owned.append(item_id)
	(data["cosmetics"] as Dictionary)["owned"] = owned
	save_progress(profile_id, data)
	EventBus.coins_changed.emit(profile_id, data["coins"])
	return true


# ── Achievements ──────────────────────────────────────────────────────────────

func get_achievement(profile_id: String, achievement_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	return bool((data.get("achievements", {}) as Dictionary).get(achievement_id, false))


func set_achievement(profile_id: String, achievement_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("achievements"):
		data["achievements"] = {}
	(data["achievements"] as Dictionary)[achievement_id] = true
	save_progress(profile_id, data)


# ── Characters ────────────────────────────────────────────────────────────────

func get_character_unlocked(profile_id: String, char_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	return bool((data.get("characters", {}) as Dictionary).get(char_id, false))


func set_character_unlocked(profile_id: String, char_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("characters"):
		data["characters"] = {}
	(data["characters"] as Dictionary)[char_id] = true
	save_progress(profile_id, data)
	EventBus.character_unlocked.emit(char_id)


func get_equipped_character(profile_id: String) -> String:
	var data: Dictionary = load_progress(profile_id)
	return str((data.get("cosmetics", {}) as Dictionary).get("equipped_character", "default_fish"))


func set_equipped_character(profile_id: String, char_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("cosmetics"):
		data["cosmetics"] = {}
	(data["cosmetics"] as Dictionary)["equipped_character"] = char_id
	save_progress(profile_id, data)


# ── Cosmetics ─────────────────────────────────────────────────────────────────

func get_cosmetic_owned(profile_id: String, item_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	var owned: Array = ((data.get("cosmetics", {}) as Dictionary).get("owned", []) as Array)
	return item_id in owned


func get_equipped_cosmetic(profile_id: String, slot: String) -> String:
	var data: Dictionary = load_progress(profile_id)
	var equipped: Dictionary = (data.get("cosmetics", {}) as Dictionary).get("equipped", {}) as Dictionary
	return str(equipped.get(slot, ""))


func set_equipped_cosmetic(profile_id: String, slot: String, item_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("cosmetics"):
		data["cosmetics"] = {}
	if not (data["cosmetics"] as Dictionary).has("equipped"):
		(data["cosmetics"] as Dictionary)["equipped"] = {}
	((data["cosmetics"] as Dictionary)["equipped"] as Dictionary)[slot] = item_id
	save_progress(profile_id, data)


# ── Treasure coins ────────────────────────────────────────────────────────────

func get_treasure_coin(profile_id: String, level_id: String, coin_idx: int) -> bool:
	var data: Dictionary = load_progress(profile_id)
	var level_data: Dictionary = (data.get("levels", {}) as Dictionary).get(level_id, {}) as Dictionary
	var coins: Array = level_data.get("treasure_coins", [false, false, false]) as Array
	if coin_idx < 0 or coin_idx >= coins.size():
		return false
	return bool(coins[coin_idx])


func set_treasure_coin(profile_id: String, level_id: String, coin_idx: int) -> void:
	if coin_idx < 0 or coin_idx > 2:
		return
	var data: Dictionary = load_progress(profile_id)
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var level_data: Dictionary = _ensure_level_entry(levels, level_id)
	if not level_data.has("treasure_coins"):
		level_data["treasure_coins"] = [false, false, false]
	(level_data["treasure_coins"] as Array)[coin_idx] = true
	levels[level_id] = level_data
	data["levels"] = levels
	save_progress(profile_id, data)
	EventBus.treasure_coin_collected.emit(level_id, coin_idx)


func count_treasure_coins(profile_id: String) -> int:
	var data: Dictionary = load_progress(profile_id)
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var total: int = 0
	for level_data: Variant in levels.values():
		var coins: Array = (level_data as Dictionary).get("treasure_coins", []) as Array
		for c: Variant in coins:
			if bool(c):
				total += 1
	return total


func _ensure_level_entry(levels: Dictionary, level_id: String) -> Dictionary:
	if levels.has(level_id):
		return levels[level_id] as Dictionary
	return {
		"best_score": 0,
		"best_stars": 0,
		"attempts": 0,
		"best_progress_pct": 0.0,
		"treasure_coins": [false, false, false],
		"practice_best_pct": 0.0,
	}


# ── Resonance Powers ─────────────────────────────────────────────────────────

func get_power_unlocked(profile_id: String, power_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	return bool((data.get("powers_unlocked", {}) as Dictionary).get(power_id, false))


func set_power_unlocked(profile_id: String, power_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("powers_unlocked"):
		data["powers_unlocked"] = {"bubble_burst": true}
	(data["powers_unlocked"] as Dictionary)[power_id] = true
	save_progress(profile_id, data)


func get_equipped_power(profile_id: String) -> String:
	var data: Dictionary = load_progress(profile_id)
	return str(data.get("equipped_power", "bubble_burst"))


func set_equipped_power(profile_id: String, power_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	data["equipped_power"] = power_id
	save_progress(profile_id, data)


# ── Build Mode Unlocks ────────────────────────────────────────────────────────

func has_build_unlock(profile_id: String, category: String, item_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	var unlocks: Dictionary = data.get("build_unlocks", {}) as Dictionary
	var list: Array = unlocks.get(category, []) as Array
	return item_id in list


func add_build_unlock(profile_id: String, category: String, item_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("build_unlocks"):
		data["build_unlocks"] = _fresh_v3_extras().get("build_unlocks", {})
	var unlocks: Dictionary = data["build_unlocks"] as Dictionary
	if not unlocks.has(category):
		unlocks[category] = []
	var list: Array = unlocks[category] as Array
	if not (item_id in list):
		list.append(item_id)
		unlocks[category] = list
		data["build_unlocks"] = unlocks
		save_progress(profile_id, data)
		EventBus.build_unlock_earned.emit(category, item_id)


func get_build_unlocks(profile_id: String, category: String) -> Array:
	var data: Dictionary = load_progress(profile_id)
	var unlocks: Dictionary = data.get("build_unlocks", {}) as Dictionary
	return unlocks.get(category, []) as Array


# ── Blueprints ────────────────────────────────────────────────────────────────

func get_blueprints(profile_id: String) -> Array:
	var data: Dictionary = load_progress(profile_id)
	return data.get("blueprints", []) as Array


func add_blueprint(profile_id: String, blueprint_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("blueprints"):
		data["blueprints"] = []
	var blueprints: Array = data["blueprints"] as Array
	if not (blueprint_id in blueprints):
		blueprints.append(blueprint_id)
		data["blueprints"] = blueprints
		save_progress(profile_id, data)


# ── Workshop Rank ─────────────────────────────────────────────────────────────

func get_workshop_rank(profile_id: String) -> int:
	var data: Dictionary = load_progress(profile_id)
	return int(data.get("workshop_rank", 0))


func add_workshop_xp(profile_id: String, xp: int) -> void:
	var data: Dictionary = load_progress(profile_id)
	var current_xp: int = int(data.get("workshop_xp", 0)) + xp
	data["workshop_xp"] = current_xp
	var rank: int = _xp_to_rank(current_xp)
	data["workshop_rank"] = rank
	save_progress(profile_id, data)


func _xp_to_rank(xp: int) -> int:
	# 0-99: rank 0 (Drifter), 100-299: rank 1 (Builder), 300-599: rank 2 (Architect),
	# 600+: rank 3 (Master Maker).
	if xp >= 600: return 3
	if xp >= 300: return 2
	if xp >= 100: return 1
	return 0


# ── Secret Exits ──────────────────────────────────────────────────────────────

func get_secret_exit_found(profile_id: String, level_id: String, exit_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	var exits: Dictionary = data.get("secret_exits_found", {}) as Dictionary
	return bool((exits.get(level_id, {}) as Dictionary).get(exit_id, false))


func set_secret_exit_found(profile_id: String, level_id: String, exit_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("secret_exits_found"):
		data["secret_exits_found"] = {}
	var exits: Dictionary = data["secret_exits_found"] as Dictionary
	if not exits.has(level_id):
		exits[level_id] = {}
	(exits[level_id] as Dictionary)[exit_id] = true
	data["secret_exits_found"] = exits
	save_progress(profile_id, data)
	EventBus.secret_exit_found.emit(level_id, exit_id)


# ── Mutators ──────────────────────────────────────────────────────────────────

func get_mutator_unlocked(profile_id: String, mutator_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	var list: Array = data.get("mutators_unlocked", []) as Array
	return mutator_id in list


func add_mutator_unlock(profile_id: String, mutator_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("mutators_unlocked"):
		data["mutators_unlocked"] = []
	var list: Array = data["mutators_unlocked"] as Array
	if not (mutator_id in list):
		list.append(mutator_id)
		data["mutators_unlocked"] = list
		save_progress(profile_id, data)


# ── Rule Cards ────────────────────────────────────────────────────────────────

func get_rule_card_unlocked(profile_id: String, card_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	var list: Array = data.get("rule_cards_unlocked", []) as Array
	return card_id in list


func add_rule_card_unlock(profile_id: String, card_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("rule_cards_unlocked"):
		data["rule_cards_unlocked"] = []
	var list: Array = data["rule_cards_unlocked"] as Array
	if not (card_id in list):
		list.append(card_id)
		data["rule_cards_unlocked"] = list
		save_progress(profile_id, data)


# ── Radio Keys ────────────────────────────────────────────────────────────────

func has_radio_key(profile_id: String, key_id: String) -> bool:
	var data: Dictionary = load_progress(profile_id)
	var list: Array = data.get("radio_keys", []) as Array
	return key_id in list


func add_radio_key(profile_id: String, key_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("radio_keys"):
		data["radio_keys"] = []
	var list: Array = data["radio_keys"] as Array
	if not (key_id in list):
		list.append(key_id)
		data["radio_keys"] = list
		save_progress(profile_id, data)


# ── World Stations ────────────────────────────────────────────────────────────

func get_world_stations_unlocked(profile_id: String) -> Array:
	var data: Dictionary = load_progress(profile_id)
	return data.get("world_stations_unlocked", ["ocean"]) as Array


func unlock_world_station(profile_id: String, station_id: String) -> void:
	var data: Dictionary = load_progress(profile_id)
	if not data.has("world_stations_unlocked"):
		data["world_stations_unlocked"] = ["ocean"]
	var list: Array = data["world_stations_unlocked"] as Array
	if not (station_id in list):
		list.append(station_id)
		data["world_stations_unlocked"] = list
		save_progress(profile_id, data)


func _write_json(path: String, payload: Dictionary) -> void:
	var tmp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: Cannot open '%s' for writing." % tmp_path)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	# Atomic rename: remove destination then rename tmp into place.
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	DirAccess.rename_absolute(tmp_path, path)
