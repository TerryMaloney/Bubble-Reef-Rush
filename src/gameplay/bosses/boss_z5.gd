extends RefCounted

func get_phases() -> Array:
	return [
		{"beat_threshold": 12.0, "name": "approach", "pattern": "dark_void_ambush"},
		{"beat_threshold": 24.0, "name": "frenzy", "pattern": "mirror_fish_echo"},
		{"beat_threshold": 36.0, "name": "final", "pattern": "void_mirror_finale"},
	]
