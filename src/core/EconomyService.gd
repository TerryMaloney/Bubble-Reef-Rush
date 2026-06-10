## EconomyService — autoload that grants coins for run achievements.
## Idempotency is session-based: closing and reopening the game allows re-earning.
## All grants are per-level-per-session to prevent farming from repeated retries.
extends Node

const FIRST_CLEAR_GRANT: int = 25
const THREE_STAR_GRANT: int = 50
const IMPROVEMENT_GRANT: int = 15
const COMBO_MILESTONE_GRANT: int = 5

## Session state — cleared by reset_session() and on app start.
var _first_clear_session: Dictionary = {}   # level_id → true
var _three_star_session: Dictionary = {}    # level_id → true
var _improvement_session: Dictionary = {}   # level_id → true
var _combo_session: Dictionary = {}         # level_id → true


## Process coin grants for a completed run. Returns total coins granted.
## Call BEFORE SaveSystem.update_level_result() so the improvement check sees
## the previous best score, not the new one.
func process_run_completed(level_id: String, score: int, stars: int) -> int:
	var profile: String = SaveSystem.get_active_profile_id()
	var earned: int = 0

	# First clear this level this session.
	if not _first_clear_session.has(level_id):
		_first_clear_session[level_id] = true
		earned += FIRST_CLEAR_GRANT

	# Three-star this level this session.
	if stars == 3 and not _three_star_session.has(level_id):
		_three_star_session[level_id] = true
		earned += THREE_STAR_GRANT

	# Score improvement over previous best this session.
	if score > 0 and not _improvement_session.has(level_id):
		var prev_results: Dictionary = SaveSystem.get_all_level_results(profile)
		var prev_best: int = int((prev_results.get(level_id, {}) as Dictionary).get("best_score", 0))
		if score > prev_best:
			_improvement_session[level_id] = true
			earned += IMPROVEMENT_GRANT

	if earned > 0:
		SaveSystem.add_coins(profile, earned)

	return earned


## Award the combo milestone grant for this level (once per session).
## Call when the player first enters fever mode (combo ≥ 30) during a run.
func award_combo_milestone(level_id: String) -> void:
	if _combo_session.has(level_id):
		return
	_combo_session[level_id] = true
	SaveSystem.add_coins(SaveSystem.get_active_profile_id(), COMBO_MILESTONE_GRANT)


## Reset session tracking — called on new game session or by tests.
func reset_session() -> void:
	_first_clear_session.clear()
	_three_star_session.clear()
	_improvement_session.clear()
	_combo_session.clear()
