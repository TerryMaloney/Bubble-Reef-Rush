extends Control

class_name LevelSelect

const ZONE_NAMES: Dictionary = {
	"z1": "Sunlit Shallows",
	"z2": "Kelp Forest Canyon",
	"z3": "Shipwreck Alley",
	"z4": "Volcanic Vent Fields",
	"z5": "Twilight Trench",
	"z6": "Crystal Caves",
}

const LEVEL_NAMES: Dictionary = {
	"z1": ["First Dive", "Spike Garden", "Jellyfish Patrol", "Sun Diver",
		   "Double Jelly", "Reef Cluster", "Combo Run", "Sunlit Finale"],
	"z2": ["Kelp Sprint", "Curtain Call", "Mine Field", "Canyon Run",
		   "Tunnel Vision", "Double Hazard", "Long Tunnel", "Kelp Mastery"],
	"z3": ["Wreck Intro", "Jet Stream", "Chain Swing", "Eel Alley",
		   "Hull Breach", "Dense Corridor", "Mixed Wreck", "Dual Eels"],
	"z4": ["Hot Start", "First Eruption", "Mine Burst", "Pressure Drop",
		   "Dual Hazard", "Volcanic Surge", "Heat Wave", "Eruption Finale"],
	"z5": ["Slow Descent", "Dark Passage", "Mirror Run", "Void Mirror",
		   "Full Chaos", "Max Range", "Precision Run", "Trench Master"],
	"z6": ["Shard Intro", "Shard Mirror", "Burst Shard", "Wall Shard",
		   "Dark Shard", "Peak Difficulty", "Triple Gauntlet", "Rainbow Run"],
}

var _profile: String = ""


func _ready() -> void:
	_profile = SaveSystem.get_active_profile_id()
	var zone_id: String = GameManager.current_zone_id
	$ZoneTitle.text = ZONE_NAMES.get(zone_id, zone_id.to_upper()) as String
	$BackButton.pressed.connect(func() -> void: GameManager.go_to_zone_select())
	_build_level_list(zone_id)


func _build_level_list(zone_id: String) -> void:
	var results: Dictionary = SaveSystem.get_all_level_results(_profile)
	var names: Array = LEVEL_NAMES.get(zone_id, []) as Array

	for i: int in range(8):
		var level_id: String = "%s-l%d" % [zone_id, i + 1]
		var level_name: String = names[i] as String if i < names.size() else "Level %d" % (i + 1)
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 88)

		var level_exists: bool = FileAccess.file_exists("res://assets/levels/%s.brl" % level_id)
		if not level_exists:
			btn.text = "L%d  %s  [soon]" % [i + 1, level_name]
			btn.disabled = true
		else:
			var stars: int = int((results.get(level_id, {}) as Dictionary).get("best_stars", 0))
			btn.text = "L%d  %s  %s" % [i + 1, level_name, _stars_text(stars)]
			var lid: String = level_id
			btn.pressed.connect(func() -> void: GameManager.start_level(lid))

		$LevelContainer.add_child(btn)


func _stars_text(stars: int) -> String:
	match stars:
		3: return "[* * *]"
		2: return "[* *  ]"
		1: return "[*    ]"
		_: return "[     ]"
