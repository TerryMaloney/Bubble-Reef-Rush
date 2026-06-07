extends Control

class_name ZoneSelect

const ZONES: Array = [
	{"id": "z1", "name": "1. Sunlit Shallows", "bpm": "100-115 BPM"},
	{"id": "z2", "name": "2. Kelp Forest Canyon", "bpm": "120-130 BPM", "requires": "z1-l4"},
	{"id": "z3", "name": "3. Shipwreck Alley", "bpm": "130-145 BPM", "requires": "z2-l4"},
	{"id": "z4", "name": "4. Volcanic Vent Fields", "bpm": "145-165 BPM", "iap": true},
	{"id": "z5", "name": "5. Twilight Trench", "bpm": "80-165 BPM", "iap": true},
	{"id": "z6", "name": "6. Crystal Caves", "bpm": "170-180 BPM", "secret": true},
]

var _profile: String = ""


func _ready() -> void:
	_profile = SaveSystem.get_active_profile_id()
	$BackButton.pressed.connect(func() -> void: GameManager.go_to_menu())
	_build_zone_list()


func _build_zone_list() -> void:
	for zone: Variant in ZONES:
		var z: Dictionary = zone as Dictionary
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 100)
		var locked: bool = not _is_unlocked(z)

		if locked:
			var why: String = ""
			if z.get("iap", false):
				why = "  (Full Reef required)"
			elif z.get("secret", false):
				why = "  (earn 3 stars on all levels)"
			elif z.has("requires"):
				why = "  (complete %s)" % (z["requires"] as String).to_upper()
			btn.text = "[LOCKED] %s%s" % [z["name"] as String, why]
			btn.disabled = true
		else:
			btn.text = "%s   %s" % [z["name"] as String, z.get("bpm", "") as String]
			var zone_id: String = z["id"] as String
			btn.pressed.connect(func() -> void: GameManager.go_to_level_select(zone_id))

		$ZoneContainer.add_child(btn)


func _is_unlocked(zone: Dictionary) -> bool:
	if zone.get("iap", false) or zone.get("secret", false):
		return false
	if zone.has("requires"):
		return SaveSystem.is_level_cleared(_profile, zone["requires"] as String)
	return true
