## economy_test.gd — Phase 7 contracts for EconomyService, AchievementSystem, SaveSystem coins.
##
## Tests:
##   1. Coin grant table: first_clear=25, 3-star=50, improvement=15.
##   2. Session idempotency: same level doesn't grant coins twice per session.
##   3. Coin persistence: add_coins writes to save, get_coins reads back.
##   4. Achievement rule engine: levels_cleared and stars_total rules.
##   5. Shop atomicity: buy_cosmetic deducts coins + records ownership atomically.
##   6. Treasure coin persistence: set/get by level + index.
##   7. Character rule: zone_cleared unlock condition evaluates correctly.
##
## Run with:
##   godot --headless --path . --script tests/integration/economy_test.gd
extends SceneTree

var _failures: PackedStringArray = []
var _economy: Node = null
var _ach: Node = null
var _save: Node = null
var _event_bus: Node = null

## Scratch profile used for all tests — isolated from active player profile.
const TEST_PROFILE: String = "_econ_test_scratch"


func _init() -> void:
	await process_frame
	await process_frame

	_economy = root.get_node("EconomyService")
	_ach = root.get_node("AchievementSystem")
	_save = root.get_node("SaveSystem")
	_event_bus = root.get_node("EventBus")

	# Ensure a clean test profile.
	_save.ensure_profile(TEST_PROFILE)
	_wipe_test_profile()

	await _test_grant_table()
	await _test_session_idempotency()
	await _test_coin_persistence()
	await _test_achievement_rule_engine()
	await _test_shop_atomicity()
	await _test_treasure_coin_persistence()
	await _test_character_zone_cleared_rule()

	print("==== ECONOMY TEST ====")
	if _failures.is_empty():
		print("All Phase 7 economy contracts hold.")
		print("ECONOMY_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("ECONOMY_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


func _wipe_test_profile() -> void:
	# Reset coins/achievements/characters/levels to zero for isolation.
	var data: Dictionary = _save.load_progress(TEST_PROFILE)
	data["coins"] = 0
	data["achievements"] = {}
	data["characters"] = {"default_fish": true}
	data["levels"] = {}
	data["total_stars"] = 0
	_save.save_progress(TEST_PROFILE, data)


## Temporarily redirect active profile to our test profile.
func _with_test_profile(callable: Callable) -> void:
	var real_profile: String = _save.get_active_profile_id()
	_save.set_active_profile(TEST_PROFILE)
	callable.call()
	_save.set_active_profile(real_profile)


## ── Grant table ──────────────────────────────────────────────────────────────
func _test_grant_table() -> void:
	_wipe_test_profile()
	_economy.reset_session()

	var real_profile: String = _save.get_active_profile_id()
	_save.set_active_profile(TEST_PROFILE)

	# First clear: +25 (first_clear) + 15 (improvement over 0 prev best) = 40.
	var earned: int = _economy.process_run_completed("z1-l1", 100, 1)
	if earned != 40:
		_fail("Grant table: first_clear+improvement expected 40, got %d" % earned)
	else:
		print("Grant table: first_clear+improvement = 40 — OK")

	# 3-star new level: +25 (first_clear) + 50 (three_star) + 15 (improvement) = 90.
	var earned2: int = _economy.process_run_completed("z1-l2", 500, 3)
	if earned2 != 90:
		_fail("Grant table: first_clear+3star+improvement expected 90, got %d" % earned2)
	else:
		print("Grant table: first_clear+3star+improvement = 90 — OK")

	# Verify individual grants: set a previous best and re-run to isolate first_clear only.
	_economy.reset_session()
	_save.update_level_result(TEST_PROFILE, "z1-l3", 200, 1)  # pre-set best score
	var earned3: int = _economy.process_run_completed("z1-l3", 150, 1)  # score < prev best → no improvement
	if earned3 != 25:
		_fail("Grant table: first_clear only expected 25, got %d" % earned3)
	else:
		print("Grant table: first_clear only (no improvement) = 25 — OK")

	_save.set_active_profile(real_profile)
	_economy.reset_session()
	await process_frame


## ── Session idempotency ───────────────────────────────────────────────────────
func _test_session_idempotency() -> void:
	_wipe_test_profile()
	_economy.reset_session()

	var real_profile: String = _save.get_active_profile_id()
	_save.set_active_profile(TEST_PROFILE)

	# First run grants coins.
	_economy.process_run_completed("z1-l1", 100, 1)
	var coins_after_first: int = _save.get_coins(TEST_PROFILE)

	# Second run of SAME level in same session: no grant.
	_economy.process_run_completed("z1-l1", 110, 1)
	var coins_after_second: int = _save.get_coins(TEST_PROFILE)

	_save.set_active_profile(real_profile)
	_economy.reset_session()

	if coins_after_first != coins_after_second:
		_fail("Session idempotency: coins changed on repeat run (first=%d, second=%d)" % [coins_after_first, coins_after_second])
	else:
		print("Session idempotency: no duplicate grant — OK")

	await process_frame


## ── Coin persistence ──────────────────────────────────────────────────────────
func _test_coin_persistence() -> void:
	_wipe_test_profile()

	_save.add_coins(TEST_PROFILE, 50)
	var coins: int = _save.get_coins(TEST_PROFILE)
	if coins != 50:
		_fail("Coin persistence: expected 50 after add, got %d" % coins)
		return

	_save.add_coins(TEST_PROFILE, 30)
	coins = _save.get_coins(TEST_PROFILE)
	if coins != 80:
		_fail("Coin persistence: expected 80 after second add, got %d" % coins)
		return

	# spend_coins returns false when insufficient.
	var ok: bool = _save.spend_coins(TEST_PROFILE, 100)
	if ok:
		_fail("Coin persistence: spend_coins should fail when insufficient")
		return

	ok = _save.spend_coins(TEST_PROFILE, 30)
	if not ok:
		_fail("Coin persistence: spend_coins failed with sufficient funds")
		return

	coins = _save.get_coins(TEST_PROFILE)
	if coins != 50:
		_fail("Coin persistence: expected 50 after spend, got %d" % coins)
	else:
		print("Coin persistence: add/spend round-trip — OK")

	await process_frame


## ── Achievement rule engine ───────────────────────────────────────────────────
func _test_achievement_rule_engine() -> void:
	_wipe_test_profile()

	# Test levels_cleared rule: need 1 level cleared.
	var rule_one: Dictionary = {"rule": "levels_cleared", "threshold": 1}
	if _ach.check_rule(rule_one, TEST_PROFILE):
		_fail("Achievement rule: levels_cleared/1 should be false on fresh profile")
		return

	# Add a cleared level.
	_save.update_level_result(TEST_PROFILE, "z1-l1", 100, 1)
	if not _ach.check_rule(rule_one, TEST_PROFILE):
		_fail("Achievement rule: levels_cleared/1 should be true after clearing z1-l1")
		return
	print("Achievement rule levels_cleared/1 — OK")

	# Test stars_total rule: need 10 stars.
	var rule_stars: Dictionary = {"rule": "stars_total", "threshold": 10}
	if _ach.check_rule(rule_stars, TEST_PROFILE):
		_fail("Achievement rule: stars_total/10 should be false (only 1 star)")
		return

	# Give 9 more stars.
	for i: int in range(2, 11):
		_save.update_level_result(TEST_PROFILE, "z1-l%d" % i, 100, 1)

	if not _ach.check_rule(rule_stars, TEST_PROFILE):
		_fail("Achievement rule: stars_total/10 should be true after 10 stars")
	else:
		print("Achievement rule stars_total/10 — OK")

	await process_frame


## ── Shop atomicity ────────────────────────────────────────────────────────────
func _test_shop_atomicity() -> void:
	_wipe_test_profile()
	_save.add_coins(TEST_PROFILE, 100)

	# Buy a cosmetic — should deduct coins AND record ownership.
	var ok: bool = _save.buy_cosmetic(TEST_PROFILE, "trail_bubbles", 60)
	if not ok:
		_fail("Shop atomicity: buy_cosmetic failed with sufficient funds")
		return

	var coins: int = _save.get_coins(TEST_PROFILE)
	if coins != 40:
		_fail("Shop atomicity: expected 40 coins after purchase, got %d" % coins)
		return

	if not _save.get_cosmetic_owned(TEST_PROFILE, "trail_bubbles"):
		_fail("Shop atomicity: item not recorded as owned after purchase")
		return
	print("Shop atomicity: coins deducted + ownership recorded atomically — OK")

	# Buying the same item again should succeed (re-buy) but not double-record.
	ok = _save.buy_cosmetic(TEST_PROFILE, "trail_bubbles", 0)
	if not ok:
		_fail("Shop atomicity: re-buy with 0 cost should succeed")
	else:
		print("Shop atomicity: re-buy idempotent — OK")

	await process_frame


## ── Treasure coin persistence ─────────────────────────────────────────────────
func _test_treasure_coin_persistence() -> void:
	_wipe_test_profile()

	if _save.get_treasure_coin(TEST_PROFILE, "z1-l1", 0):
		_fail("Treasure coin: coin 0 should start uncollected")
		return

	_save.set_treasure_coin(TEST_PROFILE, "z1-l1", 0)
	if not _save.get_treasure_coin(TEST_PROFILE, "z1-l1", 0):
		_fail("Treasure coin: coin 0 should be collected after set")
		return

	if _save.get_treasure_coin(TEST_PROFILE, "z1-l1", 1):
		_fail("Treasure coin: coin 1 should still be uncollected")
		return

	var total: int = _save.count_treasure_coins(TEST_PROFILE)
	if total != 1:
		_fail("Treasure coin: count_treasure_coins expected 1, got %d" % total)
	else:
		print("Treasure coin persistence: set/get/count — OK")

	await process_frame


## ── Character unlock: zone_cleared rule ──────────────────────────────────────
func _test_character_zone_cleared_rule() -> void:
	_wipe_test_profile()

	# zone_cleared requires all 8 levels cleared with ≥1 star.
	var rule: Dictionary = {"rule": "zone_cleared", "zone": "z1"}
	if _ach.check_rule(rule, TEST_PROFILE):
		_fail("Character zone_cleared: should be false on fresh profile")
		return

	# Clear 7 of 8 z1 levels.
	for i: int in range(1, 8):
		_save.update_level_result(TEST_PROFILE, "z1-l%d" % i, 100, 1)

	if _ach.check_rule(rule, TEST_PROFILE):
		_fail("Character zone_cleared: should be false with only 7/8 cleared")
		return

	# Clear the last level.
	_save.update_level_result(TEST_PROFILE, "z1-l8", 100, 1)
	if not _ach.check_rule(rule, TEST_PROFILE):
		_fail("Character zone_cleared: should be true after all 8 z1 levels cleared")
	else:
		print("Character unlock zone_cleared rule — OK")

	await process_frame
