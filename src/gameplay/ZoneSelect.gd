extends Control

class_name ZoneSelect

# Z6 secret unlocks at 120 total stars; a hint shows at 100 stars.
const Z6_UNLOCK_STARS: int = 120
const Z6_HINT_STARS: int = 100

const ZONES: Array = [
	{"id": "z1", "name": "1. Sunlit Shallows", "bpm": "100-115 BPM"},
	{"id": "z2", "name": "2. Kelp Forest Canyon", "bpm": "120-130 BPM", "requires": "z1-l4"},
	{"id": "z3", "name": "3. Shipwreck Alley", "bpm": "130-145 BPM", "requires": "z2-l4"},
	{"id": "z4", "name": "4. Volcanic Vent Fields", "bpm": "145-165 BPM", "requires": "z3-l4"},
	{"id": "z5", "name": "5. Twilight Trench", "bpm": "80-165 BPM", "requires": "z4-l4"},
	{"id": "z6", "name": "6. Ancient Sunken Factory", "bpm": "170-180 BPM", "secret": true},
]

var _profile: String = ""


func _ready() -> void:
	_profile = SaveSystem.get_active_profile_id()
	$BackButton.pressed.connect(func() -> void: GameManager.go_to_menu())
	_build_zone_list()


func _build_zone_list() -> void:
	var total_stars: int = SaveSystem.get_total_stars(_profile)
	for zone: Variant in ZONES:
		var z: Dictionary = zone as Dictionary
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 200)
		btn.add_theme_font_size_override("font_size", 36)
		var locked: bool = not _is_unlocked(z, total_stars)

		if locked:
			if z.get("secret", false):
				if total_stars >= Z6_HINT_STARS:
					btn.text = "???   (almost there…)"
				else:
					btn.text = "???"
			elif z.has("requires"):
				btn.text = "[LOCKED] %s\nComplete %s" % [
					z["name"] as String,
					(z["requires"] as String).to_upper()
				]
			else:
				btn.text = "[LOCKED] %s" % (z["name"] as String)
			btn.disabled = true
		else:
			btn.text = "%s\n%s" % [z["name"] as String, z.get("bpm", "") as String]
			var zone_id: String = z["id"] as String
			btn.pressed.connect(func() -> void: GameManager.go_to_level_select(zone_id))

		$ZoneContainer.add_child(btn)


func _is_unlocked(zone: Dictionary, total_stars: int) -> bool:
	if zone.get("secret", false):
		return total_stars >= Z6_UNLOCK_STARS
	if zone.has("requires"):
		return SaveSystem.is_level_cleared(_profile, zone["requires"] as String)
	return true
