extends RefCounted

func get_phases() -> Array:
	return [
		{"beat_threshold": 8.0, "name": "approach", "pattern": "crystal_storm"},
		{"beat_threshold": 16.0, "name": "buildup", "pattern": "shard_lattice"},
		{"beat_threshold": 24.0, "name": "frenzy", "pattern": "prismatic_barrage"},
		{"beat_threshold": 32.0, "name": "final", "pattern": "crystal_finale"},
	]
