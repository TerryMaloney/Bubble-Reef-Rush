extends RefCounted

func get_phases() -> Array:
	return [
		{"beat_threshold": 10.0, "name": "approach", "pattern": "lava_burst_wall"},
		{"beat_threshold": 20.0, "name": "frenzy", "pattern": "pressure_wave_surge"},
		{"beat_threshold": 32.0, "name": "final", "pattern": "volcanic_finale"},
	]
