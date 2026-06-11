## DailyDiveScreen — displays today's three Daily Dive levels and saves results.
## get_today_levels() is deterministic: same output for the whole calendar day.
extends Node

class_name DailyDiveScreen


func get_today_levels() -> Array[String]:
	var date: String = Time.get_date_string_from_system()
	var seed: int = DeterministicSeed.date_seed(date)
	return DeterministicSeed.pick_levels(seed, 3, [1, 6])


func complete_dive(profile_id: String, score: int) -> void:
	var date: String = Time.get_date_string_from_system()
	SaveSystem.set_daily_dive_result(profile_id, date, score)
	EventBus.daily_dive_completed.emit(date, score)
