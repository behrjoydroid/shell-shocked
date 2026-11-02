extends RefCounted

const Resolver := preload("res://sim/resolver.gd")
const Squad := preload("res://sim/squad.gd")
const TICK := 0.25


func _stats() -> Dictionary:
	return (load("res://data/sim.json") as JSON).data


func _squad(soldiers: int, supply := 1.0) -> Squad:
	var squad := Squad.new(0, "x", "x", soldiers, 40.0)
	squad.ammo = 40.0 * supply
	return squad


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _soldiers(side: Array) -> int:
	var total := 0
	for squad in side:
		total += squad.soldiers
	return total


# Fights until one side is gone, or nobody left can shoot.
func _fight_out(a: Array, b: Array, fort_a: float, fort_b: float, rng: RandomNumberGenerator) -> void:
	var stats := _stats()
	for i in 200000:
		if _soldiers(a) == 0 or _soldiers(b) == 0:
			return
		if Resolver.firepower(a, stats) == 0.0 and Resolver.firepower(b, stats) == 0.0:
			return
		Resolver.fight(a, b, fort_a, fort_b, TICK, stats, rng)


func _wins_for_a(trials: int, make_a: Callable, make_b: Callable, fort_a := 0.0, fort_b := 0.0) -> int:
	var wins := 0
	for trial in trials:
		var a: Array = make_a.call()
		var b: Array = make_b.call()
		_fight_out(a, b, fort_a, fort_b, _rng(trial))
		if _soldiers(a) > _soldiers(b):
			wins += 1
	return wins


func test_a_squad_with_no_ammo_cannot_shoot() -> void:
	var stats := _stats()
	var starved := [_squad(8, 0.0)]
	var supplied := [_squad(8)]
	var rng := _rng(1)
	for i in 600:
		Resolver.fight(starved, supplied, 0.0, 0.0, TICK, stats, rng)
	assert(supplied[0].soldiers == 8, "took fire from a squad with no ammo")
	assert(starved[0].soldiers < 8, "took no fire from a supplied squad")


func test_low_supply_fires_less_than_full_supply() -> void:
	var stats := _stats()
	var low: float = Resolver.firepower([_squad(8, 0.1)], stats)
	var full: float = Resolver.firepower([_squad(8, 1.0)], stats)
	assert(low > 0.0 and low < full, "%f vs %f" % [low, full])
	assert(Resolver.firepower([_squad(8, 0.0)], stats) == 0.0)


func test_losses_match_the_kill_rate_on_average() -> void:
	var stats := _stats()
	var rng := _rng(2)
	var losses := 0
	var ticks := 8000
	for i in ticks:
		var a := [_squad(8)]
		Resolver.fight(a, [_squad(8)], 0.0, 0.0, TICK, stats, rng)
		losses += 8 - a[0].soldiers
	var expected: float = 8.0 * stats.kill_rate_per_shooter_per_sec * TICK * ticks
	assert(absf(losses - expected) < expected * 0.15, "%d losses, expected about %.0f" % [losses, expected])


func test_fortification_cuts_incoming_fire_by_its_share() -> void:
	var stats := _stats()
	var rng := _rng(3)
	var losses := 0
	var ticks := 8000
	var fort := 0.5
	for i in ticks:
		var a := [_squad(8)]
		Resolver.fight(a, [_squad(8)], fort, 0.0, TICK, stats, rng)
		losses += 8 - a[0].soldiers
	var share: float = 1.0 - fort * stats.fortification_protection
	var expected: float = 8.0 * stats.kill_rate_per_shooter_per_sec * TICK * ticks * share
	assert(absf(losses - expected) < expected * 0.15, "%d losses, expected about %.0f" % [losses, expected])


func test_an_even_fight_is_even() -> void:
	var wins := _wins_for_a(400, func(): return [_squad(8)], func(): return [_squad(8)])
	assert(wins > 160 and wins < 240, "side A won %d of 400" % wins)


func test_side_order_gives_no_edge_when_losses_are_certain() -> void:
	# Above 1 expected loss a tick, a first-mover edge would show straight away.
	var stats := _stats().duplicate()
	stats.kill_rate_per_shooter_per_sec = 1.0
	var a := [_squad(8)]
	var b := [_squad(8)]
	Resolver.fight(a, b, 0.0, 0.0, 1.0, stats, _rng(4))
	assert(a[0].soldiers == 0 and b[0].soldiers == 0, "both fired at once, so both are gone")


func test_the_bigger_side_wins_nearly_always() -> void:
	var wins := _wins_for_a(200, func(): return [_squad(8)], func(): return [_squad(4)])
	assert(wins >= 190, "8 beat 4 only %d of 200 times" % wins)


func test_supply_decides_fights() -> void:
	var wins := _wins_for_a(200, func(): return [_squad(8, 1.0)], func(): return [_squad(8, 0.1)])
	assert(wins >= 130, "full supply beat low supply only %d of 200 times" % wins)


func test_fortification_decides_fights() -> void:
	var wins := _wins_for_a(200, func(): return [_squad(8)], func(): return [_squad(8)], 0.5, 0.0)
	assert(wins >= 130, "fortified side won only %d of 200 times" % wins)


func test_ammo_burns_only_with_soldiers_firing_and_never_goes_negative() -> void:
	var stats := _stats()
	var a := [_squad(8, 0.001)]
	var b := [_squad(4, 1.0)]
	var rng := _rng(5)
	for i in 1000:
		var before_a: float = a[0].ammo
		Resolver.fight(a, b, 0.0, 0.0, TICK, stats, rng)
		assert(a[0].ammo >= 0.0 and b[0].ammo >= 0.0, "ammo went negative")
		assert(a[0].ammo <= before_a, "ammo grew in a fight")


func test_soldiers_never_go_negative_or_come_back() -> void:
	var stats := _stats()
	var a := [_squad(8), _squad(3), _squad(1)]
	var b := [_squad(8), _squad(2)]
	var rng := _rng(6)
	var before := {}
	for i in 1000:
		for squad in a + b:
			before[squad] = squad.soldiers
		Resolver.fight(a, b, 0.0, 0.0, TICK, stats, rng)
		for squad in a + b:
			assert(squad.soldiers >= 0, "negative soldiers")
			assert(squad.soldiers <= before[squad], "a soldier came back")


func test_more_expected_losses_than_soldiers_stops_at_zero() -> void:
	var stats := _stats().duplicate()
	stats.kill_rate_per_shooter_per_sec = 100.0
	var a := [_squad(2), _squad(1)]
	Resolver.fight(a, [_squad(8)], 0.0, 0.0, 1.0, stats, _rng(7))
	assert(a[0].soldiers == 0 and a[1].soldiers == 0, "%d, %d" % [a[0].soldiers, a[1].soldiers])


func test_same_seed_same_fight() -> void:
	var run := func(seed_value: int) -> Array:
		var a := [_squad(8), _squad(5)]
		var b := [_squad(8), _squad(4)]
		_fight_out(a, b, 0.1, 0.2, _rng(seed_value))
		return [a[0].soldiers, a[1].soldiers, b[0].soldiers, b[1].soldiers, a[0].ammo, b[0].ammo]
	assert(run.call(42) == run.call(42), "same seed should replay exactly")
	var differed := false
	for seed_value in 10:
		differed = differed or run.call(seed_value) != run.call(seed_value + 100)
	assert(differed, "different seeds should give different fights")
